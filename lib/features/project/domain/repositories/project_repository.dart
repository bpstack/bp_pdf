import 'dart:typed_data';

import '../entities/edit_project.dart';

/// Persistence contract for editing projects.
///
/// A project = a copy of the PDF (inside app storage) + a JSON snapshot of
/// the annotations. The original PDF is never stored here — only the copy.
abstract class ProjectRepository {
  /// Create or overwrite a project.
  ///
  /// The PDF copy is sourced from either [pdfSourcePath] (desktop, a real
  /// filesystem path) or [pdfBytes] (Android SAF, where no path exists). For a
  /// new project exactly one of the two must be provided.
  ///
  /// If [existingProjectId] is given the project is overwritten and the PDF
  /// is NOT re-copied (the copy already lives in app storage), so both
  /// [pdfSourcePath] and [pdfBytes] may be omitted.
  Future<EditProject> saveProject({
    String? pdfSourcePath,
    Uint8List? pdfBytes,
    required String pdfName,
    required int pageCount,
    required String annotationsJson,
    String? existingProjectId,
  });

  /// Return all saved projects ordered by [EditProject.savedAt] descending.
  Future<List<EditProject>> listProjects();

  /// Load a single project, or `null` if it no longer exists on disk.
  Future<EditProject?> loadProject(String id);

  /// Permanently delete a project and its associated files.
  Future<void> deleteProject(String id);
}
