import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/package_code/paint_contents.dart';
import 'package:dummy/package_code/src/drawing_board.dart';
import 'package:dummy/package_code/src/drawing_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Canvas Multi-Touch Gesture Handling & Rotation Tests', () {
    test('DrawingController multi-touch cancels active drawing and blocks new drawing', () {
      final DrawingController controller = DrawingController();
      controller.setBoardSize(const Size(500, 500));

      // 1. Single finger touches down -> drawing is allowed
      controller.addFingerCount(const Offset(100, 100));
      expect(controller.drawConfig.value.fingerCount, 1);
      expect(controller.isNavigating, isFalse);
      expect(controller.couldStartDraw, isTrue);
      expect(controller.couldDrawing, isTrue);

      // Start a stroke
      controller.startDraw(const Offset(100, 100));
      expect(controller.hasPaintingContent, isTrue);

      // 2. Second finger lands (e.g. pinch-to-zoom / rotate) -> multi-touch activated
      controller.addFingerCount(const Offset(200, 200));
      expect(controller.drawConfig.value.fingerCount, 2);
      expect(controller.isNavigating, isTrue);
      expect(controller.couldStartDraw, isFalse);
      expect(controller.couldDrawing, isFalse);
      // Active stroke MUST be immediately cancelled and wiped
      expect(controller.hasPaintingContent, isFalse);
      expect(controller.startPoint, isNull);

      // 3. First finger lifted -> 1 finger remains, zoom ends and drawing is re-enabled
      controller.reduceFingerCount(const Offset(100, 100));
      expect(controller.drawConfig.value.fingerCount, 1);
      expect(controller.isNavigating, isFalse);
      expect(controller.couldStartDraw, isTrue);

      // 4. All fingers lifted -> navigation resets
      controller.reduceFingerCount(const Offset(200, 200));
      expect(controller.drawConfig.value.fingerCount, 0);
      expect(controller.isNavigating, isFalse);
      expect(controller.couldStartDraw, isTrue);

      // 5. Fresh single finger lands -> drawing resumes cleanly
      controller.addFingerCount(const Offset(150, 150));
      expect(controller.drawConfig.value.fingerCount, 1);
      expect(controller.isNavigating, isFalse);
      expect(controller.couldStartDraw, isTrue);
    });

    testWidgets('Single finger drag draws a stroke on DrawingBoard', (WidgetTester tester) async {
      final DrawingController controller = DrawingController();
      final TransformationController transformController = TransformationController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 400,
                child: DrawingBoard(
                  controller: controller,
                  transformationController: transformController,
                  background: Container(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(controller.getHistory.length, 0);

      // Single finger drag to draw
      final TestGesture gesture = await tester.startGesture(const Offset(250, 250));
      await tester.pump();
      await gesture.moveTo(const Offset(300, 300));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(controller.getHistory.length, 1);
      expect(transformController.value, equals(Matrix4.identity()));
    });

    testWidgets('DrawingBoard transforms with two-finger pinch, pan, and rotation', (WidgetTester tester) async {
      final DrawingController controller = DrawingController();
      final TransformationController transformController = TransformationController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 400,
                child: DrawingBoard(
                  controller: controller,
                  transformationController: transformController,
                  background: Container(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      );

      expect(transformController.value, equals(Matrix4.identity()));

      // Simulate 2-finger touch inside the 400x400 box centered at (400, 300)
      final TestGesture gesture1 = await tester.createGesture(pointer: 1);
      final TestGesture gesture2 = await tester.createGesture(pointer: 2);

      await gesture1.down(const Offset(350, 300));
      await gesture2.down(const Offset(450, 300));
      await tester.pump();

      expect(controller.isNavigating, isTrue);

      // Rotate 2 fingers by moving gesture1 up and gesture2 down (clockwise)
      await gesture1.moveTo(const Offset(400, 250));
      await gesture2.moveTo(const Offset(400, 350));
      await tester.pump();

      // Matrix must be rotated
      final Matrix4 matrix = transformController.value;
      expect(matrix, isNot(equals(Matrix4.identity())));
      final double rotZ = math.atan2(matrix.storage[1], matrix.storage[0]);
      expect(rotZ.abs(), greaterThan(0.1));

      // Lift both fingers
      await gesture1.up();
      await gesture2.up();
      await tester.pump(const Duration(milliseconds: 600));

      expect(controller.isNavigating, isFalse);
    });

    testWidgets('Expander icon only shows when canvas is transformed from identity', (WidgetTester tester) async {
      final TransformationController transformController = TransformationController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                ValueListenableBuilder<Matrix4>(
                  valueListenable: transformController,
                  builder: (context, matrix, child) {
                    final bool isTransformed = !matrix.isIdentity();
                    if (!isTransformed) {
                      return const SizedBox.shrink();
                    }
                    return IconButton(
                      key: const Key('reset_zoom_button'),
                      icon: const Icon(Icons.crop_free),
                      onPressed: () {
                        transformController.value = Matrix4.identity();
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );

      // Initially identity -> reset button is not present
      expect(find.byKey(const Key('reset_zoom_button')), findsNothing);

      // Transform (zoom / pan / rotate)
      transformController.value = Matrix4.identity()..scale(2.0, 2.0, 1.0);
      await tester.pump();

      // Now reset button is visible
      expect(find.byKey(const Key('reset_zoom_button')), findsOneWidget);

      // Tap reset button
      await tester.tap(find.byKey(const Key('reset_zoom_button')));
      await tester.pump();

      // Matrix is back to identity -> reset button disappears
      expect(transformController.value, equals(Matrix4.identity()));
      expect(find.byKey(const Key('reset_zoom_button')), findsNothing);
    });

    testWidgets('Paint Bucket tool is cancelled during 2-finger zoom and does not trigger fill', (WidgetTester tester) async {
      final DrawingController controller = DrawingController();
      final TransformationController transformController = TransformationController();

      // Select Paint Bucket tool
      controller.setPaintContent(FillContent());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 400,
                child: DrawingBoard(
                  controller: controller,
                  transformationController: transformController,
                  background: Container(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(controller.getHistory.length, 0);

      // 2 fingers touch down to pinch-zoom
      final TestGesture gesture1 = await tester.createGesture(pointer: 1);
      final TestGesture gesture2 = await tester.createGesture(pointer: 2);

      await gesture1.down(const Offset(350, 300));
      await tester.pump(const Duration(milliseconds: 10));
      await gesture2.down(const Offset(450, 300));
      await tester.pump(const Duration(milliseconds: 10));

      expect(controller.isNavigating, isTrue);
      expect(controller.hasPaintingContent, isFalse);

      // Pinch out (zoom in)
      await gesture1.moveTo(const Offset(300, 300));
      await gesture2.moveTo(const Offset(500, 300));
      await tester.pump();

      // Lift both fingers
      await gesture1.up();
      await gesture2.up();
      await tester.pumpAndSettle();

      // Ensure NO fill content was committed to history during zoom
      expect(controller.getHistory.length, 0);
      expect(controller.isNavigating, isFalse);
      expect(controller.isZooming, isFalse);
      expect(controller.pointerCount, 0);
    });

    testWidgets('Eyedropper is cancelled during 2-finger zoom and does not change color', (WidgetTester tester) async {
      final DrawingController controller = DrawingController();
      final TransformationController transformController = TransformationController();

      controller.setStyle(color: Colors.red);
      controller.setPaintContent(Eyedropper());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 400,
                child: DrawingBoard(
                  controller: controller,
                  transformationController: transformController,
                  background: Container(color: Colors.blue),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // 2 fingers pinch
      final TestGesture gesture1 = await tester.createGesture(pointer: 1);
      final TestGesture gesture2 = await tester.createGesture(pointer: 2);

      await gesture1.down(const Offset(350, 300));
      await gesture2.down(const Offset(450, 300));
      await tester.pump();

      expect(controller.isNavigating, isTrue);
      expect(controller.hasPaintingContent, isFalse);

      await gesture1.moveTo(const Offset(320, 300));
      await gesture2.moveTo(const Offset(480, 300));
      await tester.pump();

      await gesture1.up();
      await gesture2.up();
      await tester.pumpAndSettle();

      // Color remains red
      expect(controller.getColor, Colors.red);
      expect(controller.isNavigating, isFalse);
    });
  });
}
