import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/edit_project.dart';
import '../../domain/repositories/project_repository.dart';

/// Filesystem-backed [ProjectRepository].
///
/// Layout inside the app's documents directory:
/// ```
/// bp_pdf/
///   projects/
///     <uuid>/
///       project.json   ← metadata + serialised annotation list
///       document.pdf   ← copy of the original PDF (original never touched)
/// ```
///
/// project.json schema (version 1):
/// ```json
/// {
///   "schema": 1,
///   "id": "...",
///   "name": "Documento.pdf",
///   "savedAt": "2026-06-03T12:00:00.000Z",
///   "pageCount": 5,
///   "annotations": [...]   <- same array as AnnotationStore JSON payload
/// }
/// ```
class ProjectRepositoryImpl implements ProjectRepository {
  static const _uuid = Uuid();

  Future<Directory> get _projectsRoot async {
    final appDocs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDocs.path, 'bp_pdf', 'projects'));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  @override
  Future<EditProject> saveProject({
    String? pdfSourcePath,
    Uint8List? pdfBytes,
    required String pdfName,
    required int pageCount,
    required String annotationsJson,
    String? existingProjectId,
  }) async {
    final root = await _projectsRoot;
    final id = existingProjectId ?? _uuid.v4();
    final projectDir = Directory(p.join(root.path, id));
    if (!projectDir.existsSync()) await projectDir.create(recursive: true);

    final pdfCopyPath = p.join(projectDir.path, 'document.pdf');

    // The PDF copy already exists when overwriting a project; otherwise it must
    // be materialised from bytes (Android SAF) or copied from the source path.
    final copyExists = File(pdfCopyPath).existsSync();
    if (!copyExists) {
      if (pdfBytes != null) {
        await File(pdfCopyPath).writeAsBytes(pdfBytes);
      } else if (pdfSourcePath != null &&
          p.canonicalize(pdfSourcePath) != p.canonicalize(pdfCopyPath)) {
        await File(pdfSourcePath).copy(pdfCopyPath);
      } else {
        throw ArgumentError(
          'saveProject requires pdfBytes or pdfSourcePath for a new project.',
        );
      }
    }

    // Extract the annotations array from the AnnotationStore JSON string.
    final storeJson = jsonDecode(annotationsJson) as Map<String, dynamic>;
    final annotationsArray = storeJson['annotations'] as List<dynamic>;

    final now = DateTime.now().toUtc();
    final metadata = <String, dynamic>{
      'schema': 1,
      'id': id,
      'name': pdfName,
      'savedAt': now.toIso8601String(),
      'pageCount': pageCount,
      'annotations': annotationsArray,
    };

    final projectJsonPath = p.join(projectDir.path, 'project.json');
    await File(projectJsonPath).writeAsString(jsonEncode(metadata));

    return EditProject(
      id: id,
      name: pdfName,
      savedAt: now,
      pageCount: pageCount,
      pdfCopyPath: pdfCopyPath,
      projectJsonPath: projectJsonPath,
    );
  }

  @override
  Future<List<EditProject>> listProjects() async {
    final root = await _projectsRoot;
    if (!root.existsSync()) return [];

    final projects = <EditProject>[];
    await for (final entry in root.list()) {
      if (entry is! Directory) continue;
      final jsonFile = File(p.join(entry.path, 'project.json'));
      if (!jsonFile.existsSync()) continue;
      try {
        final project = _parse(entry, jsonFile);
        if (project != null) projects.add(project);
      } catch (_) {
        // skip corrupted entries
      }
    }
    projects.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return projects;
  }

  @override
  Future<EditProject?> loadProject(String id) async {
    final root = await _projectsRoot;
    final projectDir = Directory(p.join(root.path, id));
    final jsonFile = File(p.join(projectDir.path, 'project.json'));
    if (!jsonFile.existsSync()) return null;
    return _parse(projectDir, jsonFile);
  }

  @override
  Future<void> deleteProject(String id) async {
    final root = await _projectsRoot;
    final projectDir = Directory(p.join(root.path, id));
    if (projectDir.existsSync()) await projectDir.delete(recursive: true);
  }

  // ---------------------------------------------------------------------------

  EditProject? _parse(Directory projectDir, File jsonFile) {
    final raw = jsonDecode(jsonFile.readAsStringSync()) as Map<String, dynamic>;
    return EditProject(
      id: raw['id'] as String,
      name: raw['name'] as String,
      savedAt: DateTime.parse(raw['savedAt'] as String),
      pageCount: raw['pageCount'] as int,
      pdfCopyPath: p.join(projectDir.path, 'document.pdf'),
      projectJsonPath: jsonFile.path,
    );
  }
}
