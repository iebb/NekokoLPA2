#!/usr/bin/env python3
"""Compare APK payloads, ZIP metadata and APK signing-block records."""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import zipfile


def digest(data):
    return hashlib.sha256(data).hexdigest()


def signing_blocks(path):
    data = path.read_bytes()
    eocd = data.rfind(b'PK\x05\x06', max(0, len(data) - 65557))
    if eocd < 0:
        raise ValueError('APK has no ZIP end record')
    central = struct.unpack_from('<I', data, eocd + 16)[0]
    if data[central - 16:central] != b'APK Sig Block 42':
        return {}
    size = struct.unpack_from('<Q', data, central - 24)[0]
    start = central - size - 8
    if struct.unpack_from('<Q', data, start)[0] != size:
        raise ValueError('APK signing-block lengths disagree')
    offset = start + 8
    records = {}
    while offset < central - 24:
        length = struct.unpack_from('<Q', data, offset)[0]
        identifier = struct.unpack_from('<I', data, offset + 8)[0]
        value = data[offset + 12:offset + 8 + length]
        records[f'0x{identifier:08x}'] = {'size': len(value), 'sha256': digest(value)}
        offset += length + 8
    return records


def compare(first, second):
    contents, metadata = [], []
    with zipfile.ZipFile(first) as a, zipfile.ZipFile(second) as b:
        left, right = set(a.namelist()), set(b.namelist())
        for name in sorted(left | right):
            if name not in left or name not in right:
                contents.append({'entry': name, 'missing_from': 'first' if name not in left else 'second'})
                continue
            av, bv = a.read(name), b.read(name)
            if av != bv:
                contents.append({'entry': name, 'first_size': len(av), 'second_size': len(bv),
                                 'first_sha256': digest(av), 'second_sha256': digest(bv)})
            ai, bi = a.getinfo(name), b.getinfo(name)
            changed = []
            for key in ['date_time', 'compress_type', 'extra', 'comment', 'external_attr', 'header_offset']:
                if getattr(ai, key) != getattr(bi, key):
                    changed.append(key)
            if changed:
                metadata.append({'entry': name, 'changed_fields': changed})
        order_matches = a.namelist() == b.namelist()
    a, b = signing_blocks(first), signing_blocks(second)
    blocks = {key: {'first': a.get(key), 'second': b.get(key), 'identical': a.get(key) == b.get(key)}
              for key in sorted(a.keys() | b.keys())}
    return {'first_apk_sha256': digest(first.read_bytes()), 'second_apk_sha256': digest(second.read_bytes()),
            'payload_differences': contents, 'zip_metadata_differences': metadata,
            'zip_entry_order_identical': order_matches, 'signing_block_records': blocks}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('first', type=Path)
    parser.add_argument('second', type=Path)
    args = parser.parse_args()
    print(json.dumps(compare(args.first, args.second), indent=2))


if __name__ == '__main__':
    main()
