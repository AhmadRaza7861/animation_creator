import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/package_code/src/drawing_controller.dart';
import 'package:dummy/package_code/src/paint_contents/blur.dart';
import 'package:dummy/package_code/src/paint_contents/simple_line.dart';

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

  Future<ui.Image> createSplitImage(int width, int height, Color leftColor, Color rightColor) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width / 2.0, height.toDouble()),
      Paint()..color = leftColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(width / 2.0, 0, width / 2.0, height.toDouble()),
      Paint()..color = rightColor,
    );
    final ui.Picture picture = recorder.endRecording();
    return await picture.toImage(width, height);
  }

  group('Blur Tool Test Suite', () {
    test('BlurContent performs controlled single-pass softening preserving original detail and accumulates on repeated strokes', () async {
      // 100x100 image: Left half pure black (0,0,0), Right half pure white (255,255,255)
      final ui.Image splitImg = await createSplitImage(100, 100, Colors.black, Colors.white);
      final ByteData? data = await splitImg.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(data, isNotNull);

      // --- Pass 1: Single stroke with 50px brush ---
      final BlurContent blur1 = BlurContent(strength: 0.65);
      blur1.paint.strokeWidth = 50.0;
      blur1.setRgbaData(data!.buffer.asUint8List(), 100, 100, const Size(100, 100));

      blur1.startDrawWithPressure(const Offset(50, 20), 1.0);
      blur1.drawingWithPressure(const Offset(50, 50), 1.0);
      blur1.drawingWithPressure(const Offset(50, 80), 1.0);

      expect(blur1.rgbaData, isNotNull);
      final Uint8List pixelsPass1 = blur1.rgbaData!;

      // 1. Pixel near the edge (x=48, originally pure black 0)
      final int leftIdx = (50 * 100 + 48) * 4;
      final int pass1LeftR = pixelsPass1[leftIdx];
      expect(pass1LeftR, inInclusiveRange(20, 110),
          reason: 'Single pass must softly blend ~30-50% of blurred pixel, preserving detail');

      // Check pixel right on the left side of boundary (x=49, originally 0)
      final int midLeftIdx = (50 * 100 + 49) * 4;
      final int pass1MidLeftR = pixelsPass1[midLeftIdx];
      expect(pass1MidLeftR, inInclusiveRange(25, 120),
          reason: 'Boundary pixel on black side should be softly blended up on single pass');

      // Check pixel right on the right side of boundary (x=50, originally 255)
      final int midRightIdx = (50 * 100 + 50) * 4;
      final int pass1MidRightR = pixelsPass1[midRightIdx];
      expect(pass1MidRightR, inInclusiveRange(135, 230),
          reason: 'Boundary pixel on white side should be softly blended down on single pass');

      // 2. Far pixels outside the 50px brush radius (x=10 and x=90) must remain completely untouched
      final int farLeftIdx = (50 * 100 + 10) * 4;
      expect(pixelsPass1[farLeftIdx], equals(0), reason: 'Far left pixel must remain pure black 0');

      final int farRightIdx = (50 * 100 + 90) * 4;
      expect(pixelsPass1[farRightIdx], equals(255), reason: 'Far right pixel must remain pure white 255');

      // --- Pass 2: Second stroke over the same area ---
      final BlurContent blur2 = BlurContent(strength: 0.65);
      blur2.paint.strokeWidth = 50.0;
      blur2.setRgbaData(pixelsPass1, 100, 100, const Size(100, 100));

      blur2.startDrawWithPressure(const Offset(50, 20), 1.0);
      blur2.drawingWithPressure(const Offset(50, 50), 1.0);
      blur2.drawingWithPressure(const Offset(50, 80), 1.0);

      final Uint8List pixelsPass2 = blur2.rgbaData!;
      final int pass2LeftR = pixelsPass2[leftIdx];
      expect(pass2LeftR, greaterThan(pass1LeftR),
          reason: 'Pass 2 must progressively increase softening compared to Pass 1');

      // --- Pass 3: Third stroke over the same area ---
      final BlurContent blur3 = BlurContent(strength: 0.65);
      blur3.paint.strokeWidth = 50.0;
      blur3.setRgbaData(pixelsPass2, 100, 100, const Size(100, 100));

      blur3.startDrawWithPressure(const Offset(50, 20), 1.0);
      blur3.drawingWithPressure(const Offset(50, 50), 1.0);
      blur3.drawingWithPressure(const Offset(50, 80), 1.0);

      final Uint8List pixelsPass3 = blur3.rgbaData!;
      final int pass3LeftR = pixelsPass3[leftIdx];
      expect(pass3LeftR, greaterThan(pass2LeftR),
          reason: 'Pass 3 must progressively increase softening further');
    });

    test('BlurContent preserves transparency and avoids white halo artifacts near transparent edges', () async {
      // 100x100 image: Left half black, Right half 100% transparent
      final ui.Image splitImg = await createSplitImage(100, 100, Colors.black, Colors.transparent);
      final ByteData? data = await splitImg.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(data, isNotNull);

      final BlurContent blur = BlurContent(strength: 0.75);
      blur.paint.strokeWidth = 24.0;
      blur.setRgbaData(data!.buffer.asUint8List(), 100, 100, const Size(100, 100));

      blur.startDrawWithPressure(const Offset(50, 50), 1.0);
      blur.drawingWithPressure(const Offset(50, 60), 1.0);

      final Uint8List pixels = blur.rgbaData!;

      // Far transparent pixel (x=90, y=50) must remain completely transparent (alpha=0, rgb=0)
      final int farIdx = (50 * 100 + 90) * 4;
      expect(pixels[farIdx + 3], equals(0), reason: 'Far pixel must remain 100% transparent');

      // Pixel on boundary (x=50, y=50) should soften alpha smoothly without adding white color
      final int midIdx = (50 * 100 + 50) * 4;
      final int r = pixels[midIdx];
      final int g = pixels[midIdx + 1];
      final int b = pixels[midIdx + 2];
      expect(r, equals(0), reason: 'Premultiplied weighting ensures no white halo is added');
      expect(g, equals(0), reason: 'Premultiplied weighting ensures no green tint is added');
      expect(b, equals(0), reason: 'Premultiplied weighting ensures no blue tint is added');
    });

    test('BlurContent copy, serialization and export', () async {
      final ui.Image testImg = await createTestImage(100, 100, color: Colors.blue);
      final BlurContent blur = BlurContent(strength: 0.65);
      blur.paint.strokeWidth = 20.0;
      blur.setImageData(testImg);
      blur.startDraw(const Offset(10, 10));
      blur.drawing(const Offset(30, 30));

      final BlurContent copy = blur.copy();
      expect(copy.strength, equals(0.65));
      expect(copy.points.length, equals(2));
      expect(copy.paint.strokeWidth, equals(20.0));

      final Map<String, dynamic> json = blur.toContentJson();
      expect(json['strength'], equals(0.65));
      expect((json['points'] as List).length, equals(2));

      await blur.prepareExport();
      expect(blur.cachedBase64Image, isNotNull);
      expect(blur.cachedBase64Image!.isNotEmpty, isTrue);

      final BlurContent fromJson = BlurContent.fromJson(blur.toJson());
      expect(fromJson.strength, equals(0.65));
      expect(fromJson.points.length, equals(2));
      expect(fromJson.cachedBase64Image, equals(blur.cachedBase64Image));
    });

    test('DrawingController single-step Undo/Redo and progressive Blur', () async {
      final DrawingController controller = DrawingController();
      controller.setBoardSize(const Size(200, 200));

      // 1. Draw base stroke
      controller.setStyle(color: Colors.red, strokeWidth: 20.0);
      controller.setPaintContent(FreehandLine());
      controller.startDraw(const Offset(50, 20));
      controller.drawing(const Offset(50, 180));
      controller.endDraw();
      expect(controller.getHistory.length, equals(1));

      // 2. Blur across the stroke
      final blur = BlurContent(strength: 0.85);
      blur.paint.strokeWidth = 30.0;
      controller.setPaintContent(blur);
      controller.setStyle(strokeWidth: 30.0);
      controller.prepareSnapshot();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      controller.startDraw(const Offset(50, 100));
      controller.drawing(const Offset(50, 120));
      controller.endDraw();

      expect(controller.getHistory.length, equals(2));
      expect(controller.getHistory.last is BlurContent, isTrue);

      // 3. Undo
      controller.undo();
      expect(controller.currentIndex, equals(1));
      expect(controller.getHistory[controller.currentIndex - 1] is FreehandLine, isTrue);

      // 4. Redo
      controller.redo();
      expect(controller.currentIndex, equals(2));
      expect(controller.getHistory.last is BlurContent, isTrue);
    });

    test('BlurContent never bleeds or stretches pixels outside original image bounds', () async {
      // Create a 100x100 canvas with a 40x40 solid red image in the center (x: 30..70, y: 30..70)
      final Uint8List rawRgba = Uint8List(100 * 100 * 4);
      for (int y = 0; y < 100; y++) {
        for (int x = 0; x < 100; x++) {
          final int idx = (y * 100 + x) * 4;
          if (x >= 30 && x < 70 && y >= 30 && y < 70) {
            rawRgba[idx] = 255;     // R
            rawRgba[idx + 1] = 0;   // G
            rawRgba[idx + 2] = 0;   // B
            rawRgba[idx + 3] = 255; // A (opaque image)
          } else {
            // Transparent empty canvas
            rawRgba[idx] = 0;
            rawRgba[idx + 1] = 0;
            rawRgba[idx + 2] = 0;
            rawRgba[idx + 3] = 0;
          }
        }
      }

      final BlurContent blur = BlurContent(strength: 0.8);
      blur.paint.strokeWidth = 30.0;
      blur.setRgbaData(rawRgba, 100, 100, const Size(100, 100));

      // Draw a blur stroke that crosses through the boundary of the image (from x=20 outside to x=80 outside)
      blur.startDrawWithPressure(const Offset(20, 50), 1.0);
      blur.drawingWithPressure(const Offset(50, 50), 1.0);
      blur.drawingWithPressure(const Offset(80, 50), 1.0);

      final Uint8List pixels = blur.rgbaData!;

      // 1. Outside pixels (e.g. x=10..29 and x=70..90 at y=50) MUST remain completely transparent (0 alpha, 0 rgb)
      for (int x = 0; x < 30; x++) {
        final int idx = (50 * 100 + x) * 4;
        expect(pixels[idx + 3], equals(0), reason: 'Pixel at x=$x must remain 100% transparent with no bleed');
        expect(pixels[idx], equals(0), reason: 'Pixel at x=$x must have 0 red');
      }
      for (int x = 70; x < 100; x++) {
        final int idx = (50 * 100 + x) * 4;
        expect(pixels[idx + 3], equals(0), reason: 'Pixel at x=$x must remain 100% transparent with no bleed');
        expect(pixels[idx], equals(0), reason: 'Pixel at x=$x must have 0 red');
      }

      // 2. Pixels above and below the image (e.g. y=10..29 and y=70..90 at x=50) MUST remain completely transparent
      for (int y = 0; y < 30; y++) {
        final int idx = (y * 100 + 50) * 4;
        expect(pixels[idx + 3], equals(0), reason: 'Pixel at y=$y must remain 100% transparent with no vertical bleed');
      }
      for (int y = 70; y < 100; y++) {
        final int idx = (y * 100 + 50) * 4;
        expect(pixels[idx + 3], equals(0), reason: 'Pixel at y=$y must remain 100% transparent with no vertical bleed');
      }

      // 3. Inside the image (x: 30..69, y: 30..69), original alpha (255) must be preserved
      for (int y = 30; y < 70; y++) {
        for (int x = 30; x < 70; x++) {
          final int idx = (y * 100 + x) * 4;
          expect(pixels[idx + 3], equals(255), reason: 'Image interior pixel at ($x,$y) must preserve 255 alpha');
        }
      }
    });
  });
}
