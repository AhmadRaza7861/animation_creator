import 'dart:ui';

import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';
import 'paint_content.dart';

/// 自由手绘线条基类
///
/// 封装了与 `SimpleLine` 相同的手绘逻辑：按最小间距采集触摸点，并使用
/// 二次贝塞尔曲线平滑连接。子类只需实现各自的渲染方式（虚线、点线、
/// 荧光笔等），即可获得与普通画笔完全一致的绘制手感。
///
/// Freehand Line Base Class
///
/// Encapsulates the same freehand logic as `SimpleLine`: it samples touch
/// points by a minimum distance and connects them with quadratic bezier curves
/// for smoothing. Subclasses only implement their own rendering (dashed,
/// dotted, highlighter, etc.) to get the exact same drawing feel as the regular
/// pen.
abstract class FreehandLine extends PaintContent {
  FreehandLine({this.minPointDistance = 2.0});

  FreehandLine.data({
    this.minPointDistance = 2.0,
    required this.points,
    required Paint paint,
  }) : super.paint(paint);

  /// 最小点距离，用于过滤过近的点，减少数据量
  ///
  /// Minimum point distance for filtering points that are too close
  final double minPointDistance;

  /// 采集到的绘制点
  ///
  /// Collected drawing points
  List<Offset> points = <Offset>[];

  /// 上一个点，用于点过滤优化
  ///
  /// Last point for point filtering optimization
  Offset? _lastPoint;

  @override
  void startDraw(Offset startPoint) {
    points = <Offset>[startPoint];
    _lastPoint = startPoint;
  }

  @override
  void drawing(Offset nowPoint) {
    // 点过滤优化：跳过距离过近的点
    if (_lastPoint != null && (nowPoint - _lastPoint!).distance < minPointDistance) {
      return;
    }

    points.add(nowPoint);
    _lastPoint = nowPoint;
  }

  /// 根据采集点生成平滑路径（算法与 `SimpleLine` 一致）
  ///
  /// Build a smoothed path from the collected points (same algorithm as `SimpleLine`)
  Path buildSmoothPath() {
    final Path path = Path();

    if (points.isEmpty) {
      return path;
    }

    path.moveTo(points.first.dx, points.first.dy);

    // 少于 3 个点无法构成贝塞尔曲线，直接连线
    if (points.length < 3) {
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      return path;
    }

    // 使用当前点作为控制点、相邻中点作为终点连接曲线
    for (int i = 1; i < points.length - 1; i++) {
      final Offset p0 = points[i];
      final Offset p1 = points[i + 1];
      final Offset midPoint = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, midPoint.dx, midPoint.dy);
    }

    // 最后一段
    final Offset last = points.last;
    final Offset secondLast = points[points.length - 2];
    path.quadraticBezierTo(secondLast.dx, secondLast.dy, last.dx, last.dy);

    return path;
  }

  /// 所有手绘线条共用的 JSON 字段
  ///
  /// Common JSON fields shared by all freehand lines
  Map<String, dynamic> baseJson() => <String, dynamic>{
        'minPointDistance': minPointDistance,
        'points': points.map((Offset e) => e.toJson()).toList(),
        'paint': paint.toJson(),
      };
}
