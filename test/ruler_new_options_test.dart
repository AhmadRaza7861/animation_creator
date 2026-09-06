import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/package_code/src/ruler/ruler_config.dart';
import 'package:dummy/package_code/src/ruler/radial_content.dart';
import 'package:dummy/package_code/src/paint_contents/paint_content_decoder.dart';
import 'package:dummy/package_code/src/paint_contents/simple_line.dart';

void main() {
  group('New Ruler Options Tests', () {
    test('Triangle ruler projects points to triangular perimeter', () {
      final config = RulerConfig(
        type: RulerType.triangle,
        center: const Offset(200, 200),
        scale: 100.0,
        scaleY: 100.0,
        angle: 0.0,
      );

      final p1 = config.projectPoint(const Offset(200, 100), const Offset(200, 100));
      expect(p1.dx, closeTo(200.0, 1e-3));
      expect(p1.dy, closeTo(100.0, 1e-3)); // Top vertex (200, 200 - 100)

      final pBottom = config.projectPoint(const Offset(250, 310), const Offset(200, 100));
      expect(pBottom.dy, closeTo(300.0, 1e-3)); // Bottom edge y = 300
    });

    test('Star ruler projects points to star edges', () {
      final config = RulerConfig(
        type: RulerType.star,
        center: const Offset(200, 200),
        scale: 100.0,
        scaleY: 100.0,
        angle: 0.0,
      );

      final topTip = config.projectPoint(const Offset(200, 95), const Offset(200, 100));
      expect(topTip.dx, closeTo(200.0, 1e-2));
      expect(topTip.dy, closeTo(100.0, 1e-2));
    });

    test('Polygon (Hexagon) ruler projects points to hexagonal perimeter', () {
      final config = RulerConfig(
        type: RulerType.polygon,
        center: const Offset(200, 200),
        scale: 100.0,
        angle: 0.0,
      );

      final pt = config.projectPoint(const Offset(350, 200), const Offset(200, 200));
      expect(pt.dx, lessThanOrEqualTo(300.0 + 1e-2));
    });

    test('Isometric ruler projects points along 30, 90, or 150 degree axes', () {
      final config = RulerConfig(
        type: RulerType.isometric,
        center: const Offset(200, 200),
      );

      // Point drawn vertically
      final verticalPt = config.projectPoint(const Offset(202, 350), const Offset(200, 200));
      expect(verticalPt.dx, closeTo(200.0, 1e-3));
      expect(verticalPt.dy, closeTo(350.0, 1e-3));
    });

    test('RadialContent serializes and decodes cleanly', () {
      final child = FreehandLine()..points = [const Offset(10, 10), const Offset(20, 20)];
      final radial = RadialContent(child, const Offset(150, 150), 8, 0.0);

      final json = radial.toJson();
      final decoded = decodePaintContent('Radial', json);

      expect(decoded, isA<RadialContent>());
      final decodedRadial = decoded as RadialContent;
      expect(decodedRadial.center, equals(const Offset(150, 150)));
      expect(decodedRadial.sectors, equals(8));
    });
  });
}
