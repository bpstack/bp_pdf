/// An editing project: a saved copy of a PDF plus its annotation snapshot.
///
/// All paths are absolute filesystem paths inside the app's documents dir.
/// The original PDF is never referenced here — it was copied at save time.
class EditProject {
  const EditProject({
    required this.id,
    required this.name,
    required this.savedAt,
    required this.pageCount,
    required this.pdfCopyPath,
    required this.projectJsonPath,
  });

  final String id;
  final String name;
  final DateTime savedAt;
  final int pageCount;

  /// Absolute path to the PDF copy stored inside the app.
  final String pdfCopyPath;

  /// Absolute path to the project JSON (metadata + annotations).
  final String projectJsonPath;
}
