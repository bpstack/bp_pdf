import 'dart:typed_data';

/// Contract for the PDF export engine.
///
/// The domain layer defines only this interface; the data layer provides
/// [RasterPdfExporter] (Opción A: rasterise + overlay). See ROADMAP §2.4.
abstract class PdfExporter {
  /// Render all pages at [dpi], draw the annotations on top, and return the
  /// resulting PDF as bytes. Used directly for "share" flows (mobile) and by
  /// [export] for "save to file" flows (desktop).
  ///
  /// The original PDF is **never** modified — this always produces a new document.
  Future<Uint8List> buildBytes({required int dpi});

  /// Convenience: [buildBytes] then write to [outputPath] (desktop "Guardar como").
  Future<void> export({required int dpi, required String outputPath});
}
