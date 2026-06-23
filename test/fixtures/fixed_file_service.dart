import 'package:bp_pdf/services/file_service/file_service.dart';

/// Test double for [FileService] that returns a pre-set [PickedFile].
class FixedFileService implements FileService {
  FixedFileService(this.file);
  final PickedFile? file;

  @override
  Future<PickedFile?> pickPdf() async => file;
}
