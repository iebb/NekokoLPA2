# Experimental Android signing lineage

The shared `scripts/android_lineage.py` helper creates a rotation proof once, then signs Android 9+ APKs with only its final keystore. Passwords are read from named environment variables and passed to apksigner through environment references.

A rotation lineage does not replace a set of simultaneous signers for an existing multi-signed package. Use a separately identified experimental package when evaluating that change. This helper uses v3 only; v1/v2 fallback would require the oldest private key too.

## Create a proof

Provide a JSON array in signing order, with `keystore` (relative to the JSON file), `password_env`, and optional `alias`, `key_password_env`, and `store_type`. Inject the passwords from a protected local environment or CI secrets.

```sh
python3 scripts/android_lineage.py create --config /secure/chain.json --out /secure/app.lineage
```

The proof contains public certificates and rotation authorizations. It does not contain private keys. Existing proof files are never overwritten. `--apksigner` or `NLPA_APKSIGNER_JAR` selects the signer JAR; otherwise the Android SDK build-tools installation is used (or the existing release-overlay signer when present).

## Sign an APK

```sh
python3 scripts/android_lineage.py sign --in unsigned.apk --out signed.apk \
  --lineage /secure/app.lineage --ks /secure/leaf.p12 \
  --password-env NLPA_LINEAGE_STORE_PASSWORD
```

The helper verifies the output before replacing the destination. A failed operation preserves an existing output file.

An overlay can supply `scripts/build_variants.json` and use `create --legacy-multi` for its existing ordered key set. `NLPA_OVERLAY_ROOT` and `NLPA_BUILD_VARIANTS_FILE` can override those locations. This command loads passwords through the same credentials helper as ordinary signing; it never reads passwords from the brand manifest.

## Validation

```sh
python3 -m unittest discover -s test_release -v
```

The integration tests generate disposable test keys and verify the rotation proof and signed APK. They do not use or replace distribution keys. Test the target phone and eUICC before changing a distributed app’s signing scheme: OMAPI access can depend on how that Android implementation handles signing history.

References: [apksigner](https://developer.android.com/tools/apksigner), [APK signature scheme v3](https://source.android.com/docs/security/features/apksigning/v3).
