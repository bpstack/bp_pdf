import '../entities/edit_project.dart';
import '../repositories/project_repository.dart';

class ListProjects {
  const ListProjects(this._repo);
  final ProjectRepository _repo;

  Future<List<EditProject>> call() => _repo.listProjects();
}
