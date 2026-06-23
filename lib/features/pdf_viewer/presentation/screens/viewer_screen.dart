import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../annotation/presentation/providers/annotation_providers.dart';
import '../../../annotation/presentation/widgets/properties_panel.dart';
import '../../../annotation/presentation/widgets/tool_panel.dart';
import '../../../export/presentation/providers/export_providers.dart';
import '../../../project/presentation/providers/project_providers.dart';
import '../../../project/presentation/screens/projects_screen.dart';
import '../../domain/entities/pdf_failure.dart';
import '../providers/pdf_session_provider.dart';
import '../providers/viewer_controller_provider.dart';
import '../providers/viewer_state_providers.dart';
import '../widgets/page_navigation_bar.dart';
import '../widgets/pdf_viewer_widget.dart';
import '../widgets/thumbnail_rail.dart';
import '../widgets/zoom_controls.dart';

class ViewerScreen extends ConsumerStatefulWidget {
  const ViewerScreen({super.key});

  @override
  ConsumerState<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends ConsumerState<ViewerScreen> {
  bool _opening = false;

  // Stable key for the PDF viewer so it survives the wide↔narrow layout switch.
  // Crossing the 700 dp breakpoint changes the body from a Row to a Column;
  // without a GlobalKey, Flutter rebuilds the subtree, recreating the viewer's
  // State (and pdfrx render surface) → the page would blank out. The GlobalKey
  // makes Flutter reparent the same element instead of destroying it.
  final GlobalKey _pdfViewerKey = GlobalKey();

  Future<void> _saveProject() async {
    try {
      final project =
          await ref.read(projectsProvider.notifier).saveCurrentSession();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Proyecto guardado: ${project.name}'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    }
  }

  void _openProjectsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ProjectsScreen()),
    );
  }

  Future<void> _exportPdf() async {
    await ref.read(exportProvider.notifier).exportPdf();
    if (!mounted) return;
    final platform = Theme.of(context).platform;
    final isMobile = platform == TargetPlatform.android ||
        platform == TargetPlatform.iOS;
    ref.read(exportProvider).when(
      data: (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isMobile
              ? 'PDF generado: elige dónde compartirlo.'
              : 'PDF exportado correctamente.'),
          duration: const Duration(seconds: 3),
        ),
      ),
      error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar: $e')),
      ),
      loading: () {},
    );
  }

  Future<void> _openPdf() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final useCase = ref.read(openPdfFromPickerProvider);
      final result = await useCase();
      if (!mounted) return;
      result.when(
        success: (session) {
          // Reset annotation state for the new document.
          ref.read(annotationsProvider.notifier).clearAll();
          ref.read(selectedAnnotationProvider.notifier).clear();
          ref.read(annotationToolProvider.notifier).set(AnnotationTool.select);
          ref.read(pdfSessionProvider.notifier).set(session);
          ref.read(currentPageProvider.notifier).set(1);
          ref.read(currentZoomProvider.notifier).set(0);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Abierto: ${session.sourceName} (${session.pageCount} pág.)'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        failure: (error) {
          if (error is PdfCancelledByUser) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al abrir PDF: $error')),
          );
        },
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(pdfSessionProvider);
    final hasDocument = session != null;
    final exportState = ref.watch(exportProvider);
    final isExporting = exportState.isLoading;
    final isWide = MediaQuery.sizeOf(context).width > 700;

    return Scaffold(
      appBar: isWide
          ? _buildWideAppBar(context, session, hasDocument, isExporting)
          : _buildNarrowAppBar(context, session, hasDocument, isExporting),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 700;
          final contentRow = Row(
            children: [
              if (hasDocument && wide) const ThumbnailRail(),
              if (hasDocument && wide) const ToolPanel(),
              if (hasDocument && wide) const VerticalDivider(width: 1),
              Expanded(
                child: hasDocument
                    ? PdfViewerWidget(key: _pdfViewerKey)
                    : _EmptyState(onOpen: _openPdf, busy: _opening),
              ),
              if (hasDocument && wide) const VerticalDivider(width: 1),
              if (hasDocument && wide) const PropertiesPanel(),
            ],
          );

          if (!wide && hasDocument) {
            return Column(
              children: [
                ToolPanel(horizontal: true),
                Expanded(child: contentRow),
                _NarrowBottomBar(totalPages: session.pageCount),
              ],
            );
          }
          return contentRow;
        },
      ),
      floatingActionButton: hasDocument && !isWide
          ? _PropertiesFab(isVisible: true)
          : null,
    );
  }

  PreferredSizeWidget _buildWideAppBar(
    BuildContext context,
    dynamic session,
    bool hasDocument,
    bool isExporting,
  ) {
    return AppBar(
      title: Text(hasDocument ? session.sourceName : 'BP PDF'),
      actions: [
        if (hasDocument) ...[
          PageNavigationBar(totalPages: session.pageCount),
          const SizedBox(width: 8),
          ZoomControls(),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Proyectos guardados',
            icon: const Icon(Icons.folder_special_outlined),
            onPressed: _openProjectsScreen,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
              onPressed: _saveProject,
              icon: const Icon(Icons.save_outlined),
              label: Text(session.projectId != null ? 'Actualizar proyecto' : 'Guardar proyecto'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              onPressed: isExporting ? null : _exportPdf,
              icon: isExporting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download),
              label: const Text('Exportar PDF'),
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: FilledButton.icon(
            onPressed: _opening ? null : _openPdf,
            icon: _opening
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.folder_open),
            label: const Text('Abrir PDF'),
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildNarrowAppBar(
    BuildContext context,
    dynamic session,
    bool hasDocument,
    bool isExporting,
  ) {
    return AppBar(
      title: Text(
        hasDocument ? session.sourceName : 'BP PDF',
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        IconButton(
          tooltip: 'Abrir PDF',
          icon: _opening
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.folder_open),
          onPressed: _opening ? null : _openPdf,
        ),
        if (hasDocument)
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'open') _openPdf();
              if (value == 'save') _saveProject();
              if (value == 'export') _exportPdf();
              if (value == 'projects') _openProjectsScreen();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'open',
                enabled: !_opening,
                child: const ListTile(
                  leading: Icon(Icons.folder_open),
                  title: Text('Abrir documento'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'save',
                child: ListTile(
                  leading: const Icon(Icons.save_outlined),
                  title: Text(session.projectId != null ? 'Actualizar proyecto' : 'Guardar proyecto'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'export',
                enabled: !isExporting,
                child: ListTile(
                  leading: isExporting
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.share_outlined),
                  title: const Text('Compartir PDF'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'projects',
                child: ListTile(
                  leading: Icon(Icons.folder_special_outlined),
                  title: Text('Proyectos guardados'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Bottom bar for the narrow (mobile) layout: page navigation + zoom controls.
/// Lives at the bottom so the app bar stays uncluttered and the save/export
/// menu is never pushed off-screen. Zoom drives pdfrx's real scale via the
/// shared controller, so it works with or without touch (and complements
/// pinch-to-zoom). Horizontally scrollable to survive very narrow screens.
class _NarrowBottomBar extends ConsumerWidget {
  const _NarrowBottomBar({required this.totalPages});

  final int totalPages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(viewerControllerProvider);
    final zoom = ref.watch(currentZoomProvider);
    final page = ref.watch(currentPageProvider);
    final ready = controller != null && zoom > 0;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 48,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PageNavigationBar(totalPages: totalPages),
                const VerticalDivider(width: 1, indent: 8, endIndent: 8),
                IconButton(
                  tooltip: 'Reducir',
                  icon: const Icon(Icons.zoom_out),
                  onPressed: !ready
                      ? null
                      : () => ZoomControls.zoomTo(
                          controller, controller.currentZoom / ZoomControls.step),
                ),
                IconButton(
                  tooltip: 'Aumentar',
                  icon: const Icon(Icons.zoom_in),
                  onPressed: !ready
                      ? null
                      : () => ZoomControls.zoomTo(
                          controller, controller.currentZoom * ZoomControls.step),
                ),
                IconButton(
                  tooltip: 'Ajustar a la página',
                  icon: const Icon(Icons.fit_screen),
                  onPressed: !ready
                      ? null
                      : () => controller.goTo(
                          controller.calcMatrixForFit(
                              pageNumber: page < 1 ? 1 : page),
                          duration: Duration.zero,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// FAB shown on narrow screens (≤ 700 dp) that opens [PropertiesPanel]
/// as a modal bottom sheet.
class _PropertiesFab extends ConsumerWidget {
  const _PropertiesFab({required this.isVisible});
  final bool isVisible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isVisible) return const SizedBox.shrink();
    final tool = ref.watch(annotationToolProvider);
    final selectedId = ref.watch(selectedAnnotationProvider);
    // Only show FAB when there are properties to display.
    final hasProps = tool != AnnotationTool.select || selectedId != null;
    if (!hasProps) return const SizedBox.shrink();
    return FloatingActionButton.small(
      tooltip: 'Propiedades',
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (ctx, scroll) => SingleChildScrollView(
            controller: scroll,
            child: const PropertiesPanel(fillWidth: true),
          ),
        ),
      ),
      child: const Icon(Icons.tune),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onOpen, required this.busy});

  final VoidCallback onOpen;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.picture_as_pdf, size: 96, color: scheme.outline),
          const SizedBox(height: 12),
          Text(
            'Ningún documento abierto',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Abre un PDF desde tu sistema de archivos para empezar.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.outline),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: busy ? null : onOpen,
            icon: const Icon(Icons.folder_open),
            label: const Text('Abrir PDF'),
          ),
        ],
      ),
    );
  }
}
