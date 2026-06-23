import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/viewer_controller_provider.dart';
import '../providers/viewer_state_providers.dart';

/// Compact page navigation: previous, "N / M", next, and a jump-to-page
/// field. Disabled when no document is open.
class PageNavigationBar extends ConsumerWidget {
  const PageNavigationBar({super.key, required this.totalPages});

  final int totalPages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentPageProvider);
    final controller = ref.watch(viewerControllerProvider);
    final hasDoc = totalPages > 0 && controller != null;
    final canPrev = hasDoc && current > 1;
    final canNext = hasDoc && current < totalPages;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Página anterior',
          icon: const Icon(Icons.chevron_left),
          onPressed: !canPrev ? null : () => controller.goToPage(pageNumber: current - 1),
        ),
        SizedBox(
          width: 90,
          child: Text(
            hasDoc ? '$current / $totalPages' : '— / —',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        IconButton(
          tooltip: 'Página siguiente',
          icon: const Icon(Icons.chevron_right),
          onPressed: !canNext ? null : () => controller.goToPage(pageNumber: current + 1),
        ),
        IconButton(
          tooltip: 'Ir a página',
          icon: const Icon(Icons.first_page),
          onPressed: !hasDoc ? null : () => _showJumpDialog(context, ref, totalPages),
        ),
      ],
    );
  }

  Future<void> _showJumpDialog(BuildContext context, WidgetRef ref, int max) async {
    final controller = TextEditingController(
      text: ref.read(currentPageProvider).toString(),
    );
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Ir a página'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: '1..$max'),
            onSubmitted: (v) => Navigator.of(ctx).pop(int.tryParse(v)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(int.tryParse(controller.text)),
              child: const Text('Ir'),
            ),
          ],
        );
      },
    );
    if (result != null && result >= 1 && result <= max) {
      final pdfController = ref.read(viewerControllerProvider);
      await pdfController?.goToPage(pageNumber: result);
    }
  }
}
