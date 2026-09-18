import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/package_code/src/paint_contents/blur.dart';

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

  group('Blur Tool Test Suite', () {
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
  });
}
