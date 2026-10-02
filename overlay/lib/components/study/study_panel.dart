import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:saber/components/canvas/image/editor_image.dart';
import 'package:saber/components/study/answer_painter.dart';
import 'package:saber/components/study/answer_sheet.dart';
import 'package:saber/data/editor/editor_core_info.dart';
import 'package:saber/data/editor/editor_exporter.dart';
import 'package:saber/data/study/cloze.dart';
import 'package:saber/data/study/study_exporter.dart';

class StudyPanel extends StatefulWidget {
  const new({super.key, required this.coreInfo, required this.pageIndex,
    required this.onChanged});
  final EditorCoreInfo coreInfo;
  final int pageIndex;
  final Future<bool> Function(Map<int, ClozeState>) onChanged;
  @override
  State<StudyPanel> createState() => _StudyPanelState();
}

class _StudyPanelState extends State<StudyPanel> with WidgetsBindingObserver {
  static const _channel = MethodChannel('study.local/pdf_speech');
  late final Map<int, ClozeState> _states;
  late int _page;
  var _tab = 0;
  var _previewGeneration = 0;
  var _revision = 0;
  Uint8List? _preview;
  String? _error;
  var _operation = '';
  var _busy = false;
  var _saving = false;
  var _dirty = false;
  var _delete = false;
  var _showOriginal = false;
  var _reading = false;
  var _continuous = false;
  var _speechToken = 0;
  var _speechOffset = 0;
  var _speechStartOffset = 0;
  String? _voice;
  var _rate = 0.5;
  List<Map<String, dynamic>> _voices = [];
  Offset? _start;
  Rect? _pending;
  final _transform = TransformationController();
  final _keyword = TextEditingController();
  Future<bool> _saveQueue = Future.value(true);
  Timer? _progressTimer;
  ClozeState get _state => _states[_page]!;
  int get _count => widget.coreInfo.pages.length > 1 && widget.coreInfo.pages.last.isEmpty
      ? widget.coreInfo.pages.length - 1 : widget.coreInfo.pages.length;

