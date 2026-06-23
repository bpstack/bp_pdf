import 'dart:convert';

import '../../domain/entities/annotation.dart';
import '../../domain/repositories/annotation_store.dart';

/// In-memory [AnnotationStore] with undo/redo and JSON (de)serialization.
///
/// Undo/redo uses immutable snapshots of the annotation list. Each mutating
/// operation ([add], [update], [remove]) records a snapshot before applying
/// the change and clears the redo stack. [clear] resets everything including
/// both stacks (not undoable — used when opening a new document).
///
/// Stack depth is capped at 50 to bound memory usage.
class AnnotationStoreImpl implements AnnotationStore {
  static const int _maxStackDepth = 50;

  final List<Annotation> _items = <Annotation>[];
  final List<List<Annotation>> _undoStack = [];
  final List<List<Annotation>> _redoStack = [];

  void _saveSnapshot() {
    _undoStack.add(List<Annotation>.from(_items));
    _redoStack.clear();
    if (_undoStack.length > _maxStackDepth) _undoStack.removeAt(0);
  }

  @override
  List<Annotation> listAll() => List<Annotation>.unmodifiable(_items);

  @override
  List<Annotation> listForPage(int pageNumber) {
    return _items.where((a) => a.pageNumber == pageNumber).toList(growable: false);
  }

  @override
  Annotation? getById(String id) {
    for (final a in _items) {
      if (a.id == id) return a;
    }
    return null;
  }

  @override
  bool add(Annotation annotation) {
    if (_items.any((a) => a.id == annotation.id)) return false;
    _saveSnapshot();
    _items.add(annotation);
    return true;
  }

  @override
  bool update(Annotation annotation) {
    final i = _items.indexWhere((a) => a.id == annotation.id);
    if (i < 0) return false;
    _saveSnapshot();
    _items[i] = annotation;
    return true;
  }

  @override
  bool remove(String id) {
    final i = _items.indexWhere((a) => a.id == id);
    if (i < 0) return false;
    _saveSnapshot();
    _items.removeAt(i);
    return true;
  }

  @override
  void clear() {
    _items.clear();
    _undoStack.clear();
    _redoStack.clear();
  }

  @override
  bool undo() {
    if (_undoStack.isEmpty) return false;
    _redoStack.add(List<Annotation>.from(_items));
    _items
      ..clear()
      ..addAll(_undoStack.removeLast());
    return true;
  }

  @override
  bool redo() {
    if (_redoStack.isEmpty) return false;
    _undoStack.add(List<Annotation>.from(_items));
    _items
      ..clear()
      ..addAll(_redoStack.removeLast());
    return true;
  }

  @override
  bool get canUndo => _undoStack.isNotEmpty;

  @override
  bool get canRedo => _redoStack.isNotEmpty;

  @override
  String toJson() {
    final payload = <String, Object?>{
      'version': 1,
      'annotations': _items,
    };
    return jsonEncode(payload);
  }

  @override
  void loadFromJson(String source) {
    final raw = jsonDecode(source);
    if (raw is! Map<String, Object?>) {
      throw const FormatException('AnnotationStore JSON root must be an object.');
    }
    final list = raw['annotations'];
    if (list is! List) {
      throw const FormatException('AnnotationStore JSON missing "annotations" list.');
    }
    _items
      ..clear()
      ..addAll(list.map(
        (e) => Annotation.fromJson(Map<String, dynamic>.from(e as Map)),
      ));
    _undoStack.clear();
    _redoStack.clear();
  }
}
