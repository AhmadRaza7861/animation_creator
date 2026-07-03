import 'dart:math';

void main() {
  double cx = 100, cy = 100;
  // Handle at bottom-left
  double hx = 0, hy = 100; // wait, if Container is 200x100, center is 100,50

  // Let Container be 200x100. Center = 100, 50
  cx = 100;
  cy = 50;
  // Handle at bottom-left is 0, 100
  hx = 0;
  hy = 100;

  double _rotation = 0.0;

  double startAngle = atan2(hy - cy, hx - cx); // atan2(50, -100)
  print("startAngle: $startAngle (${startAngle * 180 / pi})");
  double _startPanRotation = startAngle - _rotation;

  // We drag it clockwise (which means moving the bottom-left handle UP and LEFT).
  // E.g., moving from (0, 100) along a circle around (100, 50).
  // At angle startAngle, let's rotate it by 10 degrees clockwise (-10 degrees math?).
  // Clockwise visually is +10 degrees in flutter.
  // So finger moves to angle `startAngle + 10 degrees`.
  double angle = startAngle + (10 * pi / 180);
  print("new finger angle: $angle (${angle * 180 / pi})");
  _rotation = angle - _startPanRotation;
  print(
    "rotation = $_rotation rad (${_rotation * 180 / pi} deg)",
  ); // expected 10
}
