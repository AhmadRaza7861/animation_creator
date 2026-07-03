import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dummy/package_code/src/paint_contents/simple_line.dart';
import 'package:dummy/package_code/src/paint_contents/group.dart';
import 'package:dummy/package_code/src/paint_contents/clipped.dart';
import 'package:dummy/package_code/src/paint_contents/paint_content_decoder.dart';
import 'package:dummy/package_code/src/draw_path/draw_path.dart';

void main() {
  test('Encode and decode GroupContent and ClippedHistoryContent', () {
    final paint = Paint()..color = Colors.blue..strokeWidth = 3;

    final line1 = SimpleLine();
    line1.paint = paint;
    line1.startDraw(const Offset(0, 0));
    line1.drawing(const Offset(10, 10));

    final group = GroupContent(children: [line1]);

    final bounds = const Rect.fromLTWH(0, 0, 50, 50);
    final clipPath = DrawPath();
    clipPath.moveTo(0, 0);
    clipPath.lineTo(50, 50);
    final clipped = ClippedHistoryContent([line1], clipPath, bounds);

    final list = [group, clipped];

    print('Encoding complex shapes...');
    final jsonList = list.map((e) => e.toJson()).toList();
    final jsonStr = jsonEncode(jsonList);
    print('Encoded!');

    final decodedStr = jsonDecode(jsonStr);
    for (var item in decodedStr) {
      print('Decoding ${item['type']}...');
      final content = decodePaintContent(item['type'], item);
      print('Decoded success: ${content != null}');
    }
  });
}
