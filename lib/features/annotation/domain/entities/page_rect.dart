import 'package:freezed_annotation/freezed_annotation.dart';

part 'page_rect.freezed.dart';
part 'page_rect.g.dart';

/// Rectangle in **page-relative PDF points** (1 pt = 1/72 inch).
///
/// Origin is the page's top-left corner (matches Flutter's render box
/// coordinates). The page's bounds in this unit are
/// `[0, pageWidth] x [0, pageHeight]` (in points). Coordinate system
/// is fixed regardless of zoom/scroll (ROADMAP §2.2, R5).
@freezed
abstract class PageRect with _$PageRect {
  const factory PageRect({
    required double x,
    required double y,
    required double width,
    required double height,
  }) = _PageRect;

  factory PageRect.fromJson(Map<String, dynamic> json) =>
      _$PageRectFromJson(json);
}
