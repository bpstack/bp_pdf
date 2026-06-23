import 'dart:io';
import 'dart:typed_data';

import 'package:pdfrx/pdfrx.dart';

import '../../../../core/result/result.dart';
import '../../domain/entities/pdf_failure.dart';
import '../../domain/entities/pdf_session.dart';
import '../../domain/repositories/pdf_repository.dart';
import '../datasources/pdfrx_data_source.dart';

/// Concrete [PdfRepository] backed by pdfrx via [PdfrxDataSource].
///
/// All exceptions are caught and mapped to typed [PdfFailure] values; the
/// domain layer never sees raw pdfrx exceptions.
class PdfRepositoryImpl implements PdfRepository {
  PdfRepositoryImpl(this._dataSource);

  final PdfrxDataSource _dataSource;

  @override
  bool get isOpen => _dataSource.isOpen;

  @override
  Uint8List? get currentSourceBytes => _dataSource.sourceBytes;

  @override
  Future<void> close() => _dataSource.close();

  @override
  Future<Result<PdfSession>> openPdfFromPath(
    String path, {
    String? displayName,
    String? projectId,
  }) async {
    try {
      if (!File(path).existsSync()) {
        return Failure(PdfInvalidFile('No se encontró el archivo: $path'));
      }
      final doc = await _dataSource.openFromPath(path);
      return Success(_buildSession(
        doc,
        displayName ?? _basename(path),
        sourcePath: path,
        projectId: projectId,
      ));
    } on Object catch (e) {
      return Failure(_mapError(e));
    }
  }

  @override
  Future<Result<PdfSession>> openPdfFromBytes(
    Uint8List bytes, {
    required String displayName,
  }) async {
    try {
      final doc = await _dataSource.openFromBytes(
        bytes,
        sourceName: displayName,
      );
      return Success(_buildSession(doc, displayName));
    } on Object catch (e) {
      return Failure(_mapError(e));
    }
  }

  @override
  Future<Uint8List?> renderThumbnail({
    required int pageNumber,
    int maxPixelSize = 120,
  }) {
    final doc = _dataSource.document;
    if (doc == null) return Future.value(null);
    if (pageNumber < 1 || pageNumber > doc.pages.length) {
      return Future.value(null);
    }
    return _dataSource.renderPagePng(
      pageNumber: pageNumber,
      maxPixelSize: maxPixelSize,
    );
  }

  PdfSession _buildSession(
    PdfDocument doc,
    String sourceName, {
    String? sourcePath,
    String? projectId,
  }) {
    final pages = <PdfPageInfo>[];
    for (final p in doc.pages) {
      pages.add(PdfPageInfo(
        pageNumber: p.pageNumber,
        widthPoints: p.width,
        heightPoints: p.height,
      ));
    }
    return PdfSession(
      sourceName: sourceName,
      pageCount: doc.pages.length,
      pages: pages,
      sourcePath: sourcePath,
      projectId: projectId,
    );
  }

  PdfFailure _mapError(Object e) {
    if (e is PdfFailure) return e;
    if (e is FileSystemException) return PdfIoError(e.message);
    final msg = e.toString();
    return PdfInvalidFile(msg);
  }

  String _basename(String path) {
    final i = path.lastIndexOf(RegExp(r'[/\\]'));
    return i >= 0 ? path.substring(i + 1) : path;
  }
}
