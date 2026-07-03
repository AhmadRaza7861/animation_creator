import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/package_code/src/paint_extension/ex_paint.dart';
import 'dart:convert';

void main() {
  test('Test jsonToPaint', () {
    final str = '{"blendMode":3,"color":4294198070,"filterQuality":0,"invertColors":false,"isAntiAlias":true,"strokeCap":1,"strokeJoin":1,"strokeWidth":4.0,"style":1}';
    final data = jsonDecode(str);
    final paint = jsonToPaint(data);
    print('Color alpha: \${paint.color.alpha}');
    print('Color hex: \${paint.color.value.toRadixString(16)}');
    print('Stroke width: \${paint.strokeWidth}');
    print('Style: \${paint.style}');
    print('BlendMode: \${paint.blendMode}');
    expect(paint.color.value, 4294198070);
  });
}
