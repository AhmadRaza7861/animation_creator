import 'dart:ui';
import 'package:flutter/painting.dart';

import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';
import '../draw_path/draw_path.dart';
import 'paint_content.dart';

/// Lasso Selection Content
/// 
/// Draws a freehand shape that connects the end point back to the start point
/// to form a closed loop.
class Lasso extends PaintContent {
  Lasso({
    this.minPointDistance = 2.0,
  });

  Lasso.data({
    this.minPointDistance = 2.0,
    this.points,
    required Paint paint,
  }) : super.paint(paint);

  factory Lasso.fromJson(Map<String, dynamic> data) {
    return Lasso.data(
      minPointDistance: (data['minPointDistance'] ?? 2.0) as double,
      points: (data['points'] as List<dynamic>)
          .map((dynamic e) => jsonToOffset(e as Map<String, dynamic>))
          .toList(),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
  }

  /// Minimum point distance
  final double minPointDistance;

  /// Drawing points list
  List<Offset>? points;

  /// Last point position for point filtering optimization
  Offset? _lastPoint;

  @override
  String get contentType => 'Lasso';

  @override
  void startDraw(Offset startPoint) {
    _lastPoint = startPoint;
    points = <Offset>[startPoint];
  }

  @override
  void drawing(Offset nowPoint) {
    if (_lastPoint != null) {
      final double distance = (nowPoint - _lastPoint!).distance;

      // Skip point if too close
      if (distance < minPointDistance) {
        return;
      }
    }

    points?.add(nowPoint);
    _lastPoint = nowPoint;
  }

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (points == null || points!.isEmpty) {
      return;
    }

    final Path path = getPath();

    // MS Paint style alternating black/white dashed selection border
    final Paint blackDashedPaint = Paint()
      ..color = const Color(0xFF000000)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final Paint whiteDashedPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final Path dashedPath1 = Path();
    final Path dashedPath2 = Path();
    
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      bool drawBlack = true;
      while (distance < metric.length) {
        final double len = 4.0;
        if (drawBlack) {
          dashedPath1.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        } else {
          dashedPath2.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        drawBlack = !drawBlack;
      }
    }

    canvas.drawPath(dashedPath1, blackDashedPaint);
    canvas.drawPath(dashedPath2, whiteDashedPaint);
  }

  @override
  Lasso copy() => Lasso.data(
        minPointDistance: minPointDistance,
        points: points?.toList(),
        paint: paint.copyWith(),
      );

  @override
  Path getPath() {
    final Path path = Path();
    if (points == null || points!.isEmpty) {
      return path;
    }

    path.moveTo(points![0].dx, points![0].dy);
    for (int i = 1; i < points!.length; i++) {
      path.lineTo(points![i].dx, points![i].dy);
    }
    
    return path;
  }

  DrawPath getDrawPath() {
    final DrawPath path = DrawPath();
    if (points == null || points!.isEmpty) {
      return path;
    }

    path.moveTo(points![0].dx, points![0].dy);
    for (int i = 1; i < points!.length; i++) {
      path.lineTo(points![i].dx, points![i].dy);
    }
    
    return path;
  }

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'minPointDistance': minPointDistance,
      'points': points?.map((Offset e) => e.toJson()).toList(),
      'paint': paint.toJson(),
    };
  }
}
