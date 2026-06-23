import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart' as pdflib;
import 'package:pdf/widgets.dart' as pw;
// Hide PdfPoint to avoid collision with pdf package's PdfPoint (pdflib.PdfPoint).
// PdfDocument from this import is pdfrx's; pdflib.PdfDocument is the output PDF.
import 'package:pdfrx/pdfrx.dart' hide PdfPoint;

import '../../../../features/annotation/domain/entities/annotation.dart';
import '../../../../services/font_registry/font_registry.dart';
import '../../domain/repositories/pdf_exporter.dart';

/// Opción A export (ROADMAP §2.4):
///  1. Rasterise each page at [dpi] using pdfrx.
///  2. Build a new PDF with the `pdf` package, placing the raster as background.
///  3. Draw all annotations on top in PDF-point coordinates.
///  4. Write the result to [outputPath] — original file is never touched.
///
/// Fonts from the curated set (ROADMAP §2.5) are embedded using their TTF
/// assets so they display correctly in other PDF readers.
class RasterPdfExporter implements PdfExporter {
  const RasterPdfExporter({
    required this.document,
    required this.annotations,
  });

  final PdfDocument document;
  final List<Annotation> annotations;

  @override
  Future<void> export({required int dpi, required String outputPath}) async {
    final bytes = await buildBytes(dpi: dpi);
    await File(outputPath).writeAsBytes(bytes);
  }

  @override
  Future<Uint8List> buildBytes({required int dpi}) async {
    // Preload and embed all curated fonts
    final Map<String, pw.Font> fonts = {};
    for (final family in FontRegistry.curado) {
      final data = await rootBundle.load(family.assetPath);
      fonts[family.family] = pw.Font.ttf(data);
    }

    final pdfDoc = pw.Document(compress: true);
    final rasterScale = dpi / 72.0;

    for (int i = 0; i < document.pages.length; i++) {
      final page = document.pages[i];
      final pageNum = i + 1;
      final pageW = page.width;
      final pageH = page.height;

      // Rasterise original page at target DPI
      final pdfImage = await page.render(
        fullWidth: pageW * rasterScale,
        fullHeight: pageH * rasterScale,
      );
      if (pdfImage == null) continue;

      Uint8List? pngBytes;
      ui.Image? uiImage;
      try {
        uiImage = await pdfImage.createImage();
        final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
        pngBytes = byteData?.buffer.asUint8List();
      } finally {
        uiImage?.dispose();
        pdfImage.dispose();
      }
      if (pngBytes == null) continue;

      final bgImage = pw.MemoryImage(pngBytes);
      final pageAnnotations =
          annotations.where((a) => a.pageNumber == pageNum).toList();

      pdfDoc.addPage(
        pw.Page(
          pageFormat: pdflib.PdfPageFormat(pageW, pageH),
          margin: pw.EdgeInsets.zero,
          build: (context) => _buildPage(
            bgImage: bgImage,
            pageW: pageW,
            pageH: pageH,
            pageAnnotations: pageAnnotations,
            fonts: fonts,
          ),
        ),
      );
    }

    return pdfDoc.save();
  }

  // ---------------------------------------------------------------------------
  // Page builder
  // ---------------------------------------------------------------------------

  pw.Widget _buildPage({
    required pw.MemoryImage bgImage,
    required double pageW,
    required double pageH,
    required List<Annotation> pageAnnotations,
    required Map<String, pw.Font> fonts,
  }) {
    // pw.Stack uses Flutter-like coordinates: top-left origin, Y down.
    // pw.CustomPaint (PdfGraphics) uses PDF-native: bottom-left origin, Y up.
    // → strokes flip Y: pdf_y = pageH - point.y

    return pw.Stack(
      children: [
        // 1. Rasterised background filling the full page
        pw.Image(bgImage, width: pageW, height: pageH, fit: pw.BoxFit.fill),

        // 2. Highlight annotations (semi-transparent, below other annotations)
        for (final a in pageAnnotations.whereType<HighlightAnnotation>())
          pw.Positioned(
            left: a.rect.x,
            top: a.rect.y,
            child: pw.Container(
              width: a.rect.width,
              height: a.rect.height,
              color: _argbToPdfColor(a.colorArgb, a.opacity),
            ),
          ),

        // 3. Rect ("tipp-ex") annotations — opaque boxes
        for (final a in pageAnnotations.whereType<RectAnnotation>())
          pw.Positioned(
            left: a.rect.x,
            top: a.rect.y,
            child: pw.Container(
              width: a.rect.width,
              height: a.rect.height,
              color: _argbToPdfColor(a.colorArgb, a.opacity),
            ),
          ),

        // 4. Text annotations with embedded TTF fonts
        for (final a in pageAnnotations.whereType<TextAnnotation>())
          pw.Positioned(
            left: a.rect.x,
            top: a.rect.y,
            child: pw.Text(
              a.text,
              style: pw.TextStyle(
                font: fonts[a.fontFamily],
                fontSize: a.fontSize,
                color: _argbToPdfColor(a.colorArgb, 1.0),
              ),
            ),
          ),

        // 5. Freehand strokes — full-page CustomPaint on top.
        //    PdfGraphics origin = bottom-left → flip Y: pdf_y = size.y - our_y.
        if (pageAnnotations.any((a) => a is StrokeAnnotation))
          pw.CustomPaint(
            size: pdflib.PdfPoint(pageW, pageH),
            painter: (canvas, size) {
              for (final a
                  in pageAnnotations.whereType<StrokeAnnotation>()) {
                if (a.points.length < 2) continue;
                canvas
                  ..setStrokeColor(_argbToPdfColor(a.colorArgb, 1.0))
                  ..setLineWidth(a.strokeWidth)
                  ..setLineCap(pdflib.PdfLineCap.round)
                  ..setLineJoin(pdflib.PdfLineJoin.round);
                final first = a.points.first;
                canvas.moveTo(first.x, size.y - first.y);
                for (int j = 1; j < a.points.length; j++) {
                  final p = a.points[j];
                  canvas.lineTo(p.x, size.y - p.y);
                }
                canvas.strokePath();
              }
            },
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Convert a Flutter ARGB integer + explicit opacity to [pdflib.PdfColor].
  static pdflib.PdfColor _argbToPdfColor(int argb, double opacity) {
    final r = ((argb >> 16) & 0xFF) / 255.0;
    final g = ((argb >> 8) & 0xFF) / 255.0;
    final b = (argb & 0xFF) / 255.0;
    return pdflib.PdfColor(r, g, b, opacity);
  }
}
