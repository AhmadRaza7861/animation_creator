import 'dart:ui';
import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';
import 'paint_content.dart';

/// 笔触线条
class SmoothLine extends PaintContent {
  SmoothLine({
    /// 绘制影响因子，值越小线条越平滑，粗细变化越慢
    this.brushPrecision = 0.8,

    /// 最小点距离，用于过滤过近的点，减少数据量
    /// 值越大，点越少，性能越好，但可能丢失细节
    this.minPointDistance = 2.0,

    /// 是否使用贝塞尔曲线平滑，默认 true
    this.useBezierCurve = true,

    /// 平滑级别，值越大越平滑，但计算成本越高
    /// 0: 无额外平滑 (快速)
    /// 1: 基础平滑 (推荐，默认)
    /// 2: 高级平滑 (解决快速绘制折线感)
    this.smoothLevel = 1,
  });

  SmoothLine.data({
    this.brushPrecision = 0.4,
    this.minPointDistance = 2.0,
    this.useBezierCurve = true,
    this.smoothLevel = 1,
    required this.points,
    required this.strokeWidthList,
    required Paint paint,
  }) : super.paint(paint);

  factory SmoothLine.fromJson(Map<String, dynamic> data) {
    return SmoothLine.data(
      brushPrecision: (data['brushPrecision'] ?? 0.4) as double,
      minPointDistance: (data['minPointDistance'] ?? 2.0) as double,
      useBezierCurve: (data['useBezierCurve'] ?? true) as bool,
      smoothLevel: (data['smoothLevel'] ?? 1) as int,
      points: (data['points'] as List<dynamic>)
          .map((dynamic e) => jsonToOffset(e as Map<String, dynamic>))
          .toList(),
      strokeWidthList:
          (data['strokeWidthList'] as List<dynamic>).map((dynamic e) => e as double).toList(),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
  }

  final double brushPrecision;
  final double minPointDistance;
  final bool useBezierCurve;
  final int smoothLevel;

  /// 绘制点列表
  List<Offset> points = <Offset>[];

  /// 点之间的绘制线条权重列表
  List<double> strokeWidthList = <double>[];

  // Cached coalesced width-bucketed paths + baked completed Picture.
  final List<({Path path, double width})> _cachedRuns =
      <({Path path, double width})>[];
  Picture? _cachedPicture;
  int _cachedPtLen = 0;
  Offset? _cachedFirst;
  Offset? _cachedSecond;
  Offset? _cachedLast;
  double _cachedBaseWidth = 0;
  int _cachedColor = 0;
  int _cachedBlend = 0;

  @override
  String get contentType => 'SmoothLine';

  @override
  void clearRenderCache() {
    try {
      _cachedPicture?.dispose();
    } catch (_) {}
    _cachedPicture = null;
    _cachedRuns.clear();
    _cachedPtLen = 0;
    _cachedFirst = null;
    _cachedLast = null;
  }

  @override
  void startDraw(Offset startPoint) {
    clearRenderCache();
    points = <Offset>[startPoint];
    strokeWidthList = <double>[paint.strokeWidth];
  }

  @override
  void drawing(Offset nowPoint) {
    // 点过滤优化：跳过距离过近的点
    if (points.isNotEmpty) {
      final double distance = (nowPoint - points.last).distance;

      // 如果距离小于最小点距离，跳过此点
      if (distance < minPointDistance) {
        return;
      }
    }

    final double distance = (nowPoint - points.last).distance;

    //原始画笔线条线宽
    final double s = paint.strokeWidth;

    double strokeWidth = s * (s * 2 / (s * distance));

    if (strokeWidth > s * 2) {
      strokeWidth = s * 2;
    }

    //上一个线宽
    final double preWidth = strokeWidthList.last;

    if (strokeWidth - preWidth > brushPrecision) {
      strokeWidth = preWidth + brushPrecision;
    } else if (preWidth - strokeWidth > brushPrecision) {
      strokeWidth = preWidth - brushPrecision;
    }

    //记录点位
    points.add(nowPoint);
    strokeWidthList.add(strokeWidth);
  }

  @override
  Path getPath() {
    if (points.isEmpty) return Path();
    final Path p = Path();
    p.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      p.lineTo(points[i].dx, points[i].dy);
    }
    return p;
  }

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    final int n = points.length;
    if (n == 0) {
      return;
    }

