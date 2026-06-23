import '../entities/annotation.dart';
import '../repositories/annotation_store.dart';

class UpdateAnnotation {
  const UpdateAnnotation(this._store);
  final AnnotationStore _store;

  /// `true` if the store had a record with the same id and replaced it.
  bool call(Annotation annotation) => _store.update(annotation);
}
