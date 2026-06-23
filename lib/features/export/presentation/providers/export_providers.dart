import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../../features/annotation/presentation/providers/annotation_providers.dart';
import '../../../../features/pdf_viewer/presentation/providers/pdf_session_provider.dart';
import '../../data/repositories/raster_pdf_exporter.dart';
import '../../domain/usecases/export_to_new_pdf.dart';

/// Default DPI for rasterisation. 200 balances quality vs. file size (R6).
const int kDefaultExportDpi = 200;

/// Async notifier that drives the export flow.
///
/// [state] is [AsyncLoading] while the PDF is being written,
/// [AsyncData] on success, [AsyncError] on failure.
class ExportNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  /// Mobile (Android/iOS) shares the generated PDF via the OS share sheet;
  /// desktop writes it to a user-chosen file ("Guardar como"). Mobile has no
  /// natural "save to arbitrary path" under scoped storage, so sharing is the
  /// idiomatic way to keep the new PDF.
  bool get _isMobile =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> exportPdf({int dpi = kDefaultExportDpi}) async {
    // On desktop, ask for the destination BEFORE the heavy work; if the user
    // cancels, keep the current state. On mobile the share sheet comes after.
    FileSaveLocation? saveLocation;
    if (!_isMobile) {
      saveLocation = await getSaveLocation(
        suggestedName: 'anotaciones.pdf',
        acceptedTypeGroups: [
          const XTypeGroup(label: 'PDF', extensions: ['pdf']),
        ],
      );
      if (saveLocation == null) return; // cancelled
    }

    state = const AsyncLoading();
    try {
      final dataSource = ref.read(pdfrxDataSourceProvider);
      final doc = dataSource.document;
      if (doc == null) {
        throw StateError('No hay ningún documento abierto.');
      }
      final annotations = ref.read(annotationStoreProvider).listAll();
      final exporter = RasterPdfExporter(
        document: doc,
        annotations: annotations,
      );

      if (_isMobile) {
        final bytes = await exporter.buildBytes(dpi: dpi);
        await Printing.sharePdf(bytes: bytes, filename: 'anotaciones.pdf');
      } else {
        await ExportToNewPdf(exporter)(dpi: dpi, outputPath: saveLocation!.path);
      }
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final exportProvider =
    AsyncNotifierProvider<ExportNotifier, void>(ExportNotifier.new);
