import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/annotation_providers.dart';
import '../../domain/entities/annotation.dart';

// ---------------------------------------------------------------------------
// Public entry point
// ---------------------------------------------------------------------------

/// Right-side contextual properties panel (ROADMAP Fase 6).
///
/// Shows editable defaults for the active annotation tool, or live-editable
/// properties for the currently-selected annotation. Hides itself when there
/// is nothing relevant to display.
class PropertiesPanel extends ConsumerWidget {
  const PropertiesPanel({super.key, this.fillWidth = false});

  /// When true the panel fills its parent instead of using a fixed 200 dp width.
  /// Use this inside a modal bottom sheet.
  final bool fillWidth;

  static const double _kWidth = 200;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tool = ref.watch(annotationToolProvider);
    final selectedId = ref.watch(selectedAnnotationProvider);

    // Determine what content to show
    final String? title;
    final Widget? body;

    switch (tool) {
      case AnnotationTool.addText:
        title = 'Estilo de texto';
        body = const _TextDefaults();
      case AnnotationTool.addRect:
        title = 'Tipp-ex';
        body = const _RectDefaults();
      case AnnotationTool.addHighlight:
        title = 'Resaltado';
        body = const _HighlightDefaults();
      case AnnotationTool.addStroke:
        title = 'Trazo';
        body = const _StrokeDefaults();
      case AnnotationTool.pan:
        title = null;
        body = null;
      case AnnotationTool.select:
        if (selectedId != null) {
          final ann = ref
              .watch(annotationsProvider)
              .where((a) => a.id == selectedId)
              .firstOrNull;
          if (ann != null) {
            title = _titleForAnnotation(ann);
            body = _SelectedAnnotationProps(annotation: ann);
          } else {
            title = null;
            body = null;
          }
        } else {
          title = null;
          body = null;
        }
    }

    if (body == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final inner = Container(
      color: scheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: fillWidth ? MainAxisSize.min : MainAxisSize.max,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600),
              ),
            ),
          const Divider(height: 1),
          if (fillWidth)
            Padding(padding: const EdgeInsets.all(10), child: body)
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(10),
                child: body,
              ),
            ),
        ],
      ),
    );
    return fillWidth ? inner : SizedBox(width: _kWidth, child: inner);
  }

  static String _titleForAnnotation(Annotation a) => switch (a) {
        TextAnnotation() => 'Texto',
        RectAnnotation() => 'Tipp-ex',
        HighlightAnnotation() => 'Resaltado',
        StrokeAnnotation() => 'Trazo',
      };
}

// ---------------------------------------------------------------------------
// Tool defaults
// ---------------------------------------------------------------------------

class _TextDefaults extends ConsumerWidget {
  const _TextDefaults();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(textStyleProvider);
    final n = ref.read(textStyleProvider.notifier);
    return _PropsColumn(children: [
      _FontFamilyRow(
        current: s.fontFamily,
        onChange: n.setFontFamily,
      ),
      _FontSizeRow(
        current: s.fontSize,
        onChange: n.setFontSize,
      ),
      _ColorRow(
        label: 'Color',
        argb: s.colorArgb,
        onChange: n.setColor,
      ),
    ]);
  }
}

class _RectDefaults extends ConsumerWidget {
  const _RectDefaults();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(rectStyleProvider);
    final n = ref.read(rectStyleProvider.notifier);
    return _PropsColumn(children: [
      _ColorRow(label: 'Color', argb: s.colorArgb, onChange: n.setColor),
      _SliderRow(
        label: 'Opacidad',
        value: s.opacity,
        min: 0.05,
        max: 1.0,
        displayPercent: true,
        onChange: n.setOpacity,
      ),
    ]);
  }
}

class _HighlightDefaults extends ConsumerWidget {
  const _HighlightDefaults();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(highlightStyleProvider);
    final n = ref.read(highlightStyleProvider.notifier);
    return _PropsColumn(children: [
      _ColorRow(label: 'Color', argb: s.colorArgb, onChange: n.setColor),
      _SliderRow(
        label: 'Opacidad',
        value: s.opacity,
        min: 0.05,
        max: 1.0,
        displayPercent: true,
        onChange: n.setOpacity,
      ),
    ]);
  }
}

