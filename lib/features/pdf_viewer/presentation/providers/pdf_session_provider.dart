import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/file_service/file_service.dart';
import '../../data/datasources/pdfrx_data_source.dart';
import '../../data/repositories/pdf_repository_impl.dart';
import '../../domain/entities/pdf_session.dart';
import '../../domain/repositories/pdf_repository.dart';
import '../../domain/usecases/open_pdf_from_picker.dart';

/// Infrastructure: the pdfrx-backed data source. Singleton for the app
/// lifetime — the wrapped [PdfDocument] is the current open document.
final pdfrxDataSourceProvider = Provider<PdfrxDataSource>((ref) {
  final ds = PdfrxDataSource();
  ref.onDispose(ds.close);
  return ds;
});

/// Repository wired with the data source.
final pdfRepositoryProvider = Provider<PdfRepository>((ref) {
  return PdfRepositoryImpl(ref.watch(pdfrxDataSourceProvider));
});

/// File picker abstraction.
final fileServiceProvider = Provider<FileService>((ref) {
  return const FileServiceImpl();
});

/// Use case: open a PDF via the system file picker.
final openPdfFromPickerProvider = Provider<OpenPdfFromPicker>((ref) {
  return OpenPdfFromPicker(
    ref.watch(fileServiceProvider),
    ref.watch(pdfRepositoryProvider),
  );
});

/// Current PDF session. `null` means nothing is open.
class PdfSessionNotifier extends Notifier<PdfSession?> {
  @override
  PdfSession? build() => null;

  void set(PdfSession? session) => state = session;
}

final pdfSessionProvider =
    NotifierProvider<PdfSessionNotifier, PdfSession?>(PdfSessionNotifier.new);
