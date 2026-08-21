import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../projects/data/project_repository.dart';
import 'editor_controller.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository();
});

final editorControllerProvider = ChangeNotifierProvider.family<EditorController, String?>((ref, projectId) {
  final repo = ref.watch(projectRepositoryProvider);
  final controller = EditorController(repository: repo, projectId: projectId);
  return controller;
});
