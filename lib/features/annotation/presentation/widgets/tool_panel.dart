import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/annotation_providers.dart';

/// Icon toolbar. Vertical (left side) on desktop; horizontal (top) on mobile.
class ToolPanel extends ConsumerWidget {
  const ToolPanel({super.key, this.horizontal = false});

  final bool horizontal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tool = ref.watch(annotationToolProvider);
    final selectedId = ref.watch(selectedAnnotationProvider);
    final undoRedo = ref.watch(undoRedoProvider);
    final scheme = Theme.of(context).colorScheme;

    Widget btn(
      IconData icon,
      String tooltip,
      AnnotationTool t, {
      Color? activeColor,
      String? label,
    }) {
      final active = tool == t;
      final button = Tooltip(
        message: tooltip,
        preferBelow: !horizontal,
        child: IconButton(
          icon: Icon(icon, size: 22),
          isSelected: active,
          selectedIcon: Icon(icon, size: 22, color: activeColor ?? scheme.primary),
          style: IconButton.styleFrom(foregroundColor: scheme.onSurfaceVariant),
          onPressed: () => ref.read(annotationToolProvider.notifier).set(t),
        ),
      );
      if (label == null) return button;
      // Icon + small caption beneath, for the most-used navigation tools.
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          button,
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9,
                height: 1,
                color: active ? (activeColor ?? scheme.primary) : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      );
    }

    Widget iconAction({
      required IconData icon,
      required String tooltip,
      required VoidCallback? onPressed,
    }) {
      return Tooltip(
        message: tooltip,
        preferBelow: !horizontal,
        child: IconButton(
          icon: Icon(icon, size: 22),
          onPressed: onPressed,
          style: IconButton.styleFrom(foregroundColor: scheme.onSurfaceVariant),
        ),
      );
    }

    final items = [
      // Navigation / pan
      btn(Icons.pan_tool_outlined, 'Desplazar / hacer zoom', AnnotationTool.pan,
          label: 'Mover'),
      // Selection
      btn(Icons.pan_tool_alt_outlined, 'Seleccionar · mover', AnnotationTool.select,
          label: 'Seleccionar'),

      if (horizontal) _HDivider(scheme) else _VDivider(scheme),

      // Annotation tools
      btn(Icons.title, 'Añadir texto', AnnotationTool.addText),
      btn(Icons.rectangle_outlined, 'Añadir rect (tipp-ex)', AnnotationTool.addRect),
      btn(Icons.brush_outlined, 'Dibujar a mano alzada', AnnotationTool.addStroke),
      btn(Icons.highlight, 'Resaltar zona', AnnotationTool.addHighlight),

      if (horizontal) _HDivider(scheme) else _VDivider(scheme),

      // History
      iconAction(
        icon: Icons.undo,
        tooltip: 'Deshacer',
        onPressed: undoRedo.canUndo
            ? () => ref.read(annotationsProvider.notifier).undoAnnotations()
            : null,
      ),
      iconAction(
        icon: Icons.redo,
        tooltip: 'Rehacer',
        onPressed: undoRedo.canRedo
            ? () => ref.read(annotationsProvider.notifier).redoAnnotations()
            : null,
      ),

      if (horizontal) _HDivider(scheme) else _VDivider(scheme),

      // Actions
      iconAction(
        icon: Icons.delete_outline,
        tooltip: 'Eliminar selección',
        onPressed: selectedId == null
            ? null
            : () => ref.read(annotationsProvider.notifier).removeLocal(selectedId),
      ),
    ];

    if (horizontal) {
      return Container(
        height: 64,
        color: scheme.surfaceContainerHighest,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [const SizedBox(width: 4), ...items, const SizedBox(width: 4)],
          ),
        ),
      );
    }

    return Container(
      width: 60,
      color: scheme.surfaceContainerHighest,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [const SizedBox(height: 6), ...items, const SizedBox(height: 6)],
      ),
    );
  }
}

class _VDivider extends StatelessWidget {
  const _VDivider(this.scheme);
  final ColorScheme scheme;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Divider(height: 1, indent: 10, endIndent: 10, color: scheme.outlineVariant),
      );
}

class _HDivider extends StatelessWidget {
  const _HDivider(this.scheme);
  final ColorScheme scheme;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: VerticalDivider(width: 1, indent: 8, endIndent: 8, color: scheme.outlineVariant),
      );
}
