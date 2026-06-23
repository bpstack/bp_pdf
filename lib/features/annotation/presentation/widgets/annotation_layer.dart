import 'dart:math' show min, max;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../domain/entities/annotation.dart';
import '../../domain/entities/page_rect.dart';
import '../../domain/entities/pdf_point.dart';
import '../painters/stroke_painter.dart';
import '../providers/annotation_providers.dart';

/// Per-page overlay widget. Returned by [PdfViewerParams.pageOverlaysBuilder]
/// for every visible page; renders all annotations of that page on top of
/// pdfrx's own rendering.
///
/// Text content is entered through a modal dialog (not inline) — editing inside
/// pdfrx's overlay fought pdfrx for keyboard focus, so a dialog (its own focus
/// scope) is reliable. Coordinates are always in PDF points (R5); a single
/// scale factor maps points to overlay pixels.
class AnnotationLayer extends ConsumerStatefulWidget {
  const AnnotationLayer({super.key, required this.page});
  final PdfPage page;

  @override
  ConsumerState<AnnotationLayer> createState() => _AnnotationLayerState();
}

class _AnnotationLayerState extends ConsumerState<AnnotationLayer> {
  PdfPage get page => widget.page;

  // Active resize state — updated on every pointer move, committed on pan end.
  String? _resizingId;
  double _resizeDx = 0;
  double _resizeDy = 0;
  // Pre-resize base (PDF points) captured on pan-start — avoids double-counting delta.
  double _resizeBaseW = 0;
  double _resizeBaseH = 0;

  // Active move (drag) state — lifted here (not local to the annotation widget)
  // so the resize handle, which is a sibling Positioned, follows the annotation
  // live during a drag instead of snapping to the new corner only on release.
  String? _movingId;
  double _moveDx = 0;
  double _moveDy = 0;

  // One GlobalKey per annotation: lets us read the actual rendered size
  // (from the previous frame) to position the resize handle correctly even
  // when the annotation is auto-sized (e.g. text with rect.width == 0).
  final Map<String, GlobalKey> _keys = {};

  GlobalKey _keyFor(String id) => _keys.putIfAbsent(id, GlobalKey.new);

  /// Rendered pixel size of annotation [id] from the previous frame, or null
  /// if the widget hasn't been laid out yet (first frame).
  Size? _renderedSize(String id) {
    final rb = _keys[id]?.currentContext?.findRenderObject() as RenderBox?;
    return rb?.hasSize == true ? rb!.size : null;
  }

  void _onResizeStart(String id, double scale) {
    final a = ref.read(annotationsProvider).where((a) => a.id == id).firstOrNull;
    if (a == null) return;
    final rendered = _renderedSize(id);
    // Capture the base dimensions BEFORE any delta is applied.
    final baseW = a.rect.width > 0
        ? a.rect.width
        : (rendered != null ? rendered.width / scale : 80.0);
    final baseH = a.rect.height > 0
        ? a.rect.height
        : (rendered != null ? rendered.height / scale : 20.0);
    setState(() {
      _resizingId = id;
      _resizeDx = 0;
      _resizeDy = 0;
      _resizeBaseW = baseW;
      _resizeBaseH = baseH;
    });
  }

  void _onResizeUpdate(String id, double dx, double dy) {
    setState(() { _resizeDx += dx; _resizeDy += dy; });
  }

  void _onMoveStart(String id) {
    ref.read(selectedAnnotationProvider.notifier).set(id);
    setState(() { _movingId = id; _moveDx = 0; _moveDy = 0; });
  }

  void _onMoveUpdate(double dx, double dy) {
    setState(() { _moveDx += dx; _moveDy += dy; });
  }

  void _onMoveEnd(String id, double scale) {
    final a = ref.read(annotationsProvider).where((a) => a.id == id).firstOrNull;
    if (a != null && (_moveDx != 0 || _moveDy != 0)) {
      ref.read(annotationsProvider.notifier).moveLocal(
            id,
            a.rect.copyWith(
              x: a.rect.x + _moveDx / scale,
              y: a.rect.y + _moveDy / scale,
            ),
          );
    }
    setState(() { _movingId = null; _moveDx = 0; _moveDy = 0; });
  }

  void _onResizeEnd(String id, double scale) {
    final a = ref.read(annotationsProvider).where((a) => a.id == id).firstOrNull;
    if (a != null) {
      // Text resizes both dims like rect: once resized it becomes a fixed box.
      final newW = (_resizeBaseW + _resizeDx / scale).clamp(20.0, double.infinity);
      final newH = (_resizeBaseH + _resizeDy / scale).clamp(10.0, double.infinity);
      ref.read(annotationsProvider.notifier).moveLocal(
            id, a.rect.copyWith(width: newW, height: newH));
    }
    setState(() { _resizingId = null; _resizeDx = 0; _resizeDy = 0; });
  }

