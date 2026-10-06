import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdfrx/pdfrx.dart';

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
    print('STUDY_PDF_BEGIN:${pdfBytes.length}:$chunks');
    for (var index = 0; index < chunks; index++) {
      final start = index * chunkSize;
      final end = start + chunkSize < encoded.length ? start + chunkSize : encoded.length;
      print('STUDY_PDF_CHUNK:$index:${encoded.substring(start, end)}');
    }
    print('STUDY_PDF_END');
    await input.delete();
  });
}
