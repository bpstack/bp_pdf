sealed class PdfFailure implements Exception {
  const PdfFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

class PdfCancelledByUser extends PdfFailure {
  const PdfCancelledByUser() : super('Operación cancelada por el usuario.');
}

class PdfInvalidFile extends PdfFailure {
  const PdfInvalidFile(super.message);
}

class PdfIoError extends PdfFailure {
  const PdfIoError(super.message);
}

class PdfPageOutOfRange extends PdfFailure {
  const PdfPageOutOfRange(this.pageNumber, this.maxPage)
      : super('Página $pageNumber fuera de rango (1..$maxPage).');
  final int pageNumber;
  final int maxPage;
}