  @override
  void initState() {
    super.initState();
    _page = widget.pageIndex.clamp(0, _count - 1).toInt();
    _states = {for (int i = 0; i < widget.coreInfo.pages.length; i++) i: widget.coreInfo.pages[i].cloze};
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isIOS) _channel.setMethodCallHandler(_speechEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) { _loadPreview(); _loadVoices(); });
  }

  Future<void> _loadVoices() async {
    if (!Platform.isIOS) return;
    try {
      final list = await _channel.invokeListMethod<dynamic>('voices');
      if (mounted) setState(() { _voices = (list ?? []).map((v) => Map<String, dynamic>.from(v as Map)).toList(); });
    } catch (_) { /* Reading stays available even if system voice discovery fails. */ }
  }

  Future<void> _loadPreview() async {
    final generation = ++_previewGeneration;
    final index = _page;
    setState(() { _preview = null; });
    try {
      final pages = widget.coreInfo.pages.toList();
      pages[index] = pages[index].copyWith(cloze: ClozeState());
      final image = await EditorExporter.screenshotPage(
        coreInfo: widget.coreInfo.copyWith(pages: pages), pageIndex: index,
        rasterizeAllStrokes: true, pixelRatio: 1.2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (mounted && generation == _previewGeneration) setState(() { _preview = data!.buffer.asUint8List(); });
    } catch (e) {
      if (mounted && generation == _previewGeneration) setState(() { _error = '页面加载失败：$e'; });
    }
  }

  Future<bool> _persist(Map<int, ClozeState> changes) {
    if (!mounted) return Future.value(false);
    _states.addAll(changes);
    final revision = ++_revision;
    final snapshot = Map<int, ClozeState>.from(_states);
    setState(() { _saving = true; _dirty = true; });
    return _saveQueue = _saveQueue.then((_) async {
      bool ok = false;
      try { ok = await widget.onChanged(snapshot); } catch (_) { ok = false; }
      if (mounted && revision == _revision) setState(() {
        _saving = false; _dirty = !ok;
        if (!ok) _error = '保存未完成，请点“重试保存”，暂勿关闭应用。';
      });
      return ok;
    });
  }

  Future<void> _leave() async {
    await _stop();
    final ok = await (_dirty ? _persist({}) : _saveQueue);
    if (mounted && ok) {
      // Allow PopScope to rebuild before popping after an asynchronous save.
      setState(() { _dirty = false; _saving = false; });
      WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) Navigator.pop(context); });
    }
  }

  Future<void> _navigate(int index, {bool continueReading = false}) async {
    if (index < 0 || index >= _count || _busy) return;
    if (!continueReading) await _stop();
    if (!mounted) return;
    setState(() { _page = index; _error = null; _transform.value = Matrix4.identity(); });
    await _loadPreview();
  }

  Future<void> _run(String operation, Future<void> Function() action) async {
    if (_busy) return;
    setState(() { _busy = true; _error = null; _operation = operation; });
    try { await action(); }
    catch (e) { if (mounted) setState(() { _error = e.toString(); }); }
    finally { if (mounted) setState(() { _busy = false; _operation = ''; }); }
  }

  Future<({PdfEditorImage image, Uint8List bytes})> _pdf(int index) async {
    final page = widget.coreInfo.pages[index];
    final image = page.backgroundImage;
    if (image is! PdfEditorImage) throw const FormatException('这页不是 PDF 教材，可手动框选；请先在教材编辑器中导入 PDF。');
    if ((page.size.aspectRatio - image.naturalSize.aspectRatio).abs() > 0.01) {
      throw const FormatException('页面比例改变，请重新导入 PDF 再自动识别。');
    }
    final bytes = image.pdfBytes ?? await image.pdfFile!.readAsBytes();
    if (bytes.length > 80 * 1024 * 1024) throw const FormatException('教材较大，请拆分为章节后再识别。');
    return (image: image, bytes: bytes);
  }

  Future<Map<String, dynamic>> _analyze(int index, {List<String> keywords = const [],
      bool bold = false, bool underline = false, bool highlight = false, String? color}) async {
    if (!Platform.isIOS) throw const FormatException('自动识别使用苹果 PDFKit；其他平台可导入电脑生成的规则。');
    final source = await _pdf(index);
    return await _channel.invokeMapMethod<String, dynamic>('analyze', {
      'bytes': source.bytes, 'page': source.image.pdfPage, 'keywords': keywords,
      'bold': bold, 'underline': underline, 'highlight': highlight, 'color': color,
    }) ?? {};
  }

  Future<bool> _confirm(String title, String message) async => await showDialog<bool>(
    context: context, builder: (context) => AlertDialog(title: Text(title), content: Text(message), actions: [
      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('应用')),
    ])) ?? false;

  Future<void> _rules() async {
    await _stop();
    if (!mounted) return;
    bool whole = false, bold = false, underline = false, highlight = false;
    String color = '';
    final colors = TextEditingController();
    final apply = await showModalBottomSheet<bool>(context: context, isScrollControlled: true,
      builder: (context) => StatefulBuilder(builder: (context, update) => SafeArea(child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('自动挖空', style: TextStyle(fontSize: 20)),
          TextField(controller: _keyword, decoration: const InputDecoration(labelText: '关键词（每行一个）'), maxLines: 3),
          TextField(controller: colors, decoration: const InputDecoration(labelText: '字体颜色（可选）', hintText: '例如 FF0000，不限红色'), onChanged: (v) { color = v; }),
          CheckboxListTile(title: const Text('加粗'), value: bold, onChanged: (v) => update(() { bold = v!; })),
          CheckboxListTile(title: const Text('下划线'), value: underline, onChanged: (v) => update(() { underline = v!; })),
          CheckboxListTile(title: const Text('PDF 高亮批注'), value: highlight, onChanged: (v) => update(() { highlight = v!; })),
          SwitchListTile(title: const Text('应用到整本教材'), value: whole, onChanged: (v) => update(() { whole = v; })),
          const Text('任一条件匹配即列为候选。先预览，再保存；图片中的标记需要人工框选。'),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('生成候选')),
        ])),
      ))));
    colors.dispose();
    if (apply != true || !mounted) return;
    color = color.trim().replaceFirst('#', '').toUpperCase();
    final words = _keyword.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (color.isNotEmpty && !RegExp(r'^[0-9A-F]{6}$').hasMatch(color)) {
      setState(() { _error = '颜色需为六位 RGB，例如 0000FF。'; }); return;
    }
    if (words.isEmpty && color.isEmpty && !bold && !underline && !highlight) return;
    await _run('正在识别教材', () async {
      final changes = <int, ClozeState>{};
      final failures = <int>[];
      int count = 0;
      for (final index in whole ? List.generate(_count, (i) => i) : [_page]) {
        if (!mounted) return;
        setState(() { _operation = '识别第 ${index + 1} / $_count 页'; });
        try {
          final result = await _analyze(index, keywords: words, bold: bold,
            underline: underline, highlight: highlight, color: color);
          final masks = (result['masks'] as List? ?? []).map((m) => ClozeMask.fromJson(Map<String, dynamic>.from(m as Map))).toList();
          count += masks.length;
          changes[index] = _states[index]!.mergeMasks(masks).copyWith(text: result['text'] as String? ?? '');
        } catch (_) { failures.add(index + 1); }
      }
      if (!mounted) return;
      final failureText = failures.isEmpty ? '' : '\n未处理页：${failures.join('、')}。可手动框选。';
      if (count == 0) throw FormatException('没有找到挖空候选。$failureText');
      if (await _reviewCandidates(changes, '共 $count 个候选。$failureText')) {
        await _persist(changes);
      }
    });
  }

  Future<bool> _reviewCandidates(Map<int, ClozeState> changes, String summary) async {
    // Review every candidate's answer and normalized region; deselection is applied before persistence.
    return await showModalBottomSheet<bool>(context: context, isScrollControlled: true,
      builder: (context) => StatefulBuilder(builder: (context, update) => SafeArea(child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(children: [Padding(padding: const EdgeInsets.all(16), child: Text(summary)),
          Expanded(child: ListView(children: [for (final entry in changes.entries)
            ExpansionTile(title: Text('第 ${entry.key + 1} 页 · ${entry.value.masks.length} 空'), children: [
              for (final mask in entry.value.masks) ListTile(
                title: Text(mask.answer.isEmpty ? '手动区域' : mask.answer),
                subtitle: Text('页面纵向 ${(mask.rect.top * 100).round()}% 处'),
                trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => update(() {
                  changes[entry.key] = changes[entry.key]!.removeMask(mask);
                })),
              ),
            ]),
          ])),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('保存候选')),
          ]), const SizedBox(height: 12),
        ]),
      )))) ?? false;
  }

  Future<void> _importRules() => _run('导入规则', () async {
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['json']);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.length > 20 * 1024 * 1024) throw const FormatException('规则文件过大，请按章节处理。');
    final manifest = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    if (manifest['schema'] != 'saber-study/1') throw const FormatException('不是教材规则文件。');
    final source = await _pdf(_page);
    final hash = sha256.convert(source.bytes).toString();
    if (manifest['pdf_sha256'] != hash) throw const FormatException('规则与当前 PDF 不匹配，请导入同批生成的 textbook.pdf。');
    final records = {for (final p in manifest['pages'] as List) p['index'] as int: p};
    final changes = <int, ClozeState>{};
    // Verify each PDF's identity. Mixed-document notebooks must never inherit another document's masks.
    final hashes = <String, String>{};
    for (int i = 0; i < _count; i++) {
      final background = widget.coreInfo.pages[i].backgroundImage;
      if (background is! PdfEditorImage) continue;
      final candidate = await _pdf(i);
      final identity = background.pdfFile?.path ?? 'memory-${identityHashCode(background.pdfBytes)}';
      final digest = hashes.putIfAbsent(identity, () => sha256.convert(candidate.bytes).toString());
      if (digest != hash) continue;
      final record = records[background.pdfPage];
      if (record == null) continue;
      final incoming = ClozeState.fromJson(Map<String, dynamic>.from(record as Map));
      changes[i] = _states[i]!.mergeMasks(incoming.masks).copyWith(text: incoming.text);
    }
    if (!mounted) return;
    if (changes.isEmpty) throw const FormatException('未找到可应用页面。');
    if (await _reviewCandidates(changes, '导入 ${changes.length} 页；已有答案和笔记保留。')) await _persist(changes);
  });

  Future<void> _editAnswer(ClozeMask mask) async {
    final index = _page;
    await showModalBottomSheet<void>(context: context, isScrollControlled: true,
      builder: (_) => AnswerSheet(initial: _states[index]!.responses[mask.key] ?? StudyResponse(),
        answer: mask.answer, onChanged: (answer) {
          final responses = {..._states[index]!.responses};
          if (answer.isEmpty) { responses.remove(mask.key); } else { responses[mask.key] = answer; }
          _persist({index: _states[index]!.copyWith(responses: responses)});
        }));
  }

  Future<void> _note() async {
    final index = _page;
    final controller = TextEditingController(text: _state.note);
    await showModalBottomSheet<void>(context: context, isScrollControlled: true,
      builder: (context) => SafeArea(child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('本页长期笔记'),
          TextField(controller: controller, minLines: 3, maxLines: 8, autofocus: true,
            onChanged: (text) => _persist({index: _states[index]!.copyWith(note: text)})),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('完成')),
        ]))));
    controller.dispose();
  }

  Future<void> _export(StudyExportMode mode) => _run('正在导出', () async {
    final copy = widget.coreInfo.copyWith(pages: [for (int i = 0; i < _count; i++)
      widget.coreInfo.pages[i].copyWith(cloze: _states[i])]);
    final bytes = await StudyExporter.generate(copy, mode);
    if (mounted) await Printing.sharePdf(bytes: bytes, filename: '教材-${mode.name}.pdf');
  });

  Future<void> _speak({bool fromStart = false}) async {
    await _run('提取朗读文字', () async {
      if (!Platform.isIOS) throw const FormatException('朗读使用苹果系统声音。');
      final index = _page;
      String text = _state.text;
      if (text.isEmpty) {
        final result = await _analyze(index);
        text = result['text'] as String? ?? '';
        if (!mounted) return;
        await _persist({index: _states[index]!.copyWith(text: text)});
      }
      if (text.trim().isEmpty) throw const FormatException('本页未识别到文字。请检查扫描清晰度，或使用手动框选。');
      if (_state.hidden && _state.masks.isNotEmpty) {
        if (_state.masks.any((m) => m.answer.isEmpty)) {
          throw const FormatException('本页有手动挖空，为避免读出答案，请先切换为原文学习。');
        }
        // Equal UTF-16 length substitution keeps saved offsets aligned to the original text.
        for (final mask in _state.masks) { text = text.replaceAll(mask.answer, '　' * mask.answer.length); }
      }
      final offset = fromStart ? 0 : _state.speechOffset.clamp(0, text.length).toInt();
      if (offset == text.length) { _speechStartOffset = 0; } else { _speechStartOffset = offset; }
      _speechOffset = _speechStartOffset;
      final token = ++_speechToken;
      if (!mounted) return;
      await _channel.invokeMethod<void>('speak', {'text': text.substring(_speechStartOffset),
        'voice': _voice, 'rate': _rate, 'token': token});
      if (mounted) setState(() { _reading = true; });
      _progressTimer?.cancel();
      _progressTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted && _reading) _persist({_page: _state.copyWith(speechOffset: _speechOffset)});
      });
    });
  }

  Future<void> _speechEvent(MethodCall call) async {
    if (!mounted) return;
    final args = Map<String, dynamic>.from(call.arguments as Map);
    if (args['token'] != _speechToken) return;
    if (call.method == 'speechProgress') {
      _speechOffset = _speechStartOffset + (args['offset'] as num).toInt();
    } else if (call.method == 'speechDone') {
      _progressTimer?.cancel();
      setState(() { _reading = false; });
      await _persist({_page: _state.copyWith(speechOffset: 0)});
      if (mounted && _continuous && _page + 1 < _count) {
        await _navigate(_page + 1, continueReading: true);
        if (mounted) await _speak(fromStart: true);
      }
    }
  }

  Future<void> _stop() async {
    _progressTimer?.cancel();
    final wasReading = _reading;
    final index = _page;
    final offset = _speechOffset;
    ++_speechToken;
    if (Platform.isIOS) { try { await _channel.invokeMethod<void>('stop'); } catch (_) {} }
    if (mounted) {
      setState(() { _reading = false; });
      if (wasReading) await _persist({index: _states[index]!.copyWith(speechOffset: offset)});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _stop();
      if (_dirty) _persist({});
    }
  }

  Offset _normalized(Offset p, Size size) => Offset((p.dx / size.width).clamp(0.0, 1.0).toDouble(), (p.dy / size.height).clamp(0.0, 1.0).toDouble());

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_dirty && !_saving && !_busy,
    onPopInvokedWithResult: (didPop, _) { if (!didPop && !_busy) _leave(); },
    child: Scaffold(
      appBar: AppBar(title: Text('第 ${_page + 1} / $_count 页'),
        leading: IconButton(onPressed: _busy ? null : _leave, icon: const Icon(Icons.arrow_back)),
        actions: [IconButton(onPressed: _busy ? null : _note, icon: const Icon(Icons.note_add_outlined), tooltip: '长期笔记'),
          PopupMenuButton<String>(enabled: !_busy, onSelected: (action) async {
            switch (action) {
              case 'import': await _importRules();
              case 'reset': await _stop(); if (await _confirm('重新练习本页', '只清除本页答案，保留教材、挖空和长期笔记。')) await _persist({_page: _state.resetPractice()});
              case 'retry': await _persist({});
              case 'source': await _export(StudyExportMode.original);
              case 'practice': await _export(StudyExportMode.practice);
              case 'answers': await _export(StudyExportMode.annotated);
            }
          }, itemBuilder: (_) => const [
            PopupMenuItem(value: 'import', child: Text('导入整本挖空规则')),
            PopupMenuItem(value: 'reset', child: Text('重新练习本页')),
            PopupMenuItem(value: 'retry', child: Text('重试保存')),
            PopupMenuItem(value: 'source', child: Text('导出原文版')),
            PopupMenuItem(value: 'practice', child: Text('导出挖空版')),
            PopupMenuItem(value: 'answers', child: Text('导出笔记与答题版')),
          ]),
        ]),
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: [
          Expanded(child: Text(_saving ? '正在保存…' : _dirty ? '未保存，请重试' : '已保存', style: TextStyle(fontSize: 12, color: _dirty && !_saving ? Colors.red : Colors.teal))),
          Text('${_state.responses.length} / ${_state.masks.length} 已答', style: const TextStyle(fontSize: 12)),
          IconButton(onPressed: _busy || _page == 0 ? null : () => _navigate(_page - 1), icon: const Icon(Icons.chevron_left)),
          IconButton(onPressed: _busy || _page + 1 >= _count ? null : () => _navigate(_page + 1), icon: const Icon(Icons.chevron_right)),
        ])),
        if (_busy) Column(children: [const LinearProgressIndicator(), Text(_operation)]),
        if (_error != null) MaterialBanner(content: Text(_error!, maxLines: 3, overflow: TextOverflow.ellipsis), actions: [TextButton(onPressed: () => setState(() { _error = null; }), child: const Text('关闭'))]),
        Expanded(child: _tab == 3 ? _audioControls() : _canvas()),
        if (_tab == 1) SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          TextButton.icon(onPressed: _busy ? null : _rules, icon: const Icon(Icons.auto_fix_high), label: const Text('自动挖空')),
          FilterChip(label: const Text('点选删除'), selected: _delete, onSelected: (v) => setState(() { _delete = v; })),
          TextButton(onPressed: () => setState(() { _transform.value = Matrix4.identity(); }), child: const Text('复位缩放')),
        ])),
        if (_tab == 0 || _tab == 2) Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          TextButton(onPressed: () => setState(() { _showOriginal = !_showOriginal; }), child: Text(_showOriginal ? '隐藏原文' : '查看原文')),
          TextButton(onPressed: () async { await _stop(); if (mounted) await _persist({_page: _state.copyWith(hidden: !_state.hidden)}); }, child: Text(_state.hidden ? '切换原文学习' : '切换挖空练习')),
        ]),
      ])),
      bottomNavigationBar: NavigationBar(selectedIndex: _tab, height: 64,
        onDestinationSelected: (v) => setState(() { _tab = v; _pending = null; _start = null; }),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: '阅读'),
          NavigationDestination(icon: Icon(Icons.crop_square), label: '挖空'),
          NavigationDestination(icon: Icon(Icons.edit_note), label: '答题'),
          NavigationDestination(icon: Icon(Icons.headphones_outlined), label: '听读'),
        ]),
    ));

  Widget _audioControls() => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('听教材', style: TextStyle(fontSize: 24)),
    const SizedBox(height: 16),
    DropdownButton<String>(isExpanded: true, value: _voice, hint: const Text('系统默认中文声音'),
      items: _voices.map((v) => DropdownMenuItem<String>(value: v['id'] as String,
        child: Text('${v['name']} · ${v['gender']}'))).toList(), onChanged: (v) => setState(() { _voice = v; })),
    const Text('语速'), Slider(value: _rate, min: 0.25, max: 0.65, onChanged: (v) => setState(() { _rate = v; })),
    SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('连续朗读后续页面'), value: _continuous,
      onChanged: (v) => setState(() { _continuous = v; })),
    FilledButton.icon(onPressed: _busy ? null : () => _speak(), icon: const Icon(Icons.play_arrow), label: const Text('从保存位置朗读')),
    Wrap(spacing: 8, children: [
      TextButton(onPressed: () async { if (Platform.isIOS) { try { await _channel.invokeMethod<void>('pause'); } catch (_) {} } }, child: const Text('暂停')),
      TextButton(onPressed: () async { if (Platform.isIOS) { try { await _channel.invokeMethod<void>('resume'); } catch (_) {} } }, child: const Text('继续')),
      TextButton(onPressed: _stop, child: const Text('停止')),
      TextButton(onPressed: _busy ? null : () => _speak(fromStart: true), child: const Text('本页重读')),
    ]),
    const Text('隐藏答案时跳过已知答案；手动框选题需切换原文学习后朗读。'),
    const SizedBox(height: 16),
    if (_state.text.isNotEmpty) SelectableText(_state.hidden ? '原文在阅读页查看。' : _state.text),
    if (_state.note.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 20), child: Text('本页笔记\n${_state.note}')),
  ]);

  Widget _canvas() {
    if (_preview == null) return Center(child: _error == null ? const CircularProgressIndicator() : TextButton(onPressed: _loadPreview, child: const Text('重新加载')));
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final size = Size(width, width / widget.coreInfo.pages[_page].size.aspectRatio);
      return InteractiveViewer(transformationController: _transform, minScale: 0.8, maxScale: 5,
        constrained: false, panEnabled: _tab != 1 || _delete, child: SizedBox.fromSize(size: size,
          child: GestureDetector(
            onTapUp: (event) {
              if (_busy) return;
              final point = _normalized(event.localPosition, size);
              final masks = _state.masks.where((m) => m.onPage(size).inflate(10).contains(event.localPosition)).toList()
                ..sort((a, b) => (a.rect.center - point).distance.compareTo((b.rect.center - point).distance));
              if (masks.isEmpty) return;
              if (_tab == 1 && _delete) { _persist({_page: _state.removeMask(masks.first)}); }
              else if (_tab == 2) { _editAnswer(masks.first); }
            },
            onPanStart: _tab == 1 && !_delete && !_busy ? (e) { _start = _normalized(e.localPosition, size); } : null,
            onPanUpdate: _tab == 1 && !_delete && !_busy ? (e) => setState(() { if (_start != null) _pending = Rect.fromPoints(_start!, _normalized(e.localPosition, size)); }) : null,
            onPanEnd: _tab == 1 && !_delete && !_busy ? (_) {
              final rect = _pending;
              setState(() { _pending = null; _start = null; });
              if (rect != null && rect.width * width > 4 && rect.height * size.height > 4) {
                _persist({_page: _state.mergeMasks([ClozeMask(rect)])});
              }
            } : null,
            onPanCancel: () => setState(() { _pending = null; _start = null; }),
            child: Stack(fit: StackFit.expand, children: [
              Image.memory(_preview!, fit: BoxFit.fill),
              if (!_showOriginal && (_state.hidden || _tab == 1)) for (final mask in _state.masks)
                Positioned.fromRect(rect: mask.onPage(size), child: ColoredBox(color: Colors.white,
                  child: DecoratedBox(decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.teal.shade400)))))),
              if (!_showOriginal && _state.showResponses && _tab != 1) for (final mask in _state.masks)
                if (_state.responses[mask.key] != null) Positioned.fromRect(rect: mask.onPage(size),
                  child: CustomPaint(painter: AnswerPainter(_state.responses[mask.key]!))),
              if (_pending != null) Positioned.fromRect(rect: ClozeMask(_pending!).onPage(size),
                child: ColoredBox(color: Colors.teal.withValues(alpha: 0.3))),
            ]),
          )),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progressTimer?.cancel();
    _transform.dispose(); _keyword.dispose();
    if (Platform.isIOS) {
      _channel.setMethodCallHandler(null);
      _channel.invokeMethod<void>('stop').catchError((Object _) {});
    }
    super.dispose();
  }
}
