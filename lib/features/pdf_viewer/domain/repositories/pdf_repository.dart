import 'dart:typed_data';

import '../../../../core/result/result.dart';
import '../entities/pdf_session.dart';

/// Contract for the PDF feature data layer.
///
/// The domain owns this interface; concrete implementations live in `data/`.
/// The presentation layer depends only on this abstraction, never on pdfrx.
abstract class PdfRepository {
  /// Open a PDF from a file system path (Windows/Linux desktop).
  ///
  /// Use [openPdfFromBytes] when the file comes from a content URI (Android
  /// Storage Access Framework) or any source without a direct path.
  Future<Result<PdfSession>> openPdfFromPath(
    String path, {
    String? displayName,
    String? projectId,
  });

  /// Open a PDF from raw bytes (cross-platform; required for Android SAF).
  Future<Result<PdfSession>> openPdfFromBytes(Uint8List bytes, {required String displayName});

  /// Closes the current document, releasing native resources.
  Future<void> close();

  /// True if a PDF is currently open.
  bool get isOpen;

  /// Raw bytes of the current document when it was opened from memory
  /// (Android SAF), or `null` if it was opened from a filesystem path.
  /// Lets a project be saved when there is no path to copy from (B7).
  Uint8List? get currentSourceBytes;

  /// Renders a single page of the currently open document to PNG bytes
  /// suitable for a thumbnail. Returns `null` if the page is out of range
  /// or no document is open.
  Future<Uint8List?> renderThumbnail({required int pageNumber, int maxPixelSize = 120});
}
