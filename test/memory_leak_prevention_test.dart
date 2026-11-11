import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/package_code/paint_contents.dart';
import 'package:dummy/package_code/src/drawing_controller.dart';
import 'package:dummy/features/editor/presentation/controllers/editor_controller.dart';
import 'package:dummy/features/projects/data/project_repository.dart';

Future<ui.Image> createTestImage(int width, int height) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = Colors.red,
  );
  final picture = recorder.endRecording();
  final img = await picture.toImage(width, height);
  picture.dispose();
  return img;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Memory Leak Prevention & Resource Disposal Tests', () {
    test(
      'DrawingController disposeContentResources cleans up FillContent image without error',
      () async {
        final img = await createTestImage(50, 50);
        final fill = FillContent.data(image: img, paint: Paint());

        expect(fill.image, isNotNull);
        DrawingController.disposeContentResources(fill);
        expect(fill.image, isNull);
      },
    );

    test(
      'DrawingController history truncation cleans up undone raster contents',
      () async {
        final controller = DrawingController();
        controller.setBoardSize(const Size(100, 100));

        final img1 = await createTestImage(50, 50);
        final fill1 = FillContent.data(image: img1, paint: Paint());
        controller.addContent(fill1);

        final img2 = await createTestImage(50, 50);
        final fill2 = FillContent.data(image: img2, paint: Paint());
        controller.addContent(fill2);

        expect(controller.getHistory.length, equals(2));

        // Undo the second stroke
        controller.undo();
        expect(controller.activeLayer.value?.currentIndex, equals(1));
        expect(fill2.image, isNotNull);

        // Add a third stroke: this should truncate and dispose fill2
        final line = SimpleLine();
        controller.addContent(line);

        expect(controller.getHistory.length, equals(2));
        expect(
          fill2.image,
          isNull,
          reason:
              'Undone FillContent must have its image resources released upon truncation',
        );

        controller.dispose();
      },
    );

    test(
      'DrawingController clear() disposes all contents on active layer',
      () async {
        final controller = DrawingController();
        controller.setBoardSize(const Size(100, 100));

        final img = await createTestImage(50, 50);
        final fill = FillContent.data(image: img, paint: Paint());
        controller.addContent(fill);

        controller.clear();
        expect(controller.getHistory.isEmpty, isTrue);
        expect(
          fill.image,
          isNull,
          reason: 'Clear must dispose contents on the cleared layer',
        );

        controller.dispose();
      },
    );

    test('EditorController deletes frame and disposes thumbnail', () async {
      final editorController = EditorController(
        repository: ProjectRepository(),
      );
      final img = await createTestImage(50, 50);

      // Add a frame and set a thumbnail
      editorController.addFrame();
      expect(editorController.canvases.length, equals(2));

      editorController.recordThumbnailUsageForTesting(1, img);
      expect(editorController.thumbnails[1], isNotNull);

      // Delete frame 1
      editorController.deleteFrame(1);
      expect(editorController.canvases.length, equals(1));
      expect(editorController.thumbnails.length, equals(1));

      editorController.dispose();
    });
  });
}
