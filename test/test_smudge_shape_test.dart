import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/package_code/src/paint_contents/smudge.dart';

void main() {
  test('Smudge on shape drags pigment outward in multiple directions matching competitor plumes', () {
    const int width = 300;
    const int height = 300;
    final Uint32List pixels = Uint32List(width * height);
    
    // Fill white background (0xFFFFFFFF)
    pixels.fillRange(0, pixels.length, 0xFFFFFFFF);
    
    // Draw solid black circle at center (150, 150) with radius 50 (0xFF000000)
    const double cx = 150.0;
    const double cy = 150.0;
    const double r = 50.0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final double dx = x - cx;
        final double dy = y - cy;
        if (dx * dx + dy * dy <= r * r) {
          pixels[y * width + x] = 0xFF000000; // Black
        }
      }
    }

    // Perform 5 outward smudge gestures from inside circle into surrounding white canvas
    final angles = [-math.pi / 2, -math.pi / 4, 0.0, math.pi / 2, 3 * math.pi / 4];

    Uint32List currentBuffer = Uint32List.fromList(pixels);

    for (final angle in angles) {
      final smudge = SmudgeContent(strength: 0.75);
      smudge.paint = Paint()
        ..strokeWidth = 28.0
        ..style = PaintingStyle.stroke;
      smudge.canvasSize = const Size(300, 300);
      smudge.setRgba32Data(currentBuffer, width, height, const Size(300, 300));

      final double startX = cx + math.cos(angle) * 35.0;
      final double startY = cy + math.sin(angle) * 35.0;

      smudge.startDrawWithPressure(Offset(startX, startY), 1.0);
      for (double d = 45.0; d <= 110.0; d += 15.0) {
        final double currX = cx + math.cos(angle) * d;
        final double currY = cy + math.sin(angle) * d;
        smudge.drawingWithPressure(Offset(currX, currY), 1.0);
      }
      smudge.finalizeStroke();

      final ByteData bd = ByteData.sublistView(smudge.rgbaData!);
      currentBuffer = Uint32List.fromList(bd.buffer.asUint32List(bd.offsetInBytes, bd.lengthInBytes ~/ 4));
    }

    // Verify all 5 plumes created dark pigment outside the 50px radius circle
    for (final angle in angles) {
      // Sample 25px outside original circle (radius 75px from center)
      final int sampleX = (cx + math.cos(angle) * 75.0).round().clamp(0, width - 1);
      final int sampleY = (cy + math.sin(angle) * 75.0).round().clamp(0, height - 1);
      final int pixel = currentBuffer[sampleY * width + sampleX];
      final int red = pixel & 0xFF;
      
      expect(red < 150, isTrue, reason: 'Plume at angle $angle should carry dark pigment 25px outside shape (got $red)');
    }
  });
}
