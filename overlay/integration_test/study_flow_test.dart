import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:saber/components/study/study_panel.dart';
import 'package:saber/data/editor/editor_core_info.dart';
import 'package:saber/data/file_manager/file_manager.dart';
import 'package:saber/data/routes.dart';
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

    await saber.appRunner(const []);
    await waitFor(tester, find.byType(HomePage));
    final notePath = await FileManager.newFilePath('/');
    GoRouter.of(tester.element(find.byType(HomePage)))
        .push(RoutePaths.editImportPdf(notePath, source.path));
    await waitFor(tester, find.byType(Editor));
    await waitFor(tester, find.byTooltip('学习：挖空与朗读'));

    // The native plugin must extract real PDF text and coordinates.
    const channel = MethodChannel('study.local/pdf_speech');
    final analysis = await channel.invokeMapMethod<String, dynamic>('analyze', {
      'bytes': bytes, 'page': 0, 'keywords': ['Alpha'],
      'bold': false, 'underline': false, 'highlight': false, 'color': '',
    });
    expect(analysis?['text'], contains('Alpha'));
    expect(analysis?['masks'], isNotEmpty);

    await tester.tap(find.byTooltip('学习：挖空与朗读'));
    await waitFor(tester, find.byType(StudyPanel));
    await tester.tap(find.text('挖空').last);
    await waitFor(tester, find.text('自动挖空'));
    await tester.tap(find.text('自动挖空'));
    await waitFor(tester, find.text('生成候选'));
    await tester.enterText(find.byType(TextField).last, 'Alpha');
    await tester.tap(find.text('生成候选'));
    await waitFor(tester, find.text('保存候选'));
    await tester.tap(find.text('保存候选'));
    await waitFor(tester, find.textContaining('0 / 1 已答'));

    await tester.tap(find.byTooltip('长期笔记'));
    await waitFor(tester, find.text('本页长期笔记'));
    await tester.enterText(find.byType(TextField).last, '这段需要复习');
    await tester.tap(find.text('完成'));
    await waitFor(tester, find.text('已保存'));

    final saved = await EditorCoreInfo.loadFromFilePath(notePath);
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
    await waitFor(tester, find.byTooltip('学习：挖空与朗读'));
    await tester.tap(find.byTooltip('学习：挖空与朗读'));
    await waitFor(tester, find.byType(StudyPanel));
    expect(find.textContaining('0 / 1 已答'), findsOneWidget);
    await tester.tap(find.byTooltip('长期笔记'));
    await waitFor(tester, find.text('这段需要复习'));
  }, timeout: const Timeout(Duration(minutes: 10)));
}
