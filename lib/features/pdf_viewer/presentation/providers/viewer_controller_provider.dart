import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

/// Holds the active [PdfViewerController] when the viewer is mounted.
///
/// The controller is created by [PdfViewerWidget] once the document is open
/// and cleared when the widget leaves the tree. Other widgets (zoom
/// controls, page navigation, thumbnail rail) read this provider to control
/// the viewer without holding direct references.
class ViewerControllerHolder extends Notifier<PdfViewerController?> {
  @override
  PdfViewerController? build() => null;

  void set(PdfViewerController? controller) => state = controller;
}

final viewerControllerProvider =
    NotifierProvider<ViewerControllerHolder, PdfViewerController?>(ViewerControllerHolder.new);
