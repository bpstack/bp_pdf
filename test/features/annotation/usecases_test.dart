import 'package:flutter_test/flutter_test.dart';
import 'package:bp_pdf/features/annotation/domain/entities/annotation.dart';
import 'package:bp_pdf/features/annotation/domain/entities/page_rect.dart';
import 'package:bp_pdf/features/annotation/domain/entities/pdf_point.dart';
import 'package:bp_pdf/features/annotation/domain/repositories/annotation_store.dart';
import 'package:bp_pdf/features/annotation/domain/usecases/add_annotation.dart';
import 'package:bp_pdf/features/annotation/domain/usecases/move_annotation.dart';
import 'package:bp_pdf/features/annotation/domain/usecases/remove_annotation.dart';
import 'package:bp_pdf/features/annotation/domain/usecases/update_annotation.dart';

void main() {
  late _SpyStore store;
  late AddAnnotation add;
  late UpdateAnnotation update;
  late MoveAnnotation move;
  late RemoveAnnotation remove;

  setUp(() {
    store = _SpyStore();
    add = AddAnnotation(store);
    update = UpdateAnnotation(store);
    move = MoveAnnotation(store);
    remove = RemoveAnnotation(store);
  });

  Annotation text({
    String id = 't1',
    int pageNumber = 1,
    double x = 10,
    double y = 20,
    double w = 200,
    double h = 50,
  }) {
    return Annotation.text(
      id: id,
      pageNumber: pageNumber,
      rect: PageRect(x: x, y: y, width: w, height: h),
      text: 'Hola',
      fontFamily: 'Roboto',
      fontSize: 14,
      colorArgb: 0xFF000000,
    );
  }

  Annotation rect({String id = 'r1', int pageNumber = 1}) {
    return Annotation.rect(
      id: id,
      pageNumber: pageNumber,
      rect: const PageRect(x: 5, y: 6, width: 150, height: 50),
      colorArgb: 0xFFFFFFFF,
      opacity: 0.9,
    );
  }

  group('AddAnnotation', () {
    test('inserts a new annotation and returns it', () {
      final a = text();
      final stored = add(a);
      expect(stored, isNotNull);
      expect(stored!.id, 't1');
      expect(store.listAll(), hasLength(1));
    });

    test('refuses a duplicate id and returns null', () {
      add(text());
      final second = add(text());
      expect(second, isNull);
      expect(store.listAll(), hasLength(1));
    });
  });

  group('UpdateAnnotation', () {
    test('replaces by id', () {
      final a = add(text()) as TextAnnotation?;
      expect(a, isNotNull);
      final modified = a!.copyWith(text: 'Adiós');
      final ok = update(modified);
      expect(ok, isTrue);
      final updated = store.getById('t1')! as TextAnnotation;
      expect(updated.text, 'Adiós');
    });

    test('returns false on unknown id', () {
      final ok = update(text(id: 'nope'));
      expect(ok, isFalse);
      expect(store.listAll(), isEmpty);
    });
  });

  group('MoveAnnotation', () {
    test('moves an existing text annotation', () {
      add(text());
      final ok = move('t1', const PageRect(x: 100, y: 200, width: 200, height: 50));
      expect(ok, isTrue);
      final moved = store.getById('t1')!.rect;
      expect(moved.x, 100);
      expect(moved.y, 200);
    });

    test('moves an existing rect annotation', () {
      add(rect());
      final ok = move('r1', const PageRect(x: 0, y: 0, width: 50, height: 30));
      expect(ok, isTrue);
      expect(store.getById('r1')!.rect, const PageRect(x: 0, y: 0, width: 50, height: 30));
    });

    test('returns false on unknown id', () {
      final ok = move('nope', const PageRect(x: 0, y: 0, width: 1, height: 1));
      expect(ok, isFalse);
    });

    test('moving a stroke translates its points by the same delta', () {
      add(Annotation.stroke(
        id: 's1',
        pageNumber: 1,
        points: const [PagePoint(x: 10, y: 20), PagePoint(x: 30, y: 40)],
        rect: const PageRect(x: 10, y: 20, width: 20, height: 20),
        colorArgb: 0xFF000000,
        strokeWidth: 2,
      ));
      // Move the box by (+5, -8).
      final ok = move('s1', const PageRect(x: 15, y: 12, width: 20, height: 20));
      expect(ok, isTrue);
      final moved = store.getById('s1')! as StrokeAnnotation;
      expect(moved.rect.x, 15);
      expect(moved.rect.y, 12);
      expect(moved.points, const [PagePoint(x: 15, y: 12), PagePoint(x: 35, y: 32)]);
    });
  });

  group('RemoveAnnotation', () {
    test('removes an existing annotation', () {
      add(text());
      final ok = remove('t1');
      expect(ok, isTrue);
      expect(store.listAll(), isEmpty);
    });

    test('returns false when nothing to remove', () {
      expect(remove('nope'), isFalse);
    });
  });

  group('Annotation list/lookup', () {
    test('listForPage filters by pageNumber', () {
      add(text(id: 'p1'));
      add(text(id: 'p2'));
      add(rect(id: 'p3'));
      add(text(id: 'p4', pageNumber: 2));
      expect(store.listForPage(1), hasLength(3));
      expect(store.listForPage(2), hasLength(1));
      expect(store.getById('p3'), isNotNull);
    });
  });
}

// Tiny spy that wraps the same logic the production store uses, but
// stays inside the test file (the production impl lives in `data/`).
class _SpyStore implements AnnotationStore {
  final List<Annotation> _items = <Annotation>[];

  int addCalls = 0;
  int updateCalls = 0;
  int removeCalls = 0;

  @override
  bool add(Annotation a) {
    addCalls++;
    if (_items.any((e) => e.id == a.id)) return false;
    _items.add(a);
    return true;
  }

  @override
  bool update(Annotation a) {
    updateCalls++;
    final i = _items.indexWhere((e) => e.id == a.id);
    if (i < 0) return false;
    _items[i] = a;
    return true;
  }

  @override
  bool remove(String id) {
    removeCalls++;
    final before = _items.length;
    _items.removeWhere((e) => e.id == id);
    return _items.length != before;
  }

  @override
  Annotation? getById(String id) {
    for (final a in _items) {
      if (a.id == id) return a;
    }
    return null;
  }

  @override
  List<Annotation> listAll() => List<Annotation>.unmodifiable(_items);

  @override
  List<Annotation> listForPage(int pageNumber) {
    return _items.where((a) => a.pageNumber == pageNumber).toList(growable: false);
  }

  @override
  void clear() => _items.clear();

  @override
  bool undo() => false;

  @override
  bool redo() => false;

  @override
  bool get canUndo => false;

  @override
  bool get canRedo => false;

  @override
  String toJson() => throw UnimplementedError();

  @override
  void loadFromJson(String source) => throw UnimplementedError();
}
