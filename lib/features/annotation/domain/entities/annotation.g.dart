// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'annotation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TextAnnotation _$TextAnnotationFromJson(Map<String, dynamic> json) =>
    TextAnnotation(
      id: json['id'] as String,
      pageNumber: (json['pageNumber'] as num).toInt(),
      rect: PageRect.fromJson(json['rect'] as Map<String, dynamic>),
      text: json['text'] as String,
      fontFamily: json['fontFamily'] as String,
      fontSize: (json['fontSize'] as num).toDouble(),
      colorArgb: (json['colorArgb'] as num).toInt(),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$TextAnnotationToJson(TextAnnotation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pageNumber': instance.pageNumber,
      'rect': instance.rect,
      'text': instance.text,
      'fontFamily': instance.fontFamily,
      'fontSize': instance.fontSize,
      'colorArgb': instance.colorArgb,
      'runtimeType': instance.$type,
    };

RectAnnotation _$RectAnnotationFromJson(Map<String, dynamic> json) =>
    RectAnnotation(
      id: json['id'] as String,
      pageNumber: (json['pageNumber'] as num).toInt(),
      rect: PageRect.fromJson(json['rect'] as Map<String, dynamic>),
      colorArgb: (json['colorArgb'] as num).toInt(),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$RectAnnotationToJson(RectAnnotation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pageNumber': instance.pageNumber,
      'rect': instance.rect,
      'colorArgb': instance.colorArgb,
      'opacity': instance.opacity,
      'runtimeType': instance.$type,
    };

StrokeAnnotation _$StrokeAnnotationFromJson(Map<String, dynamic> json) =>
    StrokeAnnotation(
      id: json['id'] as String,
      pageNumber: (json['pageNumber'] as num).toInt(),
      points: (json['points'] as List<dynamic>)
          .map((e) => PagePoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      rect: PageRect.fromJson(json['rect'] as Map<String, dynamic>),
      colorArgb: (json['colorArgb'] as num).toInt(),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 2.0,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$StrokeAnnotationToJson(StrokeAnnotation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pageNumber': instance.pageNumber,
      'points': instance.points,
      'rect': instance.rect,
      'colorArgb': instance.colorArgb,
      'strokeWidth': instance.strokeWidth,
      'runtimeType': instance.$type,
    };

HighlightAnnotation _$HighlightAnnotationFromJson(Map<String, dynamic> json) =>
    HighlightAnnotation(
      id: json['id'] as String,
      pageNumber: (json['pageNumber'] as num).toInt(),
      rect: PageRect.fromJson(json['rect'] as Map<String, dynamic>),
      colorArgb: (json['colorArgb'] as num?)?.toInt() ?? 0xFFFFFF00,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 0.4,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$HighlightAnnotationToJson(
  HighlightAnnotation instance,
) => <String, dynamic>{
  'id': instance.id,
  'pageNumber': instance.pageNumber,
  'rect': instance.rect,
  'colorArgb': instance.colorArgb,
  'opacity': instance.opacity,
  'runtimeType': instance.$type,
};
