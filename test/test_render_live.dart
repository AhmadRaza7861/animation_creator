import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dummy/package_code/src/paint_contents/paint_content_decoder.dart';
import 'package:dummy/package_code/src/paint_contents/paint_content.dart';

void main() {
  testWidgets('Simulate deep render from JSON', (WidgetTester tester) async {
    // A SimpleLine saved JSON
    final str = '[{"type":"SimpleLine","minPointDistance":2.0,"useBezierCurve":true,"points":[{"dx":10.0,"dy":10.0},{"dx":50.0,"dy":50.0},{"dx":100.0,"dy":100.0}],"paint":{"blendMode":3,"color":4294198070,"filterQuality":0,"invertColors":false,"isAntiAlias":true,"strokeCap":1,"strokeJoin":1,"strokeWidth":10.0,"style":1}}]';

    final decoded = jsonDecode(str);
    final contents = <PaintContent>[];
    for (final item in decoded) {
      contents.add(decodePaintContent(item['type'], item)!);
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 500, 500));
    canvas.drawColor(Colors.white, BlendMode.src);

    for (final content in contents) {
      content.draw(canvas, const Size(500, 500), true); // deeper=true
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(500, 500);

    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    bool hasColor = false;
    for (int i = 0; i < byteData!.lengthInBytes; i += 4) {
      final r = byteData.getUint8(i);
      final g = byteData.getUint8(i+1);
      final b = byteData.getUint8(i+2);
      if (r < 255 || g < 255 || b < 255) {
        hasColor = true;
        break;
      }
    }
    
    expect(hasColor, true, reason: 'Expected non-white pixels from the drawn simple line');
  });
}
