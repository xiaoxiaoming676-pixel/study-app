import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:saber/components/study/study_panel.dart';
import 'package:saber/data/editor/editor_core_info.dart';
import 'package:saber/data/file_manager/file_manager.dart';
import 'package:saber/data/flavor_config.dart';
import 'package:saber/data/prefs.dart';
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

  testWidgets('iOS PDF import, cloze, note, save, reopen and speech channel',
      (tester) async {
    final document = pw.Document();
    document.addPage(pw.Page(build: (_) => pw.Text('Study Alpha Beta')));
    final source = File('${Directory.systemTemp.path}/study-flow-source.pdf');
    final bytes = await document.save();
    await source.writeAsBytes(bytes, flush: true);

    FlavorConfig.setupFromEnvironment();
    disableSentryForTesting();
    await saber.appRunner(const []);
    await waitFor(tester, find.byType(HomePage));
    final notePath = await FileManager.newFilePath('/');
    GoRouter.of(tester.element(find.byType(HomePage)))
        .push(RoutePaths.editImportPdf(notePath, source.path));
    await waitFor(tester, find.byType(Editor));
    await waitFor(tester, find.byTooltip('学习：挖空与朗读'));

    // iPhone handwriting uses a finger on the imported PDF page.
    final editor = tester.state<EditorState>(find.byType(Editor));
    stows.editorFingerDrawing.value = true;
    for (var i = 0; i < 40 && editor.coreInfo.pages.first.renderBox == null; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final pageBox = editor.coreInfo.pages.first.renderBox!;
    final start = pageBox.localToGlobal(
      Offset(pageBox.size.width * 0.5, pageBox.size.height * 0.5));
    final pen = await tester.startGesture(start, kind: PointerDeviceKind.touch);
    await tester.pump(const Duration(milliseconds: 50));
    await pen.moveBy(const Offset(24, 12));
    await tester.pump(const Duration(milliseconds: 50));
    await pen.moveBy(const Offset(24, 12));
    await tester.pump(const Duration(milliseconds: 50));
    await pen.up();
    await tester.pump(const Duration(milliseconds: 400));
    expect(editor.coreInfo.pages.first.strokes, isNotEmpty,
        reason: 'The imported PDF canvas did not accept a finger stroke');
    await editor.saveToFile();
    expect((await EditorCoreInfo.loadFromFilePath(notePath)).pages.first.strokes,
        isNotEmpty);

    // The native plugin must extract real PDF text and coordinates.
    const channel = MethodChannel('study.local/pdf_speech');
    final analysis = await channel.invokeMapMethod<String, dynamic>('analyze', {
      'bytes': bytes, 'page': 0, 'keywords': ['Alpha'],
      'bold': false, 'underline': false, 'highlight': false, 'color': '',
    });
    expect(analysis?['text'], contains('Alpha'));
    expect(analysis?['masks'], isNotEmpty);

    // A raster-only PDF exercises Vision OCR and its page-coordinate masks.
    final recorder = ui.PictureRecorder();
    final rasterCanvas = Canvas(recorder);
    rasterCanvas.drawColor(Colors.white, BlendMode.src);
    final label = TextPainter(
      text: const TextSpan(text: 'Alpha', style: TextStyle(fontSize: 72, color: Colors.red)),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(rasterCanvas, const Offset(75, 75));
    final otherLabel = TextPainter(
      text: const TextSpan(text: 'Beta', style: TextStyle(fontSize: 72, color: Colors.black)),
      textDirection: TextDirection.ltr,
    )..layout();
    otherLabel.paint(rasterCanvas, const Offset(75, 190));
    final raster = await recorder.endRecording().toImage(640, 320);
    final rasterBytes = await raster.toByteData(format: ui.ImageByteFormat.png);
    raster.dispose();
    final scanned = pw.Document();
    scanned.addPage(pw.Page(build: (_) => pw.Image(
      pw.MemoryImage(rasterBytes!.buffer.asUint8List()))));
    final scannedPdf = await scanned.save();
    final scanResult = await channel.invokeMapMethod<String, dynamic>('analyze', {
      'bytes': scannedPdf, 'page': 0, 'keywords': ['Alpha'],
      'bold': false, 'underline': false, 'highlight': false, 'color': '',
    });
    expect(scanResult?['text'], contains('Alpha'));
    expect(scanResult?['masks'], isNotEmpty);
    final colorResult = await channel.invokeMapMethod<String, dynamic>('analyze', {
      'bytes': scannedPdf, 'page': 0, 'keywords': <String>[],
      'bold': false, 'underline': false, 'highlight': false, 'color': 'FF0000',
    });
    final colorMasks = (colorResult?['masks'] as List?) ?? [];
    expect(colorMasks, isNotEmpty, reason: 'Red scan text should be detected');
    expect(colorMasks.any((mask) => (mask as Map)['answer'].toString().contains('Alpha')),
        isTrue);
    expect(colorMasks.any((mask) => (mask as Map)['answer'].toString().contains('Beta')),
        isFalse, reason: 'Black scan text must not match red ink');

    await tester.tap(find.byTooltip('学习：挖空与朗读'));
    await waitFor(tester, find.byType(StudyPanel));
    final clozeTab = find.text('挖空').last.hitTestable();
    await waitFor(tester, clozeTab);
    await tester.tap(clozeTab);
    await waitFor(tester, find.text('自动挖空'));
    await tester.tap(find.text('自动挖空'));
    await waitFor(tester, find.text('生成候选'));
    await tester.enterText(find.byType(TextField).first, 'Alpha');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('生成候选'));
    await waitFor(tester, find.text('保存候选'));
    await tester.tap(find.text('保存候选'));
    await waitFor(tester, find.textContaining('0 / 1 已答'));
    final enabledNote = find.byWidgetPredicate((widget) =>
        widget is IconButton &&
        widget.tooltip == '长期笔记' &&
        widget.onPressed != null);
    await waitFor(tester, enabledNote);
    await tester.tap(enabledNote);
    await waitFor(tester, find.text('本页长期笔记'));
    await tester.enterText(find.byType(TextField).last, '这段需要复习');
    await tester.tap(find.text('完成'));
    await waitFor(tester, find.text('已保存'));

    final saved = await EditorCoreInfo.loadFromFilePath(notePath);
    expect(saved.pages.first.strokes, isNotEmpty);
    expect(saved.pages.first.cloze.masks.single.answer, 'Alpha');
    expect(saved.pages.first.cloze.note, '这段需要复习');

    await tester.tap(find.text('听读').last);
    await waitFor(tester, find.text('从保存位置朗读'));
    await tester.tap(find.text('本页重读'));
    await tester.pump(const Duration(seconds: 2));
    expect(find.textContaining('本页未识别到文字'), findsNothing);
    await tester.tap(find.text('停止'));

    await tester.tap(find.byIcon(Icons.arrow_back).first);
    await waitFor(tester, find.byType(Editor));
    GoRouter.of(tester.element(find.byType(Editor))).pop();
    await waitFor(tester, find.byType(HomePage));
    GoRouter.of(tester.element(find.byType(HomePage)))
        .push(RoutePaths.editFilePath(notePath));
    final reopenedStudyButton =
        find.byTooltip('学习：挖空与朗读').hitTestable();
    await waitFor(tester, reopenedStudyButton);
    await tester.tap(reopenedStudyButton);
    await waitFor(tester, find.byType(StudyPanel));
    expect(find.textContaining('0 / 1 已答'), findsOneWidget);
    await tester.tap(find.byTooltip('长期笔记'));
    await waitFor(tester, find.text('这段需要复习'));
  }, timeout: const Timeout(Duration(minutes: 10)));
}
