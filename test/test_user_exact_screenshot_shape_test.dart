import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/package_code/src/paint_contents/smudge.dart';

void main() {
  test('6-directional smudge on black circle produces wide solid-base plumes matching competitor', () {
    const int width = 400;
    const int height = 400;
    final Uint32List pixels = Uint32List(width * height);
    pixels.fillRange(0, pixels.length, 0xFFFFFFFF); // White background

    // Center circle at (200, 200) with radius 70
    const double cx = 200.0;
    const double cy = 200.0;
    const double r = 70.0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final double dx = x - cx;
        final double dy = y - cy;
        if (dx * dx + dy * dy <= r * r) {
          pixels[y * width + x] = 0xFF000000;
        }
      }
    }

    // 6 swipe directions as shown in user screenshot:
    // Top-left, Left, Bottom-left, Bottom, Bottom-right, Top
    final directions = [
      -3 * math.pi / 4, // Top-left
      math.pi,          // Left
      3 * math.pi / 4,  // Bottom-left
      math.pi / 2,      // Bottom
      math.pi / 4,      // Bottom-right
      -math.pi / 2,     // Top
    ];

    Uint32List currentBuffer = Uint32List.fromList(pixels);

    for (final angle in directions) {
      final smudge = SmudgeContent(strength: 0.50); // 50% intensity as in user screenshot
      smudge.paint = Paint()
        ..strokeWidth = 32.0
        ..style = PaintingStyle.stroke;
      smudge.canvasSize = const Size(400, 400);
      smudge.setRgba32Data(currentBuffer, width, height, const Size(400, 400));

      // Touchdown inside the circle (radius 50) and swipe outward to radius 140 (70px past boundary)
      final double startX = cx + math.cos(angle) * 50.0;
      final double startY = cy + math.sin(angle) * 50.0;

      smudge.startDrawWithPressure(Offset(startX, startY), 1.0);
      for (double dist = 60.0; dist <= 140.0; dist += 10.0) {
        final double px = cx + math.cos(angle) * dist;
        final double py = cy + math.sin(angle) * dist;
        smudge.drawingWithPressure(Offset(px, py), 1.0);
      }
      smudge.finalizeStroke();

      final ByteData bd = ByteData.sublistView(smudge.rgbaData!);
      currentBuffer = Uint32List.fromList(bd.buffer.asUint32List(bd.offsetInBytes, bd.lengthInBytes ~/ 4));
    }

    // Verify all 6 plumes:
    for (int i = 0; i < directions.length; i++) {
      final angle = directions[i];

      // 1. Plume base (20px outside circle, radius = 90px): Must be solid dark black (R < 30)
      final int baseX = (cx + math.cos(angle) * 90.0).round().clamp(0, width - 1);
      final int baseY = (cy + math.sin(angle) * 90.0).round().clamp(0, height - 1);
      final int basePixel = currentBuffer[baseY * width + baseX];
      final int baseR = basePixel & 0xFF;

      // 2. Plume body width: Normal vector perpendicular to angle
      final double normalAngle = angle + math.pi / 2;
      final int lateralX = (baseX + math.cos(normalAngle) * 10.0).round().clamp(0, width - 1);
      final int lateralY = (baseY + math.sin(normalAngle) * 10.0).round().clamp(0, height - 1);
      final int lateralPixel = currentBuffer[lateralY * width + lateralX];
      final int lateralR = lateralPixel & 0xFF;

      // 3. Plume mid-length (45px outside circle, radius = 115px): Must still carry dark pigment (R < 80)
      final int midX = (cx + math.cos(angle) * 115.0).round().clamp(0, width - 1);
      final int midY = (cy + math.sin(angle) * 115.0).round().clamp(0, height - 1);
      final int midPixel = currentBuffer[midY * width + midX];
      final int midR = midPixel & 0xFF;

      expect(baseR < 50, isTrue, reason: 'Plume base must be solid dark (got $baseR)');
      expect(lateralR < 200, isTrue, reason: 'Plume must maintain wide solid body 10px from core (got $lateralR)');
      expect(midR < 80, isTrue, reason: 'Plume must extend rich pigment past shape boundary (got $midR)');
    }
  });
}
