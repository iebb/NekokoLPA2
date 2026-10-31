import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))


def load(name):
    spec = importlib.util.spec_from_file_location('test_' + name, ROOT / 'scripts' / (name + '.py'))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class BuildConfigurationTest(unittest.TestCase):
    def test_external_brand_manifest_is_optional(self):
        with patch.dict(os.environ, {'NLPA_BUILD_VARIANTS_FILE': '/no-such-nlpa-manifest.json'}):
            module = load('build')
            self.assertEqual(module.CONFIG, [])

    def test_brand_recipes_and_flavors_can_be_supplied_without_private_code(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            recipes = [{'suffix': 'example', 'package': 'example.lpa', 'key_configs': []}]
            flavors = {'example': {'app_name': 'Example', 'bundle_id': 'example.lpa'}}
            recipe_file, flavor_file = root / 'recipes.json', root / 'flavors.json'
            recipe_file.write_text(json.dumps(recipes))
            flavor_file.write_text(json.dumps(flavors))
            with patch.dict(os.environ, {'NLPA_BUILD_VARIANTS_FILE': str(recipe_file),
                                        'NLPA_FLAVORS_FILE': str(flavor_file)}):
                self.assertEqual(load('build').CONFIG, recipes)
                self.assertEqual(load('prepare_flavor').FLAVORS, flavors)

    def test_community_builds_never_load_private_signing_credentials(self):
        module = load('build')
        for variant in ['community', 'open', 'community-rooted', 'open-rooted']:
            with self.subTest(variant=variant), \
                 patch.object(module, 'prepare_android_properties', side_effect=AssertionError('Private credentials were requested')), \
                 patch.object(module.subprocess, 'run') as run, \
                 patch.object(sys, 'argv', ['build.py', variant, 'android']):
                module.main()
                self.assertIn('reproduce_community.py', run.call_args.args[0][1])
                self.assertIn('privileged' if variant.endswith('-rooted') else 'community', run.call_args.args[0])

    def test_malformed_recipe_configuration_fails_before_building(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / 'invalid.json'
            path.write_text('{}')
            with patch.dict(os.environ, {'NLPA_BUILD_VARIANTS_FILE': str(path)}):
                with self.assertRaisesRegex(ValueError, 'JSON array'):
                    load('build')

    def test_flavor_identity_updates_leave_unrelated_native_settings_intact(self):
        module = load('prepare_flavor')
        with tempfile.TemporaryDirectory() as temporary:
            project = Path(temporary) / 'project.pbxproj'
            project.write_text('PRODUCT_BUNDLE_IDENTIFIER = original;\nDEVELOPMENT_TEAM = old;\nOTHER_SETTING = keep;\n')
            module.update_pbxproj(project, {'bundle_id': 'example.lpa', 'development_team': 'EXAMPLE'})
            text = project.read_text()
            self.assertIn('PRODUCT_BUNDLE_IDENTIFIER = "example.lpa";', text)
            self.assertIn('DEVELOPMENT_TEAM = "EXAMPLE";', text)
            self.assertIn('OTHER_SETTING = keep;', text)

    def test_android_store_build_contract_keeps_package_artifacts_and_defines(self):
        module = load('build')
        commands, copied = [], []
        with patch.object(module, 'run_cmd', side_effect=lambda cmd, **kwargs: commands.append(cmd)), \
             patch.object(module, 'prepare_android_properties'), \
             patch.object(module, 'update_commit_hash'), \
             patch.object(module.os, 'chdir'), \
             patch.object(module.shutil, 'copy2', side_effect=lambda src, dst: copied.append((src, dst))), \
             patch.object(sys, 'argv', ['build.py', 'store', 'android']), \
             contextlib.redirect_stdout(io.StringIO()):
            module.main()
        self.assertEqual([cmd[2] for cmd in commands], ['apk', 'appbundle'])
        self.assertTrue(all('--flavor' in cmd and 'store' in cmd and '--dart-define=APP_VARIANT=std' in cmd for cmd in commands))
        self.assertTrue(any('ee.nekoko.nlpa-' in destination and destination.endswith('.aab') for _, destination in copied))


if __name__ == '__main__':
    unittest.main()
