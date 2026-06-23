import 'dart:typed_data';

import '../repositories/pdf_repository.dart';

/// Renders a single page of the open PDF to a small PNG buffer
/// suitable for a thumbnail rail.
///
/// Returns `null` if the page index is out of range.
class RenderThumbnail {
  const RenderThumbnail(this._repository);

  final PdfRepository _repository;

  Future<Uint8List?> call({
    required int pageNumber,
    int maxPixelSize = 120,
  }) =>
      _repository.renderThumbnail(
        pageNumber: pageNumber,
        maxPixelSize: maxPixelSize,
      );
}
