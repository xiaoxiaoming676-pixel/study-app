"""Measure a PPTX-derived PDF against the fixed PowerPoint reference."""
from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path

import fitz
from PIL import Image, ImageChops, ImageStat

HERE = Path(__file__).resolve().parent


def render(page: fitz.Page, width: int = 960) -> Image.Image:
    scale = width / page.rect.width
    pix = page.get_pixmap(matrix=fitz.Matrix(scale, scale), alpha=False)
    return Image.frombytes('RGB', (pix.width, pix.height), pix.samples)


def character_recall(reference: str, candidate: str) -> float:
    expected = Counter(ch.casefold() for ch in reference if not ch.isspace())
    actual = Counter(ch.casefold() for ch in candidate if not ch.isspace())
    total = sum(expected.values())
    return sum(min(count, actual[ch]) for ch, count in expected.items()) / total if total else 1.0


def compare(reference: Path, candidate: Path, gates: dict) -> dict:
    with fitz.open(reference) as truth, fitz.open(candidate) as result:
        if not truth.is_pdf or not result.is_pdf:
            raise ValueError('Both files must be PDFs')
        rows = []
        for index in range(min(len(truth), len(result))):
            expected, actual = truth[index], result[index]
            aspect_delta = abs(expected.rect.width / expected.rect.height -
                               actual.rect.width / actual.rect.height)
            a, b = render(expected), render(actual)
            if b.size != a.size:
                b = b.resize(a.size, Image.Resampling.LANCZOS)
            mae = sum(ImageStat.Stat(ImageChops.difference(a, b)).mean) / 3
            recall = character_recall(expected.get_text(), actual.get_text())
            rows.append({'page': index + 1, 'rgb_mae': round(mae, 3),
                         'aspect_ratio_delta': round(aspect_delta, 6),
                         'text_character_recall': round(recall, 4)})
        mean_mae = sum(row['rgb_mae'] for row in rows) / len(rows) if rows else 255
        worst_mae = max((row['rgb_mae'] for row in rows), default=255)
        min_recall = min((row['text_character_recall'] for row in rows), default=0)
        max_aspect = max((row['aspect_ratio_delta'] for row in rows), default=1)
        checks = {
            'page_count': len(truth) == len(result),
            'aspect_ratio': max_aspect <= gates['max_aspect_ratio_delta'],
            'mean_rgb_mae': mean_mae <= gates['mean_rgb_mae_max'],
            'worst_page_rgb_mae': worst_mae <= gates['worst_page_rgb_mae_max'],
            'text_character_recall': min_recall >= gates['min_text_character_recall'],
        }
        return {'reference_pages': len(truth), 'candidate_pages': len(result),
                'pages': rows, 'summary': {'mean_rgb_mae': round(mean_mae, 3),
                                          'worst_page_rgb_mae': round(worst_mae, 3),
                                          'minimum_text_character_recall': round(min_recall, 4),
                                          'maximum_aspect_ratio_delta': round(max_aspect, 6)},
                'checks': checks, 'passed': all(checks.values())}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('candidate', type=Path, help='PDF produced by the proposed offline converter')
    parser.add_argument('--reference', type=Path, default=HERE / 'fixtures/deck_complex_powerpoint.pdf')
    parser.add_argument('--output', type=Path, help='Optional path for machine-readable metrics')
    parser.add_argument('--gate', action='store_true', help='Exit nonzero when a provisional gate fails')
    args = parser.parse_args()
    manifest = json.loads((HERE / 'corpus.json').read_text(encoding='utf-8'))
    result = compare(args.reference, args.candidate, manifest['pptx_provisional_gates'])
    report = json.dumps(result, ensure_ascii=False, indent=2) + '\n'
    if args.output:
        args.output.write_text(report, encoding='utf-8')
    print(report, end='')
    if args.gate and not result['passed']:
        parser.exit(1, 'Synthetic PPTX quality gate failed\n')


if __name__ == '__main__':
    main()
