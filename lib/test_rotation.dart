import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: TestPage()));

class TestPage extends StatefulWidget {
  const TestPage({super.key});
  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  double _rotation = 0.0;
  double _startPanRotation = 0.0;
  Offset _offset = const Offset(200, 200);

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
                translation: const Offset(-0.5, -0.5),
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
                            },
                            child: const Icon(
                              Icons.rotate_right,
                              size: 50,
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