    if (n == 1) {
      canvas.drawCircle(points[0], strokeWidthList[0] / 8, paint);
      return;
    }

    final int curColor = paint.color.toARGB32();
    final int curBlend = paint.blendMode.index;
    final bool validCache =
        _cachedPtLen == n &&
        _cachedFirst == points.first &&
        _cachedSecond == points[1] &&
        _cachedLast == points.last &&
        _cachedBaseWidth == paint.strokeWidth &&
        _cachedColor == curColor &&
        _cachedBlend == curBlend;

    if (validCache && _cachedPicture != null) {
      canvas.drawPicture(_cachedPicture!);
      return;
    }

    if (!validCache) {
      try {
        _cachedPicture?.dispose();
      } catch (_) {}
      _cachedPicture = null;
      _rebuildBucketRuns();
      _cachedPtLen = n;
      _cachedFirst = points.first;
      _cachedSecond = points[1];
      _cachedLast = points.last;
      _cachedBaseWidth = paint.strokeWidth;
      _cachedColor = curColor;
      _cachedBlend = curBlend;
    }

    final Paint workPaint = Paint()
      ..color = paint.color
      ..style = paint.style
      ..strokeCap = paint.strokeCap
      ..strokeJoin = paint.strokeJoin
      ..isAntiAlias = paint.isAntiAlias
      ..blendMode = !useBezierCurve || n <= 2 ? BlendMode.src : paint.blendMode
      ..maskFilter = paint.maskFilter
      ..colorFilter = paint.colorFilter;

    if (deeper || n > 12) {
      final PictureRecorder rec = PictureRecorder();
      final Canvas recCanvas =
          Canvas(rec, size.isEmpty ? null : Offset.zero & size);
      for (final run in _cachedRuns) {
        workPaint.strokeWidth = run.width;
        recCanvas.drawPath(run.path, workPaint);
      }
      _cachedPicture = rec.endRecording();
      canvas.drawPicture(_cachedPicture!);
      return;
    }

