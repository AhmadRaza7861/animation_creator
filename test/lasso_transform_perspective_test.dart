import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dummy/package_code/paint_contents.dart';
import 'package:dummy/package_code/src/drawing_controller.dart';
import 'package:dummy/package_code/src/paint_extension/quad_homography.dart';
import 'package:dummy/features/editor/presentation/widgets/sticker_widgets/shape_sticker_widget.dart';
import 'package:dummy/features/editor/presentation/widgets/sticker_widgets/text_sticker_widget.dart';
import 'package:dummy/features/editor/presentation/widgets/toolbar_panel.dart';
import 'package:dummy/features/editor/presentation/controllers/editor_controller.dart';
import 'package:dummy/features/editor/presentation/controllers/editor_providers.dart';
import 'package:dummy/features/projects/data/project_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuadHomography Tests', () {
    test('Rectangle to Rectangle produces identity transform', () {
      final matrix = QuadHomography.fromRectToQuad(
        width: 100,
        height: 100,
        p0: const Offset(0, 0),
        p1: const Offset(100, 0),
        p2: const Offset(100, 100),
        p3: const Offset(0, 100),
      );

      final p0Transformed = QuadHomography.transformPoint(matrix, const Offset(0, 0));
      final p1Transformed = QuadHomography.transformPoint(matrix, const Offset(100, 0));
      final p2Transformed = QuadHomography.transformPoint(matrix, const Offset(100, 100));
      final p3Transformed = QuadHomography.transformPoint(matrix, const Offset(0, 100));

      expect((p0Transformed - const Offset(0, 0)).distance, lessThan(0.01));
      expect((p1Transformed - const Offset(100, 0)).distance, lessThan(0.01));
      expect((p2Transformed - const Offset(100, 100)).distance, lessThan(0.01));
      expect((p3Transformed - const Offset(0, 100)).distance, lessThan(0.01));
    });

    test('Perspective quad maps corners accurately', () {
      final p0Dest = const Offset(10, 15);
      final p1Dest = const Offset(120, 5);
      final p2Dest = const Offset(110, 95);
      final p3Dest = const Offset(5, 85);

      final matrix = QuadHomography.fromRectToQuad(
        width: 100,
        height: 100,
        p0: p0Dest,
        p1: p1Dest,
        p2: p2Dest,
        p3: p3Dest,
      );

      final p0Actual = QuadHomography.transformPoint(matrix, const Offset(0, 0));
      final p1Actual = QuadHomography.transformPoint(matrix, const Offset(100, 0));
      final p2Actual = QuadHomography.transformPoint(matrix, const Offset(100, 100));
      final p3Actual = QuadHomography.transformPoint(matrix, const Offset(0, 100));

      expect((p0Actual - p0Dest).distance, lessThan(0.1));
      expect((p1Actual - p1Dest).distance, lessThan(0.1));
      expect((p2Actual - p2Dest).distance, lessThan(0.1));
      expect((p3Actual - p3Dest).distance, lessThan(0.1));
    });
  });

  group('ShapeStickerContent Serialization & Painting Tests', () {
    test('ShapeStickerContent serializes and deserializes with flips and perspective offsets', () {
      final original = ShapeStickerContent.data(
        child: Circle(),
        offset: const Offset(150, 200),
        scale: 1.5,
        rotation: 0.75,
        size: const Size(120, 80),
        flipX: true,
        flipY: false,
        topLeftOffset: const Offset(-10, -5),
        topRightOffset: const Offset(15, 0),
        bottomRightOffset: const Offset(5, 10),
        bottomLeftOffset: const Offset(-5, 8),
        paint: Paint()..color = const Color(0xFFFF0000),
      );

      expect(original.hasPerspectiveDistortion, isTrue);

      final json = original.toContentJson();
      expect(json['flipX'], isTrue);
      expect(json['flipY'], isFalse);
      expect(json['topLeftOffset'], isNotNull);
      expect(json['topRightOffset'], isNotNull);
      expect(json['bottomRightOffset'], isNotNull);
      expect(json['bottomLeftOffset'], isNotNull);

      final restored = ShapeStickerContent.fromJson(json);
      expect(restored.offset, equals(const Offset(150, 200)));
      expect(restored.scale, equals(1.5));
      expect(restored.rotation, equals(0.75));
      expect(restored.size, equals(const Size(120, 80)));
      expect(restored.flipX, isTrue);
      expect(restored.flipY, isFalse);
      expect(restored.topLeftOffset, equals(const Offset(-10, -5)));
      expect(restored.topRightOffset, equals(const Offset(15, 0)));
      expect(restored.bottomRightOffset, equals(const Offset(5, 10)));
      expect(restored.bottomLeftOffset, equals(const Offset(-5, 8)));
      expect(restored.hasPerspectiveDistortion, isTrue);
    });

    test('ShapeStickerContent draws successfully with perspective and flips without crashing', () {
      final content = ShapeStickerContent.data(
        child: Rectangle(),
        offset: const Offset(100, 100),
        scale: 1.2,
        rotation: 0.3,
        size: const Size(100, 100),
        flipX: true,
        flipY: true,
        topLeftOffset: const Offset(10, 10),
        paint: Paint()..color = Colors.blue,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      content.draw(canvas, const Size(500, 500), false);
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });

  group('EditorController Shape Sticker Transformation Tests', () {
    test('EditorController handles active shape sticker transforms', () {
      final repo = ProjectRepository();
      final controller = EditorController(repository: repo);
      final activeSticker = ActiveShapeSticker(
        id: 'test-sticker-1',
        content: Circle(),
        size: const Size(100, 100),
        offset: const Offset(200, 200),
        isLassoSelection: true,
      );

      controller.activeSticker = activeSticker;
      expect(controller.activeSticker, equals(activeSticker));

      // Test Mode change
      controller.setShapeStickerTransformMode(StickerTransformMode.perspective);
      expect(activeSticker.transformMode, equals(StickerTransformMode.perspective));

      // Test Flip H
      controller.flipActiveShapeStickerH();
      expect(activeSticker.flipX, isTrue);
      controller.flipActiveShapeStickerH();
      expect(activeSticker.flipX, isFalse);

      // Test Flip V
      controller.flipActiveShapeStickerV();
      expect(activeSticker.flipY, isTrue);

      // Test Duplicate
      final initialHistoryCount = controller.drawingController.getHistory.length;
      controller.duplicateActiveShapeSticker();
      expect(controller.drawingController.getHistory.length, equals(initialHistoryCount + 1));
      expect(activeSticker.offset, equals(const Offset(220, 220)));

      // Test Reset
      activeSticker.topLeftOffset = const Offset(10, 10);
      expect(activeSticker.hasPerspectiveDistortion, isTrue);
      controller.resetActiveShapeSticker();
      expect(activeSticker.hasPerspectiveDistortion, isFalse);
      expect(activeSticker.flipY, isFalse);
      expect(activeSticker.scale, equals(1.0));

      // Test Rotate 90
      final initialRotation = activeSticker.rotation;
      controller.rotateActiveShapeSticker90();
      expect(activeSticker.rotation, closeTo(initialRotation + 1.57079, 0.001));

      // Test Center
      controller.centerActiveShapeSticker();
      expect(activeSticker.offset, isNotNull);

      // Test Stamp
      controller.stampActiveSticker();
      expect(controller.activeSticker, isNull);
      expect(controller.drawingController.getHistory.length, equals(initialHistoryCount + 2));
    });

    test('Lasso on empty canvas dismisses cleanly without adding dashed outline to history', () {
      final repo = ProjectRepository();
      final controller = EditorController(repository: repo);
      final drawingController = controller.drawingController;

      expect(drawingController.getHistory.length, equals(0));

      // Simulate drawing with Lasso on empty canvas
      drawingController.setPaintContent(Lasso());
      drawingController.startDraw(const Offset(50, 50));
      drawingController.drawing(const Offset(100, 50), 1.0);
      drawingController.drawing(const Offset(100, 100), 1.0);
      drawingController.drawing(const Offset(50, 100), 1.0);
      drawingController.drawing(const Offset(50, 50), 1.0);
      drawingController.endDraw();

      // Ensure no dashed lasso line was added to layer history and no sticker was created
      expect(drawingController.getHistory.length, equals(0));
      expect(controller.activeSticker, isNull);
    });
  });

  group('ShapeStickerWidget UI & ToolbarPanel Tests', () {
    testWidgets('ShapeStickerWidget renders clean floating micro-pill for standard shape sticker', (tester) async {
      final sticker = ActiveShapeSticker(
        id: 'widget-sticker-test',
        content: Circle(),
        size: const Size(120, 120),
        offset: const Offset(200, 200),
        isLassoSelection: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ShapeStickerWidget(
                  data: sticker,
                  onUpdate: (offset, scale, rotation) {},
                  onDelete: () {},
                  onConfirm: () {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ShapeStickerWidget), findsOneWidget);
      expect(find.byIcon(Icons.flip_rounded), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.rotate_right_rounded), findsOneWidget);

      // Tap Flip icon on micro-pill
      expect(sticker.flipX, isFalse);
      await tester.tap(find.byIcon(Icons.flip_rounded));
      await tester.pumpAndSettle();
      expect(sticker.flipX, isTrue);
    });

    testWidgets('ShapeStickerWidget for Lasso does not duplicate floating micro-pill on canvas', (tester) async {
      final sticker = ActiveShapeSticker(
        id: 'widget-lasso-test',
        content: Circle(),
        size: const Size(120, 120),
        offset: const Offset(200, 200),
        isLassoSelection: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ShapeStickerWidget(
                  data: sticker,
                  onUpdate: (offset, scale, rotation) {},
                  onDelete: () {},
                  onConfirm: () {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ShapeStickerWidget), findsOneWidget);
      expect(find.byIcon(Icons.rotate_right_rounded), findsOneWidget);
      // No duplicate pill buttons on the canvas
      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
    });

    testWidgets('ToolbarPanel shows Lasso toolbar when Lasso selection is active and standard for regular stickers', (tester) async {
      final repo = ProjectRepository();
      final controller = EditorController(repository: repo);

      // 1. Regular sticker: should show standard toolbar
      final regularSticker = ActiveShapeSticker(
        id: 'regular-sticker',
        content: Circle(),
        size: const Size(100, 100),
        offset: const Offset(200, 200),
        isLassoSelection: false,
      );
      controller.activeSticker = regularSticker;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            editorControllerProvider(null).overrideWith((ref) => controller),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ToolbarPanel(projectId: null),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Regular sticker does NOT override the bottom toolbar
      expect(find.text('Export'), findsOneWidget);
      expect(find.text('Brush'), findsOneWidget);
      expect(find.text('Erase'), findsOneWidget);
      expect(find.text('Paint'), findsOneWidget);
      expect(find.text('Lasso'), findsOneWidget);

      // 2. Lasso selection: should show Lasso transformation suite
      final lassoSticker = ActiveShapeSticker(
        id: 'lasso-sticker',
        content: Circle(),
        size: const Size(100, 100),
        offset: const Offset(200, 200),
        isLassoSelection: true,
      );
      controller.activeSticker = lassoSticker;
      await tester.pumpAndSettle();

      // Lasso selection shows sub-menu with check/confirm button and TRSF/PERSP suite
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.text('TRSF'), findsOneWidget);
      expect(find.text('PERSP'), findsOneWidget);
      expect(find.text('Flip H'), findsOneWidget);
      expect(find.text('Flip V'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Paste'), findsOneWidget);
      expect(find.text('Duplicate'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Tap Flip H on bottom toolbar
      expect(lassoSticker.flipX, isFalse);
      await tester.tap(find.text('Flip H'));
      await tester.pumpAndSettle();
      expect(lassoSticker.flipX, isTrue);

      // Tap PERSP
      await tester.tap(find.text('PERSP'));
      await tester.pumpAndSettle();
      expect(lassoSticker.transformMode, equals(StickerTransformMode.perspective));

      // Tap Check/Confirm button to stamp and return to standard toolbar
      await tester.tap(find.byIcon(Icons.check_rounded));
      await tester.pumpAndSettle();
      expect(controller.activeSticker, isNull);
      expect(find.text('Export'), findsOneWidget);

      // 3. Text sticker: should show Text sub-menu with back button and full toolset
      final textSticker = ActiveTextSticker(
        id: 'text-sticker',
        text: 'Hello World',
        color: Colors.black,
        fontSize: 24,
      );
      controller.activeSticker = textSticker;
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
      expect(find.text('Edit Text'), findsOneWidget);
      expect(find.text('Fonts'), findsOneWidget);
      expect(find.text('Format'), findsOneWidget);
      expect(find.text('Flip H'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Duplicate'), findsNothing);
      expect(find.text('Reset'), findsNothing);

      // Tap Flip H
      await tester.tap(find.text('Flip H'));
      await tester.pumpAndSettle();
      expect(textSticker.flipX, isTrue);

      // Tap Back button (<) to stamp text sticker
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      expect(controller.activeSticker, isNull);
      expect(find.text('Export'), findsOneWidget);
    });

    testWidgets('TextStickerWidget renders on canvas without duplicate floating micro-pill', (tester) async {
      final sticker = ActiveTextSticker(
        id: 'widget-text-test',
        text: 'Clean Canvas Text',
        color: Colors.black,
        fontSize: 24,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                TextStickerWidget(
                  data: sticker,
                  onUpdate: (offset, scale, rotation) {},
                  onDelete: () {},
                  onConfirm: () {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TextStickerWidget), findsOneWidget);
      expect(find.text('Clean Canvas Text'), findsOneWidget);
      expect(find.byIcon(Icons.rotate_right_rounded), findsOneWidget);
      // No floating pill with delete button on canvas
      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
    });
  });

  group('Session History Refresh on Project Load Tests', () {
    test('Reopening existing project disables initial undo/redo and refreshes history session', () async {
      final repo = ProjectRepository();
      final controller = EditorController(repository: repo);
      controller.projectName = 'Saved Project';

      // Draw 3 lines
      controller.drawingController.addContent(
        StraightLine.data(startPoint: const Offset(0, 0), endPoint: const Offset(10, 10), paint: Paint()),
      );
      controller.drawingController.addContent(
        StraightLine.data(startPoint: const Offset(10, 10), endPoint: const Offset(20, 20), paint: Paint()),
      );
      controller.drawingController.addContent(
        StraightLine.data(startPoint: const Offset(20, 20), endPoint: const Offset(30, 30), paint: Paint()),
      );

      await controller.saveProject();
      final pId = controller.projectId!;

      // Create a fresh controller simulating reopening the project
      final reopenController = EditorController(repository: repo, projectId: pId);
      await reopenController.loadProjectData();

      // On freshly opened project, undo and redo must be false (session refreshed)
      expect(reopenController.drawingController.canUndo(), isFalse);
      expect(reopenController.drawingController.canRedo(), isFalse);
      expect(reopenController.drawingController.activeLayer.value?.history.length, equals(3));
      expect(reopenController.drawingController.activeLayer.value?.sessionStartIndex, equals(3));

      // Draw a new stroke in current session
      reopenController.drawingController.addContent(
        StraightLine.data(startPoint: const Offset(30, 30), endPoint: const Offset(40, 40), paint: Paint()),
      );

      // Undo is now enabled for the new stroke
      expect(reopenController.drawingController.canUndo(), isTrue);
      expect(reopenController.drawingController.canRedo(), isFalse);

      // Undo the newly added stroke
      reopenController.drawingController.undo();

      // Undo is disabled again because we reached the session baseline, and redo becomes available
      expect(reopenController.drawingController.canUndo(), isFalse);
      expect(reopenController.drawingController.canRedo(), isTrue);
      expect(reopenController.drawingController.activeLayer.value?.history.length, equals(4));
      expect(reopenController.drawingController.activeLayer.value?.currentIndex, equals(3));

      // Redo restores the new stroke
      reopenController.drawingController.redo();
      expect(reopenController.drawingController.canUndo(), isTrue);
      expect(reopenController.drawingController.canRedo(), isFalse);
      expect(reopenController.drawingController.activeLayer.value?.currentIndex, equals(4));

      await repo.deleteProject(pId);
      controller.dispose();
      reopenController.dispose();
    });

    test('Onion defaults to ON for 1st-time user, stays OFF when toggled off across sessions', () async {
      final repo = ProjectRepository();
      final controller = EditorController(repository: repo);

      // 1. By default, Onion skin is enabled
      expect(controller.isOnionEnabled, isTrue);
      expect(controller.isGridEnabled, isFalse);

      // 2. User toggles Onion OFF
      controller.updateOnion(enabled: false);
      expect(controller.isOnionEnabled, isFalse);

      // Save project with Onion OFF
      await controller.saveProject();
      final pId = controller.projectId!;

      // 3. Reopening the project respects Onion OFF
      final reopenController = EditorController(repository: repo, projectId: pId);
      await reopenController.loadProjectData();
      expect(reopenController.isOnionEnabled, isFalse);

      // 4. Turning Onion back ON
      reopenController.updateOnion(enabled: true);
      expect(reopenController.isOnionEnabled, isTrue);

      await repo.deleteProject(pId);
      controller.dispose();
      reopenController.dispose();
    });

    test('Sticker mode defaults to false for new projects, true for tutorials, and persists user toggle across reloads', () async {
      final repo = ProjectRepository();

      // 1. Fresh EditorController (new non-tutorial project) defaults to enableStickers = false
      final newProjectController = EditorController(repository: repo);
      expect(newProjectController.enableStickers, isFalse);

      // Save this new project
      await newProjectController.saveProject();
      final newProjectId = newProjectController.projectId!;

      // Reloading new project preserves enableStickers = false
      final reloadedNewController = EditorController(repository: repo, projectId: newProjectId);
      await reloadedNewController.loadProjectData();
      expect(reloadedNewController.enableStickers, isFalse);

      // User explicitly toggles Sticker mode ON in this project
      reloadedNewController.enableStickers = true;
      expect(reloadedNewController.enableStickers, isTrue);
      await reloadedNewController.saveProject();

      // Reopening preserves the user's explicit ON choice
      final reloadedToggledOn = EditorController(repository: repo, projectId: newProjectId);
      await reloadedToggledOn.loadProjectData();
      expect(reloadedToggledOn.enableStickers, isTrue);

      // 2. Tutorial project creation with enableStickers = true
      final tutorialState = {
        'projectName': 'Tutorial Lesson',
        'enableStickers': true,
        'fps': 12,
        'canvases': [],
      };
      final tutorialProjectId = await repo.saveProject(title: 'Tutorial Lesson', state: tutorialState);

      // Loading tutorial project initializes with enableStickers = true
      final tutorialController = EditorController(repository: repo, projectId: tutorialProjectId);
      await tutorialController.loadProjectData();
      expect(tutorialController.enableStickers, isTrue);

      // User explicitly toggles Sticker mode OFF in tutorial
      tutorialController.enableStickers = false;
      expect(tutorialController.enableStickers, isFalse);
      await tutorialController.saveProject();

      // Reopening tutorial preserves the user's explicit OFF choice (does not auto-change back)
      final reloadedTutorial = EditorController(repository: repo, projectId: tutorialProjectId);
      await reloadedTutorial.loadProjectData();
      expect(reloadedTutorial.enableStickers, isFalse);

      // Cleanup
      await repo.deleteProject(newProjectId);
      await repo.deleteProject(tutorialProjectId);
      newProjectController.dispose();
      reloadedNewController.dispose();
      reloadedToggledOn.dispose();
      tutorialController.dispose();
      reloadedTutorial.dispose();
    });

    test('Selecting a non-brush tool and reopening a project resets active tool and UI to default FreehandLine Brush', () async {
      final repo = ProjectRepository();

      // 1. Create and save a project
      final state = {
        'projectName': 'Shape Test Project',
        'fps': 12,
        'canvases': [
          {
            'backgroundColor': Colors.white.value,
            'layers': [
              {
                'id': 'layer_0',
                'name': 'Background',
                'isVisible': true,
                'isLocked': false,
                'opacity': 1.0,
                'blendMode': 0,
                'history': [],
                'currentIndex': 0,
              }
            ],
            'activeLayerId': 'layer_0',
          }
        ],
      };
      final projectId = await repo.saveProject(title: 'Shape Test Project', state: state);

      // 2. Open project and select a Shape tool (e.g., Circle or Heart)
      final controller1 = EditorController(repository: repo, projectId: projectId);
      await controller1.loadProjectData();
      controller1.selectShape('circle');
      expect(controller1.drawingController.drawConfig.value.contentType, equals(Circle));
      expect(GlobalToolState.instance.toolConfig.value.contentType, equals(Circle));

      // Close / dispose project 1
      controller1.dispose();

      // 3. Open project again (or another project)
      final controller2 = EditorController(repository: repo, projectId: projectId);
      await controller2.loadProjectData();

      // Verify that the active category is Brush and the tool contentType is FreehandLine, with no mismatch!
      expect(controller2.activeCategory, equals('Brush'));
      expect(controller2.drawingController.drawConfig.value.contentType, equals(FreehandLine));
      expect(GlobalToolState.instance.toolConfig.value.contentType, equals(FreehandLine));
      expect(controller2.drawingController.activeBrushPresetId, isNull);

      // Cleanup
      await repo.deleteProject(projectId);
      controller2.dispose();
    });
  });
}




