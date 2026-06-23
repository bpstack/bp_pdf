import 'dart:typed_data';

import '../entities/edit_project.dart';
import '../repositories/project_repository.dart';

class SaveProject {
  const SaveProject(this._repo);
  final ProjectRepository _repo;

  /// Persist the current editing session as a project.
  ///
  /// Provide the PDF via [pdfSourcePath] (desktop) or [pdfBytes] (Android SAF).
  /// [annotationsJson] is the serialised output of [AnnotationStore.toJson].
  Future<EditProject> call({
    String? pdfSourcePath,
    Uint8List? pdfBytes,
    required String pdfName,
    required int pageCount,
    required String annotationsJson,
    String? existingProjectId,
  }) =>
      _repo.saveProject(
        pdfSourcePath: pdfSourcePath,
        pdfBytes: pdfBytes,
        pdfName: pdfName,
        pageCount: pageCount,
        annotationsJson: annotationsJson,
        existingProjectId: existingProjectId,
      );
}
