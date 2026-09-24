import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/package_code/paint_contents.dart';
import 'package:dummy/package_code/src/paint_contents/paint_content_decoder.dart';
import 'package:dummy/package_code/src/paint_contents/smudge.dart';
import 'package:dummy/package_code/src/paint_contents/fill.dart';
import 'package:dummy/package_code/src/paint_contents/layer_data.dart';
import 'package:dummy/package_code/src/helper/flood_fill.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Uint8List> createTestPixelBuffer(int width, int height, {Color color = Colors.black}) async {
    final Uint8List pixels = Uint8List(width * height * 4);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int idx = (y * width + x) * 4;
        // Central vertical stripe of paint (like a black line between x=40 and x=60)
        if (x >= 40 && x <= 60) {
          pixels[idx] = (color.r * 255.0).round();
          pixels[idx + 1] = (color.g * 255.0).round();
          pixels[idx + 2] = (color.b * 255.0).round();
          pixels[idx + 3] = 255;
        }
      }
    }
    return pixels;
  }

  group('Smudge Tool Test Suite', () {
    test('SmudgeContent initializes with default strength and copies properly', () {
      final smudge = SmudgeContent(strength: 0.7);
      smudge.paint.strokeWidth = 24.0;
      expect(smudge.strength, equals(0.7));
      expect(smudge.contentType, equals('SmudgeContent'));

      final copy = smudge.copy();
      expect(copy.strength, equals(0.7));
      expect(copy.paint.strokeWidth, equals(24.0));
      expect(copy.contentType, equals('SmudgeContent'));
    });

    test('SmudgeContent JSON serialization and deserialization works with points', () {
      final smudge = SmudgeContent(strength: 0.85);
      smudge.paint.strokeWidth = 16.0;
      smudge.points.add(
        const SmudgePoint(
          Offset(40, 50),
          Offset(0, 0),
          1.0,
        ),
      );
      smudge.points.add(
        const SmudgePoint(
          Offset(60, 50),
          Offset(20, 0),
          0.8,
        ),
      );

      final json = smudge.toJson();

      expect(json['type'], equals('SmudgeContent'));
      expect(json['strength'], equals(0.85));

      final decoded = decodePaintContent('SmudgeContent', json);
      expect(decoded, isA<SmudgeContent>());
      final decodedSmudge = decoded as SmudgeContent;
      expect(decodedSmudge.strength, equals(0.85));
      expect(decodedSmudge.paint.strokeWidth, equals(16.0));
      expect(decodedSmudge.points.length, equals(2));
      expect(decodedSmudge.points.first.point, equals(const Offset(40, 50)));
      expect(decodedSmudge.points.last.point, equals(const Offset(60, 50)));
      expect(decodedSmudge.points.last.pressure, equals(0.8));
    });

    test('SmudgeContent gesture creates directional smear trail and modifies pixels', () async {
      final Uint8List initialPixels = await createTestPixelBuffer(100, 100, color: Colors.black);
      final SmudgeContent smudge = SmudgeContent(strength: 0.85);
      smudge.paint.strokeWidth = 24.0;

      smudge.setRgbaData(
        initialPixels,
        100,
        100,
        const Size(100, 100),
      );

      // Swipe across the vertical black line (x=40..60) from x=45 to x=85 along y=50
      smudge.startDrawWithPressure(const Offset(45, 50), 1.0);
      smudge.drawingWithPressure(const Offset(65, 50), 1.0);
      smudge.drawingWithPressure(const Offset(85, 50), 1.0);

      expect(smudge.points.isNotEmpty, isTrue);
      expect(smudge.points.length, equals(3));
      expect(smudge.points.first.point.dx, equals(45));
      expect(smudge.points.last.point.dx, equals(85));

      // Verify that pixel buffer was deformed and paint dragged into x=75 (originally transparent)
      expect(smudge.rgbaData, isNotNull);
      final Uint8List result = smudge.rgbaData!;
      final int smearedIdx = (50 * 100 + 75) * 4;
      expect(result[smearedIdx + 3], greaterThan(0), reason: 'Smudge should drag paint into x=75');

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      expect(() => smudge.draw(canvas, const Size(100, 100), false), returnsNormally);
      expect(() => smudge.draw(canvas, const Size(100, 100), true), returnsNormally);
    });

    test('Smudge followed by FillContent renders in proper layer order without white halos', () async {
      const int width = 100;
      const int height = 100;
      final Uint8List initialPixels = await createTestPixelBuffer(width, height, color: const Color(0xFF654321)); // Brown line

      final SmudgeContent smudge = SmudgeContent(strength: 0.75);
      smudge.paint.strokeWidth = 20.0;
      smudge.setRgbaData(initialPixels, width, height, const Size(100, 100));

      // Smudge the brown line from x=45 to x=70
      smudge.startDrawWithPressure(const Offset(45, 50), 1.0);
      smudge.drawingWithPressure(const Offset(70, 50), 1.0);
      smudge.finalizeStroke();

      // Render the active layer state with Smudge
      final LayerData layer = LayerData(id: 'layer1');
      layer.history.add(smudge);
      layer.currentIndex = 1;

      final ui.PictureRecorder rec1 = ui.PictureRecorder();
      final Canvas c1 = Canvas(rec1, const Rect.fromLTWH(0, 0, 100, 100));
      layer.drawHistory(c1, const Size(100, 100), true);
      final ui.Image snapshotBeforeFill = await rec1.endRecording().toImage(width, height);

      // Perform FloodFill at (10, 10) with Purple Color
      const Color purpleColor = Color(0xFF9C27B0);
      final ui.Image? filledImg = await FloodFill.fill(
        image: snapshotBeforeFill,
        startPoint: const Offset(10, 10),
        fillColor: purpleColor,
        tolerance: 0.15,
      );

      expect(filledImg, isNotNull);

      // Add FillContent after SmudgeContent
      final FillContent fillContent = FillContent.data(
        image: filledImg,
        paint: Paint(),
      );
      layer.history.add(fillContent);
      layer.currentIndex = 2;

      // Draw combined layer history
      final ui.PictureRecorder rec2 = ui.PictureRecorder();
      final Canvas c2 = Canvas(rec2, const Rect.fromLTWH(0, 0, 100, 100));
      layer.drawHistory(c2, const Size(100, 100), true);
      final ui.Image composite = await rec2.endRecording().toImage(width, height);

      final ByteData? compData = await composite.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(compData, isNotNull);
      final Uint8List compPixels = compData!.buffer.asUint8List();

      // Check background pixel (10, 10): must be Purple
      final int bgIdx = (10 * width + 10) * 4;
      expect(compPixels[bgIdx], equals(purpleColor.r.toInt() * 255 ~/ 1 | 0x9C));
      expect(compPixels[bgIdx + 3], equals(255));

      // Check smudged pixel (50, 50): must be Brown (alpha > 0)
      final int strokeIdx = (50 * width + 50) * 4;
      expect(compPixels[strokeIdx + 3], greaterThan(0));
    });

    test('Smudge pulls and stretches wet paint across black background with sharp contrast and tapered falloff', () async {
      const int width = 100;
      const int height = 100;
      final Uint8List blackCanvas = Uint8List(width * height * 4);
      // Initialize with solid black (R=0, G=0, B=0, A=255)
      for (int i = 0; i < width * height; i++) {
        blackCanvas[i * 4 + 3] = 255;
      }
      // Put a solid white patch at center (x: 40..60, y: 40..60)
      for (int y = 40; y <= 60; y++) {
        for (int x = 40; x <= 60; x++) {
          final int idx = (y * width + x) * 4;
          blackCanvas[idx] = 255;
          blackCanvas[idx + 1] = 255;
          blackCanvas[idx + 2] = 255;
          blackCanvas[idx + 3] = 255;
        }
      }

      final SmudgeContent smudge = SmudgeContent(strength: 0.85);
      smudge.paint.strokeWidth = 20.0;
      smudge.setRgbaData(blackCanvas, width, height, const Size(100, 100));

      // Smudge outward from center (50, 50) towards (90, 50)
      smudge.startDrawWithPressure(const Offset(50, 50), 1.0);
      smudge.drawingWithPressure(const Offset(70, 50), 1.0);
      smudge.drawingWithPressure(const Offset(90, 50), 1.0);
      smudge.finalizeStroke();

      final Uint8List result = smudge.rgbaData!;
      // Pixel at (70, 50) should have high brightness (carried white paint, not degraded into dark gray)
      final int idx70 = (50 * width + 70) * 4;
      expect(result[idx70], greaterThan(150), reason: 'Stretched core should preserve bright white pigment');

      // Pixel at (85, 50) should also have paint pulled into it
      final int idx85 = (50 * width + 85) * 4;
      expect(result[idx85], greaterThan(50), reason: 'Paint should stretch into the tapered tail');
    });
  });
}

