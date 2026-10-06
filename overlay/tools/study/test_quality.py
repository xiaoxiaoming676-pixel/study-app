import hashlib
import base64
import json
import tempfile
import unittest
from pathlib import Path

import fitz

from quality.evaluate import compare
from quality.extract_logged_pdf import extract
from quality.score_scan import score

QUALITY = Path(__file__).resolve().parent / 'quality'
FIXTURES = QUALITY / 'fixtures'


class QualityCorpusTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = json.loads((QUALITY / 'corpus.json').read_text(encoding='utf-8'))

    def test_fixed_fixture_hashes_and_page_counts(self):
        for name, expected in self.manifest['fixtures'].items():
            with self.subTest(name=name):
                source = FIXTURES / name
                self.assertEqual(hashlib.sha256(source.read_bytes()).hexdigest(), expected['sha256'])
                if name.endswith('.pdf'):
                    with fitz.open(source) as doc:
                        self.assertEqual(len(doc), expected['pages'])

    def test_scan_is_raster_only_and_large_fixture_has_120_pages(self):
        with fitz.open(FIXTURES / 'scan_styles.pdf') as scan:
            self.assertEqual(scan[0].get_text().strip(), '')
        with fitz.open(FIXTURES / 'large_120_pages.pdf') as large:
            self.assertEqual(len(large), 120)
            self.assertIn('page 120', large[-1].get_text())

    def test_pdf_quality_gate_accepts_identical_and_rejects_visual_damage(self):
        reference = FIXTURES / 'deck_complex_powerpoint.pdf'
        gates = self.manifest['pptx_provisional_gates']
        self.assertTrue(compare(reference, reference, gates)['passed'])
        with tempfile.TemporaryDirectory() as temp:
            candidate = Path(temp) / 'damaged.pdf'
            with fitz.open(reference) as doc:
                doc[0].draw_rect(doc[0].rect, color=None, fill=(0, 0, 0), overlay=True)
                doc.save(candidate)
            result = compare(reference, candidate, gates)
            self.assertFalse(result['passed'])
            self.assertFalse(result['checks']['worst_page_rgb_mae'])

    def test_scan_score_counts_false_positives_and_misses(self):
        expected = self.manifest['scan_expected']
        predictions = {kind: [{'answer': word, 'rect': expected['boxes'][word]}
                              for word in expected[kind]]
                       for kind in ('keyword', 'red_text', 'highlight', 'underline')}
        predictions['red_text'].append({'answer': 'Delta', 'rect': expected['boxes']['Delta']})
        predictions['underline'].clear()
        result = score(expected, predictions)
        self.assertEqual((result['red_text']['tp'], result['red_text']['fp']), (1, 1))
        self.assertEqual((result['underline']['tp'], result['underline']['fn']), (0, 1))

    def test_simulator_pdf_log_recovery_detects_missing_chunks(self):
        source = (FIXTURES / 'deck_complex_powerpoint.pdf').read_bytes()
        encoded = base64.b64encode(source).decode('ascii')
        chunks = [encoded[index:index + 3072] for index in range(0, len(encoded), 3072)]
        lines = [f'STUDY_PDF_BEGIN:{len(source)}:{len(chunks)}']
        lines.extend(f'test stdout: STUDY_PDF_CHUNK:{index}:{chunk}'
                     for index, chunk in enumerate(chunks))
        lines.append('STUDY_PDF_END')
        self.assertEqual(extract('\n'.join(lines)), source)
        with self.assertRaises(ValueError):
            extract('\n'.join(lines[0:2] + lines[3:]))


if __name__ == '__main__':
    unittest.main()
