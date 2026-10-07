import 'dart:async';
import 'dart:typed_data';

import 'package:pdfrx/pdfrx.dart';

class PdfDocumentCache {
  new({Future<PdfDocument> Function(String, Uint8List?)? loader})
      : _loader = loader ?? _openDocument;

  final Future<PdfDocument> Function(String, Uint8List?) _loader;
  final Map<String, Future<PdfDocument>> _cache = {};

  /// Loads a PDF document, sharing an in-flight load for the same path.
  Future<PdfDocument> load(String filePath, {Uint8List? pdfBytes}) {
    final cached = _cache[filePath];
    if (cached != null) return cached;
    final pending = Future<PdfDocument>.sync(() => _loader(filePath, pdfBytes));
    _cache[filePath] = pending;
    // A failed load must not poison a retry or throw again during disposal.
    // The original future still reports the error to the import caller.
    unawaited(pending.then<void>((_) {}, onError: (Object error, StackTrace stack) {
      if (identical(_cache[filePath], pending)) _cache.remove(filePath);
    }));
    return pending;
  }

  static Future<PdfDocument> _openDocument(String path, Uint8List? bytes) =>
      bytes == null
          ? PdfDocument.openFile(path, useProgressiveLoading: true)
          : PdfDocument.openData(bytes, useProgressiveLoading: true, sourceName: path);

  void dispose() {
    for (final pending in _cache.values) {
      // Disposal may race a failing load; its caller owns that load error.
      unawaited(pending.then<void>((document) => document.dispose(),
          onError: (Object error, StackTrace stack) {}));
    }
    _cache.clear();
  }
}
