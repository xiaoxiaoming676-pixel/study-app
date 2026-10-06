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
    final encoded = base64Encode(pdfBytes);
    const chunkSize = 3072;
    final chunks = (encoded.length + chunkSize - 1) ~/ chunkSize;
    debugPrintSynchronously('STUDY_PDF_BEGIN:${pdfBytes.length}:$chunks');
    for (var index = 0; index < chunks; index++) {
      final start = index * chunkSize;
      final end = start + chunkSize < encoded.length
          ? start + chunkSize
          : encoded.length;
      debugPrintSynchronously(
        'STUDY_PDF_CHUNK:$index:${encoded.substring(start, end)}',
      );
    }
    debugPrintSynchronously('STUDY_PDF_END');

    FlavorConfig.setupFromEnvironment();
    disableSentryForTesting();
    await saber.appRunner(const []);
    await waitFor(tester, find.byType(HomePage));
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

    await input.delete();
  });
}
