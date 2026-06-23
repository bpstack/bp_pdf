import 'package:flutter_test/flutter_test.dart';
import 'package:bp_pdf/features/annotation/data/repositories/annotation_store_impl.dart';
import 'package:bp_pdf/features/annotation/domain/entities/annotation.dart';
import 'package:bp_pdf/features/annotation/domain/entities/page_rect.dart';
import 'package:bp_pdf/features/annotation/domain/entities/pdf_point.dart' show PagePoint;
import 'package:bp_pdf/features/annotation/domain/usecases/redo_annotation.dart';
import 'package:bp_pdf/features/annotation/domain/usecases/undo_annotation.dart';

Annotation _text({String id = 't1', int page = 1}) => Annotation.text(
      id: id,
      pageNumber: page,
      rect: const PageRect(x: 10, y: 20, width: 200, height: 50),
      text: 'Hola',
      fontFamily: 'Roboto',
      fontSize: 14,
      colorArgb: 0xFF000000,
    );

Annotation _stroke({String id = 's1', int page = 1}) => Annotation.stroke(
      id: id,
      pageNumber: page,
      points: const [
        PagePoint(x: 10, y: 20),
        PagePoint(x: 30, y: 40),
        PagePoint(x: 50, y: 60),
      ],
      rect: const PageRect(x: 9, y: 19, width: 43, height: 43),
      colorArgb: 0xFF0000FF,
      strokeWidth: 3.0,
    );

void main() {
  late AnnotationStoreImpl store;
  late UndoAnnotation undo;
  late RedoAnnotation redo;

  setUp(() {
    store = AnnotationStoreImpl();
    undo = UndoAnnotation(store);
    redo = RedoAnnotation(store);
  });

  group('canUndo / canRedo initial state', () {
    test('both false on empty store', () {
      expect(store.canUndo, isFalse);
      expect(store.canRedo, isFalse);
    });
  });

  group('add → undo → redo', () {
    test('single add undone, then redone', () {
      store.add(_text());
      expect(store.listAll(), hasLength(1));
      expect(store.canUndo, isTrue);
      expect(store.canRedo, isFalse);

      undo();
      expect(store.listAll(), isEmpty);
      expect(store.canUndo, isFalse);
      expect(store.canRedo, isTrue);

      redo();
      expect(store.listAll(), hasLength(1));
      expect(store.canRedo, isFalse);
    });

    test('undo returns true when stack non-empty', () {
      store.add(_text());
      expect(undo(), isTrue);
      expect(undo(), isFalse); // stack empty
    });

    test('redo returns true when stack non-empty', () {
      store.add(_text());
      undo();
      expect(redo(), isTrue);
      expect(redo(), isFalse);
    });
  });

  group('multiple operations', () {
    test('add×3 then undo×3 restores empty', () {
      store.add(_text(id: 'a'));
      store.add(_text(id: 'b'));
      store.add(_text(id: 'c'));
      expect(store.listAll(), hasLength(3));

      undo();
      expect(store.listAll(), hasLength(2));
      undo();
      expect(store.listAll(), hasLength(1));
      undo();
      expect(store.listAll(), isEmpty);
      expect(store.canUndo, isFalse);
    });

    test('undo then new add clears redo stack', () {
      store.add(_text(id: 'a'));
      store.add(_text(id: 'b'));
      undo(); // redo stack has 'b' snapshot
      expect(store.canRedo, isTrue);

      store.add(_text(id: 'c')); // new mutation clears redo
      expect(store.canRedo, isFalse);
      expect(store.listAll().map((a) => a.id), containsAll(['a', 'c']));
    });

    test('remove → undo restores annotation', () {
      store.add(_text());
      store.remove('t1');
      expect(store.listAll(), isEmpty);

      undo();
      expect(store.listAll(), hasLength(1));
      expect(store.getById('t1'), isNotNull);
    });

    test('update → undo reverts to old value', () {
      store.add(_text());
      final updated = (_text() as TextAnnotation).copyWith(text: 'Adiós');
      store.update(updated);
      expect((store.getById('t1')! as TextAnnotation).text, 'Adiós');

      undo();
      expect((store.getById('t1')! as TextAnnotation).text, 'Hola');
    });
  });

  group('clear resets stacks', () {
    test('clear after adds leaves no undo/redo', () {
      store.add(_text());
      store.add(_stroke());
      store.clear();
      expect(store.canUndo, isFalse);
      expect(store.canRedo, isFalse);
      expect(store.listAll(), isEmpty);
    });
  });

  group('stroke and highlight undo/redo', () {
    test('stroke add → undo → redo', () {
      store.add(_stroke());
      expect(store.listAll().first, isA<StrokeAnnotation>());

      undo();
      expect(store.listAll(), isEmpty);

      redo();
      expect(store.listAll().first, isA<StrokeAnnotation>());
    });

    test('highlight add → undo → redo', () {
      final h = Annotation.highlight(
        id: 'h1',
        pageNumber: 1,
        rect: const PageRect(x: 5, y: 5, width: 100, height: 30),
        colorArgb: 0xFFFFFF00,
        opacity: 0.4,
      );
      store.add(h);
      expect(store.listAll().first, isA<HighlightAnnotation>());

      undo();
      expect(store.listAll(), isEmpty);

      redo();
      expect(store.listAll().first, isA<HighlightAnnotation>());
    });
  });
}
