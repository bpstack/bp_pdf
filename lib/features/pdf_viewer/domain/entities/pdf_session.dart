/// Lightweight reference to an open PDF document in a session.
///
/// Holds identifying metadata (name, page count) and the resolved page
/// metadata. The actual document bytes/lifecycle live in the data layer.
///
/// [sourcePath] is the filesystem path used to open the document. It is
/// `null` on Android SAF (bytes-only path) and when the PDF was opened from
/// app-internal project storage. [projectId] is set when the session was
/// restored from a saved project (enables overwrite on subsequent save).
class PdfSession {
  const PdfSession({
    required this.sourceName,
    required this.pageCount,
    required this.pages,
    this.sourcePath,
    this.projectId,
  });

  final String sourceName;
  final int pageCount;
  final List<PdfPageInfo> pages;

  /// Absolute filesystem path of the opened file, or `null`.
  final String? sourcePath;

  /// Project UUID if this session was opened from a saved project.
  final String? projectId;

  PdfPageInfo pageAt(int oneBasedPageNumber) {
    assert(oneBasedPageNumber >= 1 && oneBasedPageNumber <= pageCount);
    return pages[oneBasedPageNumber - 1];
  }
}

class PdfPageInfo {
  const PdfPageInfo({
    required this.pageNumber,
    required this.widthPoints,
    required this.heightPoints,
  });

  final int pageNumber;
  final double widthPoints;
  final double heightPoints;
}
