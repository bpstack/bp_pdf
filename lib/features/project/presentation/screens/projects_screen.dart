import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/project_providers.dart';

/// Full-screen list of saved editing projects.
/// Opens from ViewerScreen via [Navigator.push]; selecting a project loads it
/// and pops back to the viewer.
class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proyectos guardados'),
        actions: [
          IconButton(
            tooltip: 'Actualizar lista',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(projectsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error al cargar proyectos: $e',
              style: const TextStyle(color: Colors.red)),
        ),
        data: (projects) {
          if (projects.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_open, size: 72, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No hay proyectos guardados.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Abre un PDF y usa "Guardar proyecto" para crear uno.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: projects.length,
            separatorBuilder: (context, i) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final project = projects[index];
              final dateStr = _formatDate(project.savedAt);
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf, size: 40),
                  title: Text(project.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '$dateStr  •  ${project.pageCount} pág.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton(
                        onPressed: () => _openProject(context, ref, index),
                        child: const Text('Abrir'),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'Eliminar proyecto',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            _confirmDelete(context, ref, project.id, project.name),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openProject(
      BuildContext context, WidgetRef ref, int index) async {
    final projects = ref.read(projectsProvider).value;
    if (projects == null || index >= projects.length) return;
    final project = projects[index];
    try {
      await ref.read(projectsProvider.notifier).openProject(project);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir proyecto: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar proyecto'),
        content: Text('¿Eliminar "$name"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(projectsProvider.notifier).deleteProject(id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}  '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
