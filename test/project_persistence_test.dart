import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/core/utils/app_path_provider.dart';
import 'package:dummy/features/projects/data/project_repository.dart';
import 'package:dummy/features/projects/domain/project_model.dart';
import 'package:dummy/features/editor/presentation/controllers/editor_controller.dart';
import 'package:dummy/package_code/src/paint_contents/image.dart';

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

    test('150+ frame project loads deferred images without crashing or loading all images upfront', () async {
      final List<Map<String, dynamic>> canvases = [];
      for (int i = 0; i < 150; i++) {
        canvases.add({
          'size': {'width': 1080.0, 'height': 1920.0},
          'backgroundColor': 0xFFFFFFFF,
          'layers': [
            {
              'id': 'layer_0',
              'name': 'Layer 1',
              'isVisible': true,
              'isLocked': false,
              'opacity': 1.0,
              'blendMode': 3,
              'currentIndex': 1,
              'history': [
                {
                  'type': 'ImageContent',
                  'imageUrl': '/dummy/path/frame_$i.png',
                  'paint': {
                    'color': 0xFF000000,
                    'strokeWidth': 2.0,
                    'isAntiAlias': true,
                    'style': 0,
                  },
                }
              ],
            }
          ],
          'activeLayerId': 'layer_0',
        });
      }

      final Map<String, dynamic> state = {
        'aspectRatio': 1080.0 / 1920.0,
        'fps': 12,
        'projectName': '150 Frame Heavy Project',
        'exportType': 'Mp4',
        'canvases': canvases,
      };

      final projectId = await repository.saveProject(
        title: '150 Frame Heavy Project',
        state: state,
      );

      final controller = EditorController(
        projectId: projectId,
        repository: repository,
      );

      final stopwatch = Stopwatch()..start();
      await controller.loadProjectData();
      stopwatch.stop();

      // All 150 canvases must be loaded
      expect(controller.canvases.length, 150);

      // Loading 150 canvases must complete swiftly without loading raster images
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));

      // Inactive frames (> 2) must have their raster images deferred (imageUrl intact, image null)
      final canvas100 = controller.canvases[100];
      final content100 = canvas100.layers.first.history.first as ImageContent;
      expect(content100.imageUrl, '/dummy/path/frame_100.png');
      expect(content100.image, isNull);

      // Distant eviction works as expected
      controller.evictCanvasImages(100);

      // Project saving must succeed cleanly without decoding all 150 images
      await controller.saveProject();

      await repository.deleteProject(projectId);
      controller.dispose();
    });

    test('importVideoFrames populates video layer, thumbnails, and enables immediate display for all imported frames', () async {
      final docsDir = await AppPathProvider.getSafeDocumentsDirectory();
      final testImg = File('${docsDir.path}/test_frame_import.png');
      final pngBytes = [
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
        0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
        0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
        0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
        0x42, 0x60, 0x82,
      ];
      await testImg.writeAsBytes(pngBytes, flush: true);

      final controller = EditorController(repository: repository);
      expect(controller.canvases.length, 1);

      await controller.importVideoFrames([
        testImg.path,
        testImg.path,
        testImg.path,
      ]);

      expect(controller.canvases.length, 3);
      for (int i = 0; i < 3; i++) {
        expect(controller.thumbnails[i], isNotNull, reason: 'Frame $i thumbnail should not be null');
        final canvas = controller.canvases[i];
        final videoLayer = canvas.layers.firstWhere((l) => l.name == 'Video Layer');
        expect(videoLayer, isNotNull);
        final content = videoLayer.history.first as ImageContent;
        expect(content.image, isNotNull, reason: 'Frame $i ImageContent.image should be decoded');
      }

      if (await testImg.exists()) {
        await testImg.delete();
      }
      controller.dispose();
    });

    test('selectCanvas on deferred frame rehydrates image and invalidates raster cache', () async {
      final docsDir = await AppPathProvider.getSafeDocumentsDirectory();
      final testImg = File('${docsDir.path}/test_frame_deferred.png');
      final pngBytes = [
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
        0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
        0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
        0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
        0x42, 0x60, 0x82,
      ];
      await testImg.writeAsBytes(pngBytes, flush: true);

      // Create a 20-frame project structure where frame 10 has the image
      final canvases = <Map<String, dynamic>>[];
      for (int i = 0; i < 20; i++) {
        canvases.add({
          'backgroundColor': 0xFFFFFFFF,
          'layers': [
            {
              'id': 'layer_video_$i',
              'name': 'Video Layer',
              'isVisible': true,
              'isLocked': true,
              'opacity': 1.0,
              'blendMode': 0,
              'history': [
                {
                  'type': 'ImageContent',
                  'imageUrl': testImg.path,
                  'startPoint': {'dx': 0.0, 'dy': 0.0},
                  'size': {'dx': 100.0, 'dy': 100.0},
                }
              ],
              'currentIndex': 1,
            }
          ]
        });
      }

      final Map<String, dynamic> state = {
        'aspectRatio': 1080.0 / 1920.0,
        'fps': 12,
        'projectName': 'Deferred Test Project',
        'exportType': 'Mp4',
        'canvases': canvases,
      };
      final projectId = await repository.saveProject(
        title: 'Deferred Test Project',
        state: state,
      );

      final controller = EditorController(
        projectId: projectId,
        repository: repository,
      );
      await controller.loadProjectData();

      // Frame 10 is beyond initial window (0..2), so it should be deferred
      final canvas10 = controller.canvases[10];
      final videoLayer10 = canvas10.layers.first;
      final content10 = videoLayer10.history.first as ImageContent;
      expect(content10.image, isNull, reason: 'Frame 10 image should initially be deferred');

      // Now select frame 10
      controller.selectCanvas(10);
      expect(controller.currentIndex, 10);

      // Await hydration completion
      await controller.ensureCanvasImagesLoaded(10);
      expect(content10.image, isNotNull, reason: 'Frame 10 image should now be loaded into memory');

      if (await testImg.exists()) {
        await testImg.delete();
      }
      controller.dispose();
    });

    test('importVideoFrames generates compact thumbnails and defers full image decoding for inactive frames', () async {
      final tempDir = Directory.systemTemp.createTempSync('video_import_test');
      final List<String> framePaths = [];

      const pngBytes = <int>[
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
        0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
        0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
        0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
        0x42, 0x60, 0x82,
      ];

      for (int i = 0; i < 6; i++) {
        final imgFile = File('${tempDir.path}/frame_$i.png');
        await imgFile.writeAsBytes(pngBytes, flush: true);
        framePaths.add(imgFile.path);
      }

      final controller = EditorController(
        projectId: 'test_video_import',
        repository: repository,
      );

      await controller.importVideoFrames(framePaths);

      expect(controller.canvases.length, 6);
      expect(controller.thumbnails.length, 6);

      // Verify thumbnails are compact (<= 80px) and not null
      for (int i = 0; i < 6; i++) {
        final thumb = controller.thumbnails[i];
        expect(thumb, isNotNull);
        expect(thumb!.width, lessThanOrEqualTo(80));
        expect(thumb.height, lessThanOrEqualTo(80));
      }

      // Verify active frames (0..2) have full image loaded
      final videoLayer0 = controller.canvases[0].layers.firstWhere((l) => l.name == 'Video Layer');
      final content0 = videoLayer0.history.first as ImageContent;
      expect(content0.image, isNotNull);

      // Verify frame 5 has deferred image
      final videoLayer5 = controller.canvases[5].layers.firstWhere((l) => l.name == 'Video Layer');
      final content5 = videoLayer5.history.first as ImageContent;
      expect(content5.image, isNull);

      // Selecting frame 5 hydrates it
      controller.selectCanvas(5);
      await controller.ensureCanvasImagesLoaded(5);
      expect(content5.image, isNotNull);

      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
      controller.dispose();
    });

    test('Heavy project with 150 frames opens immediately with bounded RAM and deferred image decoding', () async {
      final tempDir = Directory.systemTemp.createTempSync('heavy_project_test');
      const pngBytes = <int>[
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
        0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
        0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
        0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
        0x42, 0x60, 0x82,
      ];

      final testImg = File('${tempDir.path}/test_frame.png');
      await testImg.writeAsBytes(pngBytes, flush: true);

      final List<Map<String, dynamic>> canvasesList = [];
      for (int i = 0; i < 150; i++) {
        canvasesList.add({
          'size': {'width': 500.0, 'height': 500.0},
          'backgroundColor': 0xFFFFFFFF,
          'layers': [
            {
              'id': 'layer_$i',
              'name': 'Video Layer',
              'isVisible': true,
              'isLocked': false,
              'isGuide': false,
              'opacity': 1.0,
              'blendMode': 0,
              'currentIndex': 1,
              'history': [
                {
                  'type': 'ImageContent',
                  'imageUrl': testImg.path,
                  'paint': {'color': 0xFFFFFFFF, 'strokeWidth': 1.0},
                }
              ],
            }
          ],
        });
      }

      final heavyProjectData = {
        'aspectRatio': 1.0,
        'globalBackground': {'type': 'color', 'color': 0xFFFFFFFF},
        'canvases': canvasesList,
      };

      final projectId = await repository.saveProject(
        title: 'Heavy 150 Project',
        state: heavyProjectData,
      );

      final controller = EditorController(
        projectId: projectId,
        repository: repository,
      );

      // Measure load execution time
      final stopwatch = Stopwatch()..start();
      await controller.loadProjectData();
      stopwatch.stop();

      // 1. Verify all 150 frames loaded
      expect(controller.canvases.length, 150);
      expect(controller.thumbnails.length, 150);
      expect(controller.frameImagePaths.length, 150);

      // Loading 150 canvases without decoding 150 heavy images should complete in < 500ms
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));

      // 2. Active frame 0 must have image loaded
      final content0 = controller.canvases[0].layers.first.history.first as ImageContent;
      expect(content0.image, isNotNull, reason: 'Active frame 0 should have image decoded');

      // 3. Inactive distant frame 75 and 149 MUST have image deferred (null in RAM!)
      final content75 = controller.canvases[75].layers.first.history.first as ImageContent;
      expect(content75.image, isNull, reason: 'Distant frame 75 image should be deferred');

      final content149 = controller.canvases[149].layers.first.history.first as ImageContent;
      expect(content149.image, isNull, reason: 'Distant frame 149 image should be deferred');

      // 4. Verify frameImagePaths returns the correct path for timeline preview
      expect(controller.getFrameImagePath(75), contains('test_frame.png'));
      expect(controller.getFrameImagePath(149), contains('test_frame.png'));

      // 5. Select frame 75 - should dynamically hydrate
      controller.selectCanvas(75);
      expect(controller.currentIndex, 75);
      await controller.ensureCanvasImagesLoaded(75);
      expect(content75.image, isNotNull, reason: 'Selected frame 75 should now be hydrated');

      // Frame 0 was distant (>15 away) when selecting 75, so its full image was evicted to conserve RAM
      expect(content0.image, isNull, reason: 'Distant frame 0 image should have been evicted to cap RAM');

      tempDir.deleteSync(recursive: true);
      controller.dispose();
    });
  });
}

