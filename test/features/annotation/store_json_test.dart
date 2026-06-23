import 'package:flutter_test/flutter_test.dart';
import 'package:bp_pdf/features/annotation/data/repositories/annotation_store_impl.dart';
import 'package:bp_pdf/features/annotation/domain/entities/annotation.dart';
import 'package:bp_pdf/features/annotation/domain/entities/page_rect.dart';

void main() {
  group('AnnotationStoreImpl JSON roundtrip', () {
    test('preserves text + rect annotations across encode/decode', () {
      final store = AnnotationStoreImpl();
      store.add(Annotation.text(
        id: 't-1',
        pageNumber: 1,
        rect: const PageRect(x: 12.5, y: 34.75, width: 200, height: 50),
        text: 'Hola mundo',
        fontFamily: 'Roboto',
        fontSize: 14,
        colorArgb: 0xFF000000,
      ));
      store.add(Annotation.rect(
        id: 'r-1',
        pageNumber: 1,
        rect: const PageRect(x: 5, y: 6, width: 150, height: 50),
        colorArgb: 0xFFFFFFFF,
        opacity: 0.75,
      ));
      store.add(Annotation.text(
        id: 't-2',
        pageNumber: 3,
        rect: const PageRect(x: 0, y: 0, width: 10, height: 10),
        text: 'otra',
        fontFamily: 'Lato',
        fontSize: 12,
        colorArgb: 0xFFE53935,
      ));

      final json = store.toJson();

      final restored = AnnotationStoreImpl();
      restored.loadFromJson(json);

      expect(restored.listAll(), hasLength(3));
      expect(restored.listForPage(1), hasLength(2));
      expect(restored.listForPage(3), hasLength(1));

      final t1 = restored.getById('t-1')!;
      expect(t1, isA<TextAnnotation>());
      expect((t1 as TextAnnotation).text, 'Hola mundo');
      expect(t1.rect.x, closeTo(12.5, 1e-9));
      expect(t1.fontFamily, 'Roboto');
      expect(t1.fontSize, 14);
      expect(t1.colorArgb, 0xFF000000);

      final r1 = restored.getById('r-1')!;
      expect(r1, isA<RectAnnotation>());
      expect((r1 as RectAnnotation).opacity, 0.75);
      expect(r1.colorArgb, 0xFFFFFFFF);

      final t2 = restored.getById('t-2')!;
      expect(t2.pageNumber, 3);
      expect((t2 as TextAnnotation).fontFamily, 'Lato');
      expect(t2.colorArgb, 0xFFE53935);
    });

    test('rejects malformed JSON', () {
      final store = AnnotationStoreImpl();
      expect(() => store.loadFromJson('not json'), throwsA(isA<FormatException>()));
      expect(() => store.loadFromJson('{}'), throwsA(isA<FormatException>()));
      expect(() => store.loadFromJson('{"annotations":"oops"}'), throwsA(isA<FormatException>()));
    });

    test('roundtrips an empty store', () {
      final store = AnnotationStoreImpl();
      final json = store.toJson();
      final restored = AnnotationStoreImpl()..loadFromJson(json);
      expect(restored.listAll(), isEmpty);
    });
  });
}