  @override
  Widget build(BuildContext context) {
    final tool = ref.watch(annotationToolProvider);
    final annotations = ref.watch(annotationsForPageProvider(page.pageNumber));
    final selectedId = ref.watch(selectedAnnotationProvider);
    final pageWidth = page.width;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double scale =
            constraints.maxWidth <= 0 ? 1.0 : constraints.maxWidth / pageWidth;

        final cursor = switch (tool) {
          AnnotationTool.addText => SystemMouseCursors.text,
          AnnotationTool.addStroke => SystemMouseCursors.precise,
          AnnotationTool.addRect ||
          AnnotationTool.addHighlight =>
            SystemMouseCursors.cell,
          _ => MouseCursor.defer,
        };

        // pdfrx composes page overlays as siblings ON TOP of its InteractiveViewer
        // (not inside it), and a Stack hit-test stops at the first hit child.
        // So whenever the overlay is hittable, pan/zoom can't reach pdfrx over the
        // page. In the pan/hand tool we make the whole overlay pointer-transparent
        // (IgnorePointer) so pdfrx receives pan AND pinch-zoom over the content;
        // annotation tools keep the overlay active (then pan/zoom needs the hand tool).
        final isPanTool = tool == AnnotationTool.pan;

        return IgnorePointer(
          ignoring: isPanTool,
          child: MouseRegion(
          cursor: cursor,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              // Background tap layer: places new annotations for the add tools,
              // and deselects (tap on empty space) for the select tool. Sits at
              // the bottom of the Stack, so taps on existing annotations hit
              // their own (opaque) GestureDetector first.
              if (tool == AnnotationTool.addText ||
                  tool == AnnotationTool.addRect ||
                  tool == AnnotationTool.addHighlight ||
                  tool == AnnotationTool.select)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) =>
                        _onBackgroundTap(context, details.localPosition, scale),
                    child: const SizedBox.expand(),
                  ),
                ),

              // Existing annotations + resize handles (separate Positioned so
              // they never compete with the move GestureDetector).
              for (final a in annotations) ...[
                _buildPositioned(a, scale, selectedId),
                if (a.id == selectedId &&
                    tool == AnnotationTool.select &&
                    a is! StrokeAnnotation)
                  _buildResizeHandle(a, scale),
              ],

