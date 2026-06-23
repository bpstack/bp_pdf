import '../repositories/annotation_store.dart';

class UndoAnnotation {
  const UndoAnnotation(this._store);
  final AnnotationStore _store;

  /// Reverts the last undoable mutation. Returns `true` when something changed.
  bool call() => _store.undo();
}
