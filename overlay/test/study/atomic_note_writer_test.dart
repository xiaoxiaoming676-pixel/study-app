import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:saber/data/editor/atomic_note_writer.dart';

void main() {
  test('A failed staged write leaves the previous note intact', () async {
    final directory = await Directory.systemTemp.createTemp('study-atomic-test-');
    try {
      final note = File('${directory.path}/lesson.sbn2');
      await note.writeAsBytes([1, 2, 3]);
      await expectLater(
        atomicReplaceFile(note, [4, 5, 6], beforeCommit: (_) async {
          throw StateError('Simulated interruption before commit');
        }),
        throwsStateError,
      );
      expect(await note.readAsBytes(), [1, 2, 3]);
      expect(directory.listSync().length, 1);
      await atomicReplaceFile(note, [4, 5, 6]);
      expect(await note.readAsBytes(), [4, 5, 6]);
      expect(directory.listSync().length, 1);
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
