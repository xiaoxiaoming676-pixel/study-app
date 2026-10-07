"""Download, derive, and verify the fixed public real-textbook corpus."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import tempfile
import urllib.request
import zipfile
from pathlib import Path

import fitz

HERE = Path(__file__).resolve().parent
DEFAULT_MANIFEST = HERE / 'real_corpus.json'


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open('rb') as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest()


def page_count(path: Path, kind: str) -> int:
    if kind == 'pptx':
        with zipfile.ZipFile(path) as archive:
            return sum(
                1
                for name in archive.namelist()
                if name.startswith('ppt/slides/slide') and name.endswith('.xml')
            )
    with fitz.open(path) as document:
        if not document.is_pdf:
            raise ValueError(f'{path.name} is not a PDF')
        return len(document)


def verify_file(path: Path, expected: dict) -> list[str]:
    errors = []
    if not path.is_file():
        return [f'missing: {path}']
    actual_bytes = path.stat().st_size
    if actual_bytes != expected['bytes']:
        errors.append(f'bytes: expected {expected["bytes"]}, got {actual_bytes}')
    actual_hash = sha256(path)
    if actual_hash != expected['sha256']:
        errors.append(f'sha256: expected {expected["sha256"]}, got {actual_hash}')
    try:
        actual_pages = page_count(path, expected['kind'])
    except Exception as error:  # Verification reports malformed files uniformly.
        errors.append(f'open: {error}')
    else:
        if actual_pages != expected['pages']:
            errors.append(f'pages: expected {expected["pages"]}, got {actual_pages}')
    return errors


def download(path: Path, expected: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    request = urllib.request.Request(
        expected['url'], headers={'User-Agent': 'study-app-real-corpus/1'}
    )
    descriptor, temp_name = tempfile.mkstemp(dir=path.parent)
    temp_path = Path(temp_name)
    try:
        with os.fdopen(descriptor, 'wb') as temporary:
            with urllib.request.urlopen(request, timeout=60) as response:
                total = 0
                while chunk := response.read(1024 * 1024):
                    total += len(chunk)
                    if total > expected['bytes']:
                        raise ValueError(
                            f'{path.name} exceeded its fixed {expected["bytes"]}-byte size'
                        )
                    temporary.write(chunk)
            temporary.flush()
            os.fsync(temporary.fileno())
        errors = verify_file(temp_path, expected)
        if errors:
            raise ValueError(f'{path.name}: ' + '; '.join(errors))
        os.replace(temp_path, path)
    except Exception:
        temp_path.unlink(missing_ok=True)
        raise


def derive_controlled_marks(source: Path, output: Path) -> None:
    """Put fixed visual marks on a real scanned page for detector scoring."""
    with fitz.open(source) as textbook:
        if len(textbook) < 5:
            raise ValueError('The scanned textbook no longer contains page 5')
        result = fitz.open()
        result.insert_pdf(textbook, from_page=4, to_page=4)
    try:
        page = result[0]
        width, height = page.rect.width, page.rect.height
        highlight = fitz.Rect(0.17 * width, 0.225 * height,
                              0.83 * width, 0.305 * height)
        page.draw_rect(
            highlight,
            color=None,
            fill=(1, 1, 0),
            fill_opacity=0.28,
            overlay=True,
        )
        page.draw_line(
            (0.32 * width, 0.445 * height),
            (0.72 * width, 0.445 * height),
            color=(0.85, 0.05, 0.05),
            width=max(2, height / 500),
            overlay=True,
        )
        result.set_metadata({})
        output.parent.mkdir(parents=True, exist_ok=True)
        result.save(output, garbage=4, deflate=True, no_new_id=True)
    finally:
        result.close()


def load_manifest(path: Path) -> dict:
    manifest = json.loads(path.read_text(encoding='utf-8'))
    if manifest.get('schema') != 'study-real-corpus/1':
        raise ValueError('Unsupported real corpus manifest schema')
    return manifest


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--manifest', type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument('--dest', type=Path)
    parser.add_argument('--only', action='append', default=[])
    parser.add_argument('--verify-only', action='store_true')
    parser.add_argument('--derive', action='store_true')
    args = parser.parse_args()

    manifest = load_manifest(args.manifest)
    destination = args.dest or (HERE / manifest['storage'])
    selected = set(args.only)
    unknown = selected - set(manifest['files']) - set(manifest['derived'])
    if unknown:
        parser.error(f'Unknown corpus entries: {", ".join(sorted(unknown))}')

    failed = False
    for name, expected in manifest['files'].items():
        if selected and name not in selected:
            continue
        target = destination / name
        errors = verify_file(target, expected)
        if errors and not args.verify_only:
            print(f'Downloading {name} ...')
            download(target, expected)
            errors = verify_file(target, expected)
        if errors:
            failed = True
            print(f'FAIL {name}: ' + '; '.join(errors))
        else:
            print(f'OK   {name}: {expected["pages"]} pages, {expected["bytes"]} bytes')

    for name, expected in manifest['derived'].items():
        if selected and name not in selected:
            continue
        target = destination / name
        if args.derive:
            source = destination / expected['source']
            source_errors = verify_file(source, manifest['files'][expected['source']])
            if source_errors:
                failed = True
                print(f'FAIL {name}: source is not verified')
                continue
            derive_controlled_marks(source, target)
        errors = verify_file(target, expected)
        if errors:
            failed = True
            print(f'FAIL {name}: ' + '; '.join(errors))
        else:
            print(f'OK   {name}: controlled marks on a verified real scan')

    if failed:
        parser.exit(1)


if __name__ == '__main__':
    main()
