import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/package_code/paint_contents.dart';
import 'package:dummy/package_code/src/drawing_controller.dart';
import 'package:dummy/package_code/src/paint_contents/layer_data.dart';
import 'package:dummy/package_code/src/paint_contents/delete_content.dart';
import 'package:dummy/features/editor/presentation/screens/animation_preview_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Playback & Deletion Tests', () {
    test('FramePainter does not draw items that have been deleted via DeleteContent', () {
      final controller = DrawingController();
      final stroke = FreehandLine.data(
        points: [const Offset(10, 10), const Offset(20, 20)],
        paint: Paint()..strokeWidth = 4.0,
      );
      final strokeId = stroke.id;
      final deleteMarker = DeleteContent(targetId: strokeId);

      final layer = LayerData(
        id: 'layer_1',
        name: 'Layer 1',
        isVisible: true,
        isLocked: false,
        history: [stroke, deleteMarker],
        currentIndex: 2,
      );

      controller.layers.clear();
      controller.layers.add(layer);

      // Verify effective history omits the deleted stroke
      expect(layer.getEffectiveHistory(), isEmpty);

      // Record painting via FramePainter
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const painter = FramePainter(controller);

      // Painting should execute cleanly without drawing deleted items
      painter.paint(canvas, const Size(200, 200));
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
      picture.dispose();
      controller.dispose();
    });

    test('DrawingController.hasUserDrawings returns false when all items are deleted via DeleteContent', () {
      final controller = DrawingController();
      final stroke = FreehandLine.data(
        points: [const Offset(50, 50), const Offset(100, 100)],
        paint: Paint()..strokeWidth = 2.0,
      );
      final deleteMarker = DeleteContent(targetId: stroke.id);

      final layer = LayerData(
        id: 'layer_test',
        name: 'Layer Test',
        isVisible: true,
        history: [stroke, deleteMarker],
        currentIndex: 2,
      );

      controller.layers.clear();
      controller.layers.add(layer);

      expect(controller.hasUserDrawings, isFalse);
      controller.dispose();
    });

    test('FramePainter does not draw history when currentIndex is 0 (undone state)', () {
      final controller = DrawingController();
      final stroke = FreehandLine.data(
        points: [const Offset(10, 10), const Offset(20, 20)],
        paint: Paint()..strokeWidth = 4.0,
      );

      // currentIndex is 0 (user undid the action)
      final layer = LayerData(
        id: 'layer_undone',
        name: 'Layer Undone',
        isVisible: true,
        isLocked: false,
        history: [stroke],
        currentIndex: 0,
      );

      controller.layers.clear();
      controller.layers.add(layer);

      expect(layer.getEffectiveHistory(), isEmpty);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const painter = FramePainter(controller);

      painter.paint(canvas, const Size(200, 200));
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
      picture.dispose();
      controller.dispose();
    });
  });
}

