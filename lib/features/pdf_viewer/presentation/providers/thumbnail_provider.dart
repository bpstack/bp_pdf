import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/pdf_repository_impl.dart';
import '../../domain/repositories/pdf_repository.dart';
import 'pdf_session_provider.dart';

/// Returns PNG bytes for the given page thumbnail, or `null` if not yet
/// rendered / out of range / no document is open.
final thumbnailProvider = FutureProvider.family<Uint8List?, int>((ref, pageNumber) async {
  final PdfRepository repo = ref.watch(pdfRepositoryProvider);
  if (repo is! PdfRepositoryImpl || !repo.isOpen) return null;
  return repo.renderThumbnail(pageNumber: pageNumber, maxPixelSize: 120);
});
