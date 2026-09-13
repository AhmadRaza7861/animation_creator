import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/package_code/src/drawing_controller.dart';
import 'package:dummy/package_code/src/paint_contents/blur.dart';
import 'package:dummy/package_code/src/paint_contents/smudge.dart';
import 'package:dummy/package_code/src/paint_contents/smooth_line.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ui.Image> createTestImage(int width, int height) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
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

    test('SmudgeContent can displace and diffuse snapshot image without errors', () async {
      final ui.Image testImg = await createTestImage(200, 200);
      final SmudgeContent smudge = SmudgeContent(strength: 0.7);
      smudge.setImageData(testImg);
      smudge.startDraw(const Offset(50, 50));
      smudge.drawing(const Offset(60, 60));
      smudge.drawing(const Offset(80, 80));

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      expect(() => smudge.draw(canvas, const Size(200, 200), false), returnsNormally);
      expect(() => smudge.draw(canvas, const Size(200, 200), true), returnsNormally);

      final SmudgeContent copy = smudge.copy();
      expect(copy.strength, equals(0.7));
      expect(copy.points.length, equals(3));
      expect(copy.image, equals(testImg));

      final Map<String, dynamic> json = smudge.toContentJson();
      expect(json['strength'], equals(0.7));
      expect((json['points'] as List).length, equals(3));
    });

    test('DrawingController lifecycle with Blur and Smudge modifier tools', () async {
      final DrawingController controller = DrawingController();
      controller.setBoardSize(const Size(400, 400));

      // 1. Draw a base line
      controller.setPaintContent(SmoothLine());
      controller.startDraw(const Offset(100, 100));
      controller.drawing(const Offset(100, 200));
      controller.endDraw();
      expect(controller.getHistory.length, equals(1));

      // 2. Apply Blur tool
      controller.setPaintContent(BlurContent(strength: 0.5));
      controller.startDraw(const Offset(80, 150));
      expect(controller.drawingContent is BlurContent, isTrue);
      controller.drawing(const Offset(120, 150));
      controller.endDraw();
      expect(controller.getHistory.length, equals(2));
      expect(controller.getHistory.last is BlurContent, isTrue);

      // 3. Apply Smudge tool
      controller.setPaintContent(SmudgeContent(strength: 0.5));
      controller.startDraw(const Offset(80, 120));
      expect(controller.drawingContent is SmudgeContent, isTrue);
      controller.drawing(const Offset(130, 120));
      controller.endDraw();
      expect(controller.getHistory.length, equals(3));
      expect(controller.getHistory.last is SmudgeContent, isTrue);
    });
  });
}
