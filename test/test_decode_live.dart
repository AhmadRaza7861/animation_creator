import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dummy/package_code/src/paint_contents/simple_line.dart';
import 'package:dummy/package_code/src/paint_contents/paint_content_decoder.dart';
import 'package:dummy/package_code/src/drawing_controller.dart';
import 'package:dummy/package_code/src/paint_contents/paint_content.dart';

void main() {
  final str = '[{"type":"SimpleLine","minPointDistance":2.0,"useBezierCurve":true,"points":[{"dx":220.66665649414062,"dy":427.3333435058594},{"dx":220.66665649414062,"dy":428.0},{"dx":218.0,"dy":432.3333435058594},{"dx":213.6666717529297,"dy":437.6666564941406},{"dx":210.0,"dy":442.3333435058594},{"dx":204.6666717529297,"dy":446.6666564941406},{"dx":198.3333282470703,"dy":450.3333435058594},{"dx":190.0,"dy":453.3333435058594}],"paint":{"blendMode":3,"color":4294198070,"filterQuality":0,"invertColors":false,"isAntiAlias":true,"strokeCap":1,"strokeJoin":1,"strokeWidth":4.0,"style":1}}]';

  final List<dynamic> decoded = jsonDecode(str);
  final List<PaintContent> contents = [];

  for (final item in decoded) {
    if (item is Map<String, dynamic>) {
      final String type = item['type'] as String;
      final PaintContent? content = decodePaintContent(type, item);
      if (content != null) {
        contents.add(content);
      } else {
        print('Unknown PaintContent type in JSON: \$type');
      }
    }
  }
  
  print('Decoded ${contents.length} contents.');
  if (contents.isNotEmpty) {
    final first = contents.first;
    if (first is FreehandLine) {
        print('Is points populated? ${first.points?.length}');
    } else if (first is SimpleLine) {
        print('Is simple line? Yes. Start: ${first.startPoint}, End: ${first.endPoint}');
    }
  }
}
