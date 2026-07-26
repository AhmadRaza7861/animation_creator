import 'dart:math';
import 'dart:ui';

import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';
import 'freehand_line.dart';

/// 笔尖形状 / Brush tip shapes (Photoshop-style)
enum BrushTip { round, square, diamond, triangle, star, calligraphy }

/// 形状笔刷基类（类似 Photoshop 的笔尖）
///
/// 与普通画笔（`SimpleLine`）手感完全一致，但绘制时会沿笔迹路径按间距不断
/// “盖章”出笔尖形状（方形、菱形、三角、星形、书法斜口等），从而形成不同风格
/// 的笔触。间距（`spacingRatio`）以画笔粗细为基准等比缩放，行为与 Photoshop
/// 笔刷的 “间距 %” 一致，因此调整粗细滑块时笔触始终协调。
///
/// Shape Brush Base Class (Photoshop-style brush tips)
///
/// Behaves exactly like the normal pen (`SimpleLine`), but stamps a tip shape
/// (square, diamond, triangle, star, calligraphy nib, ...) along the stroke path
/// at a fixed spacing, producing different brush styles. The spacing
/// (`spacingRatio`) scales with the stroke width, matching Photoshop's brush
/// "Spacing %", so the stroke stays consistent as the width slider changes.
abstract class ShapeBrushLine extends FreehandLine {
  ShapeBrushLine({super.minPointDistance, this.spacingRatio = 0.2});

  ShapeBrushLine.data({
    super.minPointDistance,
    this.spacingRatio = 0.2,
    required super.points,
    required super.paint,
  }) : super.data();

  /// 相邻笔尖之间的距离相对画笔粗细的倍数（越小笔触越连续）
  ///
  /// Distance between stamps as a multiple of the stroke width
  /// (smaller = more continuous stroke)
  final double spacingRatio;

  /// 当前笔尖形状（纹理类笔刷可忽略，直接重写 [paintStamp]）
  ///
  /// Current tip shape (textured brushes may ignore this and override [paintStamp])
  BrushTip get tip => BrushTip.round;

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (points.isEmpty) {
      return;
    }

    final double width = paint.strokeWidth;
    final double radius = width / 2;
    // 每个笔尖使用的画笔（子类可重写以实现柔边、半透明等效果）
    final Paint stampPaint = stampPaintOf(paint);

    // 单点：直接盖一个笔尖
    if (points.length == 1) {
      paintStamp(canvas, points.first, 0, radius, stampPaint, 0);
      return;
    }

    // 间距随画笔粗细缩放，并保证为正防止死循环
    final double step = (width * spacingRatio).clamp(0.5, double.infinity);
    final Path path = buildSmoothPath();

