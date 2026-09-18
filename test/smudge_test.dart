import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/package_code/src/paint_contents/paint_content_decoder.dart';
import 'package:dummy/package_code/src/paint_contents/smudge.dart';

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
  });
}

