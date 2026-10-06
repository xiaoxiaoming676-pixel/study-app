"""Score OCR mask candidates against manually checked words and page boxes."""
from __future__ import annotations

import argparse
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent


def iou(a: list[float], b: list[float]) -> float:
    ax, ay, aw, ah = a
    bx, by, bw, bh = b
    left, top = max(ax, bx), max(ay, by)
    right, bottom = min(ax + aw, bx + bw), min(ay + ah, by + bh)
    intersection = max(0, right - left) * max(0, bottom - top)
    union = aw * ah + bw * bh - intersection
    return intersection / union if union > 0 else 0.0


def score(expected: dict, predictions: dict, minimum_iou: float = 0.25) -> dict:
    results = {}
    for category in ('keyword', 'red_text', 'highlight', 'underline'):
        labels = expected[category]
        truth = [{'answer': word, 'rect': expected['boxes'][word]} for word in labels]
        guessed = predictions.get(category, [])
        matched = set()
        false_positives = []
        for item in guessed:
            answer = str(item.get('answer', '')).strip().casefold()
            box = item.get('rect', [])
            hit = next((index for index, target in enumerate(truth)
                        if index not in matched and answer == target['answer'].casefold()
                        and len(box) == 4 and iou(box, target['rect']) >= minimum_iou), None)
            if hit is None:
                false_positives.append(item)
            else:
                matched.add(hit)
        misses = [target for index, target in enumerate(truth) if index not in matched]
        tp, fp, fn = len(matched), len(false_positives), len(misses)
        results[category] = {'tp': tp, 'fp': fp, 'fn': fn,
                             'precision': round(tp / (tp + fp), 4) if tp + fp else 1.0,
                             'recall': round(tp / (tp + fn), 4) if tp + fn else 1.0,
                             'false_positives': false_positives, 'misses': misses}
    return results


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('predictions', type=Path, help='JSON with keyword/red_text/highlight/underline mask lists')
    parser.add_argument('--expected', type=Path, default=HERE / 'corpus.json')
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    truth = json.loads(args.expected.read_text(encoding='utf-8'))
    expected = truth.get('scan_expected', truth)
    predictions = json.loads(args.predictions.read_text(encoding='utf-8'))
    report = json.dumps(score(expected, predictions), ensure_ascii=False, indent=2) + '\n'
    if args.output:
        args.output.write_text(report, encoding='utf-8')
    print(report, end='')


if __name__ == '__main__':
    main()
