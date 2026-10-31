import google.auth
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from googleapiclient.http import MediaFileUpload
import argparse
import os
import re

TRACK = os.environ.get("GOOGLE_PLAY_TRACK", "production")
SERVICE_ACCOUNT_FILE = os.environ.get(
    "GOOGLE_PLAY_SERVICE_ACCOUNT_FILE",
    "store/.creds/google-play-service-account.json",
)
VALIDATE_ONLY = os.environ.get("GOOGLE_PLAY_VALIDATE_ONLY", "").lower() in {
    "1",
    "true",
    "yes",
}

def create_service():
    credentials, _ = google.auth.load_credentials_from_file(
        SERVICE_ACCOUNT_FILE, scopes=['https://www.googleapis.com/auth/androidpublisher'])
    return build('androidpublisher', 'v3', credentials=credentials)

def upload_aab(package_name, aab_file_path, *, service):
    # Step 1: Create a new edit session
    edit_request = service.edits().insert(body={}, packageName=package_name)
    edit = edit_request.execute()
    edit_id = edit['id']
    print(f"Edit session created: {edit_id}")

    # Step 2: Upload the .aab file
    aab_upload_request = service.edits().bundles().upload(
        editId=edit_id,
        packageName=package_name,
        media_body=MediaFileUpload(aab_file_path, mimetype="application/octet-stream")
    )
    try:
        aab_response = aab_upload_request.execute()
    except HttpError as e:
        if _is_duplicate_version_code_error(e):
            print(
                "AAB upload skipped: Google Play already has this version code."
            )
            return
        raise
    print(f"AAB uploaded: Version Code {aab_response['versionCode']}")

    # Step 3: Assign release to a track
    release = {
        "releases": [
            {
                "name": aab_response['versionCode'],
                "versionCodes": [str(aab_response['versionCode'])],
                "status": "completed"
            }
        ]
    }

    track_update_request = service.edits().tracks().update(
        editId=edit_id,
        packageName=package_name,
        track=TRACK,
        body=release
    )
    track_update_response = track_update_request.execute()
    print(f"Track '{TRACK}' updated.")

    # Step 4: Validate or commit the edit
    if VALIDATE_ONLY:
        validate_request = service.edits().validate(editId=edit_id, packageName=package_name)
        validate_response = validate_request.execute()
        print(f"Edit validated: {validate_response}")
        return

    try:
        commit_request = service.edits().commit(editId=edit_id, packageName=package_name)
        commit_response = commit_request.execute()
    except:
        commit_request = service.edits().commit(editId=edit_id, packageName=package_name)
        commit_response = commit_request.execute()
    print(f"Edit committed: {commit_response}")

def _is_duplicate_version_code_error(error):
    content = error.content.decode("utf-8", errors="replace")
    return (
        error.resp.status == 403
        and re.search(r"Version code \d+ has already been used", content)
        is not None
    )

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--target",
        action="append",
        default=[],
        help="Upload target in the form package_name=/path/to/file.aab",
    )
    args = parser.parse_args()

    targets = []
    if args.target:
        for target in args.target:
            if "=" not in target:
                raise SystemExit(f"Invalid --target value: {target}")
            package_name, aab_file_path = target.split("=", 1)
            targets.append((package_name, aab_file_path))
    else:
        targets = [
            ("ee.nekoko.nlpa", "./outputs/bundle/app-store-release.aab"),
            ("ee.nekoko.nlpa.flavor1", "./outputs/bundle/app-flavor1-release.aab"),
        ]

    service = create_service()
    for package_name, aab_file_path in targets:
        upload_aab(package_name, aab_file_path, service=service)
