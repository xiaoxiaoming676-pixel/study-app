import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:saber/components/canvas/image/pdf_document_cache.dart';

class _Document extends Fake implements PdfDocument {
  var disposals = 0;

  @override
  Future<void> dispose() async { disposals++; }
}

void main() {
  test('Failed PDF load is evicted so a corrected file can be retried', () async {
    var attempts = 0;
    final document = _Document();
    final cache = PdfDocumentCache(loader: (_, _) async {
      if (++attempts == 1) throw StateError('Invalid PDF');
      return document;
    });
    await expectLater(cache.load('lesson.pdf'), throwsStateError);
    expect(await cache.load('lesson.pdf'), same(document));
    expect(attempts, 2);
    cache.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(document.disposals, 1);
  });

  test('Disposing during a failed load does not emit a second error', () async {
    final loading = Completer<PdfDocument>();
    final cache = PdfDocumentCache(loader: (_, _) => loading.future);
    final failure = expectLater(cache.load('broken.pdf'), throwsStateError);
    cache.dispose();
    loading.completeError(StateError('Invalid PDF'));
    await failure;
    await Future<void>.delayed(Duration.zero);
  });

  test('Concurrent loads share one document and disposal releases it once', () async {
    final loading = Completer<PdfDocument>();
    final document = _Document();
    var attempts = 0;
    final cache = PdfDocumentCache(loader: (_, _) {
      attempts++;
      return loading.future;
    });
    final first = cache.load('lesson.pdf');
    expect(cache.load('lesson.pdf'), same(first));
    cache.dispose();
    loading.complete(document);
    expect(await first, same(document));
    await Future<void>.delayed(Duration.zero);
    expect(attempts, 1);
    expect(document.disposals, 1);
  });
}
