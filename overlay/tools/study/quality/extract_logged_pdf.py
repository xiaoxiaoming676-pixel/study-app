"""Recover a fixed PDF printed by the iOS integration test."""
from __future__ import annotations

import argparse
import base64
import re
from pathlib import Path


def extract(log: str, prefix: str = 'STUDY_PDF') -> bytes:
    marker = re.escape(prefix)
    begin = re.findall(rf'{marker}_BEGIN:(\d+):(\d+)', log)
    if len(begin) != 1:
        raise ValueError(f'Expected one PDF header, found {len(begin)}')
    byte_count, chunk_count = map(int, begin[0])
    if byte_count < 100 or byte_count > 150 * 1024 * 1024 or chunk_count < 1:
        raise ValueError('Invalid PDF size or chunk count')
    parts = re.findall(rf'{marker}_CHUNK:(\d+):([A-Za-z0-9+/=]+)', log)
    if len(parts) != chunk_count or [int(index) for index, _ in parts] != list(range(chunk_count)):
        raise ValueError(f'PDF chunks missing or out of order: {len(parts)}/{chunk_count}')
    if log.count(f'{prefix}_END') != 1:
        raise ValueError('PDF end marker missing')
    data = base64.b64decode(''.join(part for _, part in parts), validate=True)
    if len(data) != byte_count or not data.startswith(b'%PDF-'):
        raise ValueError('Reconstructed PDF failed length or header check')
    return data


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('log', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--prefix', default='STUDY_PDF')
    args = parser.parse_args()
    data = extract(args.log.read_text(encoding='utf-8'), args.prefix)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(data)
    print(f'Recovered {len(data)} PDF bytes: {args.output}')


if __name__ == '__main__':
    main()
