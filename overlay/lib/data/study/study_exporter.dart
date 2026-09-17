import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:saber/data/editor/editor_core_info.dart';
import 'package:saber/data/editor/editor_exporter.dart';
import 'package:saber/data/study/cloze.dart';

enum StudyExportMode { original, practice, annotated }

abstract class StudyExporter {
  /// Render sequentially so a phone never holds all uncompressed pages at once.
  /// Only visible pixels enter the export: hidden PDF text cannot be copied out.
  static Future<Uint8List> generate(EditorCoreInfo source, StudyExportMode mode) async {
    final pdf = pw.Document();
    for (int i = 0; i < source.pages.length; i++) {
      final page = source.pages[i];
      if (i == source.pages.length - 1 && page.isEmpty) continue;
      final state = switch (mode) {
        StudyExportMode.original => ClozeState(),
        StudyExportMode.practice => page.cloze.copyWith(hidden: true, responses: {}, showResponses: false),
        StudyExportMode.annotated => page.cloze,
      };
      final pages = source.pages.toList();
      pages[i] = page.copyWith(cloze: state,
        strokes: mode == StudyExportMode.annotated ? page.strokes : []);
      final image = await EditorExporter.screenshotPage(coreInfo: source.copyWith(pages: pages),
        pageIndex: i, rasterizeAllStrokes: true, pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final memory = pw.MemoryImage(bytes!.buffer.asUint8List());
      pdf.addPage(pw.Page(pageFormat: PdfPageFormat(page.size.width, page.size.height,
        marginAll: 0), build: (_) => pw.Image(memory, fit: pw.BoxFit.contain)));
      if (mode == StudyExportMode.annotated && state.note.isNotEmpty) {
        await _appendNotes(pdf, '第 ${i + 1} 页 · 长期笔记', state.note);
      }
    }
    return pdf.save();
  }

  static Future<void> _appendNotes(pw.Document pdf, String title, String note) async {
    // Lay out one bounded page at a time; no separate network font dependency.
    for (int start = 0; start < note.length; start += 1000) {
      final chunk = note.substring(start, (start + 1000).clamp(0, note.length).toInt());
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(const Rect.fromLTWH(0, 0, 1000, 1400), Paint()..color = Colors.white);
      final painter = TextPainter(text: TextSpan(text: '$title\n\n$chunk',
        style: const TextStyle(color: Colors.black, fontSize: 24, height: 1.5)),
        textDirection: TextDirection.ltr)..layout(maxWidth: 880);
      // Long runs of line breaks can exceed a page even within a short chunk.
      final scale = (1260 / painter.height.clamp(1, double.infinity)).clamp(0.0, 1.0).toDouble();
      canvas.translate(60, 60); canvas.scale(scale);
      painter.paint(canvas, Offset.zero); painter.dispose();
      final picture = recorder.endRecording();
      final image = await picture.toImage(1000, 1400); picture.dispose();
      final data = await image.toByteData(format: ui.ImageByteFormat.png); image.dispose();
      final memory = pw.MemoryImage(data!.buffer.asUint8List());
      pdf.addPage(pw.Page(pageFormat: const PdfPageFormat(1000, 1400, marginAll: 0),
        build: (_) => pw.Image(memory)));
    }
  }
}