class _StrokeDefaults extends ConsumerWidget {
  const _StrokeDefaults();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(strokeStyleProvider);
    final n = ref.read(strokeStyleProvider.notifier);
    return _PropsColumn(children: [
      _ColorRow(label: 'Color', argb: s.colorArgb, onChange: n.setColor),
      _SliderRow(
        label: 'Grosor',
        value: s.strokeWidth,
        min: 1.0,
        max: 12.0,
        onChange: n.setWidth,
      ),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Selected annotation (live edit)
// ---------------------------------------------------------------------------

class _SelectedAnnotationProps extends ConsumerWidget {
  const _SelectedAnnotationProps({required this.annotation});
  final Annotation annotation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(annotationsProvider.notifier);

    switch (annotation) {
      case TextAnnotation(:final fontFamily, :final fontSize, :final colorArgb):
        return _PropsColumn(children: [
          _FontFamilyRow(
            current: fontFamily,
            onChange: (v) => notifier.updateLocal(
              (annotation as TextAnnotation).copyWith(fontFamily: v),
            ),
          ),
          _FontSizeRow(
            current: fontSize,
            onChange: (v) => notifier.updateLocal(
              (annotation as TextAnnotation).copyWith(fontSize: v),
            ),
          ),
          _ColorRow(
            label: 'Color',
            argb: colorArgb,
            onChange: (v) => notifier.updateLocal(
              (annotation as TextAnnotation).copyWith(colorArgb: v),
            ),
          ),
        ]);

      case RectAnnotation(:final colorArgb, :final opacity):
        return _PropsColumn(children: [
          _ColorRow(
            label: 'Color',
            argb: colorArgb,
            onChange: (v) => notifier.updateLocal(
              (annotation as RectAnnotation).copyWith(colorArgb: v),
            ),
          ),
          _SliderRow(
            label: 'Opacidad',
            value: opacity,
            min: 0.05,
            max: 1.0,
            displayPercent: true,
            onChange: (v) => notifier.updateLocal(
              (annotation as RectAnnotation).copyWith(opacity: v),
            ),
          ),
        ]);

      case HighlightAnnotation(:final colorArgb, :final opacity):
        return _PropsColumn(children: [
          _ColorRow(
            label: 'Color',
            argb: colorArgb,
            onChange: (v) => notifier.updateLocal(
              (annotation as HighlightAnnotation).copyWith(colorArgb: v),
            ),
          ),
          _SliderRow(
            label: 'Opacidad',
            value: opacity,
            min: 0.05,
            max: 1.0,
            displayPercent: true,
            onChange: (v) => notifier.updateLocal(
              (annotation as HighlightAnnotation).copyWith(opacity: v),
            ),
          ),
        ]);

      case StrokeAnnotation(:final colorArgb, :final strokeWidth):
        return _PropsColumn(children: [
          _ColorRow(
            label: 'Color',
            argb: colorArgb,
            onChange: (v) => notifier.updateLocal(
              (annotation as StrokeAnnotation).copyWith(colorArgb: v),
            ),
          ),
          _SliderRow(
            label: 'Grosor',
            value: strokeWidth,
            min: 1.0,
            max: 12.0,
            onChange: (v) => notifier.updateLocal(
              (annotation as StrokeAnnotation).copyWith(strokeWidth: v),
            ),
          ),
        ]);
    }
  }
}

// ---------------------------------------------------------------------------
// Reusable control widgets
// ---------------------------------------------------------------------------

class _PropsColumn extends StatelessWidget {
  const _PropsColumn({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children
          .expand((w) => [w, const SizedBox(height: 12)])
          .toList()
        ..removeLast(),
    );
  }
}

// Color palette shared across all color pickers.
const List<int> _kPalette = <int>[
  0xFF000000, 0xFF424242, 0xFF757575, 0xFFFFFFFF,
  0xFFE53935, 0xFFFB8C00, 0xFFFDD835, 0xFF43A047,
  0xFF1E88E5, 0xFF039BE5, 0xFF5E35B1, 0xFFD81B60,
  0xFF6D4C41, 0xFF00897B, 0xFF3949AB, 0xFF00ACC1,
];

/// Labelled color swatch that opens a compact colour-picker dialog.
class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.label,
    required this.argb,
    required this.onChange,
  });

  final String label;
  final int argb;
  final void Function(int argb) onChange;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: Theme.of(context).textTheme.bodySmall),
        ),
        GestureDetector(
          onTap: () => _pick(context),
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Color(argb),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await showDialog<int>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: SizedBox(
          width: 200,
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _kPalette
                .map(
                  (c) => GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(c),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(c),
                        border: Border.all(
                          color: c == argb
                              ? Theme.of(ctx).colorScheme.primary
                              : Theme.of(ctx).colorScheme.outline,
                          width: c == argb ? 2.5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
    if (picked != null) onChange(picked);
  }
}

/// Labelled slider. [displayPercent] formats value as 0–100%.
class _SliderRow extends StatefulWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChange,
    this.displayPercent = false,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final bool displayPercent;
  final void Function(double) onChange;

  @override
  State<_SliderRow> createState() => _SliderRowState();
}

class _SliderRowState extends State<_SliderRow> {
  late double _local;

  @override
  void initState() {
    super.initState();
    _local = widget.value;
  }

  @override
  void didUpdateWidget(_SliderRow old) {
    super.didUpdateWidget(old);
    // Sync from provider if changed externally (e.g. undo)
    if ((old.value - widget.value).abs() > 0.001) {
      _local = widget.value;
    }
  }

  String get _display => widget.displayPercent
      ? '${(_local * 100).round()}%'
      : _local.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(widget.label,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
            Text(_display,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    )),
          ],
        ),
        Slider(
          value: _local,
          min: widget.min,
          max: widget.max,
          onChanged: (v) => setState(() => _local = v),
          onChangeEnd: widget.onChange, // commit + undo snapshot on release
        ),
      ],
    );
  }
}

