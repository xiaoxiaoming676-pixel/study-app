import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:saber/data/editor/editor_core_info.dart';
import 'package:saber/data/file_manager/file_manager.dart';
import 'package:saber/data/flavor_config.dart';
import 'package:saber/data/routes.dart';
import 'package:saber/data/sentry/sentry_init.dart';
import 'package:saber/main.dart' as saber;
import 'package:saber/pages/editor/editor.dart';
import 'package:saber/pages/home/home.dart';

Future<void> waitFor(WidgetTester tester, Finder target) async {
  for (var i = 0; i < 240 && target.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
  expect(target, findsWidgets);
}

void emitPdf(String prefix, List<int> bytes) {
  final encoded = base64Encode(bytes);
  const chunkSize = 3072;
  final chunks = (encoded.length + chunkSize - 1) ~/ chunkSize;
  debugPrintSynchronously('${prefix}_BEGIN:${bytes.length}:$chunks');
  for (var index = 0; index < chunks; index++) {
    final start = index * chunkSize;
    final end = start + chunkSize < encoded.length
        ? start + chunkSize
        : encoded.length;
    debugPrintSynchronously(
      '${prefix}_CHUNK:$index:${encoded.substring(start, end)}',
    );
  }
  debugPrintSynchronously('${prefix}_END');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('complex PPTX becomes a four-page PDF entirely inside the app',
      (tester) async {
    final fixture = await rootBundle.load('assets/images/deck_complex.pptx');
    final input = File('${Directory.systemTemp.path}/study-offline-complex.pptx');
    await input.writeAsBytes(fixture.buffer.asUint8List(), flush: true);
    const channel = MethodChannel('study.local/pptx');
    final path = await channel.invokeMethod<String>('convert', {
      'path': input.path,
    }).timeout(const Duration(minutes: 3));
    expect(path, isNotNull);
    final output = File(path!);
    expect(output.existsSync(), isTrue);
    final pdfBytes = await output.readAsBytes();
    final pdf = await PdfDocument.openData(pdfBytes);
    expect(pdf.pages.length, 4);
    for (final page in pdf.pages) {
      expect(page.width / page.height, closeTo(16 / 9, 0.02));
    }
    pdf.dispose();
    // Flutter may remove the test app before a later CI step can read its tmp directory.
    // Emit only this fixed synthetic PDF so CI can score the actual WebKit output.
    emitPdf('STUDY_PDF', pdfBytes);

    FlavorConfig.setupFromEnvironment();
    disableSentryForTesting();
    await saber.appRunner(const []);
    await waitFor(tester, find.byType(HomePage));
    // Chart labels are rendered into the slide image and are not selectable PDF
    // text. Verify that the existing Vision channel supplies text and coordinates
    // before the converted PDF enters the normal study system.
    const studyChannel = MethodChannel('study.local/pdf_speech');
    final chartResult = await studyChannel.invokeMapMethod<String, dynamic>(
      'analyze',
      {
        'bytes': pdfBytes,
        'page': 2,
        'keywords': ['一月', '二月', '三月'],
        'bold': false,
        'underline': false,
        'highlight': false,
        'color': '',
      },
    );
    final chartText = chartResult?['text'] as String? ?? '';
    final chartMasks = (chartResult?['masks'] as List? ?? [])
        .map((mask) => Map<String, dynamic>.from(mask as Map))
        .toList();
    for (final label in ['一月', '二月', '三月']) {
      expect(chartText, contains(label));
      expect(chartMasks.any((mask) => mask['answer'] == label), isTrue);
    }
    for (final mask in chartMasks) {
      final rect = (mask['rect'] as List).cast<num>();
      expect(rect, hasLength(4));
      expect(rect.every((value) => value >= 0 && value <= 1), isTrue);
    }
    debugPrintSynchronously(
      'STUDY_PPTX_OCR:page=3 labels=3 masks=${chartMasks.length}',
    );
    final notePath = await FileManager.newFilePath('/');
    GoRouter.of(tester.element(find.byType(HomePage)))
        .push(RoutePaths.editImportPdf(notePath, output.path));
    await waitFor(tester, find.byType(Editor));
    final editor = tester.state<EditorState>(find.byType(Editor));
    int importedPages() => editor.coreInfo.pages
        .where((page) => page.backgroundImage != null)
        .length;
    for (var i = 0;
        i < 240 && importedPages() != 4;
        i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(importedPages(), 4);
    await editor.saveToFile();
    final reopened = await EditorCoreInfo.loadFromFilePath(notePath);
    expect(
      reopened.pages.where((page) => page.backgroundImage != null).length,
      4,
    );

    // This public Illinois DoIT exercise has images, a chart, a table and
    // process shapes, plus an official PowerPoint PDF reference. Keep the file
    // out of git; CI downloads it and verifies its fixed hash before bundling.
    final realFixture =
        await rootBundle.load('assets/images/real_corpus_illinois.pptx');
    final realInput =
        File('${Directory.systemTemp.path}/study-real-illinois.pptx');
    await realInput.writeAsBytes(
      realFixture.buffer.asUint8List(),
      flush: true,
    );
    final realPath = await channel.invokeMethod<String>('convert', {
      'path': realInput.path,
    }).timeout(const Duration(minutes: 3));
    expect(realPath, isNotNull);
    final realOutput = File(realPath!);
    final realPdfBytes = await realOutput.readAsBytes();
    final realPdf = await PdfDocument.openData(realPdfBytes);
    expect(realPdf.pages.length, 5);
    for (final page in realPdf.pages) {
      expect(page.width / page.height, closeTo(16 / 9, 0.02));
    }
    realPdf.dispose();
    emitPdf('STUDY_REAL_PDF', realPdfBytes);

    final realChartResult = await studyChannel.invokeMapMethod<String, dynamic>(
      'analyze',
      {
        'bytes': realPdfBytes,
        'page': 2,
        'keywords': ['January', 'February', 'March'],
        'bold': false,
        'underline': false,
        'highlight': false,
        'color': '',
      },
    );
    final realChartMasks = (realChartResult?['masks'] as List? ?? [])
        .map((mask) => Map<String, dynamic>.from(mask as Map))
        .toList();
    for (final label in ['January', 'February', 'March']) {
      expect(
        realChartMasks.any((mask) => mask['answer'] == label),
        isTrue,
      );
    }
    debugPrintSynchronously(
      'STUDY_REAL_PPTX:pages=5 labels=3 masks=${realChartMasks.length}',
    );

    await input.delete();
    await realInput.delete();
  });
}
