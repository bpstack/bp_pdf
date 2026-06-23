import '../repositories/annotation_store.dart';

class RemoveAnnotation {
  const RemoveAnnotation(this._store);
  final AnnotationStore _store;

  /// `true` if an annotation with that id existed and was removed.
  bool call(String id) => _store.remove(id);
}
