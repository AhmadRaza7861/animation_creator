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

  Path? _committedPath;
  int _committedSegEnd = 1;
  Path? _cachedFullPath;
  int _cachedPtLen = 0;
  bool _cachedBezier = true;
  Offset? _cachedFirst;
  Offset? _cachedSecond;
  Offset? _cachedLast;

  @override
  String get contentType => 'FreehandLine';

  void _resetPathCache() {
    _committedPath = null;
    _committedSegEnd = 1;
    _cachedFullPath = null;
    _cachedPtLen = 0;
    _cachedFirst = null;
    _cachedSecond = null;
    _cachedLast = null;
  }

  @override
  void clearRenderCache() {
    _resetPathCache();
  }

  @override
  void startDraw(Offset startPoint) {
    _resetPathCache();
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
      if (points!.length == 1) {
        canvas.drawCircle(points![0], paint.strokeWidth / 8, paint);
        return;
      }
      canvas.drawPath(_getOrBuildPointPath(), paint);
    } else {
      canvas.drawPath(path.path, paint);
    }
  }

  Path _getOrBuildPointPath() {
    final List<Offset> pts = points!;
    final int n = pts.length;
    if (!useBezierCurve || n < 3) {
      if (_cachedFullPath != null &&
          _cachedBezier == useBezierCurve &&
          _cachedPtLen == n &&
          _cachedFirst == pts.first &&
          _cachedLast == pts.last &&
          (n < 2 || _cachedSecond == pts[1])) {
        return _cachedFullPath!;
      }
      final Path p = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (int i = 1; i < n; i++) {
        p.lineTo(pts[i].dx, pts[i].dy);
      }
      _cachedFullPath = p;
      _cachedPtLen = n;
      _cachedBezier = useBezierCurve;
      _cachedFirst = pts.first;
      _cachedSecond = n > 1 ? pts[1] : null;
      _cachedLast = pts.last;
      return p;
    }

    if (_cachedFullPath != null &&
        _cachedBezier &&
        _cachedPtLen == n &&
        _cachedFirst == pts.first &&
        _cachedSecond == pts[1] &&
        _cachedLast == pts.last) {
      return _cachedFullPath!;
    }

    final bool canExtend =
        _cachedBezier &&
        _committedPath != null &&
        _cachedPtLen >= 3 &&
        n >= _cachedPtLen &&
        _cachedFirst == pts.first &&
        _cachedSecond == pts[1];

    if (!canExtend) {
      _committedPath = Path()..moveTo(pts[0].dx, pts[0].dy);
      _committedSegEnd = 1;
    }

    while (_committedSegEnd <= n - 2) {
      final int i = _committedSegEnd;
      final Offset p0 = pts[i];
      final Offset p1 = pts[i + 1];
      _committedPath!.quadraticBezierTo(
        p0.dx,
        p0.dy,
        (p0.dx + p1.dx) * 0.5,
        (p0.dy + p1.dy) * 0.5,
      );
      _committedSegEnd++;
    }

    final Path full = Path.from(_committedPath!);
    final Offset lastPoint = pts.last;
    final Offset secondLastPoint = pts[n - 2];
    full.quadraticBezierTo(
      secondLastPoint.dx,
      secondLastPoint.dy,
      lastPoint.dx,
      lastPoint.dy,
    );

    _cachedFullPath = full;
    _cachedBezier = true;
    _cachedPtLen = n;
    _cachedFirst = pts.first;
    _cachedSecond = pts[1];
    _cachedLast = lastPoint;
    return full;
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
      if (useBezierCurve && points!.length == 1) {
        return Path()
          ..addOval(Rect.fromCircle(center: points![0], radius: paint.strokeWidth / 8));
      }
      return _getOrBuildPointPath();
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
