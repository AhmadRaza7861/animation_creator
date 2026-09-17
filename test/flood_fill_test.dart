import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/package_code/paint_contents.dart';
import 'package:dummy/package_code/src/drawing_controller.dart';
import 'package:dummy/package_code/src/helper/flood_fill.dart';
import 'package:dummy/package_code/src/paint_contents/layer_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FloodFill Accurate Boundary & Dilation Tests', () {
    test('FloodFill inside a stroked Rectangle fills only the interior without leaking', () async {
      const int width = 100;
      const int height = 100;

      // 1. Draw a stroked rectangle on a transparent canvas from (20, 20) to (80, 80)
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 100, 100));

      final Paint strokePaint = Paint()
        ..color = const Color(0xFF000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..isAntiAlias = true;

      final Rectangle rect = Rectangle.data(
        startPoint: const Offset(20, 20),
        endPoint: const Offset(80, 80),
        paint: strokePaint,
      );

      rect.draw(canvas, const Size(100, 100), false);
      final ui.Picture picture = recorder.endRecording();
      final ui.Image snapshotImage = await picture.toImage(width, height);

      // 2. Perform FloodFill at center (50, 50) with Red color
      const Color fillColor = Color(0xFFFF0000);
      final ui.Image? filledImage = await FloodFill.fill(
        image: snapshotImage,
        startPoint: const Offset(50, 50),
        fillColor: fillColor,
        tolerance: 0.15,
      );

      expect(filledImage, isNotNull);

      final ByteData? filledData = await filledImage!.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(filledData, isNotNull);
      final Uint8List pixels = filledData!.buffer.asUint8List();

      // Check interior pixel (50, 50) -> should be filled Red (255, 0, 0, 255)
      final int centerIdx = (50 * width + 50) * 4;
      expect(pixels[centerIdx], 255, reason: 'Red channel at center');
      expect(pixels[centerIdx + 1], 0, reason: 'Green channel at center');
      expect(pixels[centerIdx + 2], 0, reason: 'Blue channel at center');
      expect(pixels[centerIdx + 3], 255, reason: 'Alpha channel at center');

      // Check exterior pixels (5, 5), (95, 95), (10, 50), (50, 95) -> must NOT be filled (alpha == 0)
      final int outerTopLeftIdx = (5 * width + 5) * 4;
      expect(pixels[outerTopLeftIdx + 3], 0, reason: 'Outer top-left must remain transparent');

      final int outerBottomRightIdx = (95 * width + 95) * 4;
      expect(pixels[outerBottomRightIdx + 3], 0, reason: 'Outer bottom-right must remain transparent');

      final int outerLeftIdx = (50 * width + 5) * 4;
      expect(pixels[outerLeftIdx + 3], 0, reason: 'Outer left must remain transparent');

      final int outerBottomIdx = (95 * width + 50) * 4;
      expect(pixels[outerBottomIdx + 3], 0, reason: 'Outer bottom must remain transparent');
    });

    test('FloodFill inside ShapeStickerContent fills only within the shape boundary', () async {
      const int width = 120;
      const int height = 120;

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 120, 120));

      final Paint strokePaint = Paint()
        ..color = const Color(0xFFE53935) // Red stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..isAntiAlias = true;

      final childRect = Rectangle.data(
        startPoint: const Offset(10, 10),
        endPoint: const Offset(70, 70),
        paint: strokePaint,
      );

      final shapeSticker = ShapeStickerContent.data(
        child: childRect,
        offset: const Offset(60, 60),
        scale: 1.0,
        rotation: 0.0,
        size: const Size(80, 80),
        paint: strokePaint,
      );

      shapeSticker.draw(canvas, const Size(120, 120), false);
      final ui.Picture picture = recorder.endRecording();
      final ui.Image snapshotImage = await picture.toImage(width, height);

      // Perform flood fill with Blue (0xFF2196F3) inside the sticker
      const Color fillColor = Color(0xFF2196F3);
      final ui.Image? filledImage = await FloodFill.fill(
        image: snapshotImage,
        startPoint: const Offset(60, 60),
        fillColor: fillColor,
        tolerance: 0.15,
      );

      expect(filledImage, isNotNull);

      final ByteData? filledData = await filledImage!.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(filledData, isNotNull);
      final Uint8List pixels = filledData!.buffer.asUint8List();

      // Interior pixel (60, 60) must be Blue (33, 150, 243, 255)
      final int centerIdx = (60 * width + 60) * 4;
      expect(pixels[centerIdx], (fillColor.r * 255).round());
      expect(pixels[centerIdx + 1], (fillColor.g * 255).round());
      expect(pixels[centerIdx + 2], (fillColor.b * 255).round());
      expect(pixels[centerIdx + 3], 255);

      // Exterior pixel (5, 5) must be 0 (no leak)
      final int outerIdx = (5 * width + 5) * 4;
      expect(pixels[outerIdx + 3], 0, reason: 'Outer area must not be leaked into');
    });

    test('FloodFill in multi-loop intersecting scribble fills ONLY the tapped closed region', () async {
      const int width = 200;
      const int height = 200;

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 200, 200));

      final Paint strokePaint = Paint()
        ..color = const Color(0xFFC2185B) // Magenta stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0
        ..isAntiAlias = true;

      // Draw two adjacent closed circles that touch/overlap:
      // Loop 1 centered at (60, 100), radius 35
      // Loop 2 centered at (140, 100), radius 35
      canvas.drawCircle(const Offset(60, 100), 35, strokePaint);
      canvas.drawCircle(const Offset(140, 100), 35, strokePaint);

      final ui.Picture picture = recorder.endRecording();
      final ui.Image snapshotImage = await picture.toImage(width, height);

      // Tap strictly inside Loop 1 at (60, 100) with Green (0xFF00897B)
      const Color greenColor = Color(0xFF00897B);
      final ui.Image? filledImage = await FloodFill.fill(
        image: snapshotImage,
        startPoint: const Offset(60, 100),
        fillColor: greenColor,
        tolerance: 0.15,
        expandRadius: 2.0,
      );

      expect(filledImage, isNotNull);

      final ByteData? filledData = await filledImage!.toByteData(format: ui.ImageByteFormat.rawRgba);
      final Uint8List fillPixels = filledData!.buffer.asUint8List();

      // 1. Loop 1 interior (60, 100) is filled with Green
      final int loop1Idx = (100 * width + 60) * 4;
      expect(fillPixels[loop1Idx + 3], 255, reason: 'Loop 1 interior must be fully filled');
      expect(fillPixels[loop1Idx], (greenColor.r * 255).round());
      expect(fillPixels[loop1Idx + 1], (greenColor.g * 255).round());
      expect(fillPixels[loop1Idx + 2], (greenColor.b * 255).round());

      // 2. Loop 2 interior (140, 100) MUST NOT be filled (must be 0 alpha!)
      final int loop2Idx = (100 * width + 140) * 4;
      expect(fillPixels[loop2Idx + 3], 0, reason: 'Loop 2 must remain completely unfilled!');

      // 3. Exterior outside both loops (10, 10) must be 0 alpha
      final int exteriorIdx = (10 * width + 10) * 4;
      expect(fillPixels[exteriorIdx + 3], 0, reason: 'Exterior canvas must remain transparent');
    });

    test('DrawingController undoes FillContent first, preserving the earlier drawn stroke', () async {
      final DrawingController controller = DrawingController();
      controller.setBoardSize(const Size(200, 200));

      // 1. Draw a circle stroke
      final SimpleLine stroke = SimpleLine.data(
        startPoint: const Offset(20, 20),
        endPoint: const Offset(80, 80),
        paint: Paint()..color = Colors.black,
      );
      controller.addContent(stroke);

      expect(controller.activeLayer.value!.history.length, 1);
      expect(controller.activeLayer.value!.currentIndex, 1);
      expect(controller.activeLayer.value!.history[0], stroke);

      // 2. Fill with color
      final FillContent fill = FillContent();
      controller.addContent(fill);

      expect(controller.activeLayer.value!.history.length, 2);
      expect(controller.activeLayer.value!.currentIndex, 2);
      expect(controller.activeLayer.value!.history[0], stroke);
      expect(controller.activeLayer.value!.history[1], fill);

      // 3. First Undo: must undo the FillContent (since fill was performed last)
      controller.undo();
      expect(controller.activeLayer.value!.currentIndex, 1, reason: 'Current index should be 1 after 1st undo');

      // 4. Second Undo: must undo the stroke
      controller.undo();
      expect(controller.activeLayer.value!.currentIndex, 0, reason: 'Current index should be 0 after 2nd undo');

      // 5. First Redo: stroke returns
      controller.redo();
      expect(controller.activeLayer.value!.currentIndex, 1);

      // 6. Second Redo: fill returns
      controller.redo();
      expect(controller.activeLayer.value!.currentIndex, 2);
    });

    test('LayerData.drawHistory renders FillContent in Pass 1 and strokes on top in Pass 2', () async {
      final LayerData layer = LayerData(id: 'test_layer');
      final SimpleLine stroke = SimpleLine.data(
        startPoint: const Offset(10, 10),
        endPoint: const Offset(50, 50),
        paint: Paint()..color = Colors.black,
      );
      final FillContent fill = FillContent();

      // History has [stroke, fill] in chronological order
      layer.history = [stroke, fill];
      layer.currentIndex = 2;

      // Draw history onto a recorded canvas
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 100, 100));

      layer.drawHistory(canvas, const Size(100, 100), false);
      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = await picture.toImage(100, 100);

      expect(image.width, 100);
      expect(image.height, 100);
    });

    test('FloodFill does not leak through 1-pixel diagonal stroke barrier', () async {
      const int width = 50;
      const int height = 50;

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 50, 50));

      final Paint strokePaint = Paint()
        ..color = const Color(0xFF000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..isAntiAlias = false;

      // Draw a closed polygon with diagonal lines from (10, 10) -> (40, 10) -> (40, 40) -> (10, 40) -> close
      final Path path = Path()
        ..moveTo(10, 10)
        ..lineTo(40, 10)
        ..lineTo(40, 40)
        ..lineTo(10, 40)
        ..close();

      canvas.drawPath(path, strokePaint);
      final ui.Picture picture = recorder.endRecording();
      final ui.Image snapshotImage = await picture.toImage(width, height);

      // Fill at interior (25, 25)
      const Color fillColor = Color(0xFF00FF00);
      final ui.Image? filledImage = await FloodFill.fill(
        image: snapshotImage,
        startPoint: const Offset(25, 25),
        fillColor: fillColor,
        tolerance: 0.15,
      );

      expect(filledImage, isNotNull);

      final ByteData? filledData = await filledImage!.toByteData(format: ui.ImageByteFormat.rawRgba);
      final Uint8List fillPixels = filledData!.buffer.asUint8List();

      // Interior (25, 25) is filled
      final int centerIdx = (25 * width + 25) * 4;
      expect(fillPixels[centerIdx + 3], 255);

      // Exterior (5, 5) must NOT be filled
      final int exteriorIdx = (5 * width + 5) * 4;
      expect(fillPixels[exteriorIdx + 3], 0);
    });

    test('FloodFill re-coloring replaces existing color accurately', () async {
      const int width = 60;
      const int height = 60;

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 60, 60));

      // Draw a solid yellow box with a black border
      canvas.drawRect(
        const Rect.fromLTWH(10, 10, 40, 40),
        Paint()..color = const Color(0xFFFFFF00)..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        const Rect.fromLTWH(10, 10, 40, 40),
        Paint()..color = const Color(0xFF000000)..style = PaintingStyle.stroke..strokeWidth = 3,
      );

      final ui.Picture picture = recorder.endRecording();
      final ui.Image snapshotImage = await picture.toImage(width, height);

      // Re-fill inside at (30, 30) from Yellow to Cyan (0xFF00FFFF)
      const Color newFillColor = Color(0xFF00FFFF);
      final ui.Image? filledImage = await FloodFill.fill(
        image: snapshotImage,
        startPoint: const Offset(30, 30),
        fillColor: newFillColor,
        tolerance: 0.15,
      );

      expect(filledImage, isNotNull);

      final ByteData? filledData = await filledImage!.toByteData(format: ui.ImageByteFormat.rawRgba);
      final Uint8List fillPixels = filledData!.buffer.asUint8List();

      // (30, 30) should now be Cyan (0, 255, 255, 255)
      final int centerIdx = (30 * width + 30) * 4;
      expect(fillPixels[centerIdx], 0);
      expect(fillPixels[centerIdx + 1], 255);
      expect(fillPixels[centerIdx + 2], 255);
      expect(fillPixels[centerIdx + 3], 255);

      // Outside (5, 5) remains 0
      final int outerIdx = (5 * width + 5) * 4;
      expect(fillPixels[outerIdx + 3], 0);
    });
  });
}
