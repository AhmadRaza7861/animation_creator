import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../paint_extension/ex_paint.dart';
import 'paint_content.dart';

/// Eyedropper tool to pick color from the canvas
class Eyedropper extends PaintContent {
  Eyedropper();

  Eyedropper.data({
    required Paint paint,
  }) : super.paint(paint);

  factory Eyedropper.fromJson(Map<String, dynamic> data) {
    return Eyedropper.data(
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
  }

  Offset? _currentPoint;
  Color? _currentColor;

  /// Gets the currently picked color
  Color? get pickedColor => _currentColor;

  Uint8List? _pixels;
  int _width = 0;
  int _height = 0;

  /// Store pixel data to sample from
  void setImageData(Uint8List pixels, int width, int height) {
    _pixels = pixels;
    _width = width;
    _height = height;
    if (_currentPoint != null) {
      pickColorAt(_currentPoint!);
    }
  }

  /// Sample the color from the image grid at the specific point
  void pickColorAt(Offset point) {
    if (_pixels == null) return;
    
    final int startX = point.dx.toInt();
    final int startY = point.dy.toInt();

    // Bounds checking
    if (startX < 0 || startX >= _width || startY < 0 || startY >= _height) {
      return;
    }

    final int startIndex = (startY * _width + startX) * 4;
    final int r = _pixels![startIndex];
    final int g = _pixels![startIndex + 1];
    final int b = _pixels![startIndex + 2];
    final int a = _pixels![startIndex + 3];

    _currentColor = Color.fromARGB(a, r, g, b);
  }

  @override
  String get contentType => 'Eyedropper';

  @override
  void startDraw(Offset startPoint) {
    _currentPoint = startPoint;
  }

  @override
  void drawing(Offset nowPoint) {
    _currentPoint = nowPoint;
    if (_pixels != null) {
      pickColorAt(nowPoint);
    }
  }

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    // Only display preview if dragging (not saving to history!)
    if (deeper || _currentPoint == null) return;

    final double radius = 24.0;
    final double pointerHeight = 12.0;
    final double pointerWidth = 16.0;

    // The center of the color preview circle is offset upwards
    final Offset center = Offset(
      _currentPoint!.dx,
      _currentPoint!.dy - radius - pointerHeight,
    );

    // Build the drop shape
    final Path circlePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    final Path trianglePath = Path()
      ..moveTo(_currentPoint!.dx, _currentPoint!.dy)
      ..lineTo(_currentPoint!.dx - pointerWidth / 2, _currentPoint!.dy - pointerHeight)
      ..lineTo(_currentPoint!.dx + pointerWidth / 2, _currentPoint!.dy - pointerHeight)
      ..close();

    final Path dropPath = Path.combine(PathOperation.union, circlePath, trianglePath);

    // Paint the inner color fill
    final Paint colorPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = _currentColor ?? Colors.white;

    // Paint the dark outer border
    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black
      ..strokeWidth = 3.0;

    // Paint a subtle inner white border that overlays the color 
    // to distinguish it from a similar background
    final Paint innerBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeWidth = 1.0;

    canvas.drawPath(dropPath, colorPaint);
    canvas.drawPath(dropPath, borderPaint);
    canvas.drawPath(dropPath, innerBorderPaint);
  }

  @override
  Eyedropper copy() => Eyedropper();

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'paint': paint.toJson(),
    };
  }
}
