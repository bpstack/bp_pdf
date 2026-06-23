import '../entities/annotation.dart';
import '../repositories/annotation_store.dart';

class AddAnnotation {
  const AddAnnotation(this._store);
  final AnnotationStore _store;

  /// Returns the stored instance (with canonical id set) or `null` if
  /// the store refused the insert because of a duplicate id.
  Annotation? call(Annotation annotation) {
    final ok = _store.add(annotation);
    return ok ? annotation : null;
  }
}
