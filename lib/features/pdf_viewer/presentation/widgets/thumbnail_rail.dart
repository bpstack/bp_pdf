import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/pdf_session_provider.dart';
import '../providers/thumbnail_provider.dart';
import '../providers/viewer_controller_provider.dart';
import '../providers/viewer_state_providers.dart';

/// Left sidebar with one thumbnail per page of the open document.
///
/// Tapping a thumbnail tells the viewer to jump to that page. Each
/// thumbnail is rendered on demand by the [thumbnailProvider] family.
class ThumbnailRail extends ConsumerWidget {
  const ThumbnailRail({super.key, this.width = 120});

  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(pdfSessionProvider);
    if (session == null) return const SizedBox.shrink();

    final current = ref.watch(currentPageProvider);

    return Container(
      width: width,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: session.pageCount,
        itemBuilder: (context, i) {
          final pageNumber = i + 1;
          final isActive = pageNumber == current;
          return _ThumbnailTile(
            pageNumber: pageNumber,
            isActive: isActive,
            width: width,
            onTap: () {
              final c = ref.read(viewerControllerProvider);
              c?.goToPage(pageNumber: pageNumber);
            },
          );
        },
      ),
    );
  }
}

class _ThumbnailTile extends ConsumerWidget {
  const _ThumbnailTile({
    required this.pageNumber,
    required this.isActive,
    required this.width,
    required this.onTap,
  });

  final int pageNumber;
  final bool isActive;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bytes = ref.watch(thumbnailProvider(pageNumber));
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      child: Material(
        color: isActive ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 0.75,
                  child: Container(
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      border: Border.all(color: scheme.outlineVariant),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: bytes.when(
                      data: (png) => png == null
                          ? const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(4),
                              child: Image.memory(png, fit: BoxFit.contain),
                            ),
                      loading: () => const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (_, _) => const Icon(Icons.broken_image, size: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$pageNumber',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
