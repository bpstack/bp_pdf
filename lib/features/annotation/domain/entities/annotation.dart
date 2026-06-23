import 'package:freezed_annotation/freezed_annotation.dart';

import 'page_rect.dart';
import 'pdf_point.dart';

part 'annotation.freezed.dart';
part 'annotation.g.dart';

/// Sealed union of all annotation types.
///
/// Variants: [TextAnnotation], [RectAnnotation] (Fase 2),
/// [StrokeAnnotation], [HighlightAnnotation] (Fase 3).
/// All coordinates are in PDF points relative to the page origin (R5).
@freezed
sealed class Annotation with _$Annotation {
  const Annotation._();

  /// Free-form text drawn on top of a page. Color is stored as a 32-bit
  /// ARGB integer so the domain layer has no Flutter dependency.
  const factory Annotation.text({
    required String id,
    required int pageNumber,
    required PageRect rect,
    required String text,
    required String fontFamily,
    required double fontSize,
    required int colorArgb,
  }) = TextAnnotation;

  /// Opaque rectangle ("tipp-ex"): used to mask parts of the original page
  /// before drawing on top.
  const factory Annotation.rect({
    required String id,
    required int pageNumber,
    required PageRect rect,
    required int colorArgb,
    @Default(1.0) double opacity,
  }) = RectAnnotation;

  /// Freehand stroke. [points] are in PDF points relative to the page origin.
  /// [rect] is the bounding box (used for [Positioned] in the overlay).
  /// [strokeWidth] is in PDF points; the painter scales it with zoom.
  const factory Annotation.stroke({
    required String id,
    required int pageNumber,
    required List<PagePoint> points,
    required PageRect rect,
    required int colorArgb,
    @Default(2.0) double strokeWidth,
  }) = StrokeAnnotation;

  /// Semi-transparent highlight rectangle.
  const factory Annotation.highlight({
    required String id,
    required int pageNumber,
    required PageRect rect,
    @Default(0xFFFFFF00) int colorArgb,
    @Default(0.4) double opacity,
  }) = HighlightAnnotation;

  /// JSON factory used by [json_serializable] to round-trip the sealed
  /// union. The generated `_$AnnotationFromJson` is produced by
  /// `build_runner`.
  factory Annotation.fromJson(Map<String, dynamic> json) =>
      _$AnnotationFromJson(json);
}
