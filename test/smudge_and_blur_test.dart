import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/package_code/src/drawing_controller.dart';
import 'package:dummy/package_code/src/paint_contents/blur.dart';
import 'package:dummy/package_code/src/paint_contents/smudge.dart';
import 'package:dummy/package_code/src/paint_contents/simple_line.dart';
import 'package:dummy/package_code/src/paint_contents/layer_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ui.Image> createTestImage(int width, int height, {Color color = Colors.black}) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = color,
    );
    final ui.Picture picture = recorder.endRecording();
    return await picture.toImage(width, height);
  }

  Future<ui.Image> createStripeImage(int width, int height) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    // Draw black stripe on the left half (0..width/2), right half transparent
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width / 2, height.toDouble()),
      Paint()..color = Colors.black,
    );
    final ui.Picture picture = recorder.endRecording();
    return await picture.toImage(width, height);
  }

  group('Blur & Smudge Tools Test Suite', () {
    test('BlurContent can sample snapshot image and draw smoothly without errors', () async {
      final ui.Image testImg = await createTestImage(200, 200);
      final BlurContent blur = BlurContent(strength: 0.6);
      blur.setImageData(testImg);
      blur.startDraw(const Offset(50, 50));
      blur.drawing(const Offset(100, 100));

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      expect(() => blur.draw(canvas, const Size(200, 200), false), returnsNormally);
      expect(() => blur.draw(canvas, const Size(200, 200), true), returnsNormally);

      final BlurContent copy = blur.copy();
      expect(copy.strength, equals(0.6));
      expect(copy.image, equals(testImg));

      final Map<String, dynamic> json = blur.toContentJson();
      expect(json['strength'], equals(0.6));
    });

    test('SmudgeContent displaces paint in drag direction and preserves alpha', () async {
      // 100x100 image: left half is black (0..50), right half is transparent (50..100)
      final ui.Image stripeImg = await createStripeImage(100, 100);
      final ByteData? initialByteData = await stripeImg.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(initialByteData, isNotNull);

      final SmudgeContent smudge = SmudgeContent(strength: 0.8);
      smudge.paint.strokeWidth = 30.0;
      smudge.setRgbaData(initialByteData!.buffer.asUint8List(), 100, 100);

      // Drag from black area (x=40, y=50) into transparent area (x=70, y=50)
      smudge.startDrawWithPressure(const Offset(40, 50), 1.0);
      smudge.drawingWithPressure(const Offset(55, 50), 1.0);
      smudge.drawingWithPressure(const Offset(70, 50), 1.0);

      expect(smudge.rgbaData, isNotNull);
      final Uint8List resultBytes = smudge.rgbaData!;

      // Check pixel at (x=60, y=50) - was originally 100% transparent (alpha=0),
      // should now have paint pulled into it (alpha > 0 and color is black RGB=0,0,0)
      final int idx = (50 * 100 + 60) * 4;
      final int r = resultBytes[idx];
      final int g = resultBytes[idx + 1];
      final int b = resultBytes[idx + 2];
      final int a = resultBytes[idx + 3];

      expect(a, greaterThan(0), reason: 'Paint should have smeared into the transparent area');
      expect(r, equals(0), reason: 'Smeared black paint should have 0 red channel');
      expect(g, equals(0), reason: 'Smeared black paint should have 0 green channel');
      expect(b, equals(0), reason: 'Smeared black paint should have 0 blue channel');

      // Check pixel far away at (x=95, y=50) - should remain 100% transparent (alpha=0)
      final int farIdx = (50 * 100 + 95) * 4;
      expect(resultBytes[farIdx + 3], equals(0), reason: 'Pixels outside smudge radius must remain unaffected');
    });

    test('SmudgeContent copy, serialize and export functions', () async {
      final ui.Image testImg = await createTestImage(100, 100);
      final SmudgeContent smudge = SmudgeContent(strength: 0.75);
      smudge.paint.strokeWidth = 20.0;
      smudge.setImageData(testImg);
      smudge.startDraw(const Offset(10, 10));
      smudge.drawing(const Offset(30, 30));

      final SmudgeContent copy = smudge.copy();
      expect(copy.strength, equals(0.75));
      expect(copy.points.length, equals(2));
      expect(copy.paint.strokeWidth, equals(20.0));

      final Map<String, dynamic> json = smudge.toContentJson();
      expect(json['strength'], equals(0.75));
      expect((json['points'] as List).length, equals(2));

      final SmudgeContent fromJson = SmudgeContent.fromJson(smudge.toJson());
      expect(fromJson.strength, equals(0.75));
      expect(fromJson.points.length, equals(2));
    });

    test('DrawingController single-step Undo and Redo with Smudge tool', () async {
      final DrawingController controller = DrawingController();
      controller.setBoardSize(const Size(400, 400));

      // 1. Draw 2 base strokes
      controller.setPaintContent(FreehandLine());
      controller.startDraw(const Offset(50, 50));
      controller.drawing(const Offset(50, 150));
      controller.endDraw();
      expect(controller.getHistory.length, equals(1));

      controller.startDraw(const Offset(100, 50));
      controller.drawing(const Offset(100, 150));
      controller.endDraw();
      expect(controller.getHistory.length, equals(2));

      // 2. Perform a Smudge stroke across the lines
      controller.setPaintContent(SmudgeContent(strength: 0.6));
      controller.startDraw(const Offset(40, 100));
      expect(controller.drawingContent is SmudgeContent, isTrue);
      controller.drawing(const Offset(80, 100));
      controller.drawing(const Offset(120, 100));
      controller.endDraw();

      // Verify that the entire smudge stroke is exactly ONE action
      expect(controller.getHistory.length, equals(3));
      expect(controller.getHistory.last is SmudgeContent, isTrue);
      expect(controller.canUndo(), isTrue);

      // 3. Undo the smudge stroke
      controller.undo();
      expect(controller.currentIndex, equals(2));
      expect(controller.getHistory[controller.currentIndex - 1] is FreehandLine, isTrue);

      // 4. Redo the smudge stroke
      expect(controller.canRedo(), isTrue);
      controller.redo();
      expect(controller.currentIndex, equals(3));
      expect(controller.getHistory.last is SmudgeContent, isTrue);
    });

    test('Multi-layer isolation: Smudge on active layer does not alter other layers', () async {
      final DrawingController controller = DrawingController();
      controller.setBoardSize(const Size(400, 400));

      // Layer 0: Background drawing
      final LayerData layer0 = controller.layers.first;
      controller.activeLayer.value = layer0;
      controller.setPaintContent(FreehandLine());
      controller.startDraw(const Offset(10, 10));
      controller.drawing(const Offset(10, 100));
      controller.endDraw();
      expect(layer0.history.length, equals(1));

      // Layer 1: Foreground drawing
      final LayerData layer1 = LayerData(id: 'layer_1', name: 'Foreground');
      controller.layers.insert(0, layer1);
      controller.activeLayer.value = layer1;

      controller.startDraw(const Offset(50, 50));
      controller.drawing(const Offset(50, 200));
      controller.endDraw();
      expect(layer1.history.length, equals(1));

      // Smudge on Layer 1
      controller.setPaintContent(SmudgeContent(strength: 0.5));
      controller.startDraw(const Offset(45, 100));
      controller.drawing(const Offset(70, 100));
      controller.endDraw();

      // Layer 1 history has smudge added
      expect(layer1.history.length, equals(2));
      expect(layer1.history.last is SmudgeContent, isTrue);

      // Layer 0 history is completely untouched
      expect(layer0.history.length, equals(1));
      expect(layer0.history.first is FreehandLine, isTrue);
    });

    test('Smudge actively pulls pixels from base stroke during live drawing lifecycle', () async {
      final DrawingController controller = DrawingController();
      controller.setBoardSize(const Size(200, 200));

      // 1. Draw a thick black line at x=50, y=0..200
      controller.setStyle(color: Colors.black, strokeWidth: 20.0, style: PaintingStyle.stroke);
      controller.setPaintContent(FreehandLine());
      controller.startDraw(const Offset(50, 20));
      controller.drawing(const Offset(50, 180));
      controller.endDraw();

      // 2. Select Smudge tool
      final smudge = SmudgeContent(strength: 0.85);
      smudge.paint.strokeWidth = 30.0;
      controller.setPaintContent(smudge);
      controller.setStyle(strokeWidth: 30.0);
      controller.prepareSnapshot();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // 3. Start smudge at (50, 100) and drag to (90, 100)
      controller.startDraw(const Offset(50, 100));
      controller.drawing(const Offset(70, 100));
      controller.drawing(const Offset(90, 100));
      controller.endDraw();

      // Wait for live image decoding
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // 4. Verify that the committed SmudgeContent has pixel buffer and image
      final lastContent = controller.getHistory.last as SmudgeContent;
      expect(lastContent.rgbaData, isNotNull);
      final Uint8List pixels = lastContent.rgbaData!;

      // Check pixel at logical (x=70, y=100) mapped to buffer resolution (inside smeared region)
      final int w = lastContent.rgbaWidth!;
      final int h = lastContent.rgbaHeight!;
      final int pxX = (70 * (w / 200.0)).round().clamp(0, w - 1);
      final int pxY = (100 * (h / 200.0)).round().clamp(0, h - 1);
      final int idx = (pxY * w + pxX) * 4;
      final int a = pixels[idx + 3];
      expect(a, greaterThan(0), reason: 'Smudge must actively smear black paint from line into x=70');
    });

    test('Multiple consecutive smudge strokes retain accumulated smear without resetting', () async {
      final DrawingController controller = DrawingController();
      controller.setBoardSize(const Size(200, 200));

      // Draw initial green line
      controller.setStyle(color: const Color(0xFF00AA00), strokeWidth: 20.0);
      controller.setPaintContent(FreehandLine());
      controller.startDraw(const Offset(40, 20));
      controller.drawing(const Offset(40, 180));
      controller.endDraw();

      // First smudge stroke: drag from 40 to 80
      final smudge1 = SmudgeContent(strength: 0.85);
      smudge1.paint.strokeWidth = 30.0;
      controller.setPaintContent(smudge1);
      controller.setStyle(strokeWidth: 30.0);
      controller.prepareSnapshot();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      controller.startDraw(const Offset(40, 100));
      controller.drawing(const Offset(60, 100));
      controller.drawing(const Offset(80, 100));
      controller.endDraw();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Second smudge stroke: drag from 55 to 110 (dragging the already smeared paint further)
      final smudge2 = SmudgeContent(strength: 0.85);
      smudge2.paint.strokeWidth = 30.0;
      controller.setPaintContent(smudge2);
      controller.setStyle(strokeWidth: 30.0);
      controller.startDraw(const Offset(55, 100));
      controller.drawing(const Offset(85, 100));
      controller.drawing(const Offset(110, 100));
      controller.endDraw();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(controller.getHistory.length, equals(3));
      final lastSmudge = controller.getHistory.last as SmudgeContent;
      expect(lastSmudge.rgbaData, isNotNull);

      final Uint8List pixels = lastSmudge.rgbaData!;
      final int w = lastSmudge.rgbaWidth!;
      final int h = lastSmudge.rgbaHeight!;
      final int pxX = (100 * (w / 200.0)).round().clamp(0, w - 1);
      final int pxY = (100 * (h / 200.0)).round().clamp(0, h - 1);
      final int idx = (pxY * w + pxX) * 4;
      final int a = pixels[idx + 3];
      final int g = pixels[idx + 1];

      expect(a, greaterThan(0), reason: 'Second smudge stroke should drag green paint all the way to x=100');
      expect(g, greaterThan(0), reason: 'Should preserve green channel in second smudge stroke');
    });

    test('DrawingController releases unmanaged working pixel buffers from superseded smudge strokes in history', () async {
      final DrawingController controller = DrawingController();
      controller.setBoardSize(const Size(200, 200));

      final testImg = await createTestImage(200, 200);

      // Draw 3 consecutive smudge strokes
      for (int i = 0; i < 3; i++) {
        final smudge = SmudgeContent(strength: 0.7);
        smudge.paint.strokeWidth = 20.0;
        smudge.setImageData(testImg);
        controller.setPaintContent(smudge);
        controller.startDraw(Offset(20.0 + i * 20, 50.0));
        controller.drawing(Offset(40.0 + i * 20, 50.0));
        controller.endDraw();
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }

      final history = controller.getHistory;
      expect(history.length, equals(3));

      // Older strokes (index 0 and 1) should have had their heavy _pixels buffers released
      final stroke0 = history[0] as SmudgeContent;
      final stroke1 = history[1] as SmudgeContent;

      expect(stroke0.rgbaData, isNull, reason: 'Superseded stroke 0 pixel buffer must be released');
      expect(stroke1.rgbaData, isNull, reason: 'Superseded stroke 1 pixel buffer must be released');
    });

    test('DrawingController.getLayersConfig only serializes active raster snapshot to prevent bloated JSON and OOM crashes', () async {
      final DrawingController controller = DrawingController();
      controller.setBoardSize(const Size(100, 100));

      final testImg = await createTestImage(100, 100);

      // Create 3 smudge strokes with images
      for (int i = 0; i < 3; i++) {
        final smudge = SmudgeContent(strength: 0.7);
        smudge.paint.strokeWidth = 20.0;
        smudge.setImageData(testImg);
        controller.setPaintContent(smudge);
        controller.startDraw(Offset(10.0 + i * 10, 50.0));
        controller.drawing(Offset(20.0 + i * 10, 50.0));
        controller.endDraw();
      }

      final layersConfig = await controller.getLayersConfig();
      expect(layersConfig.length, equals(1));

      final historyJson = layersConfig.first['history'] as List<dynamic>;
      expect(historyJson.length, equals(3));

      // Strokes 0 and 1 should NOT have exported base64 image strings
      expect(historyJson[0]['imageDataBase64'], isNull, reason: 'Stroke 0 is superseded and must not bloat JSON');
      expect(historyJson[1]['imageDataBase64'], isNull, reason: 'Stroke 1 is superseded and must not bloat JSON');
      // Stroke 2 (the latest active raster state) SHOULD have exported base64 image data
      expect(historyJson[2]['imageDataBase64'], isNotNull, reason: 'Latest active raster state must be serialized');
    });

    test('BlurContent and SmudgeContent getPath returns non-empty path bounding the stroke for accurate hit-testing', () {
      final smudge = SmudgeContent(strength: 0.7);
      smudge.paint.strokeWidth = 10.0;
      smudge.startDraw(const Offset(10, 20));
      smudge.drawing(const Offset(30, 40));

      final Path smudgePath = smudge.getPath();
      final Rect bounds = smudgePath.getBounds();
      expect(bounds.left, equals(10.0));
      expect(bounds.top, equals(20.0));
      expect(bounds.right, equals(30.0));
      expect(bounds.bottom, equals(40.0));

      final blur = BlurContent(strength: 0.5);
      blur.paint.strokeWidth = 15.0;
      blur.startDraw(const Offset(50, 60));
      blur.drawing(const Offset(70, 80));

      final Path blurPath = blur.getPath();
      final Rect blurBounds = blurPath.getBounds();
      expect(blurBounds.left, equals(50.0));
      expect(blurBounds.top, equals(60.0));
      expect(blurBounds.right, equals(70.0));
      expect(blurBounds.bottom, equals(80.0));
    });

    test('Smudge at 0% intensity applies zero distortion and leaves pixels intact', () async {
      final ui.Image stripeImg = await createStripeImage(100, 100);
      final ByteData? data = await stripeImg.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(data, isNotNull);

      final Uint8List originalBytes = Uint8List.fromList(data!.buffer.asUint8List());

      final SmudgeContent smudgeZero = SmudgeContent(strength: 0.0);
      smudgeZero.paint.strokeWidth = 30.0;
      smudgeZero.setRgbaData(Uint8List.fromList(originalBytes), 100, 100, const Size(100, 100));

      smudgeZero.startDrawWithPressure(const Offset(40, 50), 1.0);
      smudgeZero.drawingWithPressure(const Offset(60, 50), 1.0);
      smudgeZero.finalizeStroke();

      final Uint8List modifiedBytes = smudgeZero.rgbaData!;
      for (int i = 0; i < originalBytes.length; i++) {
        expect(modifiedBytes[i], equals(originalBytes[i]), reason: 'At 0% smudge intensity, pixels must not be modified');
      }
    });

    test('Smudge dragging black shape into white canvas preserves rich pigment and crisp directional trail', () async {
      // Create 100x100 white canvas with black box at x: 20..50, y: 30..70
      final Uint8List rawRgba = Uint8List(100 * 100 * 4);
      for (int y = 0; y < 100; y++) {
        for (int x = 0; x < 100; x++) {
          final int idx = (y * 100 + x) * 4;
          if (x >= 20 && x < 50 && y >= 30 && y < 70) {
            rawRgba[idx] = 0;       // R (Black)
            rawRgba[idx + 1] = 0;   // G
            rawRgba[idx + 2] = 0;   // B
            rawRgba[idx + 3] = 255; // A
          } else {
            rawRgba[idx] = 255;     // R (White)
            rawRgba[idx + 1] = 255; // G
            rawRgba[idx + 2] = 255; // B
            rawRgba[idx + 3] = 255; // A
          }
        }
      }

      final SmudgeContent smudge = SmudgeContent(strength: 0.85);
      smudge.paint.strokeWidth = 24.0;
      smudge.setRgbaData(Uint8List.fromList(rawRgba), 100, 100, const Size(100, 100));

      // Drag from black area (x=45, y=50) to white area (x=75, y=50)
      smudge.startDrawWithPressure(const Offset(45, 50), 1.0);
      smudge.drawingWithPressure(const Offset(60, 50), 1.0);
      smudge.drawingWithPressure(const Offset(75, 50), 1.0);
      smudge.finalizeStroke();

      final Uint8List result = smudge.rgbaData!;

      // At x=60, y=50: Paint must have been deposited (darker than white)
      final int dragIdx = (50 * 100 + 60) * 4;
      expect(result[dragIdx], lessThan(100), reason: 'Black paint should have been dragged to x=60');
      expect(result[dragIdx + 3], equals(255), reason: 'Alpha must remain 255 (opaque on opaque canvas)');

      // At distant position x=95, y=50: Must remain pure white
      final int farIdx = (50 * 100 + 95) * 4;
      expect(result[farIdx], equals(255), reason: 'Distant pixels must remain unaffected white');
      expect(result[farIdx + 1], equals(255));
      expect(result[farIdx + 2], equals(255));
    });
  });
}
