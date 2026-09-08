import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/package_code/src/drawing_bar/brush_presets.dart';
import 'package:dummy/package_code/paint_contents.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('All 110+ brush presets can be instantiated, drawn, and painted without crashing', () {
    final presets = kDefaultBrushPresets;
    expect(presets.isNotEmpty, isTrue);

    const Size size = Size(160, 100);
    final List<Offset> points = <Offset>[];
    final double padX = size.width * 0.12;
    final double usableW = size.width - padX * 2;
    final double midY = size.height / 2;
    final double amp = size.height * 0.22;
    const int segments = 48;

    for (int i = 0; i <= segments; i++) {
      final double t = i / segments;
      final double x = padX + usableW * t;
      final double y = midY - sin(t * pi * 2) * amp;
      points.add(Offset(x, y));
    }

    int testedCount = 0;
    for (final preset in presets) {
      try {
        final PaintContent content = preset.create()
          ..paint = (Paint()
            ..color = Colors.black
            ..strokeWidth = 7.0
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..isAntiAlias = true);

        content.startDraw(points.first);
        for (int i = 1; i < points.length; i++) {
          content.drawing(points[i]);
        }

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder, Offset.zero & size);
        content.draw(canvas, size, false);
        final pic = recorder.endRecording();
        expect(pic, isNotNull);
        testedCount++;
      } catch (e, stack) {
        fail('Preset ${preset.id} (${preset.name}) crashed during drawing: $e\n$stack');
      }
    }

    expect(testedCount, presets.length);
  });
}
