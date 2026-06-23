import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/annotation/presentation/providers/annotation_providers.dart';
import '../../../../features/pdf_viewer/domain/entities/pdf_session.dart';
import '../../../../features/pdf_viewer/presentation/providers/pdf_session_provider.dart';
import '../../../../features/pdf_viewer/presentation/providers/viewer_state_providers.dart';
import '../../data/repositories/project_repository_impl.dart';
import '../../domain/entities/edit_project.dart';
import '../../domain/repositories/project_repository.dart';
import '../../domain/usecases/delete_project.dart';
import '../../domain/usecases/list_projects.dart';
import '../../domain/usecases/save_project.dart';

final projectRepositoryProvider = Provider<ProjectRepository>(
  (_) => ProjectRepositoryImpl(),
);

final saveProjectUseCaseProvider = Provider<SaveProject>(
  (ref) => SaveProject(ref.watch(projectRepositoryProvider)),
);
final listProjectsUseCaseProvider = Provider<ListProjects>(
  (ref) => ListProjects(ref.watch(projectRepositoryProvider)),
);
final deleteProjectUseCaseProvider = Provider<DeleteProject>(
  (ref) => DeleteProject(ref.watch(projectRepositoryProvider)),
);

// ---------------------------------------------------------------------------
// Project list notifier
// ---------------------------------------------------------------------------

class ProjectsNotifier extends AsyncNotifier<List<EditProject>> {
  @override
  Future<List<EditProject>> build() => ref.read(listProjectsUseCaseProvider)();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(ref.read(listProjectsUseCaseProvider).call);
  }

  /// Save the current session as a new project (or overwrite if it was opened
  /// from one). Returns the saved project, or throws on failure.
  Future<EditProject> saveCurrentSession() async {
    final session = ref.read(pdfSessionProvider);
    if (session == null) throw StateError('No hay ningún documento abierto.');

    final sourcePath = session.sourcePath;
    // On Android SAF there is no filesystem path; fall back to the in-memory
    // bytes held by the PDF repository so the PDF can still be copied (B7).
    final pdfBytes = sourcePath == null
        ? ref.read(pdfRepositoryProvider).currentSourceBytes
        : null;
    if (sourcePath == null && pdfBytes == null && session.projectId == null) {
      throw StateError(
        'No se puede guardar: no hay datos del PDF disponibles.',
      );
    }

    final annotationsJson = ref.read(annotationStoreProvider).toJson();

    final project = await ref.read(saveProjectUseCaseProvider).call(
          pdfSourcePath: sourcePath,
          pdfBytes: pdfBytes,
          pdfName: session.sourceName,
          pageCount: session.pageCount,
          annotationsJson: annotationsJson,
          existingProjectId: session.projectId,
        );

    // Update session with projectId so subsequent saves overwrite.
    if (session.projectId == null) {
      ref.read(pdfSessionProvider.notifier).set(
            _withProjectId(session, project.id),
          );
    }

    await refresh();
    return project;
  }

  /// Restore a saved project: open PDF copy, load annotations, update state.
  Future<void> openProject(EditProject project) async {
    // Read annotation data from the project JSON
    final raw =
        jsonDecode(File(project.projectJsonPath).readAsStringSync()) as Map;
    final annotationsArray = raw['annotations'] as List<dynamic>;
    final annotationsJsonStr =
        jsonEncode({'version': 1, 'annotations': annotationsArray});

    final result = await ref.read(pdfRepositoryProvider).openPdfFromPath(
          project.pdfCopyPath,
          displayName: project.name,
          projectId: project.id,
        );

    result.when(
      success: (session) {
        // Reset annotation state before loading saved data
        ref.read(annotationsProvider.notifier).clearAll();
        ref.read(annotationStoreProvider).loadFromJson(annotationsJsonStr);
        ref.read(annotationsProvider.notifier).restoreFromStore();
        ref.read(pdfSessionProvider.notifier).set(session);
        ref.read(currentPageProvider.notifier).set(1);
        ref.read(currentZoomProvider.notifier).set(0);
        ref.read(annotationToolProvider.notifier).set(AnnotationTool.select);
        ref.read(selectedAnnotationProvider.notifier).clear();
      },
      failure: (e) => throw e,
    );
  }

  Future<void> deleteProject(String id) async {
    await ref.read(deleteProjectUseCaseProvider).call(id);
    await refresh();
  }
}

final projectsProvider =
    AsyncNotifierProvider<ProjectsNotifier, List<EditProject>>(
        ProjectsNotifier.new);

// ---------------------------------------------------------------------------
// Helper: create a copy of PdfSession with a projectId
// ---------------------------------------------------------------------------

PdfSession _withProjectId(PdfSession s, String id) => PdfSession(
      sourceName: s.sourceName,
      pageCount: s.pageCount,
      pages: s.pages,
      sourcePath: s.sourcePath,
      projectId: id,
    );
