import importlib.util
from pathlib import Path
import io
import zipfile
import tempfile
import unittest
from unittest.mock import patch
SCRIPT = Path(__file__).resolve().parents[2] / 'scripts/crowdin_sync.py'
spec = importlib.util.spec_from_file_location('crowdin_sync', SCRIPT)
sync = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sync)
class CrowdinMigrationTest(unittest.TestCase):
    def test_paths_belong_to_the_public_repository(self):
        self.assertEqual(sync.APP_DIR, SCRIPT.parents[1])
        self.assertEqual(sync.SOURCE_REL, 'l10n/app_en.arb')
        self.assertEqual(sync.PROJECT_ID, 876432)
        self.assertEqual(sync.FILE_ID, 5)
        self.assertEqual(len(sync.MANAGED_FILES), 9)
    def test_bundle_writes_only_managed_locales_and_preserves_english(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            english = root / 'app_en.arb'; english.write_text('{"message":"English source"}')
            locale = root / 'app_ru.arb'; stream = io.BytesIO()
            with zipfile.ZipFile(stream, 'w') as bundle:
                bundle.writestr('ru/l10n/app.arb', '{"message":"Russian translation"}')
                bundle.writestr('en/l10n/app.arb', '{"message":"Must not replace source"}')
            with patch.object(sync, 'MANAGED_FILES', {'ru': locale}):
                self.assertEqual(sync.apply_translations(stream.getvalue()), [locale])
            self.assertIn('Russian translation', locale.read_text())
            self.assertEqual(english.read_text(), '{"message":"English source"}')
    def test_missing_locale_fails_instead_of_erasing_a_translation(self):
        with tempfile.TemporaryDirectory() as temporary:
            locale = Path(temporary) / 'app_ru.arb'; locale.write_text('existing')
            stream = io.BytesIO()
            with zipfile.ZipFile(stream, 'w'): pass
            with patch.object(sync, 'MANAGED_FILES', {'ru': locale}):
                with self.assertRaises(sync.CrowdinError): sync.apply_translations(stream.getvalue())
            self.assertEqual(locale.read_text(), 'existing')
if __name__ == '__main__': unittest.main()
