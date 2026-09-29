import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/package_code/paint_contents.dart';
import 'package:dummy/package_code/src/paint_contents/layer_data.dart';
import 'package:dummy/package_code/src/drawing_board.dart';
import 'package:dummy/package_code/src/drawing_controller.dart';
import 'package:dummy/features/editor/presentation/widgets/layer_panel.dart';

void main() {
  testWidgets('Layer blend mode change invalidates cache and triggers repaint', (tester) async {
    final controller = DrawingController();

    // Layer 1 (Bottom): Red rectangle
    final layer1 = controller.activeLayer.value!;
    controller.addContent(
      Rectangle.data(
        startPoint: const Offset(10, 10),
        endPoint: const Offset(100, 100),
        paint: Paint()..color = const Color(0xFFFF0000)..style = PaintingStyle.fill,
      ),
    );

    // Add Layer 2 (Top): Blue rectangle
    final layer2 = LayerData(
      id: 'layer_2',
      name: 'Layer 2',
      blendMode: BlendMode.srcOver,
    );
    controller.layers.insert(0, layer2);
    controller.activeLayer.value = layer2;

    controller.addContent(
      Rectangle.data(
        startPoint: const Offset(50, 50),
        endPoint: const Offset(150, 150),
        paint: Paint()..color = const Color(0xFF0000FF)..style = PaintingStyle.fill,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: DrawingBoard(
                background: Container(width: 300, height: 300, color: Colors.white),
                controller: controller,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify snapshot generation with BlendMode.srcOver
    final imgNormal = controller.generateSnapshotSync(const Size(300, 300));
    expect(imgNormal, isNotNull);

    // Change Layer 2 blend mode to Multiply
    layer2.blendMode = BlendMode.multiply;
    controller.refresh();
    await tester.pumpAndSettle();

    // Cache should be cleared and new snapshot rendered with Multiply
    expect(controller.cachedImage, isNull);
    final imgMultiply = controller.generateSnapshotSync(const Size(300, 300));
    expect(imgMultiply, isNotNull);
  });

  testWidgets('LayerPanel renders curated mostly-used blend modes in modern bottom sheet', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = DrawingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: LayerPanel(
              controller: controller,
              onClose: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the expand button on Layer 1
    final expandFinder = find.byIcon(Icons.keyboard_arrow_down);
    expect(expandFinder, findsOneWidget);
    await tester.tap(expandFinder);
    await tester.pumpAndSettle();

    // Find the blend mode tile button
    final blendTileFinder = find.text('Blend');
    expect(blendTileFinder, findsOneWidget);

    // Open the blend mode bottom sheet
    await tester.tap(blendTileFinder);
    await tester.pumpAndSettle();

    // Verify sheet title and curated blend modes with descriptions are present
    expect(find.text('${controller.activeLayer.value?.name} Blend Mode'), findsOneWidget);
    expect(find.text('Normal'), findsWidgets);
    expect(find.text('Multiply'), findsOneWidget);
    expect(find.text('Darkens base colors; ideal for shading & shadows'), findsOneWidget);
    expect(find.text('Screen'), findsOneWidget);
    expect(find.text('Overlay'), findsOneWidget);

    // Verify non-standard/unused blend modes are completely excluded
    expect(find.text('Exclusion'), findsNothing);
    expect(find.text('Hue'), findsNothing);
    expect(find.text('Saturation'), findsNothing);
    expect(find.text('Luminosity'), findsNothing);

    // Select Multiply
    await tester.tap(find.text('Multiply'));
    await tester.pumpAndSettle();

    expect(controller.activeLayer.value?.blendMode, equals(BlendMode.multiply));

    // Close the sheet
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // Verify the Layer Item now displays the Multiply mode badge
    expect(find.text('Multiply'), findsWidgets);
  });
}
