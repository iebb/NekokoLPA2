#!/usr/bin/env python3
"""Build public Community APKs from a Git commit, optionally verifying two clean runs.

Requires Python, Git, Docker and public internet access. No Kasutera checkout,
local signing configuration, or GitHub/Cloudflare/Play secret is used.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def build_once(image, commit, epoch, variant, output):
    output.mkdir(parents=True, exist_ok=True)
    command = ['docker', 'run', '--rm', '--platform', 'linux/amd64', '-i',
               '-v', str(output.resolve()) + ':/out',
               '-e', 'SOURCE_DATE_EPOCH=' + epoch,
               '-e', 'OUTPUT_UID=' + str(os.getuid()),
               '-e', 'OUTPUT_GID=' + str(os.getgid()), image, variant]
    archive = subprocess.Popen(['git', 'archive', '--format=tar', commit], cwd=ROOT, stdout=subprocess.PIPE)
    try:
        subprocess.run(command, stdin=archive.stdout, check=True)
    except BaseException:
        archive.terminate()
        archive.wait()
        raise
    finally:
        archive.stdout.close()
    if archive.wait():
        raise RuntimeError('Could not archive the public source commit')
    return output / 'community.apk'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ref', default='HEAD', help='Public source commit or tag; uncommitted files are excluded')
    parser.add_argument('--variant', choices=['community', 'privileged'], default='community')
    parser.add_argument('--verify', action='store_true', help='Build in two new containers and require identical APK bytes')
    parser.add_argument('--output', type=Path, default=ROOT / 'dist/community')
    args = parser.parse_args()
    commit = subprocess.check_output(['git', 'rev-parse', args.ref + '^{commit}'], cwd=ROOT, text=True).strip()
    epoch = subprocess.check_output(['git', 'show', '-s', '--format=%ct', commit], cwd=ROOT, text=True).strip()
    with tempfile.TemporaryDirectory(prefix='nlpa-community-recipe-') as recipe_directory:
        recipe = Path(recipe_directory)
        for name in ['Dockerfile', 'build.sh']:
            content = subprocess.check_output(['git', 'show', commit + ':scripts/reproducible/' + name], cwd=ROOT)
            (recipe / name).write_bytes(content)
        (recipe / 'build.sh').chmod(0o755)
        digest = hashlib.sha256(b''.join((recipe / name).read_bytes() for name in ['Dockerfile', 'build.sh'])).hexdigest()
        image = 'nlpa2-community-repro:' + digest[:16]
        subprocess.run(['docker', 'build', '--platform', 'linux/amd64', '-t', image, str(recipe)], check=True)
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='nlpa-community-repro-') as temporary:
        first = build_once(image, commit, epoch, args.variant, Path(temporary) / 'first')
        checksum = sha256(first)
        if args.verify:
            second = build_once(image, commit, epoch, args.variant, Path(temporary) / 'second')
            if checksum != sha256(second):
                # Preserve evidence for comparing individual APK entries.
                shutil.copytree(temporary, output / 'mismatch', dirs_exist_ok=True)
                raise RuntimeError('Independent Community builds differ; see output/mismatch')
        shutil.copy2(first, output / 'community.apk')
        shutil.copy2(first.parent / 'signer.txt', output / 'signer.txt')
    metadata = {'source_commit': commit, 'source_date_epoch': int(epoch), 'variant': args.variant,
                'recipe_sha256': digest, 'apk_sha256': checksum, 'independent_builds_compared': 2 if args.verify else 1}
    (output / 'build.json').write_text(json.dumps(metadata, indent=2) + '\n')
    print(json.dumps(metadata, indent=2))


if __name__ == '__main__':
    main()
