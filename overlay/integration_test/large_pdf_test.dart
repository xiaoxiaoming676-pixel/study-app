import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
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

  testWidgets('120-page synthetic PDF import, save and failed-import recovery',
      (tester) async {
    final fixture = await rootBundle.load('assets/images/study_large_120_pages.pdf');
    final source = File('${Directory.systemTemp.path}/study-large-120.pdf');
    final bytes = fixture.buffer.asUint8List();
    await source.writeAsBytes(bytes, flush: true);

    FlavorConfig.setupFromEnvironment();
    disableSentryForTesting();
    await saber.appRunner(const []);
    await waitFor(tester, find.byType(HomePage));
    final notePath = await FileManager.newFilePath('/');
    final importWatch = Stopwatch()..start();
    GoRouter.of(tester.element(find.byType(HomePage)))
        .push(RoutePaths.editImportPdf(notePath, source.path));
    await waitFor(tester, find.byType(Editor));
    final editor = tester.state<EditorState>(find.byType(Editor));
    int pageCount() => editor.coreInfo.pages
        .where((page) => page.backgroundImage != null)
        .length;
    for (var i = 0; i < 240 && pageCount() != 120; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    importWatch.stop();
    expect(pageCount(), 120);
    final importMs = importWatch.elapsedMilliseconds;
    final peakRss = ProcessInfo.maxRss;
    debugPrintSynchronously(
      'STUDY_LARGE_PDF:pages=120 bytes=${bytes.length} '
      'import_ms=$importMs peak_rss_bytes=$peakRss',
    );
    expect(importWatch.elapsed, lessThan(const Duration(minutes: 2)));

    final saveWatch = Stopwatch()..start();
    await editor.saveToFile();
    saveWatch.stop();
    final reopened = await EditorCoreInfo.loadFromFilePath(notePath);
    expect(
      reopened.pages.where((page) => page.backgroundImage != null).length,
      120,
    );
    debugPrintSynchronously(
      'STUDY_LARGE_SAVE:save_ms=${saveWatch.elapsedMilliseconds} '
      'peak_rss_bytes=${ProcessInfo.maxRss}',
    );
    expect(saveWatch.elapsed, lessThan(const Duration(minutes: 2)));

    // An unreadable PDF must leave the already imported textbook untouched.
    final broken = File('${Directory.systemTemp.path}/study-broken.pdf');
    await broken.writeAsBytes([0, 1, 2, 3], flush: true);
    await expectLater(editor.importPdfFromFilePath(broken.path), throwsA(anything));
    expect(pageCount(), 120);
    await broken.delete();
    await source.delete();
  });
}
