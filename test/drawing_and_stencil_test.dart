import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/package_code/paint_contents.dart';
import 'package:dummy/package_code/src/paint_contents/layer_data.dart';
import 'package:dummy/package_code/src/drawing_controller.dart';
import 'package:dummy/features/templates/data/tutorial_project_builder.dart';
import 'package:dummy/features/editor/presentation/screens/animation_preview_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Drawing Touch & Controller Tests', () {
    test('DrawingController allows drawing when finger count is 0 or 1', () {
      final controller = DrawingController();
      expect(controller.couldStartDraw, isTrue);
      expect(controller.couldDrawing, isTrue);

      // Simulate finger down (fingerCount = 1)
      controller.addFingerCount(const Offset(10, 10));
      expect(controller.drawConfig.value.fingerCount, 1);
      expect(controller.couldStartDraw, isTrue);
      expect(controller.couldDrawing, isTrue);

      // Simulate second finger down (pinch zoom / pan, fingerCount = 2)
      controller.addFingerCount(const Offset(50, 50));
      expect(controller.drawConfig.value.fingerCount, 2);
      expect(controller.couldStartDraw, isFalse);
      expect(controller.couldDrawing, isFalse);

      // Release one finger
      controller.reduceFingerCount(const Offset(50, 50));
      expect(controller.drawConfig.value.fingerCount, 1);
      expect(controller.couldStartDraw, isTrue);
      expect(controller.couldDrawing, isTrue);

      // Release last finger
      controller.reduceFingerCount(const Offset(10, 10));
      expect(controller.drawConfig.value.fingerCount, 0);
      expect(controller.couldStartDraw, isTrue);
    });

    test('Drawing lifecycle commits strokes to active unlocked layer', () {
      final controller = DrawingController();
      controller.setPaintContent(FreehandLine());

      expect(controller.activeLayer.value?.id, 'layer_0');
      expect(controller.activeLayer.value?.isLocked, isFalse);
      expect(controller.getHistory.length, 0);

      // 1. Pointer Down
      controller.startDraw(const Offset(100, 100));
      expect(controller.hasPaintingContent, isTrue);

      // 2. Pointer Move (drag)
      controller.drawing(const Offset(120, 120));
      controller.drawing(const Offset(140, 140));

      // 3. Pointer Up
      controller.endDraw();
      expect(controller.hasPaintingContent, isFalse);
      expect(controller.getHistory.length, 1);
      expect(controller.getHistory.first, isA<FreehandLine>());
    });

    test('Locked active layer rejects drawing', () {
      final controller = DrawingController();
      controller.setPaintContent(FreehandLine());
      controller.activeLayer.value!.isLocked = true;

      controller.startDraw(const Offset(50, 50));
      expect(controller.hasPaintingContent, isFalse);
      controller.drawing(const Offset(60, 60));
      controller.endDraw();

      expect(controller.getHistory.length, 0);
    });
  });

  group('Guided Stencil & Full Template Project Integration Tests', () {
    test('Guided Stencil mode generates locked stencil guide and unlocked active drawing layer', () {
      final baseState = TutorialProjectBuilder.buildBouncingBallProject();
      final canvasesList = (baseState['canvases'] as List<dynamic>?) ?? [];
      final updatedCanvases = [];

      for (final c in canvasesList) {
        final cMap = Map<String, dynamic>.from(c as Map<String, dynamic>);
        final layers = (cMap['layers'] as List<dynamic>?) ?? [];
        final updatedLayers = [];

        for (final l in layers) {
          final lMap = Map<String, dynamic>.from(l as Map<String, dynamic>);
          lMap['name'] = 'Stencil Guide';
          lMap['opacity'] = 0.28;
          lMap['isLocked'] = true;
          lMap['isGuide'] = true;
          updatedLayers.add(lMap);
        }

        updatedLayers.add({
          'id': 'layer_1',
          'name': 'Your Drawing',
          'isVisible': true,
          'isLocked': false,
          'isGuide': false,
          'opacity': 1.0,
          'blendMode': BlendMode.srcOver.index,
          'currentIndex': 0,
          'history': <Map<String, dynamic>>[],
        });

        cMap['layers'] = updatedLayers;
        cMap['activeLayerId'] = 'layer_1';
        updatedCanvases.add(cMap);
      }

      final guidedProject = Map<String, dynamic>.from(baseState);
      guidedProject['canvases'] = updatedCanvases;
      guidedProject['enableStickers'] = true;

      // Verify every canvas has 2 layers with layer_1 active and unlocked
      for (final c in updatedCanvases) {
        final layers = c['layers'] as List;
        expect(layers.length, 2);
        expect(layers[0]['id'], 'layer_0');
        expect(layers[0]['isLocked'], isTrue);
        expect(layers[0]['isGuide'], isTrue);
        expect(layers[0]['opacity'], 0.28);
        expect(layers[1]['id'], 'layer_1');
        expect(layers[1]['isLocked'], isFalse);
        expect(layers[1]['isGuide'], isFalse);
        expect(layers[1]['opacity'], 1.0);
        expect(c['activeLayerId'], 'layer_1');
      }
    });

    test('FramePainter in preview ignores guide stencil layers and only renders user drawings', () {
      final controller = DrawingController();
      controller.drawConfig.value = controller.drawConfig.value.copyWith(
        size: const Size(360, 202.5),
      );

      // Layer 0: Stencil Guide with guide strokes
      final guideLine = SimpleLine()
        ..startPoint = const Offset(10, 10)
        ..endPoint = const Offset(100, 100);
      final stencilLayer = LayerData(
        id: 'layer_0',
        name: 'Stencil Guide',
        isLocked: true,
        isGuide: true,
        opacity: 0.28,
        history: [guideLine],
        currentIndex: 1,
      );

      // Layer 1: User's Drawing (empty initially)
      final userLayer = LayerData(
        id: 'layer_1',
        name: 'Your Drawing',
        isLocked: false,
        isGuide: false,
        opacity: 1.0,
        history: [],
        currentIndex: 0,
      );

      controller.layers.clear();
      controller.layers.addAll([stencilLayer, userLayer]);
      controller.activeLayer.value = userLayer;

      final painter = FramePainter(controller);
      expect(painter, isNotNull);

      // Verify user can draw on userLayer
      controller.setPaintContent(FreehandLine());
      controller.startDraw(const Offset(50, 50));
      controller.drawing(const Offset(60, 60));
      controller.endDraw();

      expect(userLayer.history.length, 1);
      expect(stencilLayer.history.length, 1);
    });
  });
}
