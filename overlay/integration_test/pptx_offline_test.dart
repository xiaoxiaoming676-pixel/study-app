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
    final pdf = await PdfDocument.openData(await output.readAsBytes());
    expect(pdf.pages.length, 4);
    for (final page in pdf.pages) {
      expect(page.width / page.height, closeTo(16 / 9, 0.02));
    }
    pdf.dispose();
    await output.delete();
    await input.delete();
  });
}
