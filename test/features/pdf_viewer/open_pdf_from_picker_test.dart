import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:bp_pdf/core/result/result.dart';
import 'package:bp_pdf/features/pdf_viewer/domain/entities/pdf_failure.dart';
import 'package:bp_pdf/features/pdf_viewer/domain/entities/pdf_session.dart';
import 'package:bp_pdf/features/pdf_viewer/domain/repositories/pdf_repository.dart';
import 'package:bp_pdf/features/pdf_viewer/domain/usecases/open_pdf_from_picker.dart';
import 'package:bp_pdf/services/file_service/file_service.dart';

class _StubFileService implements FileService {
  _StubFileService(this._file);
  final PickedFile? _file;

  int calls = 0;

  @override
  Future<PickedFile?> pickPdf() async {
    calls++;
    return _file;
  }
}

class _FakeRepository implements PdfRepository {
  _FakeRepository(this._sessionToReturn);
  final PdfSession? _sessionToReturn;
  String? lastPath;
  Uint8List? lastBytes;
  String? lastDisplayName;
  bool openedFromPath = false;
  bool openedFromBytes = false;

  @override
  Future<Result<PdfSession>> openPdfFromPath(String path, {String? displayName, String? projectId}) async {
    openedFromPath = true;
    lastPath = path;
    lastDisplayName = displayName;
    return _sessionToReturn == null
        ? const Failure<PdfSession>(PdfInvalidFile('fake'))
        : Success<PdfSession>(_sessionToReturn);
  }

  @override
  Future<Result<PdfSession>> openPdfFromBytes(Uint8List bytes, {required String displayName}) async {
    openedFromBytes = true;
    lastBytes = bytes;
    lastDisplayName = displayName;
    return _sessionToReturn == null
        ? const Failure<PdfSession>(PdfInvalidFile('fake'))
        : Success<PdfSession>(_sessionToReturn);
  }

  @override
  Future<void> close() async {}
  @override
  bool get isOpen => true;
  @override
  Uint8List? get currentSourceBytes => lastBytes;
  @override
  Future<Uint8List?> renderThumbnail({required int pageNumber, int maxPixelSize = 120}) async => null;
}

void main() {
  group('OpenPdfFromPicker', () {
    test('returns PdfCancelledByUser when user cancels the picker', () async {
      final fileService = _StubFileService(null);
      final repo = _FakeRepository(null);
      final useCase = OpenPdfFromPicker(fileService, repo);

      final result = await useCase();

      expect(result.isFailure, isTrue);
      result.when(
        success: (_) => fail('expected failure'),
        failure: (e) => expect(e, isA<PdfCancelledByUser>()),
      );
      expect(fileService.calls, 1);
      expect(repo.openedFromPath, isFalse);
      expect(repo.openedFromBytes, isFalse);
    });

    test('delegates to openPdfFromPath when the file has a real path', () async {
      final fileService = _StubFileService(
        PickedFile(
          bytes: Uint8List.fromList(<int>[1, 2, 3]),
          displayName: 'demo.pdf',
          path: 'C:/tmp/demo.pdf',
        ),
      );
      final session = PdfSession(
        sourceName: 'demo.pdf',
        pageCount: 1,
        pages: const <PdfPageInfo>[
          PdfPageInfo(pageNumber: 1, widthPoints: 595, heightPoints: 842),
        ],
      );
      final repo = _FakeRepository(session);
      final useCase = OpenPdfFromPicker(fileService, repo);

      final result = await useCase();

      expect(result.isSuccess, isTrue);
      expect(repo.openedFromPath, isTrue);
      expect(repo.openedFromBytes, isFalse);
      expect(repo.lastPath, 'C:/tmp/demo.pdf');
      expect(repo.lastDisplayName, 'demo.pdf');
    });

    test('delegates to openPdfFromBytes when the file has no path (Android SAF)', () async {
      final fileService = _StubFileService(
        PickedFile(
          bytes: Uint8List.fromList(<int>[1, 2, 3]),
          displayName: 'saf.pdf',
        ),
      );
      final session = PdfSession(
        sourceName: 'saf.pdf',
        pageCount: 2,
        pages: const <PdfPageInfo>[
          PdfPageInfo(pageNumber: 1, widthPoints: 595, heightPoints: 842),
          PdfPageInfo(pageNumber: 2, widthPoints: 595, heightPoints: 842),
        ],
      );
      final repo = _FakeRepository(session);
      final useCase = OpenPdfFromPicker(fileService, repo);

      final result = await useCase();

      expect(result.isSuccess, isTrue);
      expect(repo.openedFromPath, isFalse);
      expect(repo.openedFromBytes, isTrue);
      expect(repo.lastBytes, isNotNull);
      expect(repo.lastDisplayName, 'saf.pdf');
    });
  });
}
