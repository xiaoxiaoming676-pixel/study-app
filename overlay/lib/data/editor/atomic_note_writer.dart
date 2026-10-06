import 'dart:io';
import 'dart:math';

import 'package:saber/data/file_manager/file_manager.dart';
import 'package:saber/data/nextcloud/saber_syncer.dart';
import 'package:saber/data/prefs.dart';

/// Replace a document only after its new bytes have been flushed to disk.
Future<void> writeNoteAtomically(String relativePath, List<int> bytes) async {
  final target = FileManager.getFile(relativePath);
  await atomicReplaceFile(target, bytes);

  // Keep FileManager's recent-file and sync notifications after the commit.
  stows.recentFiles.value.remove(relativePath);
  stows.recentFiles.value.insert(0, relativePath);
  if (stows.recentFiles.value.length > FileManager.maxRecentlyAccessedFiles) {
    stows.recentFiles.value.removeLast();
  }
  stows.recentFiles.notifyListeners();
  FileManager.broadcastFileWrite(FileOperationType.write, relativePath);
  syncer.uploader.enqueueRel(relativePath);
}

Future<void> writeNoteAssetAtomically(String relativePath, List<int> bytes) async {
  await atomicReplaceFile(FileManager.getFile(relativePath), bytes);
  FileManager.broadcastFileWrite(FileOperationType.write, relativePath);
  syncer.uploader.enqueueRel(relativePath);
}

Future<void> atomicReplaceFile(
  File target,
  List<int> bytes, {
  Future<void> Function(File staged)? beforeCommit,
}) async {
  await target.parent.create(recursive: true);
  final random = Random.secure().nextInt(1 << 32);
  final staged = File('${target.path}.study-${DateTime.now().microsecondsSinceEpoch}-$random.tmp');
  try {
    await staged.writeAsBytes(bytes, flush: true);
    if (beforeCommit != null) await beforeCommit(staged);
    await staged.rename(target.path);
  } finally {
    if (await staged.exists()) await staged.delete();
  }
}
