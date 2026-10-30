#!/usr/bin/env python3
"""Publish Android variants and the shared NekokoLPA2 desktop releases."""
import argparse
import json
from pathlib import Path
import re
import subprocess
import tempfile
from urllib.request import Request, urlopen

from update_config_json import get_apk_signature, metadata, publish

REPOSITORY = 'iebb/NekokoLPA2'
COMMUNITY_CERT = 'c47350c7ba682b34a3e584a0d58463ea42b1ad73'
FEED = 'https://updates.lpa.ee/nlpa2.json'


def android_filename(assets, suffix, tail):
    """Prefer Community names while accepting previously published Open APKs."""
    for name in ('community', 'open'):
        filename = f'ee.nekoko.nlpa2.{name}-{suffix}-{tail}'
        if filename in assets:
            return filename
    raise ValueError(f'Required Community Android asset is missing: {tail}')


def api(path):
    result = subprocess.run(['gh', 'api', f'repos/{REPOSITORY}/{path}'],
                            check=True, capture_output=True, text=True)
    return json.loads(result.stdout)


def plan(release, channel, certificates, migrate_standard_desktop=False):
    tag = release['tag_name']
    if release['draft'] or release['prerelease'] or re.fullmatch(r'v\d+\.\d+\.\d+\+\d+', tag) is None:
        raise ValueError('A published stable app release is required')
    version, build = tag[1:].split('+')
    suffix = tag[1:].replace('+', '-')
    assets = {asset['name']: asset for asset in release['assets'] if asset['state'] == 'uploaded'}
    result = []

    def add(platform, variant, filename, signatures=()):
        asset = assets.get(filename)
        if not asset or asset['size'] <= 0:
            raise ValueError(f'Required release asset is missing: {filename}')
        expected = f'https://github.com/{REPOSITORY}/releases/download/{tag}/{filename}'
        if asset['browser_download_url'].replace('%2B', '+') != expected:
            raise ValueError('Release asset URL does not match the selected release')
        result.append(metadata(platform, variant, version, build,
                               asset['browser_download_url'], signatures, asset['size']))

    if channel in ('public', 'community', 'open'):
        prefix = f'ee.nekoko.nlpa2.open-{suffix}'
        for variants, tail in [
            (('community', 'open'), 'android.apk'),
            (('community-rooted', 'open-rooted'), 'rooted-arm64-v8a.apk'),
        ]:
            filename = android_filename(assets, suffix, tail)
            signatures = certificates[filename]
            if signatures != [COMMUNITY_CERT]:
                raise ValueError('Community APK must use the public community certificate')
            for variant in variants:
                add('android', variant, filename, signatures)
                if tail == 'android.apk':
                    add('android-armeabi-v7a', variant, filename, signatures)
        # Before separate channels existed, both public Android flavors said
        # `store`. Their certificate/variant cannot distinguish rooted from
        # normal; give those legacy clients a chooser, never the wrong APK.
        legacy = metadata('android', 'store', version, build, release['html_url'], [COMMUNITY_CERT])
        legacy['data']['changelog'] = ('Community update available. Choose the Community Android APK or the Community rooted module matching your installation; vendor APKs use different signing/package identities.')
        result.append(legacy)
        result.append({**legacy, 'platform': 'android-armeabi-v7a'})
        def desktop(platform, variant, canonical, legacy):
            add(platform, variant, canonical if canonical in assets else legacy)

        for variant, tail in [('open', 'setup.exe'), ('open-portable', 'x64.zip'), ('store', 'setup.exe')]:
            legacy_tail = 'windows-' + tail
            desktop('windows', variant, f'ee.nekoko.nlpa2.windows-{suffix}-{tail}', f'{prefix}-{legacy_tail}')
        for variant, tail in [('open', 'AppImage'), ('open-appimage', 'AppImage'), ('open-tgz', 'tar.gz'), ('store', 'AppImage')]:
            desktop('linux', variant, f'ee.nekoko.nlpa2.linux-{suffix}-x64.{tail}', f'{prefix}-linux-x64.{tail}')
        if migrate_standard_desktop:
            start = len(result)
            desktop('windows', 'std', f'ee.nekoko.nlpa2.windows-{suffix}-setup.exe', f'{prefix}-windows-setup.exe')
            for variant, tail in [('std', 'AppImage'), ('std-appimage', 'AppImage'), ('std-tgz', 'tar.gz')]:
                desktop('linux', variant, f'ee.nekoko.nlpa2.linux-{suffix}-x64.{tail}', f'{prefix}-linux-x64.{tail}')
            for entry in result[start:]:
                entry['data']['changelog'] = ('Desktop updates now come from the public NekokoLPA2 repository. Core LPA, readers and experimental IMS/SMS are included. See the release notes for provider integrations included in this build.')
    elif channel == 'standard':
        add('windows', 'std', f'ee.nekoko.nlpa2.windows-{suffix}-setup.exe')
        for variant, tail in [('std', 'AppImage'), ('std-appimage', 'AppImage'), ('std-tgz', 'tar.gz')]:
            add('linux', variant, f'ee.nekoko.nlpa2.linux-{suffix}-x64.{tail}')
    else:
        raise ValueError('Unknown channel')
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--release-tag', default='')
    parser.add_argument('--channel', choices=['public', 'community', 'open', 'standard'], default='public')
    parser.add_argument('--dry-run', action='store_true')
    parser.add_argument('--migrate-standard-desktop', action='store_true')
    args = parser.parse_args()
    latest = api('releases/latest')
    tag = args.release_tag or latest['tag_name']
    # Feed writes cannot roll back a channel through a delayed/manual old run.
    if tag != latest['tag_name']:
        raise ValueError('Only the latest stable release may update the feed')
    release = latest
    certificates = {}
    with tempfile.TemporaryDirectory() as tmp:
        if args.channel in ('public', 'community', 'open'):
            suffix = tag[1:].replace('+', '-')
            assets = {asset['name'] for asset in release['assets'] if asset['state'] == 'uploaded'}
            for tail in ['android.apk', 'rooted-arm64-v8a.apk']:
                filename = android_filename(assets, suffix, tail)
                subprocess.run(['gh', 'release', 'download', tag, '--repo', REPOSITORY,
                                '--pattern', filename, '--dir', tmp], check=True)
                certificates[filename] = get_apk_signature(Path(tmp) / filename)
        payloads = plan(release, args.channel, certificates, args.migrate_standard_desktop)
    with urlopen(Request(FEED, headers={'User-Agent': 'Mozilla/5.0'}), timeout=30) as response:
        current = json.load(response)
    for payload in payloads:
        previous = current.get(payload['platform'], {}).get(payload['identifier'], {})
        if isinstance(previous, dict) and previous.get('build', 0) > payload['data']['build']:
            raise ValueError('The feed already contains a newer build')
    for payload in payloads:
        if args.dry_run:
            print(json.dumps(payload))
        else:
            publish(payload)


if __name__ == '__main__':
    main()
