import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dummy/package_code/src/paint_contents/simple_line.dart';
import 'package:dummy/package_code/src/paint_contents/paint_content_decoder.dart';

void main() {
  try {
    final line = FreehandLine.data(
      points: [const Offset(10, 10), const Offset(20, 20)],
      paint: Paint()..color = Colors.red..strokeWidth = 2,
    );

    final jsonList = [line.toJson()];
    final jsonStr = jsonEncode(jsonList);
    print('Encoded JSON: $jsonStr');

    final decodedStr = jsonDecode(jsonStr);
    for (var item in decodedStr) {
      final content = decodePaintContent(item['type'], item);
      print('Decoded: ${content?.contentType}');
      if (content is FreehandLine) {
        print('Points: ${content.points}');
      }
    }
  } catch (e, stackTrace) {
    print('Error: $e');
    print(stackTrace);
  }
}
