#!/usr/bin/env python3
"""Restore a Play service account only for a publishing job and remove it after."""
import argparse
import json
import os
from pathlib import Path
import shutil
import tempfile


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--cleanup', action='store_true')
    args = parser.parse_args()
    temporary_root = Path(os.environ['RUNNER_TEMP']).resolve()
    if args.cleanup:
        name = os.environ.get('NLPA_PLAY_CREDENTIALS_DIR')
        if not name:
            return
        directory = Path(name)
        if directory.is_symlink() or directory.resolve().parent != temporary_root or not directory.name.startswith('nlpa-play-'):
            raise ValueError('Unexpected credential cleanup path')
        shutil.rmtree(directory, ignore_errors=True)
        return
    raw = os.environ.get('GOOGLE_PLAY_SERVICE_ACCOUNT_JSON')
    if not raw:
        raise ValueError('GOOGLE_PLAY_SERVICE_ACCOUNT_JSON is not configured')
    config = json.loads(raw)
    if config.get('type') != 'service_account' or not config.get('private_key') or not config.get('client_email'):
        raise ValueError('Invalid Play service account configuration')
    directory = Path(tempfile.mkdtemp(prefix='nlpa-play-', dir=temporary_root))
    directory.chmod(0o700)
    path = directory / 'service-account.json'
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, 'w') as stream:
        stream.write(raw)
    with Path(os.environ['GITHUB_ENV']).open('a') as stream:
        stream.write(f'GOOGLE_PLAY_SERVICE_ACCOUNT_FILE={path}\nNLPA_PLAY_CREDENTIALS_DIR={directory}\n')
    print('Prepared temporary Play credentials')


if __name__ == '__main__':
    main()
