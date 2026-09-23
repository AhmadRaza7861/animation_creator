import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/core/utils/app_path_provider.dart';
import 'package:dummy/features/projects/data/project_repository.dart';
import 'package:dummy/features/projects/domain/project_model.dart';
import 'package:dummy/features/editor/presentation/controllers/editor_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Project Persistence & Auto-Save Tests', () {
    late ProjectRepository repository;

    setUp(() {
      repository = ProjectRepository();
    });

    test('ProjectRepository saves, flushes, and loads a project correctly', () async {
      final Map<String, dynamic> state = {
        'aspectRatio': 1.0,
        'fps': 9,
        'projectName': 'Test Animation',
        'exportType': 'Mp4',
        'canvases': [],
      };

      final projectId = await repository.saveProject(
        title: 'Test Animation',
        state: state,
        thumbnailBytes: [0, 1, 2, 3],
      );

      expect(projectId, isNotEmpty);

      // Load project
      final loaded = await repository.loadProject(projectId);
      expect(loaded, isNotNull);
      expect(loaded!.meta.title, 'Test Animation');
      expect(loaded.meta.id, projectId);
      expect(loaded.state['fps'], 9);

      // Verify listProjects keeps blank projects intact
      final projects = await repository.listProjects();
      expect(projects.any((p) => p.id == projectId), isTrue);

      // Clean up
      await repository.deleteProject(projectId);
    });

    test('ProjectRepository loadProject falls back to tmp files if main files missing', () async {
      final docsDir = await AppPathProvider.getSafeDocumentsDirectory();
      final testId = 'recovery_test_project';
      final projDir = Directory('${docsDir.path}/drawing_projects/$testId');
      if (await projDir.exists()) {
        await projDir.delete(recursive: true);
      }
      await projDir.create(recursive: true);

      final meta = ProjectMeta(
        id: testId,
        title: 'Recovered Project',
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
        fps: 12,
        frameCount: 1,
      );

      final metaTmp = File('${projDir.path}/meta.json.tmp');
      final dataTmp = File('${projDir.path}/data.json.tmp');

      await metaTmp.writeAsString(jsonEncode(meta.toJson()), flush: true);
      await dataTmp.writeAsString(jsonEncode({'recovered': true}), flush: true);

      final loaded = await repository.loadProject(testId);
      expect(loaded, isNotNull);
      expect(loaded!.meta.title, 'Recovered Project');
      expect(loaded.state['recovered'], isTrue);

      await repository.deleteProject(testId);
    });

    test('EditorController markDirty flags dirty state and schedules auto-save', () async {
      final controller = EditorController(repository: repository);
      expect(controller.isDirty, isFalse);

      controller.markDirty();
      expect(controller.isDirty, isTrue);

      // Initial save without drawing should NOT delete project
      controller.projectName = 'Persistent Test';
      await controller.saveProject();
      expect(controller.isDirty, isFalse);

      final projects = await repository.listProjects();
      final matching = projects.firstWhere((p) => p.title == 'Persistent Test');
      expect(matching, isNotNull);

      final loaded = await repository.loadProject(matching.id);
      expect(loaded, isNotNull);
      expect(loaded!.meta.title, 'Persistent Test');

      await repository.deleteProject(matching.id);
      controller.dispose();
    });

    test('EditorController safely recovers and opens project with missing/deleted background image', () async {
      final String nonExistentPath =
          '/data/user/0/com.flipbook.draw.animation/cache/cropped_bg_9999999999999.png';

      final Map<String, dynamic> stateWithMissingBg = {
        'aspectRatio': 1.0,
        'fps': 12,
        'projectName': 'Missing Bg Test',
        'globalBackground': {
          'color': 0xFFFFFFFF,
          'imagePath': nonExistentPath,
          'imageOpacity': 1.0,
          'pattern': null,
        },
        'canvases': [
          {
            'size': null,
            'backgroundColor': 0xFFFFFFFF,
            'layers': [
              {
                'id': 'layer_0',
                'name': 'Layer 1',
                'isVisible': true,
                'isLocked': false,
                'opacity': 1.0,
                'blendMode': 3,
                'currentIndex': 0,
                'history': [],
              }
            ],
            'activeLayerId': 'layer_0',
          }
        ],
      };

      final projectId = await repository.saveProject(
        title: 'Missing Bg Test',
        state: stateWithMissingBg,
      );

      final controller = EditorController(
        projectId: projectId,
        repository: repository,
      );

      // Should complete initialization without hanging or crashing
      await controller.loadProjectData();
      expect(controller.canvases.length, 1);
      expect(controller.globalBackground.image, isNull);

      await repository.deleteProject(projectId);
      controller.dispose();
    });

    test('ProjectRepository relocates external background image into project assets directory', () async {
      final docsDir = await AppPathProvider.getSafeDocumentsDirectory();
      final tempAsset = File('${docsDir.path}/temp_sample_bg.png');
      await tempAsset.writeAsBytes([1, 2, 3, 4], flush: true);

      final Map<String, dynamic> state = {
        'aspectRatio': 1.0,
        'fps': 12,
        'globalBackground': {
          'color': 0xFFFFFFFF,
          'imagePath': tempAsset.path,
          'imageOpacity': 1.0,
          'pattern': null,
        },
        'canvases': [],
      };

      final projectId = await repository.saveProject(
        title: 'Relocate Asset Test',
        state: state,
      );

      final loaded = await repository.loadProject(projectId);
      expect(loaded, isNotNull);
      final bgPath = loaded!.state['globalBackground']?['imagePath'] as String?;
      expect(bgPath, isNotNull);
      expect(bgPath!.contains('drawing_projects/$projectId/assets'), isTrue);
      expect(File(bgPath).existsSync(), isTrue);

      if (await tempAsset.exists()) {
        await tempAsset.delete();
      }
      await repository.deleteProject(projectId);
    });
  });
}