    int index = 0;
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance <= metric.length) {
        final Tangent? tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          paintStamp(canvas, tangent.position, tangent.angle, radius, stampPaint, index);
        }
        index++;
        distance += step;
      }
    }
  }

  /// 每个笔尖使用的画笔，默认填充；柔边/喷枪等子类可重写添加模糊或透明度
  ///
  /// Paint used for each stamp; defaults to fill. Soft/airbrush subclasses
  /// override this to add a blur mask filter or reduce opacity.
  Paint stampPaintOf(Paint source) => source.copyWith(style: PaintingStyle.fill);

  /// 在路径上某一点绘制一个笔尖，默认盖出 [tip] 形状。
  /// 纹理类笔刷（喷枪、粉笔、散布等）可重写此方法绘制多个抖动的小图形。
  ///
  /// Paint a single stamp at a point on the path. By default stamps the [tip]
  /// shape. Textured brushes (airbrush, chalk, scatter) override this to paint
  /// multiple jittered marks.
  void paintStamp(
    Canvas canvas,
    Offset center,
    double angle,
    double radius,
    Paint paint,
    int index,
  ) {
    _stamp(canvas, center, angle, radius, paint);
  }

  /// 基于笔迹与索引生成稳定的伪随机抖动值，范围 [-1, 1]
  ///
  /// Deterministic pseudo-random jitter in [-1, 1], stable across repaints so
  /// the texture does not flicker between frames or differ from the cache.
  double jitter(int index, int channel) {
    final int s = (_seed + index * 374761393 + channel * 668265263) & 0x7fffffff;
    return Random(s).nextDouble() * 2 - 1;
  }

  int get _seed {
    if (points.isEmpty) {
      return 1;
    }
    return ((points.first.dx.toInt() * 73856093) ^ (points.first.dy.toInt() * 19349663)) &
        0x7fffffff;
  }

  /// 在指定位置盖一个几何笔尖
  ///
  /// Stamp a single geometric tip at the given position, rotated to follow the stroke
  void _stamp(Canvas canvas, Offset center, double angle, double radius, Paint paint) {
    switch (tip) {
      case BrushTip.round:
        canvas.drawCircle(center, radius, paint);
      case BrushTip.square:
        _rotated(canvas, center, angle, () {
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: radius * 2, height: radius * 2),
            paint,
          );
        });
      case BrushTip.diamond:
        _rotated(canvas, center, angle + pi / 4, () {
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: radius * 2, height: radius * 2),
            paint,
          );
        });
      case BrushTip.triangle:
        _rotated(canvas, center, angle, () => canvas.drawPath(_polygon(3, radius), paint));
      case BrushTip.star:
        _rotated(canvas, center, angle, () {
          canvas.drawPath(_star(5, radius, radius * 0.45), paint);
        });
      case BrushTip.calligraphy:
        // 书法斜口笔：固定 -45° 斜口，粗细随运笔方向自然变化
        _rotated(canvas, center, -pi / 4, () {
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: radius * 2, height: radius * 0.6),
            paint,
          );
        });
    }
  }

  /// 以 [center] 为中心、旋转 [angle] 弧度后执行绘制
  ///
  /// Run [draw] translated to [center] and rotated by [angle] radians
  void _rotated(Canvas canvas, Offset center, double angle, void Function() draw) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    draw();
    canvas.restore();
  }

  /// 生成以原点为中心、顶点朝上的正多边形
  ///
  /// Build a regular polygon centered at the origin, first vertex pointing up
  Path _polygon(int sides, double radius) {
    final Path path = Path();
    for (int i = 0; i < sides; i++) {
      final double a = -pi / 2 + i * 2 * pi / sides;
      final Offset p = Offset(radius * cos(a), radius * sin(a));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    return path;
  }

  /// 生成以原点为中心的星形
  ///
  /// Build a star centered at the origin
  Path _star(int count, double outer, double inner) {
    final Path path = Path();
    final int total = count * 2;
    for (int i = 0; i < total; i++) {
      final double r = i.isEven ? outer : inner;
      final double a = -pi / 2 + i * pi / count;
      final Offset p = Offset(r * cos(a), r * sin(a));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    return path;
  }

  @override
  Map<String, dynamic> toContentJson() => <String, dynamic>{
        ...baseJson(),
        'spacingRatio': spacingRatio,
      };
}

/// 方形笔刷 / Square tip brush
class SquareBrush extends ShapeBrushLine {
  SquareBrush({super.minPointDistance, super.spacingRatio = 0.25});

  SquareBrush.data({
    super.minPointDistance,
    super.spacingRatio = 0.25,
    required super.points,
    required super.paint,
  }) : super.data();

  factory SquareBrush.fromJson(Map<String, dynamic> data) => SquareBrush.data(
        minPointDistance: (data['minPointDistance'] ?? 2.0) as double,
        spacingRatio: (data['spacingRatio'] ?? 0.25) as double,
        points: (data['points'] as List<dynamic>)
            .map((dynamic e) => jsonToOffset(e as Map<String, dynamic>))
            .toList(),
        paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
      );

  @override
  BrushTip get tip => BrushTip.square;

  @override
  String get contentType => 'SquareBrush';

  @override
  SquareBrush copy() => SquareBrush(minPointDistance: minPointDistance, spacingRatio: spacingRatio);
}

/// 菱形笔刷 / Diamond tip brush
class DiamondBrush extends ShapeBrushLine {
  DiamondBrush({super.minPointDistance, super.spacingRatio = 0.25});

  DiamondBrush.data({
    super.minPointDistance,
    super.spacingRatio = 0.25,
    required super.points,
    required super.paint,
  }) : super.data();

  factory DiamondBrush.fromJson(Map<String, dynamic> data) => DiamondBrush.data(
        minPointDistance: (data['minPointDistance'] ?? 2.0) as double,
        spacingRatio: (data['spacingRatio'] ?? 0.25) as double,
        points: (data['points'] as List<dynamic>)
            .map((dynamic e) => jsonToOffset(e as Map<String, dynamic>))
            .toList(),
        paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
      );

  @override
  BrushTip get tip => BrushTip.diamond;

  @override
  String get contentType => 'DiamondBrush';

  @override
  DiamondBrush copy() =>
      DiamondBrush(minPointDistance: minPointDistance, spacingRatio: spacingRatio);
}

/// 三角形笔刷 / Triangle tip brush
class TriangleBrush extends ShapeBrushLine {
  TriangleBrush({super.minPointDistance, super.spacingRatio = 0.3});

  TriangleBrush.data({
    super.minPointDistance,
    super.spacingRatio = 0.3,
    required super.points,
    required super.paint,
  }) : super.data();

  factory TriangleBrush.fromJson(Map<String, dynamic> data) => TriangleBrush.data(
        minPointDistance: (data['minPointDistance'] ?? 2.0) as double,
        spacingRatio: (data['spacingRatio'] ?? 0.3) as double,
        points: (data['points'] as List<dynamic>)
            .map((dynamic e) => jsonToOffset(e as Map<String, dynamic>))
            .toList(),
        paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
      );

  @override
  BrushTip get tip => BrushTip.triangle;

  @override
  String get contentType => 'TriangleBrush';

  @override
  TriangleBrush copy() =>
      TriangleBrush(minPointDistance: minPointDistance, spacingRatio: spacingRatio);
}

/// 星形笔刷 / Star tip brush
class StarBrush extends ShapeBrushLine {
  StarBrush({super.minPointDistance, super.spacingRatio = 0.7});

  StarBrush.data({
    super.minPointDistance,
    super.spacingRatio = 0.7,
    required super.points,
    required super.paint,
  }) : super.data();

  factory StarBrush.fromJson(Map<String, dynamic> data) => StarBrush.data(
        minPointDistance: (data['minPointDistance'] ?? 2.0) as double,
        spacingRatio: (data['spacingRatio'] ?? 0.7) as double,
        points: (data['points'] as List<dynamic>)
            .map((dynamic e) => jsonToOffset(e as Map<String, dynamic>))
            .toList(),
        paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
      );

  @override
  BrushTip get tip => BrushTip.star;

  @override
  String get contentType => 'StarBrush';

  @override
  StarBrush copy() => StarBrush(minPointDistance: minPointDistance, spacingRatio: spacingRatio);
}

/// 书法（斜口）笔刷 / Calligraphy (chisel) tip brush
class CalligraphyBrush extends ShapeBrushLine {
  CalligraphyBrush({super.minPointDistance, super.spacingRatio = 0.12});

  CalligraphyBrush.data({
    super.minPointDistance,
    super.spacingRatio = 0.12,
    required super.points,
    required super.paint,
  }) : super.data();

  factory CalligraphyBrush.fromJson(Map<String, dynamic> data) => CalligraphyBrush.data(
        minPointDistance: (data['minPointDistance'] ?? 2.0) as double,
        spacingRatio: (data['spacingRatio'] ?? 0.12) as double,
        points: (data['points'] as List<dynamic>)
            .map((dynamic e) => jsonToOffset(e as Map<String, dynamic>))
            .toList(),
        paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
      );

  @override
  BrushTip get tip => BrushTip.calligraphy;

  @override
  String get contentType => 'CalligraphyBrush';

  @override
  CalligraphyBrush copy() =>
      CalligraphyBrush(minPointDistance: minPointDistance, spacingRatio: spacingRatio);
}

/// 柔边圆形笔刷（类似 PS 的 Soft Round）
///
/// 使用高斯模糊柔化笔尖边缘，形成从中心向外渐隐的柔和笔触。
///
/// Soft round brush (like Photoshop's Soft Round preset). Uses a gaussian blur
/// mask to feather the tip edge, producing a soft stroke that fades outward.
class SoftRoundBrush extends ShapeBrushLine {
  SoftRoundBrush({super.minPointDistance, super.spacingRatio = 0.1, this.softness = 0.5});

  SoftRoundBrush.data({
    super.minPointDistance,
    super.spacingRatio = 0.1,
    this.softness = 0.5,
    required super.points,
    required super.paint,
  }) : super.data();

  factory SoftRoundBrush.fromJson(Map<String, dynamic> data) => SoftRoundBrush.data(
        minPointDistance: (data['minPointDistance'] ?? 2.0) as double,
        spacingRatio: (data['spacingRatio'] ?? 0.1) as double,
        softness: (data['softness'] ?? 0.5) as double,
        points: (data['points'] as List<dynamic>)
            .map((dynamic e) => jsonToOffset(e as Map<String, dynamic>))
            .toList(),
        paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
      );

  /// 边缘柔化程度（相对半径的模糊比例）/ Edge softness (blur sigma as a fraction of radius)
  final double softness;

  @override
  String get contentType => 'SoftRoundBrush';

  @override
  Paint stampPaintOf(Paint source) {
    final double sigma = (source.strokeWidth / 2) * softness;
    return source.copyWith(
      style: PaintingStyle.fill,
      maskFilter: sigma > 0 ? MaskFilter.blur(BlurStyle.normal, sigma) : null,
    );
  }

  @override
  void paintStamp(
    Canvas canvas,
    Offset center,
    double angle,
    double radius,
    Paint paint,
    int index,
  ) {
    canvas.drawCircle(center, radius, paint);
  }

  @override
  SoftRoundBrush copy() => SoftRoundBrush(
        minPointDistance: minPointDistance,
        spacingRatio: spacingRatio,
        softness: softness,
      );

  @override
  Map<String, dynamic> toContentJson() => <String, dynamic>{
        ...super.toContentJson(),
        'softness': softness,
      };
}

/// 硬边圆形笔刷（类似 PS 的 Hard Round）/ Hard round brush (like PS's Hard Round)
class HardRoundBrush extends ShapeBrushLine {
  HardRoundBrush({super.minPointDistance, super.spacingRatio = 0.1});

  HardRoundBrush.data({
    super.minPointDistance,
    super.spacingRatio = 0.1,
    required super.points,
    required super.paint,
  }) : super.data();

  factory HardRoundBrush.fromJson(Map<String, dynamic> data) => HardRoundBrush.data(
        minPointDistance: (data['minPointDistance'] ?? 2.0) as double,
        spacingRatio: (data['spacingRatio'] ?? 0.1) as double,
        points: (data['points'] as List<dynamic>)
            .map((dynamic e) => jsonToOffset(e as Map<String, dynamic>))
            .toList(),
        paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
      );

  @override
  BrushTip get tip => BrushTip.round;

  @override
  String get contentType => 'HardRoundBrush';

  @override
  HardRoundBrush copy() =>
      HardRoundBrush(minPointDistance: minPointDistance, spacingRatio: spacingRatio);
}

/// 喷枪 / 喷溅笔刷（类似 PS 的 Airbrush / Spatter）
///
/// 每一步在笔尖范围内喷出若干半透明、带模糊的小圆点，叠加形成柔和的喷雾效果。
///
/// Airbrush / spatter brush (like Photoshop's Airbrush). At each step it sprays
/// several semi-transparent, blurred dots within the tip radius; overlapping
/// stamps build up a soft spray.
class AirbrushBrush extends ShapeBrushLine {
  AirbrushBrush({super.minPointDistance, super.spacingRatio = 0.25, this.density = 8});

  AirbrushBrush.data({
    super.minPointDistance,
    super.spacingRatio = 0.25,
    this.density = 8,
    required super.points,
    required super.paint,
  }) : super.data();

  factory AirbrushBrush.fromJson(Map<String, dynamic> data) => AirbrushBrush.data(
        minPointDistance: (data['minPointDistance'] ?? 2.0) as double,
        spacingRatio: (data['spacingRatio'] ?? 0.25) as double,
        density: (data['density'] ?? 8) as int,
        points: (data['points'] as List<dynamic>)
            .map((dynamic e) => jsonToOffset(e as Map<String, dynamic>))
            .toList(),
        paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
      );

  /// 每一步喷出的小点数量 / Number of dots sprayed per step
  final int density;

  @override
  String get contentType => 'AirbrushBrush';

  @override
  Paint stampPaintOf(Paint source) {
    final double sigma = (source.strokeWidth / 2) * 0.12;
    return source.copyWith(
      style: PaintingStyle.fill,
      color: source.color.withValues(alpha: source.color.a * 0.5),
      maskFilter: sigma > 0 ? MaskFilter.blur(BlurStyle.normal, sigma) : null,
    );
  }

  @override
  void paintStamp(
    Canvas canvas,
    Offset center,
    double angle,
    double radius,
    Paint paint,
    int index,
  ) {
    for (int i = 0; i < density; i++) {
      final double dx = jitter(index, i * 2) * radius;
      final double dy = jitter(index, i * 2 + 1) * radius;
      // 越靠近中心的点越多、越大
      final double dotRadius = radius * 0.3 * (0.4 + (jitter(index, 500 + i) + 1) / 2 * 0.6);
      canvas.drawCircle(center + Offset(dx, dy), dotRadius, paint);
    }
  }

  @override
  AirbrushBrush copy() => AirbrushBrush(
        minPointDistance: minPointDistance,
        spacingRatio: spacingRatio,
        density: density,
      );

  @override
  Map<String, dynamic> toContentJson() => <String, dynamic>{
        ...super.toContentJson(),
        'density': density,
      };
}

/// 粉笔 / 蜡笔纹理笔刷（类似 PS 的 Chalk）
///
/// 每一步在笔尖圆形范围内随机撒下若干硬边小方块，形成颗粒感的粗糙纹理笔触。
///
/// Chalk / crayon textured brush (like Photoshop's Chalk). At each step it
/// scatters several small hard-edged squares within the tip circle, producing a
/// grainy, rough-textured stroke.
class ChalkBrush extends ShapeBrushLine {
  ChalkBrush({super.minPointDistance, super.spacingRatio = 0.35, this.density = 14});

  ChalkBrush.data({
    super.minPointDistance,
    super.spacingRatio = 0.35,
    this.density = 14,
    required super.points,
    required super.paint,
  }) : super.data();

  factory ChalkBrush.fromJson(Map<String, dynamic> data) => ChalkBrush.data(
        minPointDistance: (data['minPointDistance'] ?? 2.0) as double,
        spacingRatio: (data['spacingRatio'] ?? 0.35) as double,
        density: (data['density'] ?? 14) as int,
        points: (data['points'] as List<dynamic>)
            .map((dynamic e) => jsonToOffset(e as Map<String, dynamic>))
            .toList(),
        paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
      );

  /// 每一步撒下的颗粒数量 / Number of specks scattered per step
  final int density;

  @override
  String get contentType => 'ChalkBrush';

  @override
  void paintStamp(
    Canvas canvas,
    Offset center,
    double angle,
    double radius,
    Paint paint,
    int index,
  ) {
    final double speck = (radius * 0.22).clamp(0.5, double.infinity);
    for (int i = 0; i < density; i++) {
      final double dx = jitter(index, i * 2) * radius;
      final double dy = jitter(index, i * 2 + 1) * radius;
      // 只保留落在笔尖圆内的颗粒，边缘自然呈粉笔的破碎感
      if (dx * dx + dy * dy <= radius * radius) {
        canvas.drawRect(
          Rect.fromCenter(center: center + Offset(dx, dy), width: speck, height: speck),
          paint,
        );
      }
    }
  }

  @override
  ChalkBrush copy() =>
      ChalkBrush(minPointDistance: minPointDistance, spacingRatio: spacingRatio, density: density);

  @override
  Map<String, dynamic> toContentJson() => <String, dynamic>{
        ...super.toContentJson(),
        'density': density,
      };
}

/// 散布笔刷（类似 PS 的 Scattering）
///
/// 沿笔迹在两侧散布若干小圆点，圆点大小与偏移都带随机抖动，形成分散的点状笔触。
///
/// Scatter brush (like Photoshop's Scattering). Scatters small dots to both
/// sides of the stroke with jittered position and size, producing a spread-out
/// dotted stroke.
class ScatterBrush extends ShapeBrushLine {
  ScatterBrush({
    super.minPointDistance,
    super.spacingRatio = 0.5,
    this.density = 3,
    this.scatter = 1.6,
  });

  ScatterBrush.data({
    super.minPointDistance,
    super.spacingRatio = 0.5,
    this.density = 3,
    this.scatter = 1.6,
    required super.points,
    required super.paint,
  }) : super.data();

  factory ScatterBrush.fromJson(Map<String, dynamic> data) => ScatterBrush.data(
        minPointDistance: (data['minPointDistance'] ?? 2.0) as double,
        spacingRatio: (data['spacingRatio'] ?? 0.5) as double,
        density: (data['density'] ?? 3) as int,
        scatter: (data['scatter'] ?? 1.6) as double,
        points: (data['points'] as List<dynamic>)
            .map((dynamic e) => jsonToOffset(e as Map<String, dynamic>))
            .toList(),
        paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
      );

  /// 每一步散布的圆点数量 / Number of dots scattered per step
  final int density;

  /// 散布范围相对半径的倍数 / Scatter spread as a multiple of the radius
  final double scatter;

  @override
  String get contentType => 'ScatterBrush';

  @override
  void paintStamp(
    Canvas canvas,
    Offset center,
    double angle,
    double radius,
    Paint paint,
    int index,
  ) {
    // 沿路径法线方向散布
    final double nx = -sin(angle);
    final double ny = cos(angle);
    for (int i = 0; i < density; i++) {
      final double offset = jitter(index, i) * radius * scatter;
      final double along = jitter(index, 200 + i) * radius * 0.5;
      final Offset pos = center +
          Offset(nx * offset + cos(angle) * along, ny * offset + sin(angle) * along);
      final double dotRadius = radius * 0.35 * (0.5 + (jitter(index, 400 + i) + 1) / 2 * 0.5);
      canvas.drawCircle(pos, dotRadius, paint);
    }
  }

  @override
  ScatterBrush copy() => ScatterBrush(
        minPointDistance: minPointDistance,
        spacingRatio: spacingRatio,
        density: density,
        scatter: scatter,
      );

  @override
  Map<String, dynamic> toContentJson() => <String, dynamic>{
        ...super.toContentJson(),
        'density': density,
        'scatter': scatter,
      };
}
