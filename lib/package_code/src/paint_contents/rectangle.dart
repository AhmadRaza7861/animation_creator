import 'package:flutter/painting.dart';
import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';

import 'paint_content.dart';

/// 矩形绘制内容
///
/// 通过起点和终点定义对角线来绘制矩形
///
/// Rectangle Drawing Content
///
/// Draws a rectangle by defining diagonal through start and end points
class Rectangle extends PaintContent {
  Rectangle();

  Rectangle.data({
    required this.startPoint,
    required this.endPoint,
    required Paint paint,
    String? id,
    Color? fillColor,
  }) : super.paint(paint, id: id, fillColor: fillColor);

  factory Rectangle.fromJson(Map<String, dynamic> data) {
    return Rectangle.data(
      startPoint: jsonToOffset(data['startPoint'] as Map<String, dynamic>?),
      endPoint: jsonToOffset(data['endPoint'] as Map<String, dynamic>?),
      paint: data['paint'] != null
          ? jsonToPaint(data['paint'] as Map<String, dynamic>)
          : Paint(),
      id: data['id'] as String?,
      fillColor: data['fillColor'] != null ? Color((data['fillColor'] as num).toInt()) : null,
    );
  }

  /// 起始点坐标（矩形对角线的一个端点）
  ///
  /// Start point coordinates (one endpoint of the rectangle diagonal)
  Offset? startPoint;

  /// 结束点坐标（矩形对角线的另一个端点）
  ///
  /// End point coordinates (the other endpoint of the rectangle diagonal)
  Offset? endPoint;

  @override
  String get contentType => 'Rectangle';

  @override
  void startDraw(Offset startPoint) => this.startPoint = startPoint;

  @override
  void drawing(Offset nowPoint) => endPoint = nowPoint;

  @override
  bool containsPoint(Offset pt) {
    if (startPoint == null || endPoint == null) return false;
    final double tolerance = (paint.strokeWidth > 0 ? paint.strokeWidth * 0.5 : 2.0) + 1.0;
    final Rect rect = Rect.fromPoints(startPoint!, endPoint!).inflate(tolerance);
    return rect.contains(pt);
  }

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (startPoint == null || endPoint == null) {
      return;
    }

    final Rect rect = Rect.fromPoints(startPoint!, endPoint!);
    if (fillColor != null) {
      final Paint fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = fillColor!
        ..isAntiAlias = true;
      canvas.drawRect(rect, fillPaint);
    }

    canvas.drawRect(rect, paint);
  }

  @override
  Rectangle copy() => Rectangle.data(
    startPoint: startPoint,
    endPoint: endPoint,
    paint: paint.copyWith(),
    id: id,
    fillColor: fillColor,
  );

  @override
  Path getPath() {
    if (startPoint == null || endPoint == null) return Path();
    return Path()..addRect(Rect.fromPoints(startPoint!, endPoint!));
  }

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'startPoint': startPoint?.toJson(),
      'endPoint': endPoint?.toJson(),
      'paint': paint.toJson(),
      if (fillColor != null) 'fillColor': fillColor!.toARGB32(),
    };
  }
}
