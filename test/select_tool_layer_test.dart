import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/package_code/paint_contents.dart';
import 'package:dummy/package_code/src/paint_contents/layer_data.dart';
import 'package:dummy/package_code/src/paint_contents/paint_content_decoder.dart';
import 'package:dummy/features/editor/presentation/controllers/editor_controller.dart';
import 'package:dummy/features/projects/data/project_repository.dart';
import 'package:dummy/core/localization/app_localizations.dart';
import 'package:dummy/features/editor/presentation/widgets/sticker_widgets/shape_sticker_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Select Tool Persistence & Non-duplication Tests', () {
    test('Decoded PaintContent preserves its original id from JSON', () {
      final freehand = FreehandLine.data(
        points: [const Offset(50, 50), const Offset(100, 100)],
        paint: Paint()..strokeWidth = 5.0,
      );
      final originalId = freehand.id;
      final jsonMap = freehand.toJson();

      expect(jsonMap['id'], originalId);

      final decoded = decodePaintContent('FreehandLine', jsonMap);
      expect(decoded, isNotNull);
      expect(decoded!.id, originalId);
    });

    test('Deleted stroke via DeleteContent is not duplicated after JSON serialization & reload', () {
      final stroke = FreehandLine.data(
        points: [const Offset(100, 100), const Offset(150, 150)],
        paint: Paint()..strokeWidth = 10.0,
      );
      final strokeId = stroke.id;

      final deleteMarker = DeleteContent(targetId: strokeId);

      final movedSticker = ShapeStickerContent.data(
        child: OffsetContent(stroke, const Offset(-100, -100)),
        offset: const Offset(300, 300),
        scale: 1.0,
        rotation: 0.0,
        size: const Size(50, 50),
        paint: Paint()..strokeWidth = 10.0,
      );

      final layer = LayerData(
        id: 'layer_1',
        name: 'Layer 1',
        isVisible: true,
        isLocked: false,
        history: [stroke, deleteMarker, movedSticker],
        currentIndex: 3,
      );

      // Verify effective history before serialization
      final effectiveBefore = layer.getEffectiveHistory();
      expect(effectiveBefore.length, 1);
      expect(effectiveBefore.first, movedSticker);

      // Serialize layer history to JSON
      final historyJson = layer.history.map((c) => c.toJson()).toList();

      // Deserialize layer history from JSON
      final List<PaintContent> reloadedHistory = [];
      for (final itemJson in historyJson) {
        final decoded = decodePaintContent(itemJson['type'] as String, itemJson);
        expect(decoded, isNotNull);
        reloadedHistory.add(decoded!);
      }

      final reloadedLayer = LayerData(
        id: 'layer_1',
        name: 'Layer 1',
        isVisible: true,
        isLocked: false,
        history: reloadedHistory,
        currentIndex: reloadedHistory.length,
      );

      // Verify effective history after serialization
      final effectiveAfter = reloadedLayer.getEffectiveHistory();
      expect(effectiveAfter.length, 1, reason: 'Original stroke must be hidden by DeleteContent and not duplicated');
      expect(effectiveAfter.first.id, movedSticker.id);
    });

    test('Self-healing handles legacy saves where targetId was mismatched due to lost ID', () {
      // Stroke with newly generated ID 'new_id_123'
      final stroke = FreehandLine.data(
        points: [const Offset(100, 100), const Offset(150, 150)],
        paint: Paint()..strokeWidth = 10.0,
      );

      // DeleteContent referencing old lost ID 'lost_old_id'
      final deleteMarker = DeleteContent(targetId: 'lost_old_id');

      final movedSticker = ShapeStickerContent.data(
        child: OffsetContent(stroke, const Offset(-100, -100)),
        offset: const Offset(300, 300),
        scale: 1.0,
        rotation: 0.0,
        size: const Size(50, 50),
        paint: Paint()..strokeWidth = 10.0,
      );

      final layer = LayerData(
        id: 'layer_1',
        name: 'Layer 1',
        isVisible: true,
        isLocked: false,
        history: [stroke, deleteMarker, movedSticker],
        currentIndex: 3,
      );

      // Self-healing should associate DeleteContent with preceding stroke
      final effective = layer.getEffectiveHistory();
      expect(effective.length, 1, reason: 'Self-healing must hide the orphaned stroke preceding DeleteContent');
      expect(effective.first, movedSticker);
    });
  });

  group('Layer Scoped Selection Tests', () {
    testWidgets('Tapping element on Layer 1 while Layer 2 is active does NOT auto-switch layer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
          ],
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Container();
              },
            ),
          ),
        ),
      );

      final BuildContext context = tester.element(find.byType(Container));

      final controller = EditorController(repository: ProjectRepository());
      final drawingController = controller.drawingController;

      final layer1 = LayerData(
        id: 'layer_1',
        name: 'Layer 1',
        isVisible: true,
        isLocked: false,
      );
      final layer2 = LayerData(
        id: 'layer_2',
        name: 'Layer 2',
        isVisible: true,
        isLocked: false,
      );

      drawingController.layers.clear();
      drawingController.layers.addAll([layer1, layer2]);

      // Add a stroke to Layer 1 at (100, 100)
      final strokeOnLayer1 = FreehandLine.data(
        points: [const Offset(100, 100), const Offset(110, 110)],
        paint: Paint()..strokeWidth = 10.0,
      );
      layer1.history.add(strokeOnLayer1);
      layer1.currentIndex = 1;

      // Set Layer 2 as active
      drawingController.activeLayer.value = layer2;
      controller.activeCategory = 'Select';

      // Tap on stroke which is on Layer 1
      final bool selected = controller.selectElementAt(const Offset(105, 105), context);

      // Verify:
      expect(selected, isFalse, reason: 'Must not select elements on different layers');
      expect(drawingController.activeLayer.value, layer2, reason: 'Must NOT automatically switch to Layer 1');
      expect(controller.activeSticker, isNull, reason: 'No sticker should be created');
    });

    test('isContentInOrIntersectsRect does not falsely select adjacent stroke with overlapping bounding box', () {
      // Stroke 1 at top: horizontal line from (50, 50) to (200, 50)
      final stroke1 = FreehandLine.data(
        points: [const Offset(50, 50), const Offset(200, 50)],
        paint: Paint()..strokeWidth = 10.0,
      );

      // Stroke 2 at bottom: vertical line from (50, 100) to (50, 250)
      final stroke2 = FreehandLine.data(
        points: [const Offset(50, 100), const Offset(50, 250)],
        paint: Paint()..strokeWidth = 10.0,
      );

      // Marquee enclosing only Stroke 1: Rect(40, 40, 170, 20) -> from (40, 40) to (210, 60)
      final marqueeStroke1 = const Rect.fromLTRB(40, 40, 210, 60);

      expect(isContentInOrIntersectsRect(stroke1, marqueeStroke1), isTrue);
      expect(isContentInOrIntersectsRect(stroke2, marqueeStroke1), isFalse,
          reason: 'Stroke 2 is below the marquee and must not be selected');
    });

    testWidgets('Periodic saveProject does NOT dismiss or stamp activeSticker', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
          ],
          home: Scaffold(
            body: Container(),
          ),
        ),
      );

      final controller = EditorController(repository: ProjectRepository());
      final drawingController = controller.drawingController;

      final layer = LayerData(
        id: 'layer_1',
        name: 'Layer 1',
        isVisible: true,
        isLocked: false,
      );
      drawingController.layers.add(layer);
      drawingController.activeLayer.value = layer;

      final stroke = FreehandLine.data(
        points: [const Offset(50, 50), const Offset(100, 100)],
        paint: Paint()..strokeWidth = 10.0,
      );
      layer.history.add(stroke);
      layer.currentIndex = 1;

      controller.activeCategory = 'Select';
      final BuildContext context = tester.element(find.byType(Container));
      controller.selectElementAt(const Offset(60, 60), context);

      expect(controller.activeSticker, isNotNull, reason: 'Sticker should be active after selection');

      // Trigger periodic auto-save (stampStickers = false)
      await controller.saveProject(immediate: true, stampStickers: false);

      expect(controller.activeSticker, isNotNull,
          reason: 'Auto-save must NEVER dismiss activeSticker while user is editing');
    });

    testWidgets('Tapping 1 object when 2 objects have overlapping bounds selects ONLY that 1 object (not grouped)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [AppLocalizations.delegate],
          home: Scaffold(body: Container()),
        ),
      );

      final controller = EditorController(repository: ProjectRepository());
      final drawingController = controller.drawingController;

      final layer = LayerData(id: 'layer_1', name: 'Layer 1', isVisible: true, isLocked: false);
      drawingController.layers.add(layer);
      drawingController.activeLayer.value = layer;

      // Stroke 1: Loop at top left (100, 100) to (200, 200)
      final stroke1 = FreehandLine.data(
        points: [const Offset(100, 100), const Offset(200, 100), const Offset(200, 200), const Offset(100, 200)],
        paint: Paint()..strokeWidth = 10.0,
      );

      // Stroke 2: Separate scribble at bottom left (100, 250) to (150, 350)
      final stroke2 = FreehandLine.data(
        points: [const Offset(100, 250), const Offset(150, 300), const Offset(100, 350)],
        paint: Paint()..strokeWidth = 10.0,
      );

      layer.history.addAll([stroke1, stroke2]);
      layer.currentIndex = 2;

      controller.activeCategory = 'Select';
      final BuildContext context = tester.element(find.byType(Container));

      // Tap on Stroke 1 at (150, 100)
      controller.onSelectPointerDown(const Offset(150, 100));
      // Simulate minor finger touch movement (e.g. 10px)
      controller.onSelectPointerMove(const Offset(155, 105));
      controller.onSelectPointerUp(const Offset(155, 105), context);

      expect(controller.activeSticker, isNotNull);
      final sticker = controller.activeSticker;
      // It must NOT be a GroupContent
      if (sticker is ActiveShapeSticker) {
        expect(sticker.content, isNot(isA<GroupContent>()),
            reason: 'Tapping 1 object must NEVER group with other objects');
      }
    });
  });
}


