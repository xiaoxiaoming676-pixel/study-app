import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber/data/study/cloze.dart';
import 'package:saber/data/editor/page.dart';
import 'package:saber/data/editor/editor_history.dart';
import 'package:sbn/change.dart';

void main() {
  test('Saving/reloading preserves answer, geometry, and hidden state', () {
    final original = ClozeState(masks: [
      const ClozeMask(Rect.fromLTWH(0.1, 0.2, 0.3, 0.1), answer: '教材答案'),
    ], text: '原始教材答案', hidden: false);
    final restored = ClozeState.fromJson(original.toJson());
    expect(restored.hidden, false);
    expect(restored.text, original.text);
    expect(restored.masks.single.answer, '教材答案');
    final bounds = restored.masks.single.onPage(const Size(1000, 1400));
    expect(bounds.left, closeTo(100, 1e-6));
    expect(bounds.top, closeTo(280, 1e-6));
    expect(bounds.width, closeTo(300, 1e-6));
    expect(bounds.height, closeTo(140, 1e-6));
  });
  test('Export page clone retains masks; preview can omit them without mutation', () {
    final page = EditorPage(cloze: ClozeState(masks: [
      const ClozeMask(Rect.fromLTWH(0.1, 0.2, 0.3, 0.1)),
    ]));
    final export = page.cloneForRasterization();
    expect(export.cloze.masks.length, 1);
    final preview = page.copyWith(cloze: ClozeState());
    expect(preview.cloze.masks, isEmpty);
    expect(page.cloze.masks.length, 1);
    export.disposeClonedData();
    page.dispose();
  });
  test('Invalid external rule coordinates fail rather than mask another page', () {
    for (final rect in [[-0.1, 0, 0.1, 0.1], [0.9, 0.9, 0.5, 0.5], [0, 0, 0, 1]]) {
      expect(() => ClozeMask.fromJson({'rect': rect}), throwsFormatException);
    }
  });
  test('Cloze edits become dirty and keep immutable undo snapshots', () {
    final history = EditorHistory();
    final before = ClozeState();
    final masks = [const ClozeMask(Rect.fromLTWH(0, 0, 0.2, 0.1))];
    final after = ClozeState(masks: masks);
    history.recordChange(EditorHistoryItem(type: EditorHistoryItemType.cloze,
      pageIndex: 0, strokes: [], images: [],
      clozeChange: Change(previous: before, current: after)));
    masks.clear();
    expect(history.isCurrentStateSaved, false);
    expect(history.undo().clozeChange!.current.masks.length, 1);
    expect(history.isCurrentStateSaved, true);
  });
  test('Practice reset keeps permanent notes and source text', () {
    const mask = ClozeMask(Rect.fromLTWH(0.1, 0.1, 0.2, 0.1), answer: '答案');
    final state = ClozeState(masks: [mask], text: '教材答案', note: '长期笔记',
      responses: {mask.key: StudyResponse(text: '我的回答')}, speechOffset: 2);
    final reset = state.resetPractice();
    expect(reset.responses, isEmpty);
    expect(reset.note, state.note);
    expect(reset.text, state.text);
    expect(reset.masks.single.key, mask.key);
    expect(state.responses[mask.key]!.text, '我的回答');
  });
  test('Answers and resume position survive JSON reload', () {
    const mask = ClozeMask(Rect.fromLTWH(0.1, 0.1, 0.2, 0.1));
    final original = ClozeState(masks: [mask], note: '笔记', speechOffset: 7,
      responses: {mask.key: StudyResponse(text: '回答', ink: [
        [const Offset(0.1, 0.2), const Offset(0.8, 0.9)]])});
    final restored = ClozeState.fromJson(original.toJson());
    expect(restored.toJson(), original.toJson());
    expect(restored.responses[mask.key]!.ink.single.last, const Offset(0.8, 0.9));
  });
  test('Rule merge retains answers and removes only the deleted answer', () {
    const a = ClozeMask(Rect.fromLTWH(0, 0, 0.2, 0.1));
    const b = ClozeMask(Rect.fromLTWH(0.3, 0.3, 0.2, 0.1));
    final original = ClozeState(masks: [a], note: 'keep',
      responses: {a.key: StudyResponse(text: 'keep answer')});
    final merged = original.mergeMasks([a, b]);
    expect(merged.masks.length, 2);
    expect(merged.responses[a.key]!.text, 'keep answer');
    final removed = merged.removeMask(a);
    expect(removed.responses, isEmpty);
    expect(removed.masks.single.key, b.key);
    expect(removed.note, 'keep');
  });
  test('Mutable stroke inputs cannot rewrite saved history', () {
    final line = [const Offset(0.1, 0.1)];
    final ink = [line];
    final answer = StudyResponse(ink: ink);
    line.clear(); ink.clear();
    expect(answer.ink.single.single, const Offset(0.1, 0.1));
    expect(() => answer.ink.single.clear(), throwsUnsupportedError);
    expect(() => StudyResponse.fromJson({'ink': [[[2, 0]]]}), throwsFormatException);
  });
  test('A note-only page is retained when saving', () {
    final page = EditorPage(cloze: ClozeState(note: 'Do not drop this page'));
    expect(page.isEmpty, false);
    page.dispose();
  });

}
