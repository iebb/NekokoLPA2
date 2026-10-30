#!/usr/bin/env python3
"""
Validate the ARB files before they reach Crowdin.

    python3 scripts/check_l10n.py

Three things go wrong with hand edits, and all three are silent:

1. A duplicate top-level key. JSON keeps the last one, so the file still
   parses, `flutter gen-l10n` still succeeds and the tests still pass -- the
   only symptom is a second copy sitting in the file, which then gets uploaded
   to Crowdin.
2. A key added to a translation file. Crowdin owns those: the next sync
   overwrites the file wholesale, so the edit is thrown away without a word.
3. A key in a translation that the English source has never heard of, left
   behind by a rename.

Exits non-zero and names the file and key. Run by the pre-commit hook in
.githooks and by the Crowdin workflow.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
L10N_DIR = REPO_ROOT / "l10n"
TEMPLATE = L10N_DIR / "app_en.arb"


def top_level_keys(path: Path) -> list[str]:
    """Keys at depth 1, so nested placeholder metadata is not mistaken for one."""
    keys: list[str] = []
    depth = 0
    for line in path.read_text(encoding="utf-8").splitlines():
        match = re.match(r'"([^"]+)"\s*:', line.strip())
        if match and depth == 1:
            keys.append(match.group(1))
        depth += line.count("{") - line.count("}")
    return keys


def message_keys(keys: list[str]) -> set[str]:
    return {k for k in keys if not k.startswith("@")}


def main() -> int:
    problems: list[str] = []

    arbs = sorted(L10N_DIR.glob("*.arb"))
    if not arbs:
        print(f"no ARB files under {L10N_DIR}", file=sys.stderr)
        return 1

    template_keys: set[str] = set()

    for path in arbs:
        name = path.relative_to(REPO_ROOT).as_posix()

        try:
            json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            problems.append(f"{name}: not valid JSON ({exc})")
            continue

        keys = top_level_keys(path)
        for key in sorted({k for k in keys if keys.count(k) > 1}):
            problems.append(
                f"{name}: duplicate key '{key}'. JSON keeps the last one, so "
                f"this parses and builds while carrying two copies."
            )

        if path == TEMPLATE:
            template_keys = message_keys(keys)

    for path in arbs:
        if path == TEMPLATE:
            continue
        name = path.relative_to(REPO_ROOT).as_posix()
        keys = message_keys(top_level_keys(path))

        for key in sorted(keys - template_keys):
            problems.append(
                f"{name}: '{key}' is not in app_en.arb. Either it was renamed "
                f"in the source, or it was hand-added here -- Crowdin owns this "
                f"file and the next sync will drop it."
            )

    if problems:
        print("l10n check failed:\n", file=sys.stderr)
        for problem in problems:
            print(f"  - {problem}", file=sys.stderr)
        print(
            "\nAdd or change strings in l10n/app_en.arb only. The other "
            "files come back from Crowdin.",
            file=sys.stderr,
        )
        return 1

    missing = {
        path.relative_to(REPO_ROOT).as_posix(): sorted(
            template_keys - message_keys(top_level_keys(path))
        )
        for path in arbs
        if path != TEMPLATE
    }
    awaiting = {name: keys for name, keys in missing.items() if keys}

    print(f"l10n ok: {len(template_keys)} keys in app_en.arb (source), "
          f"{len(arbs) - 1} translation file(s) checked against it")
    if awaiting:
        # Not a failure: a new string is untranslated until Crowdin catches up,
        # and Flutter falls back to English meanwhile.
        total = sum(len(keys) for keys in awaiting.values())
        print(f"  {total} translation(s) still pending across "
              f"{len(awaiting)} locale(s); Crowdin will fill them in.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
