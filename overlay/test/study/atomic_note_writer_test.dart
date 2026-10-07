import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:saber/data/editor/atomic_note_writer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Thumbnail stays decodable during a partial staged replacement', () async {
    final directory = await Directory.systemTemp.createTemp('study-preview-test-');
    Future<List<int>> png(ui.Color color) async {
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawColor(color, ui.BlendMode.src);
      final picture = recorder.endRecording();
      final image = await picture.toImage(2, 2);
      picture.dispose();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data!.buffer.asUint8List();
    }
    try {
      final preview = File('${directory.path}/lesson.sbn2.p');
      final oldPng = await png(const ui.Color(0xFFFFFFFF));
      final newPng = await png(const ui.Color(0xFF000000));
      await preview.writeAsBytes(oldPng, flush: true);
      await expectLater(
        atomicReplaceFile(preview, newPng, beforeCommit: (staged) async {
          await staged.writeAsBytes(newPng.take(12).toList(), flush: true);
          // The homepage can read this path while another save is in flight.
          final visible = await preview.readAsBytes();
          expect(visible, oldPng);
          final codec = await ui.instantiateImageCodec(visible);
          final frame = await codec.getNextFrame();
          expect(frame.image.width, 2);
          frame.image.dispose();
          codec.dispose();
          throw StateError('Interrupted partial thumbnail write');
        }),
        throwsStateError,
      );
      expect(await preview.readAsBytes(), oldPng);
      await atomicReplaceFile(preview, newPng);
      expect(await preview.readAsBytes(), newPng);
      expect(directory.listSync().length, 1);
    } finally {
      await directory.delete(recursive: true);
    }
  });

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
