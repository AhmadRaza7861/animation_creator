import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/package_code/paint_contents.dart';
import 'package:dummy/package_code/src/drawing_board.dart';
import 'package:dummy/package_code/src/drawing_controller.dart';

void main() {
  testWidgets('DrawingBoard with onion skin renders onion skin when SmudgeContent is selected', (tester) async {
    final frame1Controller = DrawingController();
    final frame2Controller = DrawingController();

    // In Frame 1, add a straight line
    frame1Controller.addContent(
      StraightLine.data(
        startPoint: const Offset(50, 50),
        endPoint: const Offset(150, 150),
        paint: Paint()..color = Colors.red..strokeWidth = 5.0,
      ),
    );

    // Frame 2 is active
    final allFrames = [frame1Controller, frame2Controller];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: DrawingBoard(
                background: Container(width: 300, height: 300, color: Colors.white),
                controller: frame2Controller,
                isOnionEnabled: true,
                allControllers: allFrames,
                currentIndex: 1,
                onionBefore: 1,
                onionAfter: 0,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Now select Smudge tool on Frame 2
    frame2Controller.setPaintContent(SmudgeContent(strength: 0.75));
    await tester.pumpAndSettle();

    // Onion skin should remain active and visible without exceptions
    expect(frame2Controller.drawingContent, isNull); // before touch begins
    expect(frame2Controller.currentContent, isA<SmudgeContent>());

    // Start a smudge stroke on frame 2
    final boardFinder = find.byType(DrawingBoard);
    expect(boardFinder, findsOneWidget);
    final boardCenter = tester.getCenter(boardFinder);

    final gesture = await tester.startGesture(boardCenter);
    await tester.pump();
    await gesture.moveBy(const Offset(20, 20));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    // Active layer in frame 2 should now have the smudge content committed
    expect(frame2Controller.getHistory.length, 1);
    expect(frame2Controller.getHistory.first, isA<SmudgeContent>());
  });
}