    for (final run in _cachedRuns) {
      workPaint.strokeWidth = run.width;
      canvas.drawPath(run.path, workPaint);
    }
  }

  void _rebuildBucketRuns() {
    _cachedRuns.clear();
    final int n = points.length;
    if (n < 2) return;

    void appendRun(Path segBuilder, Offset start, Offset ctrl, Offset? end, double rawWidth, bool isQuad) {
      // Quantize width to 0.35px buckets so adjacent similar segments share 1 Path & 1 draw call.
      final double qWidth = (rawWidth * 3.0).round() / 3.0;
      if (_cachedRuns.isNotEmpty && _cachedRuns.last.width == qWidth) {
        final Path p = _cachedRuns.last.path;
        if (isQuad && end != null) {
          p.quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
        } else {
          p.lineTo(ctrl.dx, ctrl.dy);
        }
      } else {
        final Path p = Path()..moveTo(start.dx, start.dy);
        if (isQuad && end != null) {
          p.quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
        } else {
          p.lineTo(ctrl.dx, ctrl.dy);
        }
        _cachedRuns.add((path: p, width: qWidth));
      }
    }

    if (!useBezierCurve || n <= 2) {
      for (int i = 1; i < n; i++) {
        appendRun(
          Path(),
          points[i - 1],
          points[i],
          null,
          strokeWidthList[i],
          false,
        );
      }
      return;
    }

    final List<Offset> pts =
        smoothLevel >= 2 && n >= 3 ? _interpolatePoints() : points;
    final List<double> widths =
        smoothLevel >= 2 && n >= 3 ? _interpolateWidths() : strokeWidthList;

    Offset currentPoint = pts[0];
    for (int i = 1; i < pts.length - 1; i++) {
      final Offset p0 = pts[i];
      final Offset p1 = pts[i + 1];
      final Offset midPoint = Offset((p0.dx + p1.dx) * 0.5, (p0.dy + p1.dy) * 0.5);
      appendRun(Path(), currentPoint, p0, midPoint, widths[i], true);
      currentPoint = midPoint;
    }

    if (pts.length > 1) {
      final Offset lastPoint = pts.last;
      final Offset secondLastPoint = pts[pts.length - 2];
      appendRun(Path(), currentPoint, secondLastPoint, lastPoint, widths.last, true);
    }
  }

  /// 使用 Catmull-Rom 样条插值生成中间点
  List<Offset> _interpolatePoints() {
    final List<Offset> result = <Offset>[];

    // 每两个点之间插入 2 个中间点
    const int interpolationSteps = 2;

    for (int i = 0; i < points.length - 1; i++) {
      result.add(points[i]);

      // 获取四个控制点用于 Catmull-Rom 插值
      final Offset p0 = i > 0 ? points[i - 1] : points[i];
      final Offset p1 = points[i];
      final Offset p2 = points[i + 1];
      final Offset p3 = i + 2 < points.length ? points[i + 2] : points[i + 1];

      // 在 p1 和 p2 之间插值
      for (int step = 1; step <= interpolationSteps; step++) {
        final double t = step / (interpolationSteps + 1);
        final Offset interpolated = _catmullRomInterpolate(p0, p1, p2, p3, t);
        result.add(interpolated);
      }
    }

    // 添加最后一个点
    result.add(points.last);

    return result;
  }

  /// 插值笔触宽度，与插值点对应
  List<double> _interpolateWidths() {
    final List<double> result = <double>[];

    // 每两个点之间插入 2 个中间宽度
    const int interpolationSteps = 2;

    for (int i = 0; i < strokeWidthList.length - 1; i++) {
      result.add(strokeWidthList[i]);

      final double w1 = strokeWidthList[i];
      final double w2 = strokeWidthList[i + 1];

      // 在两个宽度之间线性插值
      for (int step = 1; step <= interpolationSteps; step++) {
        final double t = step / (interpolationSteps + 1);
        final double interpolatedWidth = w1 + (w2 - w1) * t;
        result.add(interpolatedWidth);
      }
    }

    // 添加最后一个宽度
    result.add(strokeWidthList.last);

    return result;
  }

  /// Catmull-Rom 样条插值
  /// 生成经过 p1 和 p2 的平滑曲线，p0 和 p3 作为控制点
  Offset _catmullRomInterpolate(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final double t2 = t * t;
    final double t3 = t2 * t;

    // Catmull-Rom 公式
    final double x = 0.5 *
        ((2 * p1.dx) +
            (-p0.dx + p2.dx) * t +
            (2 * p0.dx - 5 * p1.dx + 4 * p2.dx - p3.dx) * t2 +
            (-p0.dx + 3 * p1.dx - 3 * p2.dx + p3.dx) * t3);

    final double y = 0.5 *
        ((2 * p1.dy) +
            (-p0.dy + p2.dy) * t +
            (2 * p0.dy - 5 * p1.dy + 4 * p2.dy - p3.dy) * t2 +
            (-p0.dy + 3 * p1.dy - 3 * p2.dy + p3.dy) * t3);

    return Offset(x, y);
  }

  @override
  SmoothLine copy() => SmoothLine.data(
        brushPrecision: brushPrecision,
        minPointDistance: minPointDistance,
        useBezierCurve: useBezierCurve,
        smoothLevel: smoothLevel,
        points: points.toList(),
        strokeWidthList: strokeWidthList.toList(),
        paint: paint.copyWith(),
      );

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'brushPrecision': brushPrecision,
      'minPointDistance': minPointDistance,
      'useBezierCurve': useBezierCurve,
      'smoothLevel': smoothLevel,
      'points': points.map((Offset e) => e.toJson()).toList(),
      'strokeWidthList': strokeWidthList,
      'paint': paint.toJson(),
    };
  }
}
