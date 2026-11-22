import 'package:dummy/package_code/paint_contents.dart';
import 'package:dummy/package_code/src/drawing_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression: once a layer passed `maxHistorySteps` (100) strokes, every new
/// stroke deleted the oldest one from the canvas ("my previous drawing
/// disappears"), and undo could get stuck disabled.
void main() {
  void drawStroke(DrawingController c, int n) {
    final double y = 10.0 + n;
    c.startDraw(Offset(10, y));
    c.drawing(Offset(20, y));
    c.drawing(Offset(30, y));
    c.endDraw();
  }

  test('drawing past the undo limit never deletes earlier strokes', () {
    final DrawingController c = DrawingController();
    c.setPaintContent(FreehandLine());

    drawStroke(c, 0);
    final PaintContent firstStroke = c.getHistory.first;

    for (int i = 1; i < 150; i++) {
      drawStroke(c, i);
    }

    final layer = c.activeLayer.value!;
    expect(layer.history.length, 150, reason: 'all strokes must stay on canvas');
    expect(layer.currentIndex, 150);
    expect(identical(layer.history.first, firstStroke), isTrue,
        reason: 'the very first stroke must still be drawn');

    // Undo is still capped at the last 100 actions.
    expect(c.canUndo(), isTrue);
    for (int i = 0; i < 100; i++) {
      c.undo();
    }
    expect(layer.currentIndex, 50);
    expect(c.canUndo(), isFalse);
    c.undo(); // beyond the cap: no-op
    expect(layer.currentIndex, 50);
    expect(layer.history.length, 150);

    // Redo brings everything back.
    for (int i = 0; i < 100; i++) {
      c.redo();
    }
    expect(layer.currentIndex, 150);
  });

  test('re-opened frame with 100+ strokes keeps them and undo still works', () {
    final DrawingController c = DrawingController();
    c.setPaintContent(FreehandLine());
    for (int i = 0; i < 100; i++) {
      drawStroke(c, i);
    }
    final layer = c.activeLayer.value!;
    // Simulate re-opening the frame: loaded strokes are not undoable.
    layer.sessionStartIndex = layer.currentIndex;
    final PaintContent firstLoaded = layer.history.first;

    for (int i = 0; i < 5; i++) {
      drawStroke(c, 200 + i);
    }

    expect(layer.history.length, 105);
    expect(identical(layer.history.first, firstLoaded), isTrue);
    expect(c.canUndo(), isTrue, reason: 'new strokes must be undoable');
    for (int i = 0; i < 5; i++) {
      c.undo();
    }
    expect(layer.currentIndex, 100);
    expect(c.canUndo(), isFalse, reason: 'cannot undo into loaded strokes');
  });
}
