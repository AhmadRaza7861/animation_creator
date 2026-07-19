import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';
import 'paint_content.dart';

class Pentagon extends PaintContent {
  Pentagon();

  Pentagon.data({
    required this.startPoint,
    required this.endPoint,
    required Paint paint,
  }) : super.paint(paint);

  factory Pentagon.fromJson(Map<String, dynamic> data) {
    return Pentagon.data(
      startPoint: jsonToOffset(data['startPoint'] as Map<String, dynamic>),
      endPoint: jsonToOffset(data['endPoint'] as Map<String, dynamic>),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
  }

  Offset? startPoint;
  Offset? endPoint;

  @override
  String get contentType => 'Pentagon';

  @override
  void startDraw(Offset startPoint) => this.startPoint = startPoint;

  @override
  void drawing(Offset nowPoint) => endPoint = nowPoint;

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (startPoint == null || endPoint == null) return;
    canvas.drawPath(getPath(), paint);
  }

  @override
  Pentagon copy() => Pentagon.data(
        startPoint: startPoint,
        endPoint: endPoint,
        paint: paint.copyWith(),
      );

  @override
  Path getPath() {
    if (startPoint == null || endPoint == null) return Path();
    final rect = Rect.fromPoints(startPoint!, endPoint!);
    final center = rect.center;
    final rx = rect.width / 2;
    final ry = rect.height / 2;

    final Path path = Path();
    for (int i = 0; i < 5; i++) {
      final double angle = i * 2 * math.pi / 5 - math.pi / 2;
      final x = center.dx + rx * math.cos(angle);
      final y = center.dy + ry * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'startPoint': startPoint?.toJson(),
      'endPoint': endPoint?.toJson(),
      'paint': paint.toJson(),
    };
  }
}

class Heart extends PaintContent {
  Heart();

  Heart.data({
    required this.startPoint,
    required this.endPoint,
    required Paint paint,
  }) : super.paint(paint);

  factory Heart.fromJson(Map<String, dynamic> data) {
    return Heart.data(
      startPoint: jsonToOffset(data['startPoint'] as Map<String, dynamic>),
      endPoint: jsonToOffset(data['endPoint'] as Map<String, dynamic>),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
  }

  Offset? startPoint;
  Offset? endPoint;

  @override
  String get contentType => 'Heart';

  @override
  void startDraw(Offset startPoint) => this.startPoint = startPoint;

  @override
  void drawing(Offset nowPoint) => endPoint = nowPoint;

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (startPoint == null || endPoint == null) return;
    canvas.drawPath(getPath(), paint);
  }

  @override
  Heart copy() => Heart.data(
        startPoint: startPoint,
        endPoint: endPoint,
        paint: paint.copyWith(),
      );

  @override
  Path getPath() {
    if (startPoint == null || endPoint == null) return Path();
    final rect = Rect.fromPoints(startPoint!, endPoint!);
    final w = rect.width;
    final h = rect.height;

    final Path path = Path();
    path.moveTo(rect.left + w * 0.5, rect.top + h * 0.25);
    path.cubicTo(
      rect.left + w * 0.1,
      rect.top,
      rect.left,
      rect.top + h * 0.45,
      rect.left + w * 0.5,
      rect.bottom,
    );
    path.cubicTo(
      rect.right,
      rect.top + h * 0.45,
      rect.right - w * 0.1,
      rect.top,
      rect.left + w * 0.5,
      rect.top + h * 0.25,
    );
    path.close();
    return path;
  }

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'startPoint': startPoint?.toJson(),
      'endPoint': endPoint?.toJson(),
      'paint': paint.toJson(),
    };
  }
}

class CubeShape extends PaintContent {
  CubeShape();

  CubeShape.data({
    required this.startPoint,
    required this.endPoint,
    required Paint paint,
  }) : super.paint(paint);

