"""Load signing passwords from CI Secrets or an untracked local configuration.

Keystores intentionally remain in signer/. Never return passwords in command
arguments: apksigner reads named environment variables instead.
"""
import argparse
import json
import os
import re
from pathlib import Path


def load_credentials(optional=False):
    raw = os.environ.get('NLPA_ANDROID_SIGNING_CREDENTIALS_JSON')
    if not raw:
        path = Path(os.environ.get('NLPA_SIGNING_CREDENTIALS_FILE',
            str(Path.home() / '.config/nekokolpa/kasutera-signing.json')))
        if not path.is_file():
            if optional:
                return None
            raise ValueError('Configure ANDROID_SIGNING_CREDENTIALS_JSON in CI or NLPA_SIGNING_CREDENTIALS_FILE locally')
        raw = path.read_text()
    try:
        result = json.loads(raw)
        if not isinstance(result.get('passwords'), dict) or not isinstance(result.get('gradle_properties'), str):
            raise ValueError()
        return result
    except (ValueError, TypeError, AttributeError) as error:
        raise ValueError('Invalid signing credentials configuration') from error


def password_environment(keystore):
    filename = Path(keystore).name
    name = 'NLPA_SIGNING_PASSWORD_' + re.sub('[^A-Z0-9]', '_', filename.upper())
    if not os.environ.get(name):
        value = load_credentials()['passwords'].get(filename)
        if not isinstance(value, str) or not value:
            raise ValueError('Missing signing password for ' + filename)
        os.environ[name] = value
    return name


def signing_password(keystore):
    return os.environ[password_environment(keystore)]


def prepare_android_properties(app, optional=False):
    credentials = load_credentials(optional=optional)
    if credentials is None:
        return False
    target = Path(app) / 'android/key.properties'
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        target.chmod(0o600)
    fd = os.open(target, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, 'w') as stream:
        stream.write(credentials['gradle_properties'])
    target.chmod(0o600)
    return True


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--app', type=Path, required=True)
    parser.add_argument('--optional', action='store_true')
    args = parser.parse_args()
    prepare_android_properties(args.app, optional=args.optional)
