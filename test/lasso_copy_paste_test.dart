import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/package_code/paint_contents.dart';
import 'package:dummy/package_code/src/paint_contents/paint_content_decoder.dart';
import 'package:dummy/package_code/src/drawing_controller.dart';
import 'package:dummy/features/editor/presentation/widgets/sticker_widgets/shape_sticker_widget.dart';
import 'package:dummy/features/editor/presentation/controllers/editor_controller.dart';
import 'package:dummy/features/editor/services/global_clipboard.dart';
import 'package:dummy/features/projects/data/project_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GlobalClipboard.instance.clearAll();
  });

  tearDown(() {
    GlobalClipboard.instance.clearAll();
  });

  group('GlobalClipboard Unit Tests', () {
    test('GlobalClipboard copyLasso stores data in memory and notifies listeners', () async {
      final sticker = ActiveShapeSticker(
        id: 'test_sticker_1',
        content: Circle(),
        offset: const Offset(150, 150),
        size: const Size(100, 100),
        scale: 1.25,
        rotation: 0.5,
        flipX: true,
        flipY: false,
        topLeftOffset: const Offset(-5, -5),
        isLassoSelection: true,
      );

      bool notified = false;
      GlobalClipboard.instance.hasLassoContentNotifier.addListener(() {
        notified = true;
      });

      expect(GlobalClipboard.instance.hasLassoContent, isFalse);
      await GlobalClipboard.instance.copyLasso(sticker);

      expect(GlobalClipboard.instance.hasLassoContent, isTrue);
      expect(notified, isTrue);

      final data = GlobalClipboard.instance.lassoData;
      expect(data, isNotNull);
      expect(data!.size, equals(const Size(100, 100)));
      expect(data.scale, equals(1.25));
      expect(data.rotation, equals(0.5));
      expect(data.flipX, isTrue);
      expect(data.flipY, isFalse);
      expect(data.topLeftOffset, equals(const Offset(-5, -5)));
    });

    test('decodePaintContent on Circle and Rectangle', () {
      final circle = Circle();
      final circleJson = circle.toJson();
      print('circleJson: $circleJson');
      final decodedCircle = decodePaintContent(circleJson['type'] as String, circleJson);
      print('decodedCircle: $decodedCircle');
      expect(decodedCircle, isNotNull);

      final rect = Rectangle();
      final rectJson = rect.toJson();
      print('rectJson: $rectJson');
      final decodedRect = decodePaintContent(rectJson['type'] as String, rectJson);
      print('decodedRect: $decodedRect');
      expect(decodedRect, isNotNull);
    });

    test('GlobalClipboard copyFrame stores frame json in memory', () async {
      final frameJson = {
        'size': {'width': 800.0, 'height': 600.0},
        'backgroundColor': 0xFFFFFFFF,
        'layers': [],
      };

      expect(GlobalClipboard.instance.hasFrameContent, isFalse);
      await GlobalClipboard.instance.copyFrame(frameJson);
      expect(GlobalClipboard.instance.hasFrameContent, isTrue);
      expect(GlobalClipboard.instance.frameData, equals(frameJson));
    });
  });

  group('EditorController Lasso Copy/Paste Tests', () {
    test('Copy active lasso sticker and paste into same canvas', () async {
      final repo = ProjectRepository();
      final controller = EditorController(repository: repo);

      expect(controller.canCopyLassoSelection, isFalse);
      expect(controller.canPasteLassoSelection, isFalse);

      // Create an active shape sticker (as if created by Lasso tool)
      final circle = Circle();

      controller.activeSticker = ActiveShapeSticker(
        id: 'lasso_stk_1',
        content: circle,
        offset: const Offset(100, 100),
        size: const Size(80, 80),
        scale: 1.5,
        rotation: 0.2,
        isLassoSelection: true,
      );

      expect(controller.canCopyLassoSelection, isTrue);

      // Copy active selection
      controller.copyActiveLassoSelection();
      expect(controller.canPasteLassoSelection, isTrue);

      // Stamp or clear active sticker
      controller.stampActiveSticker();
      expect(controller.activeSticker, isNull);

      // Paste
      final success = await controller.pasteLassoSelection();
      expect(success, isTrue);
      expect(controller.activeSticker, isNotNull);
      expect(controller.activeSticker, isA<ActiveShapeSticker>());

      final pastedSticker = controller.activeSticker as ActiveShapeSticker;
      expect(pastedSticker.isLasso, isTrue);
      expect(pastedSticker.scale, equals(1.5));
      expect(pastedSticker.rotation, equals(0.2));
      expect(pastedSticker.size, equals(const Size(80, 80)));
    });

    test('Cross-project Lasso Copy & Paste persistence', () async {
      final repo = ProjectRepository();
      final controllerA = EditorController(repository: repo);

      // Set active sticker in Project A
      final rect = Rectangle();

      controllerA.activeSticker = ActiveShapeSticker(
        id: 'lasso_rect',
        content: rect,
        offset: const Offset(75, 75),
        size: const Size(50, 50),
        flipX: true,
        flipY: true,
        transformMode: StickerTransformMode.perspective,
        topLeftOffset: const Offset(-8, -4),
        topRightOffset: const Offset(6, -2),
        bottomRightOffset: const Offset(4, 5),
        bottomLeftOffset: const Offset(-3, 7),
        isLassoSelection: true,
      );

      // Copy in Project A
      controllerA.copyActiveLassoSelection();

      // Dispose/simulate closing Project A
      controllerA.dispose();

      // Open a completely new Project B
      final controllerB = EditorController(repository: repo);

      // Check that clipboard persists into Project B
      expect(controllerB.canPasteLassoSelection, isTrue);

      // Paste in Project B
      final success = await controllerB.pasteLassoSelection();
      expect(success, isTrue);

      final pasted = controllerB.activeSticker as ActiveShapeSticker;
      expect(pasted.isLasso, isTrue);
      expect(pasted.flipX, isTrue);
      expect(pasted.flipY, isTrue);
      expect(pasted.transformMode, equals(StickerTransformMode.perspective));
      expect(pasted.topLeftOffset, equals(const Offset(-8, -4)));
      expect(pasted.topRightOffset, equals(const Offset(6, -2)));
      expect(pasted.bottomRightOffset, equals(const Offset(4, 5)));
      expect(pasted.bottomLeftOffset, equals(const Offset(-3, 7)));

      controllerB.dispose();
    });
  });
}
