import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:bp_pdf/features/export/domain/repositories/pdf_exporter.dart';
import 'package:bp_pdf/features/export/domain/usecases/export_to_new_pdf.dart';

class _CapturExporter implements PdfExporter {
  int? capturedDpi;
  String? capturedPath;
  bool wasCalled = false;

  @override
  Future<void> export({required int dpi, required String outputPath}) async {
    wasCalled = true;
    capturedDpi = dpi;
    capturedPath = outputPath;
  }

  @override
  Future<Uint8List> buildBytes({required int dpi}) async => Uint8List(0);
}

void main() {
  group('ExportToNewPdf', () {
    test('delegates dpi and outputPath to PdfExporter', () async {
      final mock = _CapturExporter();
      await ExportToNewPdf(mock)(dpi: 200, outputPath: '/tmp/out.pdf');
      expect(mock.wasCalled, isTrue);
      expect(mock.capturedDpi, 200);
      expect(mock.capturedPath, '/tmp/out.pdf');
    });

    test('propagates exporter exceptions', () async {
      final bad = _ThrowingExporter();
      final useCase = ExportToNewPdf(bad);
      expect(
        () => useCase(dpi: 150, outputPath: '/tmp/fail.pdf'),
        throwsA(isA<StateError>()),
      );
    });
  });
}

class _ThrowingExporter implements PdfExporter {
  @override
  Future<void> export({required int dpi, required String outputPath}) {
    throw StateError('Export failed intentionally.');
  }

  @override
  Future<Uint8List> buildBytes({required int dpi}) {
    throw StateError('Export failed intentionally.');
  }
}
