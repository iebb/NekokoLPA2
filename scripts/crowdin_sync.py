#!/usr/bin/env python3

from __future__ import annotations

import argparse
import io
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request
import zipfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
APP_DIR = REPO_ROOT
SOURCE_FILE = APP_DIR / "l10n" / "app_en.arb"
SOURCE_REL = SOURCE_FILE.relative_to(REPO_ROOT).as_posix()
GENERATED_DIR = APP_DIR / "lib" / "l10n"
PROJECT_ID = 876432
FILE_ID = 5
API_BASE = "https://api.crowdin.com/api/v2"
POLL_INTERVAL_SECONDS = 2
POLL_TIMEOUT_SECONDS = 120
MANAGED_FILES = {
    "fr": APP_DIR / "l10n" / "app_fr.arb",
    "es-ES": APP_DIR / "l10n" / "app_es.arb",
    "de": APP_DIR / "l10n" / "app_de.arb",
    "it": APP_DIR / "l10n" / "app_it.arb",
    "ja": APP_DIR / "l10n" / "app_ja.arb",
    "ko": APP_DIR / "l10n" / "app_ko.arb",
    "ru": APP_DIR / "l10n" / "app_ru.arb",
    "zh-CN": APP_DIR / "l10n" / "app_zh.arb",
    "zh-TW": APP_DIR / "l10n" / "app_zh-TW.arb",
}


class CrowdinError(RuntimeError):
    pass


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Sync localizations with Crowdin for NekokoLPA2.",
    )
    parser.add_argument(
        "--pre-commit",
        action="store_true",
        help="Run the sync flow expected by the git pre-commit hook.",
    )
    parser.add_argument(
        "--upload-source",
        action="store_true",
        help="Upload the working tree English source file before pulling translations.",
    )
    args = parser.parse_args()

    token = get_crowdin_token()
    changed_source = args.upload_source or staged_source_changed()

    if changed_source:
        if args.upload_source:
            print("Crowdin: uploading working tree English source...", file=sys.stderr)
            upload_source(token, SOURCE_FILE.read_bytes())
        else:
            print("Crowdin: uploading staged English source...", file=sys.stderr)
            upload_source(token, get_staged_source_bytes())
    else:
        print("Crowdin: English source unchanged, skipping upload.", file=sys.stderr)

    print("Crowdin: ensuring configured target languages...", file=sys.stderr)
    ensure_project_target_languages(token)

    print("Crowdin: building translation bundle...", file=sys.stderr)
    archive = download_translation_bundle(token)

    print("Crowdin: applying downloaded translations...", file=sys.stderr)
    updated_files = apply_translations(archive)

    print("Crowdin: regenerating Flutter localizations...", file=sys.stderr)
    run_flutter_gen_l10n()

    if args.pre_commit:
        stage_managed_files()

    if updated_files:
        print(
            "Crowdin: updated files: " + ", ".join(path.relative_to(REPO_ROOT).as_posix() for path in updated_files),
            file=sys.stderr,
        )
    else:
        print("Crowdin: translations already up to date.", file=sys.stderr)

    return 0


def get_crowdin_token() -> str:
    token = os.environ.get("CROWDIN_TOKEN")
    if token:
        return token.strip()

    result = run_git("config", "--get", "crowdin.token", check=False)
    token = result.stdout.strip()
    if token:
        return token

    raise CrowdinError(
        "Crowdin token not configured. Set CROWDIN_TOKEN or run "
        "`git config crowdin.token <token>`."
    )


def staged_source_changed() -> bool:
    result = run_git("diff", "--cached", "--quiet", "--", SOURCE_REL, check=False)
    return result.returncode == 1


def get_staged_source_bytes() -> bytes:
    result = run_git("show", f":{SOURCE_REL}")
    return result.stdout.encode("utf-8")


def upload_source(token: str, content: bytes) -> None:
    storage = crowdin_request(
        token,
        "/storages",
        method="POST",
        data=content,
        headers={
            "Crowdin-API-FileName": "app.arb",
            "Content-Type": "application/octet-stream",
        },
    )
    storage_id = storage["data"]["id"]

    crowdin_request(
        token,
        f"/projects/{PROJECT_ID}/files/{FILE_ID}",
        method="PUT",
        json_body={
            "storageId": storage_id,
            "updateOption": "keep_translations",
        },
    )