              // Live stroke drawing layer
              if (tool == AnnotationTool.addStroke)
                Positioned.fill(
                  child: _StrokeDrawingLayer(page: page, scale: scale),
                ),
            ],
          ),
          ),
        );
      },
    );
  }

  /// Resize handle as a standalone [Positioned] in the outer Stack.
  /// Keeping it outside [_AnnotationWidget] means it never competes with
  /// the move [GestureDetector] in the gesture arena.
  Widget _buildResizeHandle(Annotation a, double scale) {
    final isResizing = _resizingId == a.id;

    // Prefer the actual rendered pixel size (GlobalKey) so the handle lands
    // exactly at the corner even for auto-sized text (rect.width == 0).
    final rendered = _renderedSize(a.id);

    double effWpx; // effective width in screen pixels
    double effHpx; // effective height in screen pixels

    if (isResizing) {
      // Use the captured base (PDF points) + live delta → convert to pixels.
      effWpx = (_resizeBaseW * scale + _resizeDx).clamp(20.0, double.infinity);
      effHpx = (_resizeBaseH * scale + _resizeDy).clamp(10.0, double.infinity);
    } else {
      // Prefer explicit rect dims; fall back to rendered size only for an
      // auto-sized text box that has not been resized yet (width/height == 0).
      effWpx = a.rect.width > 0 ? a.rect.width * scale : (rendered?.width ?? 80.0);
      effHpx = a.rect.height > 0 ? a.rect.height * scale : (rendered?.height ?? 20.0);
    }

    // Follow the annotation live while it is being dragged.
    final moveOffX = _movingId == a.id ? _moveDx : 0.0;
    final moveOffY = _movingId == a.id ? _moveDy : 0.0;

    // Centre the 14×14 handle on the bottom-right corner.
    final left = (a.rect.x * scale + moveOffX + effWpx - 7).clamp(0.0, double.infinity);
    final top  = (a.rect.y * scale + moveOffY + effHpx - 7).clamp(0.0, double.infinity);

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => _onResizeStart(a.id, scale),
        onPanUpdate: (d) => _onResizeUpdate(a.id, d.delta.dx, d.delta.dy),
        onPanEnd: (_) => _onResizeEnd(a.id, scale),
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.indigoAccent,
            border: Border.all(color: Colors.white, width: 1.5),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  /// Builds a [Positioned] for [a], expanding its dimensions live during resize.
  Widget _buildPositioned(Annotation a, double scale, String? selectedId) {
    final isResizing = _resizingId == a.id;

    double? displayW;
    double? displayH;

    if (a is TextAnnotation) {
      // Auto-size (null) until the user resizes; afterwards it is a fixed box
      // with explicit width AND height, exactly like a rect.
      displayW = isResizing
          ? (_resizeBaseW + _resizeDx / scale).clamp(20.0, double.infinity)
          : (a.rect.width > 0 ? a.rect.width : null);
      displayH = isResizing
          ? (_resizeBaseH + _resizeDy / scale).clamp(10.0, double.infinity)
          : (a.rect.height > 0 ? a.rect.height : null);
    } else {
      displayW = isResizing
          ? (_resizeBaseW + _resizeDx / scale).clamp(10.0, double.infinity)
          : a.rect.width;
      displayH = isResizing
          ? (_resizeBaseH + _resizeDy / scale).clamp(10.0, double.infinity)
          : a.rect.height;
    }

    final moveOffX = _movingId == a.id ? _moveDx : 0.0;
    final moveOffY = _movingId == a.id ? _moveDy : 0.0;

    return Positioned(
      left: a.rect.x * scale + moveOffX,
      top: a.rect.y * scale + moveOffY,
      width: displayW != null ? displayW * scale : null,
      height: displayH != null ? displayH * scale : null,
      child: _AnnotationWidget(
        key: _keyFor(a.id),
        annotation: a,
        scale: scale,
        isSelected: a.id == selectedId,
        autoSizeText: a is TextAnnotation && displayW == null,
        onMoveStart: _onMoveStart,
        onMoveUpdate: _onMoveUpdate,
        onMoveEnd: _onMoveEnd,
      ),
    );
  }

  Future<void> _onBackgroundTap(
    BuildContext context,
    Offset localPosition,
    double scale,
  ) async {
    final tool = ref.read(annotationToolProvider);
    if (tool == AnnotationTool.select) {
      ref.read(selectedAnnotationProvider.notifier).clear();
      return;
    }

    final double xPoints = localPosition.dx / scale;
    final double yPoints = localPosition.dy / scale;
    const double defaultRectW = 150;
    const double defaultRectH = 40;
    final double clampedX = xPoints.clamp(0, page.width.toDouble());
    final double clampedY = yPoints.clamp(0, page.height.toDouble());
    final double clampedRectX = xPoints.clamp(0, page.width - defaultRectW);
    final double clampedRectY = yPoints.clamp(0, page.height - defaultRectH);
    final id = 'a-${DateTime.now().microsecondsSinceEpoch}';

    if (tool == AnnotationTool.addText) {
      final text = await showAnnotationTextDialog(context, initialText: '');
      ref.read(annotationToolProvider.notifier).set(AnnotationTool.select);
      if (text == null || text.trim().isEmpty) return;
      final style = ref.read(textStyleProvider);
      ref.read(annotationsProvider.notifier).addLocal(Annotation.text(
            id: id,
            pageNumber: page.pageNumber,
            rect: PageRect(x: clampedX, y: clampedY, width: 0, height: 0),
            text: text.trim(),
            fontFamily: style.fontFamily,
            fontSize: style.fontSize,
            colorArgb: style.colorArgb,
          ));
      ref.read(selectedAnnotationProvider.notifier).set(id);
    } else if (tool == AnnotationTool.addRect) {
      final style = ref.read(rectStyleProvider);
      ref.read(annotationsProvider.notifier).addLocal(Annotation.rect(
            id: id,
            pageNumber: page.pageNumber,
            rect: PageRect(x: clampedRectX, y: clampedRectY, width: defaultRectW, height: defaultRectH),
            colorArgb: style.colorArgb,
            opacity: style.opacity,
          ));
      ref.read(annotationToolProvider.notifier).set(AnnotationTool.select);
      ref.read(selectedAnnotationProvider.notifier).set(id);
    } else if (tool == AnnotationTool.addHighlight) {
      final style = ref.read(highlightStyleProvider);
      ref.read(annotationsProvider.notifier).addLocal(Annotation.highlight(
            id: id,
            pageNumber: page.pageNumber,
            rect: PageRect(x: clampedRectX, y: clampedRectY, width: defaultRectW, height: defaultRectH),
            colorArgb: style.colorArgb,
            opacity: style.opacity,
          ));
      ref.read(annotationToolProvider.notifier).set(AnnotationTool.select);
      ref.read(selectedAnnotationProvider.notifier).set(id);
    }
  }
}

