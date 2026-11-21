import 'dart:ui';

import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';
import 'brush_cache.dart';
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

  /// Cached incremental tangent samples & baked picture chunks for brushes.
  final ChunkedStrokeCache strokeCache = ChunkedStrokeCache();

  Path? _committedPath;
  int _committedPathSegEnd = 1;
  Path? _cachedFullPath;
  int _cachedPathPtLen = 0;
  Offset? _cachedPathFirst;
  Offset? _cachedPathSecond;
  Offset? _cachedPathLast;

  @override
  void startDraw(Offset startPoint) {
    strokeCache.resetAll();
    _resetPathCache();
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

  /// Ensures smooth curve samples at [step] are incrementally computed.
  ChunkedStrokeCache sampleSmooth(double step) {
    strokeCache.ensureSamples(points, step);
    return strokeCache;
  }

  @override
  int get committedSampleCount => strokeCache.frozenCount;

  /// Base style hash for chunked picture invalidation when stroke paint changes.
  int get baseStyleSignature => Object.hash(
        paint.color.toARGB32(),
        paint.strokeWidth,
        paint.blendMode.index,
        paint.strokeCap.index,
        paint.strokeJoin.index,
      );

  /// Helper to render a sample slice without repeating chunk/tail loops in subclasses.
  void drawSampleSlice(
    Canvas canvas,
    Size size,
    int startSample,
    int? endSample,
    bool includeTail,
    int styleSignature,
    void Function(Canvas target, int startIdx, int endIdx, bool isTail) paintRange,
  ) {
    final int safeStart = startSample.clamp(0, strokeCache.frozenCount);
    final int safeEnd = (endSample ?? strokeCache.frozenCount).clamp(
      safeStart,
      strokeCache.frozenCount,
    );
    if (safeStart < safeEnd) {
      if (safeStart == 0 && safeEnd == strokeCache.frozenCount && includeTail) {
        strokeCache.drawWithChunks(canvas, size, styleSignature, paintRange);
        return;
      }
      paintRange(canvas, safeStart, safeEnd, false);
    }
    if (includeTail && strokeCache.tailCount > 0) {
      paintRange(canvas, 0, strokeCache.tailCount, true);
    }
  }

  /// Renders sampled stroke with automatic chunked `ui.Picture` baking.
  void drawChunkedSamples(
    Canvas canvas,
    Size size,
    double step,
    int styleSignature,
    void Function(Canvas target, int startIdx, int endIdx, bool isTail) paintRange,
  ) {
    strokeCache.ensureSamples(points, step);
    strokeCache.drawWithChunks(canvas, size, styleSignature, paintRange);
  }

  void _resetPathCache() {
    _committedPath = null;
    _committedPathSegEnd = 1;
    _cachedFullPath = null;
    _cachedPathPtLen = 0;
    _cachedPathFirst = null;
    _cachedPathSecond = null;
    _cachedPathLast = null;
  }

  @override
  void clearRenderCache() {
    strokeCache.resetAll();
    _resetPathCache();
  }

  /// 根据采集点生成平滑路径（算法与 `SimpleLine` 一致）
  ///
  /// Build a smoothed path from the collected points (same algorithm as `SimpleLine`)
  Path buildSmoothPath() {
    final int n = points.length;
    if (n == 0) {
      return Path();
    }

    if (n < 3) {
      if (_cachedFullPath != null &&
          _cachedPathPtLen == n &&
          _cachedPathFirst == points.first &&
          _cachedPathLast == points.last) {
        return _cachedFullPath!;
      }
      final Path path = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < n; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      _cachedFullPath = path;
      _cachedPathPtLen = n;
      _cachedPathFirst = points.first;
      _cachedPathSecond = n > 1 ? points[1] : null;
      _cachedPathLast = points.last;
      return path;
    }

    if (_cachedFullPath != null &&
        _cachedPathPtLen == n &&
        _cachedPathFirst == points.first &&
        _cachedPathSecond == points[1] &&
        _cachedPathLast == points.last) {
      return _cachedFullPath!;
    }

    final bool canExtend =
        _committedPath != null &&
        _cachedPathPtLen >= 3 &&
        n >= _cachedPathPtLen &&
        _cachedPathFirst == points.first &&
        _cachedPathSecond == points[1];

    if (!canExtend) {
      _committedPath = Path()..moveTo(points.first.dx, points.first.dy);
      _committedPathSegEnd = 1;
    }

    // Advance frozen quadratic Bezier segments up to index `n - 2`.
    while (_committedPathSegEnd <= n - 2) {
      final int i = _committedPathSegEnd;
      final Offset p0 = points[i];
      final Offset p1 = points[i + 1];
      _committedPath!.quadraticBezierTo(
        p0.dx,
        p0.dy,
        (p0.dx + p1.dx) * 0.5,
        (p0.dy + p1.dy) * 0.5,
      );
      _committedPathSegEnd++;
    }

    // Clone committed path and append only the final tail quadratic segment.
    final Path full = Path.from(_committedPath!);
    final Offset last = points.last;
    final Offset secondLast = points[n - 2];
    full.quadraticBezierTo(secondLast.dx, secondLast.dy, last.dx, last.dy);

    _cachedFullPath = full;
    _cachedPathPtLen = n;
    _cachedPathFirst = points.first;
    _cachedPathSecond = points[1];
    _cachedPathLast = last;
    return full;
  }

  @override
  Path getPath() => buildSmoothPath();

  /// 所有手绘线条共用的 JSON 字段
  ///
  /// Common JSON fields shared by all freehand lines
  Map<String, dynamic> baseJson() => <String, dynamic>{
        'minPointDistance': minPointDistance,
        'points': points.map((Offset e) => e.toJson()).toList(),
        'paint': paint.toJson(),
      };
}
