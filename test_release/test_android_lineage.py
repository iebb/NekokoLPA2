import importlib.util
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("android_lineage", ROOT / "scripts/android_lineage.py")
lineage = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = lineage
spec.loader.exec_module(lineage)


class LineageIntegrationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temporary = tempfile.TemporaryDirectory()
        cls.directory = Path(cls.temporary.name)
        cls.signers = []
        for index in range(3):
            key = cls.directory / f"key-{index}.p12"
            subprocess.run([
                "keytool", "-genkeypair", "-keystore", str(key), "-storetype", "PKCS12",
                "-storepass", "test-password", "-alias", "test", "-keyalg", "EC",
                "-dname", f"CN=Lineage test {index}", "-validity", "2",
            ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            cls.signers.append(lineage.Signer(key, "test-password", "test"))
        cls.proof = cls.directory / "proof.lineage"
        lineage.create_lineage(cls.signers, cls.proof)
        # A daily signing machine has neither of the old private keys.
        for signer in cls.signers[:-1]:
            signer.keystore.unlink()
        cls.apk = cls.directory / "unsigned.apk"
        with zipfile.ZipFile(cls.apk, "w") as archive:
            archive.writestr("AndroidManifest.xml", "<manifest/>")
            archive.writestr("classes.dex", b"test payload")

    @classmethod
    def tearDownClass(cls):
        cls.temporary.cleanup()

    def test_signs_and_verifies_with_only_the_leaf_key(self):
        output = self.directory / "signed.apk"
        lineage.sign_apk(self.apk, output, self.proof, self.signers[-1])
        result = subprocess.run([
            "java", "-jar", str(lineage.DEFAULT_APKSIGNER), "verify", "--verbose",
            "--min-sdk-version", "28", "--print-certs", str(output),
        ], capture_output=True, text=True, check=True)
        self.assertIn("Verified using v3 scheme (APK Signature Scheme v3): true", result.stdout)
        self.assertIn("Verified using v2 scheme (APK Signature Scheme v2): false", result.stdout)
        self.assertIn("Number of signers: 1", result.stdout)
        result = subprocess.run([
            "java", "-jar", str(lineage.DEFAULT_APKSIGNER), "lineage", "--in", str(output), "--print-certs",
        ], capture_output=True, text=True, check=True)
        self.assertEqual(result.stdout.count("certificate SHA-256 digest:"), 3)

    def test_failure_does_not_replace_an_existing_output(self):
        output = self.directory / "existing.apk"
        output.write_bytes(b"keep existing artifact")
        wrong_password = lineage.Signer(self.signers[-1].keystore, "incorrect")
        with self.assertRaises(subprocess.CalledProcessError):
            lineage.sign_apk(self.apk, output, self.proof, wrong_password)
        self.assertEqual(output.read_bytes(), b"keep existing artifact")

    def test_never_overwrites_a_rotation_proof(self):
        original = self.proof.read_bytes()
        with self.assertRaisesRegex(ValueError, "existing lineage"):
            lineage.create_lineage(self.signers, self.proof)
        self.assertEqual(self.proof.read_bytes(), original)

    def test_commands_do_not_contain_password_values(self):
        environment = {}
        signer = lineage.Signer(Path("leaf.p12"), "store-secret", "leaf", "key-secret")
        arguments = signer.arguments("TEST", environment)
        self.assertNotIn("store-secret", " ".join(arguments))
        self.assertNotIn("key-secret", " ".join(arguments))
        self.assertNotIn("store-secret", repr(signer))
        self.assertNotIn("key-secret", repr(signer))
        self.assertEqual(environment["TEST_STORE_PASSWORD"], "store-secret")


if __name__ == "__main__":
    unittest.main()