def ensure_project_target_languages(token: str) -> None:
    project = crowdin_request(token, f"/projects/{PROJECT_ID}")
    current_languages = set(project["data"].get("targetLanguageIds") or [])
    managed_languages = set(MANAGED_FILES)
    missing_languages = sorted(managed_languages - current_languages)
    if not missing_languages:
        return

    updated_languages = sorted(current_languages | managed_languages)
    print(
        "Crowdin: adding target language(s): " + ", ".join(missing_languages),
        file=sys.stderr,
    )
    crowdin_request(
        token,
        f"/projects/{PROJECT_ID}",
        method="PATCH",
        json_body=[
            {
                "op": "replace",
                "path": "/targetLanguageIds",
                "value": updated_languages,
            },
        ],
    )


def download_translation_bundle(token: str) -> bytes:
    build = crowdin_request(
        token,
        f"/projects/{PROJECT_ID}/translations/builds",
        method="POST",
        json_body={},
    )
    build_id = build["data"]["id"]
    wait_for_build(token, build_id)
    download = crowdin_request(
        token,
        f"/projects/{PROJECT_ID}/translations/builds/{build_id}/download",
    )
    url = download["data"]["url"]

    with urllib.request.urlopen(url, timeout=60) as response:
        return response.read()


def wait_for_build(token: str, build_id: int) -> None:
    deadline = time.monotonic() + POLL_TIMEOUT_SECONDS
    while time.monotonic() < deadline:
        build = crowdin_request(
            token,
            f"/projects/{PROJECT_ID}/translations/builds/{build_id}",
        )
        status = build["data"]["status"]
        if status == "finished":
            return
        if status == "failed":
            raise CrowdinError(f"Crowdin translation build {build_id} failed.")
        time.sleep(POLL_INTERVAL_SECONDS)

    raise CrowdinError(f"Timed out waiting for Crowdin build {build_id}.")


def apply_translations(archive: bytes) -> list[Path]:
    updated: list[Path] = []
    with zipfile.ZipFile(io.BytesIO(archive)) as zf:
        for language, local_path in MANAGED_FILES.items():
            archive_path = f"{language}/l10n/app.arb"
            try:
                content = zf.read(archive_path)
            except KeyError as exc:
                raise CrowdinError(
                    f"Missing translated file `{archive_path}` in Crowdin bundle. "
                    f"Add or generate translations for `{language}` in Crowdin, "
                    "then rerun the sync."
                ) from exc

            if local_path.exists() and local_path.read_bytes() == content:
                continue

            local_path.write_bytes(content)
            updated.append(local_path)

    return updated


def run_flutter_gen_l10n() -> None:
    subprocess.run(
        ["flutter", "gen-l10n"],
        cwd=APP_DIR,
        check=True,
    )


def stage_managed_files() -> None:
    paths = [SOURCE_REL]
    paths.extend(path.relative_to(REPO_ROOT).as_posix() for path in MANAGED_FILES.values())
    paths.extend(
        path.relative_to(REPO_ROOT).as_posix()
        for path in sorted(GENERATED_DIR.glob("app_localizations*.dart"))
    )
    paths.append((APP_DIR / "untranslated.json").relative_to(REPO_ROOT).as_posix())
    run_git("add", "--", *paths)


def crowdin_request(
    token: str,
    path: str,
    *,
    method: str = "GET",
    data: bytes | None = None,
    json_body: dict | None = None,
    headers: dict[str, str] | None = None,
) -> dict:
    request_headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/json",
    }
    if headers:
        request_headers.update(headers)

    payload = data
    if json_body is not None:
        payload = json.dumps(json_body).encode("utf-8")
        request_headers["Content-Type"] = "application/json"

    request = urllib.request.Request(
        f"{API_BASE}{path}",
        data=payload,
        headers=request_headers,
        method=method,
    )

    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            return json.load(response)
    except urllib.error.HTTPError as exc:
        message = exc.read().decode("utf-8", errors="replace")
        raise CrowdinError(
            f"Crowdin API request failed for {method} {path}: {exc.code} {message}"
        ) from exc
    except urllib.error.URLError as exc:
        raise CrowdinError(f"Crowdin API request failed for {method} {path}: {exc}") from exc


def run_git(*args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=REPO_ROOT,
        check=check,
        text=True,
        capture_output=True,
    )


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except CrowdinError as exc:
        print(f"error: {exc}", file=sys.stderr)
        raise SystemExit(1)