  factory CubeShape.fromJson(Map<String, dynamic> data) {
    return CubeShape.data(
      startPoint: jsonToOffset(data['startPoint'] as Map<String, dynamic>),
      endPoint: jsonToOffset(data['endPoint'] as Map<String, dynamic>),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
  }

  Offset? startPoint;
  Offset? endPoint;

  @override
  String get contentType => 'CubeShape';

  @override
  void startDraw(Offset startPoint) => this.startPoint = startPoint;

  @override
  void drawing(Offset nowPoint) => endPoint = nowPoint;

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (startPoint == null || endPoint == null) return;
    canvas.drawPath(getPath(), paint);
  }

  @override
  CubeShape copy() => CubeShape.data(
        startPoint: startPoint,
        endPoint: endPoint,
        paint: paint.copyWith(),
      );

  @override
  Path getPath() {
    if (startPoint == null || endPoint == null) return Path();
    final rect = Rect.fromPoints(startPoint!, endPoint!);
    final w = rect.width;
    final h = rect.height;
    final double offsetW = w * 0.25;
    final double offsetH = h * 0.25;

    final Path path = Path();
    // Front face
    path.addRect(Rect.fromLTWH(rect.left, rect.top + offsetH, w - offsetW, h - offsetH));
    // Back face
    path.addRect(Rect.fromLTWH(rect.left + offsetW, rect.top, w - offsetW, h - offsetH));
    // Connect corners
    path.moveTo(rect.left, rect.top + offsetH);
    path.lineTo(rect.left + offsetW, rect.top);
    path.moveTo(rect.right - offsetW, rect.top + offsetH);
    path.lineTo(rect.right, rect.top);
    path.moveTo(rect.left, rect.bottom);
    path.lineTo(rect.left + offsetW, rect.bottom - offsetH);
    path.moveTo(rect.right - offsetW, rect.bottom);
    path.lineTo(rect.right, rect.bottom - offsetH);
    return path;
  }

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'startPoint': startPoint?.toJson(),
      'endPoint': endPoint?.toJson(),
      'paint': paint.toJson(),
    };
  }
}

class CylinderShape extends PaintContent {
  CylinderShape();

  CylinderShape.data({
    required this.startPoint,
    required this.endPoint,
    required Paint paint,
  }) : super.paint(paint);

  factory CylinderShape.fromJson(Map<String, dynamic> data) {
    return CylinderShape.data(
      startPoint: jsonToOffset(data['startPoint'] as Map<String, dynamic>),
      endPoint: jsonToOffset(data['endPoint'] as Map<String, dynamic>),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
  }

  Offset? startPoint;
  Offset? endPoint;

  @override
  String get contentType => 'CylinderShape';

  @override
  void startDraw(Offset startPoint) => this.startPoint = startPoint;

  @override
  void drawing(Offset nowPoint) => endPoint = nowPoint;

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (startPoint == null || endPoint == null) return;
    canvas.drawPath(getPath(), paint);
  }

  @override
  CylinderShape copy() => CylinderShape.data(
        startPoint: startPoint,
        endPoint: endPoint,
        paint: paint.copyWith(),
      );

  @override
  Path getPath() {
    if (startPoint == null || endPoint == null) return Path();
    final rect = Rect.fromPoints(startPoint!, endPoint!);
    final w = rect.width;
    final h = rect.height;
    final double eh = h * 0.2; // ellipse height

    final Path path = Path();
    // Top ellipse
    path.addOval(Rect.fromLTWH(rect.left, rect.top, w, eh));
    
    // Bottom ellipse half (arc) and sides
    final bottomEllipse = Rect.fromLTWH(rect.left, rect.bottom - eh, w, eh);
    path.addArc(bottomEllipse, 0, math.pi); // bottom half arc
    
    // Side lines
    path.moveTo(rect.left, rect.top + eh / 2);
    path.lineTo(rect.left, rect.bottom - eh / 2);
    path.moveTo(rect.right, rect.top + eh / 2);
    path.lineTo(rect.right, rect.bottom - eh / 2);
    return path;
  }

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'startPoint': startPoint?.toJson(),
      'endPoint': endPoint?.toJson(),
      'paint': paint.toJson(),
    };
  }
}
