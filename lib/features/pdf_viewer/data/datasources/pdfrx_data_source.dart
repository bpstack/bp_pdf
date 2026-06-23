import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:pdfrx/pdfrx.dart';

/// Thin wrapper around the pdfrx engine for the data layer.
///
/// Owns the lifecycle of a single [PdfDocument] instance. The domain does NOT
/// import this class — it only sees [PdfRepository] in `domain/repositories/`.
class PdfrxDataSource {
  PdfDocument? _document;

  /// Raw bytes of the document when it was opened from memory (Android SAF).
  /// `null` when opened from a path, since the file is reachable on disk.
  /// Kept so a project can be saved even without a filesystem path (B7).
  Uint8List? _sourceBytes;

  PdfDocument? get document => _document;
  bool get isOpen => _document != null;

  /// In-memory bytes of the current document, or `null` if it was opened from
  /// a path (read the file instead).
  Uint8List? get sourceBytes => _sourceBytes;

  Future<PdfDocument> openFromPath(
    String path, {
    PdfPasswordProvider? passwordProvider,
  }) async {
    await _close();
    final doc = await PdfDocument.openFile(
      path,
      passwordProvider: passwordProvider,
    );
    _document = doc;
    return doc;
  }

  Future<PdfDocument> openFromBytes(
    Uint8List bytes, {
    required String sourceName,
    PdfPasswordProvider? passwordProvider,
  }) async {
    await _close();
    final doc = await PdfDocument.openData(
      bytes,
      sourceName: sourceName,
      passwordProvider: passwordProvider,
    );
    _document = doc;
    _sourceBytes = bytes;
    return doc;
  }

  Future<void> close() => _close();

  Future<void> _close() async {
    _sourceBytes = null;
    final doc = _document;
    if (doc != null) {
      _document = null;
      await doc.dispose();
    }
  }

  /// Render a single page to a PNG byte buffer, sized to fit [maxPixelSize]
  /// on its longest side. Returns `null` if the page is out of range.
  Future<Uint8List?> renderPagePng({
    required int pageNumber,
    int maxPixelSize = 120,
  }) async {
    final doc = _document;
    if (doc == null) return null;
    if (pageNumber < 1 || pageNumber > doc.pages.length) return null;

    final page = doc.pages[pageNumber - 1];
    // Compute target pixel size preserving aspect ratio.
    final w = page.width;
    final h = page.height;
    final longest = w >= h ? w : h;
    final scale = longest > maxPixelSize ? maxPixelSize / longest : 1.0;
    final fullW = (w * scale).round().clamp(1, 4096);
    final fullH = (h * scale).round().clamp(1, 4096);

    final image = await page.render(
      fullWidth: fullW.toDouble(),
      fullHeight: fullH.toDouble(),
    );
    if (image == null) return null;

    ui.Image? uiImage;
    try {
      uiImage = await image.createImage();
      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } finally {
      uiImage?.dispose();
      image.dispose();
    }
  }
}
