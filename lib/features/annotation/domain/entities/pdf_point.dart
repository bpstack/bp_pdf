import 'package:freezed_annotation/freezed_annotation.dart';

part 'pdf_point.freezed.dart';
part 'pdf_point.g.dart';

/// A 2-D point in PDF page coordinates (PDF points, 1/72 inch).
///
/// Origin is the page's top-left corner. Kept in the domain layer as a pure
/// Dart type — no Flutter/dart:ui dependency. The presentation layer converts
/// to [dart:ui.Offset] when painting.
///
/// Named [PagePoint] (not PdfPoint) to avoid collision with the identically
/// named type exported by the pdfrx package.
@freezed
abstract class PagePoint with _$PagePoint {
  const factory PagePoint({required double x, required double y}) = _PagePoint;

  factory PagePoint.fromJson(Map<String, dynamic> json) =>
      _$PagePointFromJson(json);
}
