import '../entities/annotation.dart';

/// In-memory annotation store contract.
///
/// The presentation layer never implements or imports this — it goes
/// through Riverpod providers that read from a [AnnotationStore] instance
/// created in `data/`.
abstract class AnnotationStore {
  /// All annotations currently held, regardless of page.
  List<Annotation> listAll();

  /// All annotations on the given page (1-based).
  List<Annotation> listForPage(int pageNumber);

  /// Look up a single annotation by its UUID.
  Annotation? getById(String id);

  /// Append a new annotation. If [annotation.id] already exists the call
  /// is a no-op (returns `false`); on insert it returns `true`.
  bool add(Annotation annotation);

  /// Replace an existing annotation by id. Returns `false` if the id is
  /// unknown. Equality is by id only; the rest of the payload can change.
  bool update(Annotation annotation);

  /// Remove an annotation by id. Returns `true` if something was removed.
  bool remove(String id);

  /// Drop every annotation and reset the undo/redo stacks.
  /// Called when a new document is opened — not undoable.
  void clear();

  /// Undo the last undoable mutation. Returns `true` if something was undone.
  bool undo();

  /// Redo the last undone mutation. Returns `true` if something was redone.
  bool redo();

  /// Whether [undo] has something to revert.
  bool get canUndo;

  /// Whether [redo] has something to replay.
  bool get canRedo;

  /// Serialize the entire store to a JSON document.
  String toJson();

  /// Restore the store contents from a JSON document produced by [toJson].
  /// Throws [FormatException] on invalid input.
  void loadFromJson(String source);
}
