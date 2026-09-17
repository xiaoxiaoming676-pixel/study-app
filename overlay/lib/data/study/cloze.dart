import 'package:flutter/material.dart';

/// Normalized coordinates keep masks stable when a page is resized.
class ClozeMask {
  const ClozeMask(this.rect, {this.answer = ''});
  final Rect rect;
  final String answer;
  String get key => [rect.left, rect.top, rect.width, rect.height]
      .map((v) => v.toStringAsFixed(6)).join(':');

  factory ClozeMask.fromJson(Map<String, dynamic> json) {
    final values = (json['rect'] as List).cast<num>();
    if (values.length != 4 || values.any((n) => !n.isFinite)) {
      throw const FormatException('Invalid mask coordinates');
    }
    final r = Rect.fromLTWH(values[0].toDouble(), values[1].toDouble(),
        values[2].toDouble(), values[3].toDouble());
    if (r.left < 0 || r.top < 0 || r.right > 1.000001 ||
        r.bottom > 1.000001 || r.width <= 0 || r.height <= 0) {
      throw const FormatException('Mask outside page');
    }
    return ClozeMask(r, answer: json['answer'] as String? ?? '');
  }

  Map<String, dynamic> toJson() => {
    'rect': [rect.left, rect.top, rect.width, rect.height],
    'answer': answer,
  };

  Rect onPage(Size size) => Rect.fromLTWH(rect.left * size.width,
      rect.top * size.height, rect.width * size.width, rect.height * size.height);
}

/// Immutable state: history items must not share mutable lists.
class ClozeState {
  ClozeState({List<ClozeMask> masks = const [], this.hidden = true,
      this.text = '', this.note = '', Map<String, StudyResponse> responses = const {},
      this.showResponses = true, this.speechOffset = 0})
      : masks = List.unmodifiable(masks), responses = Map.unmodifiable(responses);
  final List<ClozeMask> masks;
  final bool hidden;
  final String text;
  final String note;
  final Map<String, StudyResponse> responses;
  final bool showResponses;
  final int speechOffset;

  factory ClozeState.fromJson(Map<String, dynamic>? json) => json == null
      ? ClozeState()
      : ClozeState(
          masks: (json['masks'] as List? ?? []).map((m) =>
              ClozeMask.fromJson(Map<String, dynamic>.from(m as Map))).toList(),
          hidden: json['hidden'] as bool? ?? true,
          text: json['text'] as String? ?? '',
          note: json['note'] as String? ?? '',
          showResponses: json['showResponses'] as bool? ?? true,
          speechOffset: (json['speechOffset'] as num? ?? 0).toInt().clamp(0, 10000000).toInt(),
          responses: (json['responses'] as Map? ?? {}).map((key, value) =>
              MapEntry(key as String, StudyResponse.fromJson(Map<String, dynamic>.from(value as Map)))));

  Map<String, dynamic> toJson() => {
    'masks': masks.map((m) => m.toJson()).toList(),
    'hidden': hidden,
    'text': text,
    'note': note,
    'responses': responses.map((key, value) => MapEntry(key, value.toJson())),
    'showResponses': showResponses,
    'speechOffset': speechOffset,
  };
  ClozeState copyWith({List<ClozeMask>? masks, bool? hidden, String? text,
      String? note, Map<String, StudyResponse>? responses, bool? showResponses,
      int? speechOffset}) => ClozeState(
        masks: masks ?? this.masks, hidden: hidden ?? this.hidden,
        text: text ?? this.text, note: note ?? this.note,
        responses: responses ?? this.responses,
        showResponses: showResponses ?? this.showResponses,
        speechOffset: speechOffset ?? this.speechOffset);

  ClozeState mergeMasks(List<ClozeMask> incoming) {
    final byKey = {for (final m in masks) m.key: m};
    for (final m in incoming) { byKey[m.key] = m; }
    return copyWith(masks: byKey.values.toList(), hidden: true);
  }

  ClozeState removeMask(ClozeMask mask) => copyWith(
    masks: masks.where((m) => m.key != mask.key).toList(),
    responses: {...responses}..remove(mask.key));

  /// Reset practice only. Original document, permanent notes and masks survive.
  ClozeState resetPractice() => copyWith(responses: {}, hidden: true);

  bool get hasData => masks.isNotEmpty || text.isNotEmpty || note.isNotEmpty ||
      responses.isNotEmpty || speechOffset != 0;
}

class StudyResponse {
  StudyResponse({this.text = '', List<List<Offset>> ink = const []})
      : ink = List.unmodifiable(ink.map((line) => List<Offset>.unmodifiable(line)));
  final String text;
  final List<List<Offset>> ink;
  factory StudyResponse.fromJson(Map<String, dynamic> json) => StudyResponse(
    text: json['text'] as String? ?? '',
    ink: (json['ink'] as List? ?? []).map((line) => (line as List).map((p) {
      final xy = (p as List).cast<num>();
      if (xy.length != 2 || xy.any((n) => !n.isFinite || n < 0 || n > 1)) {
        throw const FormatException('Invalid answer stroke');
      }
      return Offset(xy[0].toDouble(), xy[1].toDouble());
    }).toList()).toList());
  Map<String, dynamic> toJson() => {'text': text,
    'ink': ink.map((line) => line.map((p) => [p.dx, p.dy]).toList()).toList()};
  bool get isEmpty => text.trim().isEmpty && ink.isEmpty;
}