/// Modal dialog to enter/edit annotation text. Returns the text, or `null` if
/// cancelled. Lives outside pdfrx's focus scope, so typing (incl. Space) works.
Future<String?> showAnnotationTextDialog(
  BuildContext context, {
  required String initialText,
}) {
  return showDialog<String>(
    context: context,
    useRootNavigator: true,
    builder: (_) => _TextInputDialog(initialText: initialText),
  );
}

class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({required this.initialText});
  final String initialText;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Texto'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: null,
        decoration: const InputDecoration(hintText: 'Escribe el texto'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Live stroke drawing
// ---------------------------------------------------------------------------

/// Captures pan gestures and draws the stroke in progress using [InProgressStrokePainter].
/// On pan end, converts screen points to PDF points and commits a [StrokeAnnotation].
/// Stays in [AnnotationTool.addStroke] mode after each stroke so multiple
/// strokes can be drawn without re-selecting the tool.
class _StrokeDrawingLayer extends ConsumerStatefulWidget {
  const _StrokeDrawingLayer({required this.page, required this.scale});

  final PdfPage page;
  final double scale;

  @override
  ConsumerState<_StrokeDrawingLayer> createState() => _StrokeDrawingLayerState();
}

class _StrokeDrawingLayerState extends ConsumerState<_StrokeDrawingLayer> {
  final List<Offset> _screenPoints = [];

  @override
  Widget build(BuildContext context) {
    final strokeStyle = ref.watch(strokeStyleProvider);
    final strokeWidthPx = strokeStyle.strokeWidth * widget.scale;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (d) => setState(() {
        _screenPoints
          ..clear()
          ..add(d.localPosition);
      }),
      onPanUpdate: (d) => setState(() => _screenPoints.add(d.localPosition)),
      onPanEnd: (_) => _commitStroke(),
      child: CustomPaint(
        painter: InProgressStrokePainter(
          points: List<Offset>.from(_screenPoints),
          colorArgb: strokeStyle.colorArgb,
          strokeWidthPx: strokeWidthPx,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  void _commitStroke() {
    if (_screenPoints.length < 2) {
      setState(() => _screenPoints.clear());
      return;
    }

    final scale = widget.scale;
    final page = widget.page;

    // Convert screen pixels → PDF points (page-absolute)
    final pdfPoints = _screenPoints
        .map((p) => PagePoint(x: p.dx / scale, y: p.dy / scale))
        .toList(growable: false);

    // Bounding box with a small padding equal to half stroke width
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final p in pdfPoints) {
      minX = min(minX, p.x);
      minY = min(minY, p.y);
      maxX = max(maxX, p.x);
      maxY = max(maxY, p.y);
    }

    final strokeStyle = ref.read(strokeStyleProvider);
    final pad = strokeStyle.strokeWidth / 2;
    final boxX = (minX - pad).clamp(0.0, page.width);
    final boxY = (minY - pad).clamp(0.0, page.height);
    final boxW = ((maxX - minX + pad * 2)).clamp(1.0, page.width - boxX);
    final boxH = ((maxY - minY + pad * 2)).clamp(1.0, page.height - boxY);

    final id = 'a-${DateTime.now().microsecondsSinceEpoch}';
    ref.read(annotationsProvider.notifier).addLocal(Annotation.stroke(
          id: id,
          pageNumber: page.pageNumber,
          points: pdfPoints,
          rect: PageRect(x: boxX, y: boxY, width: boxW, height: boxH),
          colorArgb: strokeStyle.colorArgb,
          strokeWidth: strokeStyle.strokeWidth,
        ));

    setState(() => _screenPoints.clear());
  }
}

// ---------------------------------------------------------------------------
// Per-annotation widget
// ---------------------------------------------------------------------------

/// A single annotation, positioned and interactive.
///
/// Dragging is reported to the parent ([_AnnotationLayerState]) via callbacks;
/// the parent holds the live drag offset and applies it to both this widget's
/// [Positioned] and the sibling resize handle, so they move together.
class _AnnotationWidget extends ConsumerWidget {
  const _AnnotationWidget({
    super.key,
    required this.annotation,
    required this.scale,
    required this.isSelected,
    required this.autoSizeText,
    required this.onMoveStart,
    required this.onMoveUpdate,
    required this.onMoveEnd,
  });

  final Annotation annotation;
  final double scale;
  final bool isSelected;
  /// True when this TextAnnotation has no explicit width and should auto-size.
  final bool autoSizeText;
  final void Function(String id) onMoveStart;
  final void Function(double dx, double dy) onMoveUpdate;
  final void Function(String id, double scale) onMoveEnd;

  Future<void> _editText(BuildContext context, WidgetRef ref) async {
    final a = annotation;
    if (a is! TextAnnotation) return;
    final text = await showAnnotationTextDialog(context, initialText: a.text);
    if (text == null) return;
    if (text.trim().isEmpty) {
      ref.read(annotationsProvider.notifier).removeLocal(a.id);
    } else {
      ref.read(annotationsProvider.notifier).updateLocal(a.copyWith(text: text.trim()));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tool = ref.watch(annotationToolProvider);
    final a = annotation;
    final canDrag = tool == AnnotationTool.select;

    final Widget visual = switch (a) {
      TextAnnotation(:final fontFamily, :final fontSize, :final colorArgb, :final text) =>
        _TextAnnotationVisual(
          text: text,
          fontFamily: fontFamily,
          fontSize: fontSize * scale,
          colorArgb: colorArgb,
          isSelected: isSelected,
          autoSize: autoSizeText,
        ),
      RectAnnotation(:final colorArgb, :final opacity) => _RectAnnotationVisual(
          colorArgb: colorArgb,
          opacity: opacity,
          isSelected: isSelected,
        ),
      StrokeAnnotation(:final points, :final colorArgb, :final strokeWidth, :final rect) =>
        CustomPaint(
          painter: StrokePainter(
            points: points,
            offsetX: rect.x,
            offsetY: rect.y,
            scale: scale,
            colorArgb: colorArgb,
            strokeWidth: strokeWidth,
          ),
          child: isSelected
              ? Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.indigoAccent, width: 1.5),
                  ),
                )
              : const SizedBox.expand(),
        ),
      HighlightAnnotation(:final colorArgb, :final opacity) => _RectAnnotationVisual(
          colorArgb: colorArgb,
          opacity: opacity,
          isSelected: isSelected,
        ),
    };

    // In pan mode let touches fall through to pdfrx's scroll/pinch handler.
    final isPan = tool == AnnotationTool.pan;

    return GestureDetector(
      behavior: isPan ? HitTestBehavior.translucent : HitTestBehavior.opaque,
      onTap: isPan ? null : () => ref.read(selectedAnnotationProvider.notifier).set(a.id),
      onDoubleTap: isPan || a is! TextAnnotation ? null : () => _editText(context, ref),
      onPanStart: canDrag ? (_) => onMoveStart(a.id) : null,
      onPanUpdate: canDrag ? (d) => onMoveUpdate(d.delta.dx, d.delta.dy) : null,
      onPanEnd: canDrag ? (_) => onMoveEnd(a.id, scale) : null,
      child: visual,
    );
  }
}

// ---------------------------------------------------------------------------
// Visual widgets
// ---------------------------------------------------------------------------

class _TextAnnotationVisual extends StatelessWidget {
  const _TextAnnotationVisual({
    required this.text,
    required this.fontFamily,
    required this.fontSize,
    required this.colorArgb,
    required this.isSelected,
    required this.autoSize,
  });

  final String text;
  final String fontFamily;
  final double fontSize;
  final int colorArgb;
  final bool isSelected;
  /// When true the widget shrink-wraps to fit the text (no explicit parent width).
  /// When false the parent Positioned constrains the width and text wraps within it.
  final bool autoSize;

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      decoration: BoxDecoration(
        border: isSelected
            ? Border.all(color: Colors.indigoAccent, width: 1.5)
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      child: Text(
        text,
        softWrap: true,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSize,
          color: Color(colorArgb),
          height: 1.2,
        ),
      ),
    );
    if (autoSize) {
      return IntrinsicWidth(child: IntrinsicHeight(child: inner));
    }
    // Fixed box (after resize): clip overflowing text to the box bounds.
    return ClipRect(child: inner);
  }
}

class _RectAnnotationVisual extends StatelessWidget {
  const _RectAnnotationVisual({
    required this.colorArgb,
    required this.opacity,
    required this.isSelected,
  });

  final int colorArgb;
  final double opacity;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(colorArgb).withValues(alpha: opacity),
        border: isSelected
            ? Border.all(color: Colors.indigoAccent, width: 1.5)
            : null,
      ),
    );
  }
}
