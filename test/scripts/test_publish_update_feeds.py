from copy import deepcopy
import os
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

SCRIPTS = Path(__file__).resolve().parents[2] / 'scripts'
sys.path.insert(0, str(SCRIPTS))
import publish_update_feeds as feeds
import update_config_json as writer


class FeedPublisherTest(unittest.TestCase):
    def setUp(self):
        prefix = 'ee.nekoko.nlpa2.open-2.4.0-600'
        self.names = [f'{prefix}-{tail}' for tail in [
            'android.apk', 'rooted-arm64-v8a.apk', 'windows-setup.exe',
            'windows-x64.zip', 'linux-x64.AppImage', 'linux-x64.tar.gz']]
        self.release = {'tag_name': 'v2.4.0+600', 'draft': False, 'prerelease': False,
                        'html_url': 'https://github.com/iebb/NekokoLPA2/releases/tag/v2.4.0%2B600',
                        'assets': [{'name': name, 'size': 100, 'state': 'uploaded',
                                    'browser_download_url': 'https://github.com/iebb/NekokoLPA2/releases/download/v2.4.0%2B600/' + name}
                                   for name in self.names]}
        self.certs = {name: [feeds.COMMUNITY_CERT] for name in self.names if name.endswith('.apk')}

    def test_all_public_channels_point_to_their_own_artifacts(self):
        payloads = feeds.plan(self.release, 'open', self.certs)
        self.assertEqual(len(payloads), 15)
        normal = next(p for p in payloads if p['platform'] == 'android' and p['identifier'].startswith('open-' + feeds.COMMUNITY_CERT))
        rooted = next(p for p in payloads if p['identifier'].startswith('open-rooted-'))
        self.assertTrue(normal['data']['download_url'].endswith('-android.apk'))
        self.assertTrue(rooted['data']['download_url'].endswith('-rooted-arm64-v8a.apk'))
        self.assertFalse(any(p['identifier'] == 'std' for p in payloads))

    def test_community_names_and_legacy_channels_share_verified_artifacts(self):
        renamed = deepcopy(self.release)
        certs = dict(self.certs)
        for asset in list(self.release['assets']):
            if not asset['name'].endswith('.apk'):
                continue
            name = asset['name'].replace('.open-', '.community-')
            renamed['assets'].append({**asset, 'name': name,
                'browser_download_url': asset['browser_download_url'].replace(asset['name'], name)})
            certs[name] = [feeds.COMMUNITY_CERT]
        payloads = feeds.plan(renamed, 'community', certs)
        for platform in ['android', 'android-armeabi-v7a']:
            for channel in ['community', 'open']:
                entry = next(p for p in payloads if p['platform'] == platform and p['identifier'] == channel + '-' + feeds.COMMUNITY_CERT)
                self.assertIn('.community-', entry['data']['download_url'])
        for channel in ['community-rooted', 'open-rooted']:
            entry = next(p for p in payloads if p['platform'] == 'android' and p['identifier'] == channel + '-' + feeds.COMMUNITY_CERT)
            self.assertTrue(entry['data']['download_url'].endswith('-rooted-arm64-v8a.apk'))

    def test_explicit_desktop_migration_points_standard_users_to_public_builds(self):
        payloads = feeds.plan(self.release, 'open', self.certs, migrate_standard_desktop=True)
        legacy = [p for p in payloads if p['identifier'] in ['std', 'std-appimage', 'std-tgz']]
        self.assertEqual(len(legacy), 4)
        for entry in legacy:
            self.assertEqual(entry['data']['build'], 600)
            self.assertIn('ee.nekoko.nlpa2.open-', entry['data']['download_url'])
            self.assertIn('public NekokoLPA2 repository', entry['data']['changelog'])
            self.assertNotIn('Open distribution', entry['data']['changelog'])

    def test_desktop_prefers_canonical_names_without_android_open_branding(self):
        renamed = deepcopy(self.release)
        replacements = {
            self.names[2]: 'ee.nekoko.nlpa2.windows-2.4.0-600-setup.exe',
            self.names[3]: 'ee.nekoko.nlpa2.windows-2.4.0-600-x64.zip',
            self.names[4]: 'ee.nekoko.nlpa2.linux-2.4.0-600-x64.AppImage',
            self.names[5]: 'ee.nekoko.nlpa2.linux-2.4.0-600-x64.tar.gz',
        }
        # Both names may exist when old download links are retained.
        for asset in self.release['assets']:
            if asset['name'] in replacements:
                name = replacements[asset['name']]
                renamed['assets'].append({**asset, 'name': name,
                    'browser_download_url': asset['browser_download_url'].replace(asset['name'], name)})
        payloads = feeds.plan(renamed, 'public', self.certs, migrate_standard_desktop=True)
        desktop = [p for p in payloads if p['platform'] in ['windows', 'linux']]
        self.assertEqual(len(desktop), 11)
        for entry in desktop:
            self.assertNotIn('.open-', entry['data']['download_url'])
        android = [p for p in payloads if p['identifier'].startswith('open-') and p['platform'] == 'android']
        self.assertIn('.open-', android[0]['data']['download_url'])

    def test_legacy_store_android_uses_a_chooser_not_the_wrong_apk(self):
        payloads = feeds.plan(self.release, 'open', self.certs)
        legacy = next(p for p in payloads if p['platform'] == 'android' and p['identifier'].startswith('store-'))
        self.assertEqual(legacy['data']['download_url'], self.release['html_url'])
        self.assertIn('rooted', legacy['data']['changelog'])

    def test_missing_or_unuploaded_assets_fail_before_publishing(self):
        for missing in [True, False]:
            release = deepcopy(self.release)
            if missing:
                release['assets'].pop()
            else:
                release['assets'][-1]['state'] = 'starter'
            with self.assertRaises(ValueError):
                feeds.plan(release, 'open', self.certs)

    def test_open_rejects_a_vendor_signed_apk(self):
        self.certs[self.names[0]] = ['d1c0f48b370e74d4ea4770ed4c3cd70a3198d31f']
        with self.assertRaises(ValueError):
            feeds.plan(self.release, 'open', self.certs)

    def test_release_url_cannot_redirect_to_a_different_artifact(self):
        self.release['assets'][-1]['browser_download_url'] = 'https://example.com/wrong'
        with self.assertRaises(ValueError):
            feeds.plan(self.release, 'open', self.certs)

    def test_drafts_prereleases_and_non_app_tags_are_rejected(self):
        for field, value in [('draft', True), ('prerelease', True), ('tag_name', 'nightly')]:
            release = {**self.release, field: value}
            with self.assertRaises(ValueError):
                feeds.plan(release, 'open', self.certs)

    def test_android_metadata_requires_signatures(self):
        with self.assertRaises(ValueError):
            writer.metadata('android', 'open', '2.4.0', 600, 'https://example.com/app.apk')

    def test_worker_failures_fail_publication_without_leaking_credentials(self):
        with patch.dict(os.environ, {'UPDATE_WORKER_URL': 'https://worker.example/nlpa2?key=secret', 'UPDATE_WORKER_KEY': 'secret'}):
            with patch.object(writer, 'urlopen', side_effect=RuntimeError('secret')):
                with self.assertRaisesRegex(RuntimeError, 'metadata write') as raised:
                    writer.publish({'platform': 'windows', 'identifier': 'open', 'data': {'build': 600}})
        self.assertNotIn('secret', str(raised.exception))


if __name__ == '__main__':
    unittest.main()
