import 'package:flutter/painting.dart';
import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';
import 'paint_content.dart';

/// Custom drawn triangles
class Triangle extends PaintContent {
  Triangle();

  Triangle.data({
    required this.startPoint,
    required this.A,
    required this.B,
    required this.C,
    required Paint paint,
    String? id,
    Color? fillColor,
  }) : super.paint(paint, id: id, fillColor: fillColor);

  factory Triangle.fromJson(Map<String, dynamic> data) {
    return Triangle.data(
      startPoint: jsonToOffset(data['startPoint'] as Map<String, dynamic>),
      A: jsonToOffset(data['A'] as Map<String, dynamic>),
      B: jsonToOffset(data['B'] as Map<String, dynamic>),
      C: jsonToOffset(data['C'] as Map<String, dynamic>),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
      id: data['id'] as String?,
      fillColor: data['fillColor'] != null ? Color((data['fillColor'] as num).toInt()) : null,
    );
  }

  Offset startPoint = Offset.zero;

  Offset A = Offset.zero;
  Offset B = Offset.zero;
  Offset C = Offset.zero;

  @override
  String get contentType => 'Triangle';

  @override
  void startDraw(Offset startPoint) => this.startPoint = startPoint;

  @override
  void drawing(Offset nowPoint) {
    A = Offset(
      startPoint.dx + (nowPoint.dx - startPoint.dx) / 2,
      startPoint.dy,
    );
    B = Offset(startPoint.dx, nowPoint.dy);
    C = nowPoint;
  }

  @override
  bool containsPoint(Offset pt) {
    return getPath().contains(pt);
  }

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    final Path path = getPath();
    if (fillColor != null) {
      final Paint fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = fillColor!
        ..isAntiAlias = true;
      canvas.drawPath(path, fillPaint);
    }

    canvas.drawPath(path, paint);
  }

  @override
  Path getPath() {
    return Path()
      ..moveTo(A.dx, A.dy)
      ..lineTo(B.dx, B.dy)
      ..lineTo(C.dx, C.dy)
      ..close();
  }

  @override
  Triangle copy() => Triangle.data(
        startPoint: startPoint,
        A: A,
        B: B,
        C: C,
        paint: paint.copyWith(),
        id: id,
        fillColor: fillColor,
      );

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'startPoint': startPoint.toJson(),
      'A': A.toJson(),
      'B': B.toJson(),
      'C': C.toJson(),
      'paint': paint.toJson(),
      if (fillColor != null) 'fillColor': fillColor!.toARGB32(),
    };
  }
}
