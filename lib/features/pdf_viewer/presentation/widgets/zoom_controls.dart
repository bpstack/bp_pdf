import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import '../providers/viewer_controller_provider.dart';
import '../providers/viewer_state_providers.dart';

/// Zoom controls driven by pdfrx's REAL absolute scale.
///
/// Both the displayed percentage and the +/- targets are derived from
/// `controller.currentZoom` (the actual on-screen scale), so the number can
/// never desync from the image. 100% == actual size (1:1). The percentage is
/// editable: type a value and press Enter to jump to it. The "fit" button snaps
/// to fit-to-page.
class ZoomControls extends ConsumerWidget {
  const ZoomControls({super.key});

  static const double step = 1.25;
  static const double minZoom = 0.1; // 10%
  static const double maxZoom = 10.0; // 1000%

  static Future<void> zoomTo(PdfViewerController controller, double target) {
    final clamped = target.clamp(minZoom, maxZoom);
    // Instant (no animation): rapid clicks must not queue 200ms tweens.
    return controller.setZoom(
      controller.centerPosition,
      clamped,
      duration: Duration.zero,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(viewerControllerProvider);
    final zoom = ref.watch(currentZoomProvider);
    final page = ref.watch(currentPageProvider);
    final ready = controller != null && zoom > 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Reducir',
          icon: const Icon(Icons.zoom_out),
          onPressed: !ready
              ? null
              : () => zoomTo(controller, controller.currentZoom / step),
        ),
        const SizedBox(width: 4),
        const _ZoomPercentField(),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'Aumentar',
          icon: const Icon(Icons.zoom_in),
          onPressed: !ready
              ? null
              : () => zoomTo(controller, controller.currentZoom * step),
        ),
        IconButton(
          tooltip: 'Ajustar a la página',
          icon: const Icon(Icons.fit_screen),
          onPressed: !ready
              ? null
              : () => controller.goTo(
                  controller.calcMatrixForFit(pageNumber: page < 1 ? 1 : page),
                  duration: Duration.zero,
                ),
        ),
      ],
    );
  }
}

/// Editable zoom percentage. Shows the live scale; typing a number and
/// submitting jumps to that zoom. While focused it does not auto-overwrite what
/// the user is typing.
class _ZoomPercentField extends ConsumerStatefulWidget {
  const _ZoomPercentField();

  @override
  ConsumerState<_ZoomPercentField> createState() => _ZoomPercentFieldState();
}

class _ZoomPercentFieldState extends ConsumerState<_ZoomPercentField> {
  final _controllerText = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      // On losing focus without submitting, resync to the real value.
      if (!_focus.hasFocus) _syncToLive();
    });
  }

  @override
  void dispose() {
    _controllerText.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _syncToLive() {
    final zoom = ref.read(currentZoomProvider);
    _controllerText.text = zoom > 0 ? '${(zoom * 100).round()}' : '';
  }

  void _submit(String raw) {
    final viewer = ref.read(viewerControllerProvider);
    if (viewer == null) return;
    final digits = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    final value = double.tryParse(digits);
    if (value == null || value <= 0) {
      _syncToLive();
      return;
    }
    ZoomControls.zoomTo(viewer, value / 100);
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final zoom = ref.watch(currentZoomProvider);
    final ready = ref.watch(viewerControllerProvider) != null && zoom > 0;

    // Keep the field in sync with the live scale unless the user is editing.
    if (!_focus.hasFocus) {
      final text = ready ? '${(zoom * 100).round()}' : '';
      if (_controllerText.text != text) {
        _controllerText.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }
    }

    return SizedBox(
      width: 64,
      child: TextField(
        controller: _controllerText,
        focusNode: _focus,
        enabled: ready,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        style: Theme.of(context).textTheme.bodySmall,
        decoration: const InputDecoration(
          isDense: true,
          suffixText: '%',
          contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          border: OutlineInputBorder(),
        ),
        onSubmitted: _submit,
        onTapOutside: (_) => _focus.unfocus(),
      ),
    );
  }
}
