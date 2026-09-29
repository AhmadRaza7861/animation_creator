import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/package_code/src/paint_contents/smudge.dart';

void main() {
  test('Smudge at 50% strength produces wide, solid-base flare with soft feathered edges', () {
    const int width = 300;
    const int height = 300;
    final Uint32List pixels = Uint32List(width * height);
    pixels.fillRange(0, pixels.length, 0xFFFFFFFF); // White canvas
    
    // Draw black circle at (150, 150), radius 50
    const double cx = 150.0;
    const double cy = 150.0;
    const double r = 50.0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final double dx = x - cx;
        final double dy = y - cy;
        if (dx * dx + dy * dy <= r * r) {
          pixels[y * width + x] = 0xFF000000;
        }
      }
    }

    final smudge = SmudgeContent(strength: 0.50); // 50% strength like in user screenshot
    smudge.paint = Paint()
      ..strokeWidth = 25.0
      ..style = PaintingStyle.stroke;
    smudge.canvasSize = const Size(300, 300);
    smudge.setRgba32Data(pixels, width, height, const Size(300, 300));

    // Swipe straight up from (150, 130) to (150, 50)
    smudge.startDrawWithPressure(const Offset(150, 130), 1.0);
    for (double y = 120; y >= 50; y -= 10) {
      smudge.drawingWithPressure(Offset(150, y), 1.0);
    }
    smudge.finalizeStroke();

    final ByteData bd = ByteData.sublistView(smudge.rgbaData!);
    final Uint32List result = bd.buffer.asUint32List(bd.offsetInBytes, bd.lengthInBytes ~/ 4);

    // Measure lateral cross-section at y = 85 (15px outside circle boundary)
    // The streak should be wide (dark in center, smooth feather on sides)
    final int centerR = result[85 * width + 150] & 0xFF;
    final int left10R = result[85 * width + 140] & 0xFF;
    final int left30R = result[85 * width + 120] & 0xFF;

    expect(centerR < 80, isTrue, reason: 'Center of plume must carry rich pigment (got $centerR)');
    expect(left10R < 240, isTrue, reason: 'Plume must have soft feathered boundary 10px from center (got $left10R)');
    expect(left30R, equals(255), reason: 'Outer background must stay clean white');
  });
}
