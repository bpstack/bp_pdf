import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../annotation/presentation/providers/annotation_providers.dart';
import '../../../annotation/presentation/widgets/annotation_layer.dart';
import '../../data/datasources/pdfrx_data_source.dart';
import '../providers/pdf_session_provider.dart';
import '../providers/viewer_controller_provider.dart';
import '../providers/viewer_state_providers.dart';

/// Wraps pdfrx's [PdfViewer] with Riverpod integration.
///
/// The widget owns the [PdfViewerController], publishes it via
/// [viewerControllerProvider] for sibling widgets (zoom controls, page
/// navigation, thumbnail rail), and mirrors the controller's current page
/// and zoom into [currentPageProvider] / [currentZoomProvider].
class PdfViewerWidget extends ConsumerStatefulWidget {
  const PdfViewerWidget({super.key});

  @override
  ConsumerState<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends ConsumerState<PdfViewerWidget> {
  late final PdfViewerController _controller;
  VoidCallback? _removeListener;

  @override
  void initState() {
    super.initState();
    _controller = PdfViewerController();
    _controller.addListener(_onControllerChanged);
    _removeListener = () => _controller.removeListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(viewerControllerProvider.notifier).set(_controller);
    });
  }

  void _onControllerChanged() {
    if (!mounted) return;
    final page = _controller.pageNumber;
    if (page != null && page > 0) {
      ref.read(currentPageProvider.notifier).set(page);
    }
    final zoom = _controller.currentZoom;
    if (zoom > 0) {
      ref.read(currentZoomProvider.notifier).set(zoom);
    }
  }

  @override
  void dispose() {
    _removeListener?.call();
    if (ref.read(viewerControllerProvider) == _controller) {
      ref.read(viewerControllerProvider.notifier).set(null);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PdfrxDataSource dataSource = ref.watch(pdfrxDataSourceProvider);
    final PdfDocument? document = dataSource.document;
    if (document == null) {
      // Guard: ViewerScreen should not mount us without a document, but if
      // it does, render a placeholder rather than crash.
      return const SizedBox.shrink();
    }
    // The session may have been closed by the user; check via provider too.
    final hasSession = ref.watch(pdfSessionProvider) != null;
    if (!hasSession) return const SizedBox.shrink();

    // panEnabled only when the pan tool is active: that tool adds no overlay
    // gestures, so pdfrx can safely win the arena for scroll/pinch-zoom.
    // For all annotation tools panEnabled stays false so taps reach the overlay.
    final tool = ref.watch(annotationToolProvider);
    final panEnabled = tool == AnnotationTool.pan;

    return PdfViewer(
      PdfDocumentRefDirect(document),
      controller: _controller,
      params: PdfViewerParams(
        backgroundColor: Colors.transparent,
        panEnabled: panEnabled,
        // Pinch-zoom (2 fingers) always on: doesn't conflict with the
        // overlay's single-finger taps, so users can zoom regardless of
        // the active annotation tool.
        scaleEnabled: true,
        pageDropShadow: const BoxShadow(
          color: Colors.black26,
          blurRadius: 6,
          spreadRadius: 1,
          offset: Offset(1, 2),
        ),
        // Ctrl+Z / Ctrl+Y undo/redo when no text-edit session is active.
        onKey: (params, key, isRealKeyPress) {
          if (!isRealKeyPress) return null;
          if (!HardwareKeyboard.instance.isControlPressed) return null;
          if (key == LogicalKeyboardKey.keyZ) {
            ref.read(annotationsProvider.notifier).undoAnnotations();
            return true;
          }
          if (key == LogicalKeyboardKey.keyY) {
            ref.read(annotationsProvider.notifier).redoAnnotations();
            return true;
          }
          return null;
        },
        // pdfrx already wraps pageOverlaysBuilder output in a Positioned
        // at the page rect. Adding our own Positioned.fromRect(pageRect)
        // inside would double-offset the overlay, mis-placing taps and
        // the cursor region. Return AnnotationLayer directly — it fills
        // the pdfrx-provided Stack which is already sized to the page.
        pageOverlaysBuilder: (context, pageRect, page) => <Widget>[
          AnnotationLayer(page: page),
        ],
      ),
    );
  }
}
