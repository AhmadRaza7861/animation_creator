import 'package:flutter/painting.dart';
import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';
import 'paint_content.dart';
import '../draw_path/draw_path.dart';

/// 简单直线绘制内容
///
/// 只有起点和终点的直线，支持编辑
///
/// Simple Line Drawing Content
///
/// A straight line with only start and end points, supports editing
class SimpleLine extends PaintContent {
  SimpleLine();

  SimpleLine.data({
    required this.startPoint,
    required this.endPoint,
    required Paint paint,
  }) : super.paint(paint);

  factory SimpleLine.fromJson(Map<String, dynamic> data) {
    return SimpleLine.data(
      startPoint: jsonToOffset(data['startPoint'] as Map<String, dynamic>),
      endPoint: jsonToOffset(data['endPoint'] as Map<String, dynamic>),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
  }

  /// 起始点坐标
  ///
  /// Start point coordinates
  Offset? startPoint;

  /// 结束点坐标
  ///
  /// End point coordinates
  Offset? endPoint;

  @override
  String get contentType => 'SimpleLine';

  @override
  void startDraw(Offset startPoint) => this.startPoint = startPoint;

  @override
  void drawing(Offset nowPoint) => endPoint = nowPoint;

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (startPoint == null || endPoint == null) {
      return;
    }

    canvas.drawLine(startPoint!, endPoint!, paint);
  }

  @override
  SimpleLine copy() => SimpleLine.data(
    startPoint: startPoint,
    endPoint: endPoint,
    paint: paint.copyWith(),
  );

  @override
  Path getPath() {
    if (startPoint == null || endPoint == null) return Path();
    return Path()
      ..moveTo(startPoint!.dx, startPoint!.dy)
      ..lineTo(endPoint!.dx, endPoint!.dy);
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

/// 自由线条绘制内容 (原 SimpleLine)
class FreehandLine extends PaintContent {
  FreehandLine({
    this.minPointDistance = 0.5,
    this.useBezierCurve = true,
  });

  FreehandLine.data({
    this.minPointDistance = 0.5,
    this.useBezierCurve = true,
    this.points,
    DrawPath? path,
    required Paint paint,
  })  : path = path ?? DrawPath(),
        super.paint(paint);

  factory FreehandLine.fromJson(Map<String, dynamic> data) {
    return FreehandLine.data(
      minPointDistance: (data['minPointDistance'] ?? 0.5) as double,
      useBezierCurve: (data['useBezierCurve'] ?? true) as bool,
      points: data.containsKey('points')
          ? (data['points'] as List<dynamic>)
              .map((dynamic e) => jsonToOffset(e as Map<String, dynamic>))
              .toList()
          : null,
      path: data.containsKey('path')
          ? DrawPath.fromJson(data['path'] as Map<String, dynamic>)
          : null,
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
  }

  final double minPointDistance;
  final bool useBezierCurve;
  DrawPath path = DrawPath();
  List<Offset>? points;
  Offset? _lastPoint;

  @override
  String get contentType => 'FreehandLine';

  @override
  void startDraw(Offset startPoint) {
    _lastPoint = startPoint;
    points = <Offset>[startPoint];
    path = DrawPath();
    path.moveTo(startPoint.dx, startPoint.dy);
  }

  @override
  void drawing(Offset nowPoint) {
    if (_lastPoint != null) {
      final double distance = (nowPoint - _lastPoint!).distance;
      if (distance < minPointDistance) return;
    }

    points?.add(nowPoint);
    path.lineTo(nowPoint.dx, nowPoint.dy);
    _lastPoint = nowPoint;
  }

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (points != null && points!.isNotEmpty) {
      if (useBezierCurve) {
        _drawWithBezierCurve(canvas);
      } else {
        _drawWithStraightLines(canvas);
      }
    } else {
      canvas.drawPath(path.path, paint);
    }
  }

  void _drawWithStraightLines(Canvas canvas) {
    if (points == null || points!.isEmpty) return;
    final Path p = Path();
    p.moveTo(points![0].dx, points![0].dy);
    for (int i = 1; i < points!.length; i++) {
      p.lineTo(points![i].dx, points![i].dy);
    }
    canvas.drawPath(p, paint);
  }

  void _drawWithBezierCurve(Canvas canvas) {
    if (points == null || points!.isEmpty) return;
    if (points!.length == 1) {
      canvas.drawCircle(points![0], paint.strokeWidth / 8, paint);
      return;
    }

    final Path bezierPath = Path();
    bezierPath.moveTo(points![0].dx, points![0].dy);

    if (points!.length == 2) {
      bezierPath.lineTo(points![1].dx, points![1].dy);
    } else {
      for (int i = 1; i < points!.length - 1; i++) {
        final Offset p0 = points![i];
        final Offset p1 = points![i + 1];
        final Offset midPoint = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
        bezierPath.quadraticBezierTo(p0.dx, p0.dy, midPoint.dx, midPoint.dy);
      }
      final Offset lastPoint = points!.last;
      final Offset secondLastPoint = points![points!.length - 2];
      bezierPath.quadraticBezierTo(secondLastPoint.dx, secondLastPoint.dy, lastPoint.dx, lastPoint.dy);
    }
    canvas.drawPath(bezierPath, paint);
  }

  @override
  FreehandLine copy() => FreehandLine.data(
        minPointDistance: minPointDistance,
        useBezierCurve: useBezierCurve,
        points: points?.toList(),
        path: path.copy(),
        paint: paint.copyWith(),
      );

  @override
  Path getPath() {
    if (points != null && points!.isNotEmpty) {
      final Path p = Path();
      p.moveTo(points![0].dx, points![0].dy);
      
      if (useBezierCurve) {
        if (points!.length == 1) {
          p.addOval(Rect.fromCircle(center: points![0], radius: paint.strokeWidth / 8));
        } else if (points!.length == 2) {
          p.lineTo(points![1].dx, points![1].dy);
        } else {
          for (int i = 1; i < points!.length - 1; i++) {
            final Offset p0 = points![i];
            final Offset p1 = points![i + 1];
            final Offset midPoint = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
            p.quadraticBezierTo(p0.dx, p0.dy, midPoint.dx, midPoint.dy);
          }
          final Offset lastPoint = points!.last;
          final Offset secondLastPoint = points![points!.length - 2];
          p.quadraticBezierTo(secondLastPoint.dx, secondLastPoint.dy, lastPoint.dx, lastPoint.dy);
        }
      } else {
        for (int i = 1; i < points!.length; i++) {
          p.lineTo(points![i].dx, points![i].dy);
        }
      }
      return p;
    } else {
      return path.path;
    }
  }

  @override
  Map<String, dynamic> toContentJson() {
    if (useBezierCurve && points != null) {
      return <String, dynamic>{
        'minPointDistance': minPointDistance,
        'useBezierCurve': useBezierCurve,
        'points': points!.map((Offset e) => e.toJson()).toList(),
        'paint': paint.toJson(),
      };
    } else {
      return <String, dynamic>{
        'minPointDistance': minPointDistance,
        'useBezierCurve': useBezierCurve,
        'path': path.toJson(),
        'paint': paint.toJson(),
      };
    }
  }
}
