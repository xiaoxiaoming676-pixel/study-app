import hashlib
import base64
import json
import tempfile
import unittest
from pathlib import Path

import fitz

from quality.evaluate import compare
from quality.extract_logged_pdf import extract
from quality.real_corpus import derive_controlled_marks, sha256, verify_file
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
        real_lines = [line.replace('STUDY_PDF', 'STUDY_REAL_PDF') for line in lines]
        self.assertEqual(extract('\n'.join(real_lines), 'STUDY_REAL_PDF'), source)
        with self.assertRaises(ValueError):
            extract('\n'.join(lines[0:2] + lines[3:]))

    def test_real_corpus_manifest_covers_the_finalization_matrix(self):
        manifest = json.loads((QUALITY / 'real_corpus.json').read_text(encoding='utf-8'))
        self.assertEqual(manifest['schema'], 'study-real-corpus/1')
        entries = {**manifest['files'], **manifest['derived']}
        coverage = {item for entry in entries.values() for item in entry['coverage']}
        self.assertTrue({
            'selectable_text', 'scanned_pdf', 'pptx', 'formula', 'chart', 'image',
            'chinese_fonts', 'highlight', 'underline', 'over_100_pages',
            'powerpoint_ground_truth',
        }.issubset(coverage))
        for name, entry in entries.items():
            with self.subTest(name=name):
                self.assertEqual(len(entry['sha256']), 64)
                int(entry['sha256'], 16)
                self.assertGreater(entry['bytes'], 0)
                self.assertGreater(entry['pages'], 0)
                if 'url' in entry:
                    self.assertTrue(entry['url'].startswith('https://'))
                    self.assertTrue(entry['source_page'].startswith('https://'))

    def test_real_corpus_verifier_and_controlled_marks_are_reproducible(self):
        source = FIXTURES / 'text_styles.pdf'
        expected = {
            'kind': 'text_pdf',
            'bytes': source.stat().st_size,
            'sha256': sha256(source),
            'pages': 2,
        }
        self.assertEqual(verify_file(source, expected), [])
        with tempfile.TemporaryDirectory() as temp:
            corrupt = Path(temp) / 'corrupt.pdf'
            corrupt.write_bytes(source.read_bytes() + b'changed')
            errors = verify_file(corrupt, expected)
            self.assertTrue(any(error.startswith('bytes:') for error in errors))
            self.assertTrue(any(error.startswith('sha256:') for error in errors))

            first = Path(temp) / 'marks-1.pdf'
            second = Path(temp) / 'marks-2.pdf'
            derive_controlled_marks(FIXTURES / 'large_120_pages.pdf', first)
            derive_controlled_marks(FIXTURES / 'large_120_pages.pdf', second)
            self.assertEqual(sha256(first), sha256(second))
            with fitz.open(first) as document:
                self.assertEqual(len(document), 1)


if __name__ == '__main__':
    unittest.main()
