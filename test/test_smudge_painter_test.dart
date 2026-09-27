import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/features/editor/presentation/screens/editor_screen.dart';

void main() {
  test('SmudgePreviewPainter paints without crashing', () {
    final painter = SmudgePreviewPainter(0.75, 10.0);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    expect(() => painter.paint(canvas, const Size(200, 60)), returnsNormally);
    
    final picture = recorder.endRecording();
    expect(picture, isNotNull);
  });
}
