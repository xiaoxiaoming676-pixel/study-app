import 'package:flutter/material.dart';
import 'package:saber/components/study/answer_painter.dart';
import 'package:saber/data/study/cloze.dart';

class AnswerSheet extends StatefulWidget {
  const new({super.key, required this.initial, required this.answer,
    required this.onChanged});
  final StudyResponse initial;
  final String answer;
  final ValueChanged<StudyResponse> onChanged;
  @override
  State<AnswerSheet> createState() => _AnswerSheetState();
}
class _AnswerSheetState extends State<AnswerSheet> {
  late final TextEditingController _text;
  late List<List<Offset>> _ink;
  List<Offset>? _current;
  var _showAnswer = false;
  @override
  void initState() { super.initState(); _text = TextEditingController(text: widget.initial.text);
    _ink = widget.initial.ink.map((line) => line.toList()).toList(); }
  void _changed() => widget.onChanged(StudyResponse(text: _text.text, ink: _ink));
  Offset _point(Offset p, Size size) => Offset((p.dx / size.width).clamp(0.0, 1.0).toDouble(),
      (p.dy / size.height).clamp(0.0, 1.0).toDouble());
  void _finish() {
    if (_current == null) return;
    setState(() { _ink.add(_current!); _current = null; }); _changed();
  }
  @override
  Widget build(BuildContext context) => SafeArea(child: Padding(
    padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
    child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [const Expanded(child: Text('填写答案', style: TextStyle(fontSize: 20))),
        TextButton(onPressed: () { _finish(); Navigator.pop(context); }, child: const Text('完成'))]),
      TextField(controller: _text, maxLines: 3, minLines: 1,
        decoration: const InputDecoration(hintText: '输入答案，也可以在下面手写', border: OutlineInputBorder()),
        onChanged: (_) => _changed()),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (_, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxWidth / 2.5);
        return SizedBox.fromSize(size: size, child: GestureDetector(
          onPanStart: (e) => setState(() { _current = [_point(e.localPosition, size)]; }),
          onPanUpdate: (e) => setState(() { _current?.add(_point(e.localPosition, size)); }),
          onPanEnd: (_) => _finish(), onPanCancel: _finish,
          child: DecoratedBox(decoration: BoxDecoration(color: const Color(0xFFF4F7F6),
            border: Border.all(color: Colors.teal.shade100), borderRadius: BorderRadius.circular(12)),
            child: CustomPaint(painter: AnswerPainter(StudyResponse(ink: [..._ink, ?_current])))),
        ));
      }),
      Row(children: [TextButton(onPressed: _ink.isEmpty ? null : () {
        setState(() { _ink.removeLast(); }); _changed(); }, child: const Text('撤销一笔')),
        TextButton(onPressed: () { setState(() { _ink.clear(); _current = null; _text.clear(); }); _changed(); }, child: const Text('清空本题')),
        const Spacer(), TextButton(onPressed: () => setState(() { _showAnswer = !_showAnswer; }), child: const Text('对照答案'))]),
      if (_showAnswer) SelectableText(widget.answer.isEmpty ? '手动框选题：返回教材，切换原文查看。' : widget.answer),
      const Text('答案独立保存；清空本题不会删除教材笔记。', style: TextStyle(fontSize: 12)),
    ])),
  ));
  @override
  void dispose() { _text.dispose(); super.dispose(); }
}
