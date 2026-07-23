import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dummy/package_code/src/paint_contents/simple_line.dart';
import 'package:dummy/package_code/src/paint_contents/group.dart';
import 'package:dummy/package_code/src/paint_contents/clipped.dart';
import 'package:dummy/package_code/src/paint_contents/text.dart';
import 'package:dummy/package_code/src/paint_contents/paint_content_decoder.dart';
import 'package:dummy/package_code/src/paint_contents/image.dart';
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

  test('Encode and decode TextContent with custom styles', () {
    final textContent = TextContent(
      text: 'Hello World',
      offset: const Offset(100, 100),
      scale: 1.5,
      rotation: 0.5,
      fontSize: 32.0,
      isBold: true,
      isItalic: true,
      isUnderline: true,
      textAlign: TextAlign.center,
      opacity: 0.8,
      fontFamily: 'serif',
    );
    textContent.paint = Paint()..color = Colors.red;

    final jsonText = textContent.toJson();
    final decodedText = decodePaintContent(jsonText['type'], jsonText) as TextContent?;

    expect(decodedText, isNotNull);
    expect(decodedText!.text, 'Hello World');
    expect(decodedText.scale, 1.5);
    expect(decodedText.rotation, 0.5);
    expect(decodedText.fontSize, 32.0);
    expect(decodedText.isBold, true);
    expect(decodedText.isItalic, true);
    expect(decodedText.isUnderline, true);
    expect(decodedText.textAlign, TextAlign.center);
    expect(decodedText.opacity, 0.8);
    expect(decodedText.fontFamily, 'serif');
    expect(decodedText.paint.color.value, Colors.red.value);
  });

  test('ImageContent template serialization and decoding test', () {
    final Map<String, dynamic> data = {
      'type': 'ImageContent',
      'startPoint': {'dx': 0.0, 'dy': 0.0},
      'size': {'dx': 1200.0, 'dy': 1200.0},
      'imageUrl': 'assets/animal/bird1/1.webp',
      'paint': {
        'color': Colors.black.value,
        'strokeWidth': 4.0,
        'isAntiAlias': true,
        'style': PaintingStyle.stroke.index,
        'strokeCap': StrokeCap.round.index,
        'strokeJoin': StrokeJoin.round.index,
        'blendMode': BlendMode.srcOver.index,
        'invertColors': false,
        'filterQuality': FilterQuality.none.index,
        'colorFilter': null,
        'imageFilter': null,
        'maskFilter': null,
      }
    };

    final content = decodePaintContent('ImageContent', data) as ImageContent?;
    expect(content, isNotNull);
    expect(content!.imageUrl, 'assets/animal/bird1/1.webp');
    expect(content.startPoint, Offset.zero);
    expect(content.size, const Offset(1200.0, 1200.0));
  });

  test('ImageContent draw fit logic with real image', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final String base64Png = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
    final bytes = base64Decode(base64Png);
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final content = ImageContent.data(
      startPoint: const Offset(0, 0),
      size: const Offset(1200, 1200),
      imageUrl: 'assets/animal/bird1/1.webp',
      image: image,
      paint: Paint(),
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    content.draw(canvas, const Size(360, 360), true);
  });
}
