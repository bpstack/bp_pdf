import '../../../../core/result/result.dart';
import '../../../../services/file_service/file_service.dart';
import '../entities/pdf_failure.dart';
import '../entities/pdf_session.dart';
import '../repositories/pdf_repository.dart';

/// Opens a PDF by showing the system file picker.
///
/// Returns:
/// - [Success] with a [PdfSession] when the user picked a valid PDF.
/// - [Failure] with [PdfCancelledByUser] when the user cancelled the dialog.
/// - [Failure] with [PdfInvalidFile] / [PdfIoError] on any I/O or parse error.
class OpenPdfFromPicker {
  const OpenPdfFromPicker(this._fileService, this._repository);

  final FileService _fileService;
  final PdfRepository _repository;

  Future<Result<PdfSession>> call() async {
    final PickedFile? picked = await _fileService.pickPdf();
    if (picked == null) {
      return const Failure(PdfCancelledByUser());
    }

    final String path = picked.path ?? '';
    if (path.isNotEmpty) {
      return _repository.openPdfFromPath(path, displayName: picked.displayName);
    }
    return _repository.openPdfFromBytes(picked.bytes, displayName: picked.displayName);
  }
}