/// Dropdown for font family.
class _FontFamilyRow extends ConsumerWidget {
  const _FontFamilyRow({
    required this.current,
    required this.onChange,
  });

  final String current;
  final void Function(String) onChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fonts = ref.watch(curadoFontsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fuente', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        DropdownButton<String>(
          value: current,
          isExpanded: true,
          isDense: true,
          onChanged: (v) {
            if (v != null) onChange(v);
          },
          items: fonts
              .map(
                (f) => DropdownMenuItem<String>(
                  value: f.family,
                  child: Text(f.family,
                      style: TextStyle(fontFamily: f.family, fontSize: 13)),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

/// Number field for font size.
class _FontSizeRow extends StatefulWidget {
  const _FontSizeRow({required this.current, required this.onChange});
  final double current;
  final void Function(double) onChange;

  @override
  State<_FontSizeRow> createState() => _FontSizeRowState();
}

class _FontSizeRowState extends State<_FontSizeRow> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.current.round().toString());
  }

  @override
  void didUpdateWidget(_FontSizeRow old) {
    super.didUpdateWidget(old);
    if (old.current != widget.current) {
      final t = widget.current.round().toString();
      if (_ctrl.text != t) _ctrl.text = t;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _commit() {
    final v = double.tryParse(_ctrl.text);
    if (v != null && v > 0) widget.onChange(v);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text('Tamaño',
              style: Theme.of(context).textTheme.bodySmall),
        ),
        SizedBox(
          width: 54,
          child: TextField(
            controller: _ctrl,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: Theme.of(context).textTheme.bodySmall,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              border: OutlineInputBorder(),
              suffix: Text('pt'),
            ),
            onSubmitted: (_) => _commit(),
            onEditingComplete: _commit,
          ),
        ),
      ],
    );
  }
}
