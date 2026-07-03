import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class TestRotationWidget extends StatefulWidget {
  @override
  _TestRotationWidgetState createState() => _TestRotationWidgetState();
}

class _TestRotationWidgetState extends State<TestRotationWidget> {
  double _rotation = 0.0;
  double _startPanRotation = 0.0;
  Offset _offset = Offset(200, 200);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            left: _offset.dx,
            top: _offset.dy,
            child: GestureDetector(
              onPanUpdate: (d) => setState(() => _offset += d.delta),
              child: FractionalTranslation(
                translation: Offset(-0.5, -0.5),
                child: Transform(
                  transform: Matrix4.diagonal3Values(1.0, 1.0, 1.0)
                    ..rotateZ(_rotation),
                  alignment: Alignment.center,
                  child: Container(
                    width: 200,
                    height: 100,
                    color: Colors.blue.withOpacity(0.5),
                    child: Stack(
                      children: [
                        Positioned(
                          key: ValueKey('rotate_button'),
                          left: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onPanStart: (details) {
                              final RenderBox renderBox =
                                  context.findRenderObject() as RenderBox;
                              final Offset center = renderBox.localToGlobal(
                                Offset.zero,
                              );
                              final pos = details.globalPosition;
                              _startPanRotation =
                                  math.atan2(
                                    pos.dy - center.dy,
                                    pos.dx - center.dx,
                                  ) -
                                  _rotation;
                              print(
                                'PAN START: center=$center pos=$pos startRot=$_startPanRotation',
                              );
                            },
                            onPanUpdate: (details) {
                              final RenderBox renderBox =
                                  context.findRenderObject() as RenderBox;
                              final Offset center = renderBox.localToGlobal(
                                Offset.zero,
                              );
                              final pos = details.globalPosition;
                              setState(() {
                                _rotation =
                                    math.atan2(
                                      pos.dy - center.dy,
                                      pos.dx - center.dx,
                                    ) -
                                    _startPanRotation;
                              });
                              print(
                                'PAN UPDATE: center=$center pos=$pos computed_rot=${math.atan2(pos.dy - center.dy, pos.dx - center.dx) - _startPanRotation} actual_applied_rot=$_rotation',
                              );
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('Test rotation dragging', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: TestRotationWidget()));
    await tester.pumpAndSettle();

    final rotateHandle = find.byKey(ValueKey('rotate_button'));
    final centerPos = tester.getCenter(rotateHandle);

    // Drag it down and right
    final gesture = await tester.startGesture(centerPos);
    await tester.pump();

    for (int i = 0; i < 10; i++) {
      await gesture.moveBy(Offset(10, 10));
      await tester.pump();
    }
  });
}
