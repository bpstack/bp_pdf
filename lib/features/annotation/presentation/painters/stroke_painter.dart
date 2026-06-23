import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/entities/pdf_point.dart';

/// Paints a finished [StrokeAnnotation] inside its bounding-box widget.
///
/// [points] are in PDF points, page-absolute. [offsetX]/[offsetY] are the
/// top-left of the bounding box (also in PDF points). The painter subtracts
/// the offset and multiplies by [scale] to get widget-local pixel coords.
class StrokePainter extends CustomPainter {
  const StrokePainter({
    required this.points,
    required this.offsetX,
    required this.offsetY,
    required this.scale,
    required this.colorArgb,
    required this.strokeWidth,
  });

  final List<PagePoint> points;
  final double offsetX;
  final double offsetY;
  final double scale;
  final int colorArgb;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = Color(colorArgb)
      ..strokeWidth = (strokeWidth * scale).clamp(1.0, double.infinity)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = ui.Path();
    final first = points.first;
    path.moveTo((first.x - offsetX) * scale, (first.y - offsetY) * scale);
    for (int i = 1; i < points.length; i++) {
      final p = points[i];
      path.lineTo((p.x - offsetX) * scale, (p.y - offsetY) * scale);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(StrokePainter old) =>
      old.points != points ||
      old.scale != scale ||
      old.colorArgb != colorArgb ||
      old.strokeWidth != strokeWidth;
}

/// Paints a stroke that is still being drawn (points in screen/widget pixels).
class InProgressStrokePainter extends CustomPainter {
  const InProgressStrokePainter({
    required this.points,
    required this.colorArgb,
    required this.strokeWidthPx,
  });

  final List<Offset> points;
  final int colorArgb;
  final double strokeWidthPx;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = Color(colorArgb)
      ..strokeWidth = strokeWidthPx.clamp(1.0, double.infinity)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = ui.Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(InProgressStrokePainter old) =>
      old.points != points ||
      old.colorArgb != colorArgb ||
      old.strokeWidthPx != strokeWidthPx;
}
