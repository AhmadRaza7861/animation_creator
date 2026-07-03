import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/package_code/src/paint_contents/simple_line.dart'; // Assuming FreehandLine is defined here
import 'package:dummy/package_code/src/paint_contents/circle.dart';
import 'package:dummy/package_code/src/paint_contents/shape_sticker.dart';
import 'package:dummy/package_code/src/paint_contents/clipped.dart';
import 'package:dummy/package_code/src/paint_contents/eraser_hole.dart';
import 'package:dummy/package_code/src/paint_contents/eraser.dart';
import 'package:dummy/package_code/src/paint_contents/eyedropper.dart';
import 'package:dummy/package_code/src/paint_contents/blur.dart';
import 'package:dummy/package_code/src/paint_contents/smudge.dart';
import 'package:dummy/package_code/src/paint_contents/fill.dart';
import 'package:dummy/package_code/src/draw_path/draw_path.dart';

void main() {
  testWidgets('Test JSON serialization', (WidgetTester tester) async {
    final line = FreehandLine(useBezierCurve: false);
    line.paint = Paint()..color = Colors.red;
    line.startDraw(const Offset(0, 0));
    line.drawing(const Offset(10, 10));

    final json1 = line.toJson();
    final jsonString = jsonEncode(json1);
    
    final decoded = jsonDecode(jsonString);
    final newLine = FreehandLine.fromJson(decoded);
    
    expect(newLine.contentType, 'FreehandLine');
    debugPrint('FreehandLine success');
    
    final circle = Circle();
    circle.paint = Paint()..color = Colors.blue;
    circle.startDraw(const Offset(0,0));
    circle.drawing(const Offset(10,10));
    final sticker = ShapeStickerContent(child: circle, offset: const Offset(0,0), scale: 1, rotation: 0, size: const Size(100,100));
    sticker.paint = Paint()..color = Colors.green;
    final Map<String, dynamic> output = sticker.toJson();
    final String stickerStr = jsonEncode(output);
    final ShapeStickerContent newSticker = ShapeStickerContent.fromJson(jsonDecode(stickerStr));
    expect(newSticker.contentType, 'ShapeStickerContent');
    debugPrint('ShapeStickerContent success');

    final eraserHole = EraserHole(path: DrawPath(path: Path()..addRect(const Rect.fromLTWH(0, 0, 10, 10))), paint: Paint()..color = Colors.black);
    final String holeStr = jsonEncode(eraserHole.toJson());
    final EraserHole newHole = EraserHole.fromJson(jsonDecode(holeStr));
    expect(newHole.contentType, 'EraserHole');
    debugPrint('EraserHole success');

    final clipped = ClippedHistoryContent([circle, line], DrawPath(path: Path()..addOval(const Rect.fromLTWH(0, 0, 100, 100))), const Rect.fromLTWH(0, 0, 100, 100), paint: Paint());
    final String clipStr = jsonEncode(clipped.toJson());
    final ClippedHistoryContent newClip = ClippedHistoryContent.fromJson(jsonDecode(clipStr));
    expect(newClip.contentType, 'ClippedHistoryContent');
    expect(newClip.history.length, 2);
    expect(newClip.history[1] is FreehandLine, true);
    debugPrint('ClippedHistoryContent success');

    final eraser = Eraser();
    eraser.paint = Paint()..color = Colors.white;
    eraser.startDraw(const Offset(0, 0));
    eraser.drawing(const Offset(10, 10));
    final Eraser newEraser = Eraser.fromJson(jsonDecode(jsonEncode(eraser.toJson())));
    expect(newEraser.contentType, 'Eraser');
    debugPrint('Eraser success');

    final fill = FillContent();
    fill.paint = Paint()..color = Colors.red;
    fill.startDraw(const Offset(0, 0));
    final FillContent newFill = FillContent.fromJson(jsonDecode(jsonEncode(fill.toJson())));
    expect(newFill.contentType, 'FillContent');
    debugPrint('FillContent success');

    final smudge = SmudgeContent(strength: 0.5);
    smudge.paint = Paint()..strokeWidth = 10.0;
    smudge.startDraw(const Offset(0,0));
    final SmudgeContent newSmudge = SmudgeContent.fromJson(jsonDecode(jsonEncode(smudge.toJson())));
    expect(newSmudge.contentType, 'SmudgeContent');
    debugPrint('SmudgeContent success');

    final blur = BlurContent();
    blur.paint = Paint()..strokeWidth = 10.0;
    blur.startDraw(const Offset(0,0));
    final BlurContent newBlur = BlurContent.fromJson(jsonDecode(jsonEncode(blur.toJson())));
    expect(newBlur.contentType, 'BlurContent');
    debugPrint('BlurContent success');

    final dropper = Eyedropper();
    dropper.paint = Paint();
    final Eyedropper newDropper = Eyedropper.fromJson(jsonDecode(jsonEncode(dropper.toJson())));
    expect(newDropper.contentType, 'Eyedropper');
    debugPrint('Eyedropper success');
  });
}
