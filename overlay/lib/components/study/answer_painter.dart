import 'package:flutter/material.dart';
import 'package:saber/data/study/cloze.dart';

void paintStudyResponse(Canvas canvas, Rect rect, StudyResponse response) {
  canvas.save();
  canvas.clipRect(rect);
  final textHeight = response.ink.isEmpty ? rect.height : rect.height * 0.45;
  if (response.text.isNotEmpty) {
    final painter = TextPainter(text: TextSpan(text: response.text,
      style: TextStyle(color: Colors.blue.shade800, fontSize: 20)),
      textDirection: TextDirection.ltr)..layout(maxWidth: 420);
    final scale = (rect.width / painter.width.clamp(1, double.infinity))
        .clamp(0.0, textHeight / painter.height.clamp(1, double.infinity)).toDouble();
    canvas.save(); canvas.translate(rect.left, rect.top); canvas.scale(scale);
    painter.paint(canvas, Offset.zero); canvas.restore(); painter.dispose();
  }
  final inkRect = Rect.fromLTWH(rect.left,
      rect.top + (response.text.isEmpty ? 0 : textHeight), rect.width,
      response.text.isEmpty ? rect.height : rect.height - textHeight);
  final pen = Paint()..color = Colors.blue.shade800..style = PaintingStyle.stroke
    ..strokeWidth = (inkRect.height / 100).clamp(0.6, 3.0).toDouble()..strokeCap = StrokeCap.round;
  for (final line in response.ink) {
    if (line.isEmpty) continue;
    Offset project(Offset p) => Offset(inkRect.left + p.dx * inkRect.width,
        inkRect.top + p.dy * inkRect.height);
    if (line.length == 1) {
      canvas.drawCircle(project(line.first), pen.strokeWidth, Paint()..color = pen.color);
      continue;
    }
    final path = Path()..moveTo(project(line.first).dx, project(line.first).dy);
    for (final point in line.skip(1)) { final p = project(point); path.lineTo(p.dx, p.dy); }
    canvas.drawPath(path, pen);
  }
  canvas.restore();
}

class AnswerPainter extends CustomPainter {
  const new(this.response);
  final StudyResponse response;
  @override
  void paint(Canvas canvas, Size size) => paintStudyResponse(canvas, Offset.zero & size, response);
  @override
  bool shouldRepaint(AnswerPainter oldDelegate) => oldDelegate.response != response;
}
