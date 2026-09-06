import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/package_code/src/ruler/ruler_config.dart';
import 'package:dummy/package_code/src/ruler/mirror_content.dart';
import 'package:dummy/package_code/src/paint_contents/paint_content_decoder.dart';
import 'package:dummy/package_code/src/paint_contents/simple_line.dart';

void main() {
  group('4-Way Quadrant Mirror Tests', () {
    test('QuadMirror ruler does not clamp point in projectPoint', () {
      final config = RulerConfig(
        type: RulerType.quadMirror,
        center: const Offset(200, 200),
        scale: 140.0,
      );

      final p = config.projectPoint(const Offset(250, 280), null);
      expect(p, equals(const Offset(250, 280)));
    });

    test('QuadMirrorContent serializes and decodes cleanly', () {
      final child = FreehandLine()..points = [const Offset(10, 10), const Offset(20, 20)];
      final quadMirror = QuadMirrorContent(child, const Offset(150, 150), 0.0);

      final json = quadMirror.toJson();
      final decoded = decodePaintContent('QuadMirror', json);

      expect(decoded, isA<QuadMirrorContent>());
      final decodedQuad = decoded as QuadMirrorContent;
      expect(decodedQuad.mirrorCenter, equals(const Offset(150, 150)));
      expect(decodedQuad.mirrorAngle, equals(0.0));
    });
  });
}
