import '../entities/annotation.dart';
import '../entities/page_rect.dart';
import '../entities/pdf_point.dart';
import '../repositories/annotation_store.dart';

class MoveAnnotation {
  const MoveAnnotation(this._store);
  final AnnotationStore _store;

  /// Move the annotation with [id] to the given page-relative rect.
  /// Returns `false` if the id is unknown.
  bool call(String id, PageRect newRect) {
    final existing = _store.getById(id);
    if (existing == null) return false;
    final moved = switch (existing) {
      TextAnnotation() => existing.copyWith(rect: newRect),
      RectAnnotation() => existing.copyWith(rect: newRect),
      // A stroke's points are page-absolute, so moving the rect alone would
      // leave the ink in place. Translate the points by the same delta.
      StrokeAnnotation() => existing.copyWith(
          rect: newRect,
          points: _translatePoints(
            existing.points,
            newRect.x - existing.rect.x,
            newRect.y - existing.rect.y,
          ),
        ),
      HighlightAnnotation() => existing.copyWith(rect: newRect),
    };
    return _store.update(moved);
  }

  List<PagePoint> _translatePoints(List<PagePoint> points, double dx, double dy) {
    if (dx == 0 && dy == 0) return points;
    return [for (final p in points) PagePoint(x: p.x + dx, y: p.y + dy)];
  }
}
