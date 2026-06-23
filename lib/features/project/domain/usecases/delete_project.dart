import '../repositories/project_repository.dart';

class DeleteProject {
  const DeleteProject(this._repo);
  final ProjectRepository _repo;

  Future<void> call(String id) => _repo.deleteProject(id);
}
