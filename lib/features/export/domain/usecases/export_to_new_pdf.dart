import '../repositories/pdf_exporter.dart';

class ExportToNewPdf {
  const ExportToNewPdf(this._exporter);
  final PdfExporter _exporter;

  /// Delegate to the injected [PdfExporter]. [dpi] controls rasterisation
  /// quality (200 is a sensible default). [outputPath] must be writeable.
  Future<void> call({required int dpi, required String outputPath}) =>
      _exporter.export(dpi: dpi, outputPath: outputPath);
}
