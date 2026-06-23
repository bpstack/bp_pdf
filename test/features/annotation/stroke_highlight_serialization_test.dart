import 'package:flutter_test/flutter_test.dart';
import 'package:bp_pdf/features/annotation/data/repositories/annotation_store_impl.dart';
import 'package:bp_pdf/features/annotation/domain/entities/annotation.dart';
import 'package:bp_pdf/features/annotation/domain/entities/page_rect.dart';
import 'package:bp_pdf/features/annotation/domain/entities/pdf_point.dart' show PagePoint;

void main() {
  group('StrokeAnnotation JSON roundtrip', () {
    test('preserves all fields', () {
      final store = AnnotationStoreImpl();
      store.add(Annotation.stroke(
        id: 's-1',
        pageNumber: 2,
        points: const [
          PagePoint(x: 10.5, y: 20.25),
          PagePoint(x: 30.0, y: 40.0),
          PagePoint(x: 50.75, y: 60.5),
        ],
        rect: const PageRect(x: 9.5, y: 19.25, width: 43.25, height: 43.25),
        colorArgb: 0xFF0000FF,
        strokeWidth: 3.5,
      ));

      final json = store.toJson();
      final restored = AnnotationStoreImpl()..loadFromJson(json);

      expect(restored.listAll(), hasLength(1));
      final s = restored.getById('s-1')!;
      expect(s, isA<StrokeAnnotation>());

      final stroke = s as StrokeAnnotation;
      expect(stroke.pageNumber, 2);
      expect(stroke.colorArgb, 0xFF0000FF);
      expect(stroke.strokeWidth, closeTo(3.5, 1e-9));
      expect(stroke.rect.x, closeTo(9.5, 1e-9));
      expect(stroke.rect.y, closeTo(19.25, 1e-9));
      expect(stroke.points, hasLength(3));
      expect(stroke.points[0].x, closeTo(10.5, 1e-9));
      expect(stroke.points[0].y, closeTo(20.25, 1e-9));
      expect(stroke.points[2].x, closeTo(50.75, 1e-9));
    });

    test('empty points list roundtrips', () {
      final store = AnnotationStoreImpl();
      store.add(Annotation.stroke(
        id: 's-empty',
        pageNumber: 1,
        points: const [],
        rect: const PageRect(x: 0, y: 0, width: 1, height: 1),
        colorArgb: 0xFF000000,
      ));

      final restored = AnnotationStoreImpl()..loadFromJson(store.toJson());
      final s = restored.getById('s-empty')! as StrokeAnnotation;
      expect(s.points, isEmpty);
      expect(s.strokeWidth, closeTo(2.0, 1e-9)); // default
    });
  });

  group('HighlightAnnotation JSON roundtrip', () {
    test('preserves all fields', () {
      final store = AnnotationStoreImpl();
      store.add(Annotation.highlight(
        id: 'h-1',
        pageNumber: 3,
        rect: const PageRect(x: 5.5, y: 10.25, width: 120.0, height: 30.0),
        colorArgb: 0xFFFFFF00,
        opacity: 0.35,
      ));

      final restored = AnnotationStoreImpl()..loadFromJson(store.toJson());

      expect(restored.listAll(), hasLength(1));
      final h = restored.getById('h-1')!;
      expect(h, isA<HighlightAnnotation>());

      final highlight = h as HighlightAnnotation;
      expect(highlight.pageNumber, 3);
      expect(highlight.colorArgb, 0xFFFFFF00);
      expect(highlight.opacity, closeTo(0.35, 1e-9));
      expect(highlight.rect.x, closeTo(5.5, 1e-9));
      expect(highlight.rect.width, closeTo(120.0, 1e-9));
    });

    test('default colorArgb and opacity are preserved', () {
      final store = AnnotationStoreImpl();
      store.add(Annotation.highlight(
        id: 'h-default',
        pageNumber: 1,
        rect: const PageRect(x: 0, y: 0, width: 50, height: 20),
      ));

      final restored = AnnotationStoreImpl()..loadFromJson(store.toJson());
      final h = restored.getById('h-default')! as HighlightAnnotation;
      expect(h.colorArgb, 0xFFFFFF00);
      expect(h.opacity, closeTo(0.4, 1e-9));
    });
  });

  group('Mixed annotations JSON roundtrip', () {
    test('text + rect + stroke + highlight all survive encode/decode', () {
      final store = AnnotationStoreImpl();
      store.add(Annotation.text(
        id: 't-1',
        pageNumber: 1,
        rect: const PageRect(x: 0, y: 0, width: 100, height: 30),
        text: 'Hola',
        fontFamily: 'Roboto',
        fontSize: 12,
        colorArgb: 0xFF000000,
      ));
      store.add(Annotation.rect(
        id: 'r-1',
        pageNumber: 1,
        rect: const PageRect(x: 10, y: 10, width: 50, height: 20),
        colorArgb: 0xFFFFFFFF,
      ));
      store.add(Annotation.stroke(
        id: 's-1',
        pageNumber: 2,
        points: const [PagePoint(x: 1, y: 1), PagePoint(x: 2, y: 2)],
        rect: const PageRect(x: 0.5, y: 0.5, width: 3, height: 3),
        colorArgb: 0xFF0000FF,
      ));
      store.add(Annotation.highlight(
        id: 'h-1',
        pageNumber: 2,
        rect: const PageRect(x: 5, y: 5, width: 80, height: 25),
      ));

      final restored = AnnotationStoreImpl()..loadFromJson(store.toJson());
      expect(restored.listAll(), hasLength(4));
      expect(restored.getById('t-1'), isA<TextAnnotation>());
      expect(restored.getById('r-1'), isA<RectAnnotation>());
      expect(restored.getById('s-1'), isA<StrokeAnnotation>());
      expect(restored.getById('h-1'), isA<HighlightAnnotation>());
    });
  });
}
