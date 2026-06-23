import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart' as fs;

/// Cross-platform abstraction for picking a file.
///
/// Implementations live in `data/` and depend on `file_selector`.
/// The domain does NOT import this interface directly — it goes through
/// the use case which calls [pickPdf].
abstract class FileService {
  /// Shows a system file picker filtered for PDF documents.
  ///
  /// Returns the chosen file's bytes (cross-platform), or `null` if the user
  /// cancelled the dialog. On Android the bytes come from a content URI
  /// (Storage Access Framework); on desktop, from a regular file path.
  Future<PickedFile?> pickPdf();
}

/// A file picked by the user, normalised to bytes + display name.
class PickedFile {
  const PickedFile({required this.bytes, required this.displayName, this.path});

  final Uint8List bytes;
  final String displayName;

  /// Real filesystem path when available (desktop). May be `null` on
  /// platforms that hand back a content URI (Android).
  final String? path;
}

class FileServiceImpl implements FileService {
  const FileServiceImpl();

  @override
  Future<PickedFile?> pickPdf() async {
    final fs.XFile? file = await fs.openFile(
      acceptedTypeGroups: const <fs.XTypeGroup>[
        fs.XTypeGroup(label: 'PDF', extensions: <String>['pdf'], mimeTypes: <String>['application/pdf']),
      ],
      confirmButtonText: 'Abrir',
    );
    if (file == null) return null;

    final Uint8List bytes = await file.readAsBytes();
    final String displayName = file.name.isNotEmpty ? file.name : 'documento.pdf';
    final String? path = file.path.isNotEmpty ? file.path : null;

    if (path != null && !File(path).existsSync()) {
      return PickedFile(bytes: bytes, displayName: displayName);
    }
    return PickedFile(bytes: bytes, displayName: displayName, path: path);
  }
}
