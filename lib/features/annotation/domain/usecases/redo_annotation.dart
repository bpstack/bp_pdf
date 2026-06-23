import '../repositories/annotation_store.dart';

class RedoAnnotation {
  const RedoAnnotation(this._store);
  final AnnotationStore _store;

  /// Replays the last undone mutation. Returns `true` when something changed.
  bool call() => _store.redo();
}
