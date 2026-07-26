import 'dart:math';
import 'dart:ui';

import 'package:flutter/painting.dart' as painting;

import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';
import 'freehand_line.dart';

/// 笔尖形状类型 / Brush tip shape kinds
enum BrushTipKind {
  round,
  square,
  diamond,
  triangle,
  pentagon,
  hexagon,
  heptagon,
  octagon,
  star,
  fourStar,
  sixStar,
  cross,
  ring,
  heart,
  flower,
  leaf,
  crescent,
  grass,
  confetti,
  teardrop,
  arrow,
  lightning,
  snowflake,
  spiral,
  gear,
  burst,
  spatter,
  chalk,
  scatter,
  bristle,
  dryBrush,
  stipple,
  charcoal,
  sponge,
  splash,
  grassClump,
  leafScatter,
  eightStar,
  pinwheel,
  fivePetal,
  clover,
  shell,
  checkmark,
  sun,
  ripple,
  squareRing,
  spade,
  musicNote,
  doubleArrow,
  club,
  shield,
  flowerEight,
  diamondRing,
  wave,
  infinity,
  flame,
  feather,
  crosshair,
  paw,
  crown,
  bowtie,
  butterfly,
  mapleLeaf,
  gem,
  atom,
  puzzle,
  anchor,
  fish,
  mushroom,
  cloud,
  pineTree,
  rocket,
  lightbulb,
  bell,
  key,
  hourglass,
  ghost,
  // 空心轮廓类 / Outline (hollow) family
  outlineCircle,
  outlineSquare,
  outlineTriangle,
  outlineHexagon,
  outlineStar,
  outlineHeart,
  // 字符类 / Glyph family
  glyphStar,
  glyphFlower,
  glyphSnow,
  glyphHeart,
  glyphNote,
  glyphClover,
}

/// 可配置笔尖笔刷（对应 Photoshop 的 “Brush Tip Shape”）
///
/// 一个笔刷即可通过参数呈现所有笔尖效果，参数与 PS 一一对应：
/// - [size]（主直径，取自画笔粗细）
/// - [angle] 角度、[roundness] 圆度、[hardness] 硬度、[spacing] 间距
/// - [flipX]/[flipY] 水平/垂直翻转
/// 与普通画笔手感一致：按最小间距采点、贝塞尔平滑，然后沿路径盖章笔尖。
///
/// Configurable tip brush (mirrors Photoshop's "Brush Tip Shape").
///
/// A single brush reproduces every tip effect through parameters that map 1:1
/// to Photoshop: [angle], [roundness], [hardness], [spacing], and [flipX] /
/// [flipY], with the size taken from the stroke width. It feels like the normal
/// pen: samples points, smooths them, then stamps the tip along the path.
class TipBrush extends FreehandLine {
  TipBrush({
    super.minPointDistance,
    this.kind = BrushTipKind.round,
    this.angle = 0.0,
    this.roundness = 1.0,
    this.hardness = 1.0,
    this.spacing = 0.25,
    this.flipX = false,
    this.flipY = false,
    this.followPath = false,
  });

  TipBrush.data({
    super.minPointDistance,
    this.kind = BrushTipKind.round,
    this.angle = 0.0,
    this.roundness = 1.0,
    this.hardness = 1.0,
    this.spacing = 0.25,
    this.flipX = false,
    this.flipY = false,
    this.followPath = false,
    required super.points,
    required super.paint,
  }) : super.data();

  factory TipBrush.fromJson(Map<String, dynamic> data) => TipBrush.data(
        minPointDistance: (data['minPointDistance'] ?? 2.0) as double,
        kind: BrushTipKind.values[(data['kind'] ?? 0) as int],
        angle: (data['angle'] ?? 0.0) as double,
        roundness: (data['roundness'] ?? 1.0) as double,
        hardness: (data['hardness'] ?? 1.0) as double,
        spacing: (data['spacing'] ?? 0.25) as double,
        flipX: (data['flipX'] ?? false) as bool,
        flipY: (data['flipY'] ?? false) as bool,
        followPath: (data['followPath'] ?? false) as bool,
        points: (data['points'] as List<dynamic>)
            .map((dynamic e) => jsonToOffset(e as Map<String, dynamic>))
            .toList(),
        paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
      );

  /// 笔尖形状 / Tip shape
  final BrushTipKind kind;

  /// 角度（度）/ Angle in degrees
  final double angle;

  /// 圆度 0-1（1 为正圆，越小越扁）/ Roundness 0-1 (1 = round, smaller = flatter)
  final double roundness;

  /// 硬度 0-1（1 为硬边，越小边缘越柔）/ Hardness 0-1 (1 = hard edge, smaller = softer)
  final double hardness;

  /// 间距（相对直径的倍数）/ Spacing as a multiple of the diameter
  final double spacing;

  /// 水平翻转 / Flip horizontally
  final bool flipX;

  /// 垂直翻转 / Flip vertically
  final bool flipY;

  /// 笔尖是否随笔迹方向旋转 / Whether the tip rotates to follow the stroke
  final bool followPath;

  @override
  String get contentType => 'TipBrush';

  int get _seed {
    if (points.isEmpty) {
      return 1;
    }
    return ((points.first.dx.toInt() * 73856093) ^ (points.first.dy.toInt() * 19349663)) &
        0x7fffffff;
  }

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (points.isEmpty) {
      return;
    }

    final double width = paint.strokeWidth;
    final double radius = width / 2;
    final Paint tipPaint = _tipPaint(paint, radius);
    final double angleRad = angle * pi / 180;

    if (points.length == 1) {
      paintDab(
        canvas,
        points.first,
        radius,
        kind: kind,
        paint: tipPaint,
        angle: angleRad,
        roundness: roundness,
        flipX: flipX,
        flipY: flipY,
        seed: _seed,
        index: 0,
      );
      return;
    }

    final double frac = spacing > 0 ? spacing : 0.05;
    final double step = (width * frac).clamp(0.5, double.infinity);
    final Path path = buildSmoothPath();

    int index = 0;
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance <= metric.length) {
        final Tangent? tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          paintDab(
            canvas,
            tangent.position,
            radius,
            kind: kind,
            paint: tipPaint,
            angle: (followPath ? tangent.angle : 0) + angleRad,
            roundness: roundness,
            flipX: flipX,
            flipY: flipY,
            seed: _seed,
            index: index,
          );
        }
        index++;
        distance += step;
      }
    }
  }

  /// 根据硬度生成笔尖画笔（硬度越低模糊越强）
  ///
  /// Build the tip paint from hardness (lower hardness = stronger blur)
  Paint _tipPaint(Paint source, double radius) {
    final double sigma = radius * (1 - hardness) * 0.9;
    return source.copyWith(
      style: PaintingStyle.fill,
      maskFilter: sigma > 0 ? MaskFilter.blur(BlurStyle.normal, sigma) : null,
    );
  }

  @override
  TipBrush copy() => TipBrush(
        minPointDistance: minPointDistance,
        kind: kind,
        angle: angle,
        roundness: roundness,
        hardness: hardness,
        spacing: spacing,
        flipX: flipX,
        flipY: flipY,
        followPath: followPath,
      );

  @override
  Map<String, dynamic> toContentJson() => <String, dynamic>{
        ...baseJson(),
        'kind': kind.index,
        'angle': angle,
        'roundness': roundness,
        'hardness': hardness,
        'spacing': spacing,
        'flipX': flipX,
        'flipY': flipY,
        'followPath': followPath,
      };

  // ---------------------------------------------------------------------------
  // 静态绘制工具：单个笔尖“盖章”，供笔刷绘制与缩略图预览共用
  // Static drawing helpers: a single tip "dab", shared by the brush and the
  // thumbnail previews so the grid always matches the real stroke.
  // ---------------------------------------------------------------------------

  /// 在 [center] 处盖一个笔尖，应用角度、圆度、翻转变换
  ///
  /// Stamp one tip at [center], applying angle / roundness / flip transforms
  static void paintDab(
    Canvas canvas,
    Offset center,
    double radius, {
    required BrushTipKind kind,
    required Paint paint,
    double angle = 0,
    double roundness = 1,
    bool flipX = false,
    bool flipY = false,
    int seed = 0,
    int index = 0,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.scale(
      flipX ? -1 : 1,
      (flipY ? -1 : 1) * (roundness <= 0 ? 0.02 : roundness),
    );
    _drawShape(canvas, kind, radius, paint, seed, index);
    canvas.restore();
  }

  static void _drawShape(
    Canvas canvas,
    BrushTipKind kind,
    double radius,
    Paint paint,
    int seed,
    int index,
  ) {
    switch (kind) {
      case BrushTipKind.round:
        canvas.drawCircle(Offset.zero, radius, paint);
      case BrushTipKind.square:
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: radius * 2, height: radius * 2),
          paint,
        );
      case BrushTipKind.diamond:
        canvas.drawPath(_polygon(4, radius), paint);
      case BrushTipKind.triangle:
        canvas.drawPath(_polygon(3, radius), paint);
      case BrushTipKind.pentagon:
        canvas.drawPath(_polygon(5, radius), paint);
      case BrushTipKind.hexagon:
        canvas.drawPath(_polygon(6, radius), paint);
      case BrushTipKind.heptagon:
        canvas.drawPath(_polygon(7, radius), paint);
      case BrushTipKind.octagon:
        canvas.drawPath(_polygon(8, radius), paint);
      case BrushTipKind.star:
        canvas.drawPath(_star(5, radius, radius * 0.45), paint);
      case BrushTipKind.fourStar:
        canvas.drawPath(_star(4, radius, radius * 0.32), paint);
      case BrushTipKind.sixStar:
        canvas.drawPath(_star(6, radius, radius * 0.5), paint);
      case BrushTipKind.cross:
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: radius * 2, height: radius * 0.6),
          paint,
        );
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: radius * 0.6, height: radius * 2),
          paint,
        );
      case BrushTipKind.ring:
        canvas.drawPath(
          Path()
            ..fillType = PathFillType.evenOdd
            ..addOval(Rect.fromCircle(center: Offset.zero, radius: radius))
            ..addOval(Rect.fromCircle(center: Offset.zero, radius: radius * 0.6)),
          paint,
        );
      case BrushTipKind.heart:
        canvas.drawPath(_heart(radius), paint);
      case BrushTipKind.flower:
        for (int i = 0; i < 6; i++) {
          final double a = i * pi / 3;
          canvas.drawCircle(Offset(cos(a) * radius * 0.5, sin(a) * radius * 0.5), radius * 0.42, paint);
        }
        canvas.drawCircle(Offset.zero, radius * 0.38, paint);
      case BrushTipKind.leaf:
        canvas.drawPath(_leaf(radius), paint);
      case BrushTipKind.crescent:
        canvas.drawPath(
          Path()
            ..fillType = PathFillType.evenOdd
            ..addOval(Rect.fromCircle(center: Offset.zero, radius: radius))
            ..addOval(Rect.fromCircle(center: Offset(radius * 0.45, -radius * 0.1), radius: radius * 0.85)),
          paint,
        );
      case BrushTipKind.grass:
        for (int i = 0; i < 5; i++) {
          final double spread = (i - 2) / 2; // -1..1
          final double w = radius * 0.12;
          canvas.drawPath(
            Path()
              ..moveTo(-w, radius)
              ..lineTo(w, radius)
              ..lineTo(spread * radius * 0.7, -radius)
              ..close(),
            paint,
          );
        }
      case BrushTipKind.confetti:
        for (int i = 0; i < 10; i++) {
          final double dx = _jitter(seed, index, i * 2) * radius;
          final double dy = _jitter(seed, index, i * 2 + 1) * radius;
          final double s = radius * 0.3;
          canvas.save();
          canvas.translate(dx, dy);
          canvas.rotate(_jitter(seed, index, 300 + i) * pi);
          if (i.isEven) {
            canvas.drawRect(
              Rect.fromCenter(center: Offset.zero, width: s, height: s * 0.6),
              paint,
            );
          } else {
            canvas.drawPath(_polygon(3, s * 0.6), paint);
          }
          canvas.restore();
        }
      case BrushTipKind.teardrop:
        canvas.drawPath(
          Path()
            ..addOval(Rect.fromCircle(center: Offset(0, radius * 0.35), radius: radius * 0.65))
            ..moveTo(-radius * 0.4, radius * 0.05)
            ..lineTo(0, -radius)
            ..lineTo(radius * 0.4, radius * 0.05)
            ..close(),
          paint,
        );
      case BrushTipKind.arrow:
        canvas.drawPath(
          Path()
            ..moveTo(0, -radius)
            ..lineTo(radius * 0.7, -radius * 0.1)
            ..lineTo(radius * 0.25, -radius * 0.1)
            ..lineTo(radius * 0.25, radius)
            ..lineTo(-radius * 0.25, radius)
            ..lineTo(-radius * 0.25, -radius * 0.1)
            ..lineTo(-radius * 0.7, -radius * 0.1)
            ..close(),
          paint,
        );
      case BrushTipKind.lightning:
        canvas.drawPath(
          Path()
            ..moveTo(radius * 0.1, -radius)
            ..lineTo(-radius * 0.5, radius * 0.15)
            ..lineTo(-radius * 0.05, radius * 0.15)
            ..lineTo(-radius * 0.3, radius)
            ..lineTo(radius * 0.5, -radius * 0.2)
            ..lineTo(radius * 0.05, -radius * 0.2)
            ..close(),
          paint,
        );
      case BrushTipKind.snowflake:
        final Paint stroke = _strokePaint(paint, radius * 0.12);
        for (int i = 0; i < 6; i++) {
          canvas.save();
          canvas.rotate(i * pi / 3);
          canvas.drawLine(Offset.zero, Offset(0, -radius), stroke);
          canvas.drawLine(Offset(0, -radius * 0.6), Offset(radius * 0.25, -radius * 0.82), stroke);
          canvas.drawLine(Offset(0, -radius * 0.6), Offset(-radius * 0.25, -radius * 0.82), stroke);
          canvas.restore();
        }
      case BrushTipKind.spiral:
        final Paint stroke = _strokePaint(paint, radius * 0.14);
        final Path path = Path();
        const int n = 120;
        for (int i = 0; i <= n; i++) {
          final double t = i / n;
          final double ang = t * 4 * pi;
          final double rad = t * radius;
          final Offset p = Offset(cos(ang) * rad, sin(ang) * rad);
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path, stroke);
      case BrushTipKind.gear:
        const int teeth = 8;
        final Path path = Path()..fillType = PathFillType.evenOdd;
        for (int i = 0; i < teeth * 2; i++) {
          final double rad = i.isEven ? radius : radius * 0.72;
          final double a = -pi / 2 + i * pi / teeth;
          final Offset p = Offset(cos(a) * rad, sin(a) * rad);
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        path.close();
        path.addOval(Rect.fromCircle(center: Offset.zero, radius: radius * 0.35));
        canvas.drawPath(path, paint);
      case BrushTipKind.burst:
        const int spikes = 12;
        for (int i = 0; i < spikes; i++) {
          final double a = i * 2 * pi / spikes;
          canvas.drawPath(
            Path()
              ..moveTo(cos(a - 0.12) * radius * 0.2, sin(a - 0.12) * radius * 0.2)
              ..lineTo(cos(a) * radius, sin(a) * radius)
              ..lineTo(cos(a + 0.12) * radius * 0.2, sin(a + 0.12) * radius * 0.2)
              ..close(),
            paint,
          );
        }
        canvas.drawCircle(Offset.zero, radius * 0.25, paint);
      case BrushTipKind.bristle:
        // 干笔/鬃毛：多条平行细线
        final Paint stroke = _strokePaint(paint, radius * 0.07);
        for (int i = 0; i < 16; i++) {
          final double y = _jitter(seed, index, i) * radius;
          final double x0 = -radius * (0.6 + 0.4 * ((_jitter(seed, index, 40 + i) + 1) / 2));
          final double x1 = radius * (0.6 + 0.4 * ((_jitter(seed, index, 80 + i) + 1) / 2));
          canvas.drawLine(Offset(x0, y), Offset(x1, y), stroke);
        }
      case BrushTipKind.dryBrush:
        // 干枯笔触：断续的短划
        final Paint stroke = _strokePaint(paint, radius * 0.08);
        for (int i = 0; i < 22; i++) {
          final double y = _jitter(seed, index, i) * radius;
          final double cx = _jitter(seed, index, 60 + i) * radius * 0.7;
          final double half = radius * 0.12 * (0.5 + (_jitter(seed, index, 120 + i) + 1) / 2);
          if (cx * cx + y * y <= radius * radius) {
            canvas.drawLine(Offset(cx - half, y), Offset(cx + half, y), stroke);
          }
        }
      case BrushTipKind.stipple:
        // 点画：大量细小圆点
        for (int i = 0; i < 46; i++) {
          final double dx = _jitter(seed, index, i * 2) * radius;
          final double dy = _jitter(seed, index, i * 2 + 1) * radius;
          if (dx * dx + dy * dy <= radius * radius) {
            canvas.drawCircle(Offset(dx, dy), radius * 0.05, paint);
          }
        }
      case BrushTipKind.charcoal:
        // 炭笔：密集且大小不一的颗粒
        for (int i = 0; i < 44; i++) {
          final double dx = _jitter(seed, index, i * 2) * radius;
          final double dy = _jitter(seed, index, i * 2 + 1) * radius;
          if (dx * dx + dy * dy <= radius * radius) {
            final double s = radius * 0.14 * (0.4 + (_jitter(seed, index, 300 + i) + 1) / 2 * 0.6);
            canvas.drawRect(Rect.fromCenter(center: Offset(dx, dy), width: s, height: s), paint);
          }
        }
      case BrushTipKind.sponge:
        // 海绵：多孔的小环
        final Paint stroke = _strokePaint(paint, radius * 0.06);
        for (int i = 0; i < 16; i++) {
          final double dx = _jitter(seed, index, i * 2) * radius * 0.9;
          final double dy = _jitter(seed, index, i * 2 + 1) * radius * 0.9;
          final double r = radius * 0.22 * (0.4 + (_jitter(seed, index, 220 + i) + 1) / 2 * 0.6);
          canvas.drawCircle(Offset(dx, dy), r, stroke);
        }
      case BrushTipKind.splash:
        // 墨点飞溅：中心大块 + 四散小滴
        canvas.drawCircle(Offset.zero, radius * 0.45, paint);
        for (int i = 0; i < 14; i++) {
          final double dx = _jitter(seed, index, i * 2) * radius * 1.1;
          final double dy = _jitter(seed, index, i * 2 + 1) * radius * 1.1;
          final double r = radius * 0.16 * (0.3 + (_jitter(seed, index, 260 + i) + 1) / 2 * 0.7);
          canvas.drawCircle(Offset(dx, dy), r, paint);
        }
      case BrushTipKind.grassClump:
        // 草丛：底部发散的多根草叶
        for (int i = 0; i < 11; i++) {
          final double spread = _jitter(seed, index, i);
          final double w = radius * 0.09;
          final double tipY = -radius * (0.7 + (_jitter(seed, index, 140 + i) + 1) / 2 * 0.3);
          canvas.drawPath(
            Path()
              ..moveTo(-w, radius)
              ..lineTo(w, radius)
              ..lineTo(spread * radius * 0.8, tipY)
              ..close(),
            paint,
          );
        }
      case BrushTipKind.leafScatter:
        // 落叶：散布并随机旋转的叶片
        for (int i = 0; i < 6; i++) {
          final double dx = _jitter(seed, index, i * 2) * radius * 0.9;
          final double dy = _jitter(seed, index, i * 2 + 1) * radius * 0.9;
          canvas.save();
          canvas.translate(dx, dy);
          canvas.rotate(_jitter(seed, index, 160 + i) * pi);
          canvas.drawPath(_leaf(radius * 0.4), paint);
          canvas.restore();
        }
      case BrushTipKind.eightStar:
        canvas.drawPath(_star(8, radius, radius * 0.55), paint);
      case BrushTipKind.pinwheel:
        for (int k = 0; k < 4; k++) {
          canvas.save();
          canvas.rotate(k * pi / 2);
          canvas.drawPath(
            Path()
              ..moveTo(0, 0)
              ..lineTo(radius, 0)
              ..quadraticBezierTo(radius * 0.6, radius * 0.55, 0, 0)
              ..close(),
            paint,
          );
          canvas.restore();
        }
      case BrushTipKind.fivePetal:
        for (int i = 0; i < 5; i++) {
          final double a = -pi / 2 + i * 2 * pi / 5;
          canvas.drawCircle(Offset(cos(a) * radius * 0.55, sin(a) * radius * 0.55), radius * 0.4, paint);
        }
        canvas.drawCircle(Offset.zero, radius * 0.3, paint);
      case BrushTipKind.clover:
        for (int i = 0; i < 3; i++) {
          final double a = -pi / 2 + i * 2 * pi / 3;
          canvas.drawCircle(Offset(cos(a) * radius * 0.5, sin(a) * radius * 0.5), radius * 0.5, paint);
        }
      case BrushTipKind.shell:
        final Paint stroke = _strokePaint(paint, radius * 0.08);
        for (int i = 0; i < 5; i++) {
          canvas.drawArc(
            Rect.fromCircle(center: Offset(0, radius * 0.5), radius: radius * (0.3 + i * 0.16)),
            pi,
            pi,
            false,
            stroke,
          );
        }
      case BrushTipKind.checkmark:
        canvas.drawPath(
          Path()
            ..moveTo(-radius * 0.6, 0)
            ..lineTo(-radius * 0.15, radius * 0.55)
            ..lineTo(radius * 0.65, -radius * 0.5),
          _strokePaint(paint, radius * 0.28),
        );
      case BrushTipKind.sun:
        for (int i = 0; i < 12; i++) {
          canvas.save();
          canvas.rotate(i * pi / 6);
          canvas.drawPath(
            Path()
              ..moveTo(radius * 0.55, -radius * 0.06)
              ..lineTo(radius, 0)
              ..lineTo(radius * 0.55, radius * 0.06)
              ..close(),
            paint,
          );
          canvas.restore();
        }
        canvas.drawCircle(Offset.zero, radius * 0.55, paint);
      case BrushTipKind.ripple:
        final Paint stroke = _strokePaint(paint, radius * 0.09);
        for (int i = 0; i < 3; i++) {
          canvas.drawCircle(Offset.zero, radius * (0.4 + i * 0.3), stroke);
        }
      case BrushTipKind.squareRing:
        canvas.drawPath(
          Path()
            ..fillType = PathFillType.evenOdd
            ..addRect(Rect.fromCenter(center: Offset.zero, width: radius * 2, height: radius * 2))
            ..addRect(
                Rect.fromCenter(center: Offset.zero, width: radius * 1.2, height: radius * 1.2)),
          paint,
        );
      case BrushTipKind.spade:
        canvas.drawPath(
          Path()
            ..moveTo(0, -radius)
            ..cubicTo(radius * 0.9, -radius * 0.1, radius * 0.6, radius * 0.5, 0, radius * 0.35)
            ..cubicTo(-radius * 0.6, radius * 0.5, -radius * 0.9, -radius * 0.1, 0, -radius)
            ..close()
            ..moveTo(-radius * 0.22, radius * 0.7)
            ..lineTo(radius * 0.22, radius * 0.7)
            ..lineTo(radius * 0.08, radius * 0.3)
            ..lineTo(-radius * 0.08, radius * 0.3)
            ..close(),
          paint,
        );
      case BrushTipKind.musicNote:
        canvas.drawOval(
          Rect.fromCenter(center: Offset(-radius * 0.35, radius * 0.55), width: radius * 0.7, height: radius * 0.5),
          paint,
        );
        canvas.drawRect(
          Rect.fromLTWH(radius * 0.0 - radius * 0.06, -radius, radius * 0.12, radius * 1.6),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(radius * 0.06, -radius)
            ..lineTo(radius * 0.5, -radius * 0.7)
            ..lineTo(radius * 0.06, -radius * 0.45)
            ..close(),
          paint,
        );
      case BrushTipKind.doubleArrow:
        canvas.drawPath(
          Path()
            ..moveTo(0, -radius)
            ..lineTo(radius * 0.4, -radius * 0.5)
            ..lineTo(radius * 0.15, -radius * 0.5)
            ..lineTo(radius * 0.15, radius * 0.5)
            ..lineTo(radius * 0.4, radius * 0.5)
            ..lineTo(0, radius)
            ..lineTo(-radius * 0.4, radius * 0.5)
            ..lineTo(-radius * 0.15, radius * 0.5)
            ..lineTo(-radius * 0.15, -radius * 0.5)
            ..lineTo(-radius * 0.4, -radius * 0.5)
            ..close(),
          paint,
        );
      case BrushTipKind.club:
        final double rr = radius * 0.42;
        canvas.drawCircle(Offset(0, -radius * 0.4), rr, paint);
        canvas.drawCircle(Offset(-radius * 0.45, radius * 0.15), rr, paint);
        canvas.drawCircle(Offset(radius * 0.45, radius * 0.15), rr, paint);
        canvas.drawPath(
          Path()
            ..moveTo(-radius * 0.18, radius * 0.75)
            ..lineTo(radius * 0.18, radius * 0.75)
            ..lineTo(radius * 0.08, radius * 0.1)
            ..lineTo(-radius * 0.08, radius * 0.1)
            ..close(),
          paint,
        );
      case BrushTipKind.shield:
        canvas.drawPath(
          Path()
            ..moveTo(0, -radius)
            ..lineTo(radius * 0.75, -radius * 0.6)
            ..lineTo(radius * 0.75, radius * 0.15)
            ..quadraticBezierTo(radius * 0.6, radius * 0.8, 0, radius)
            ..quadraticBezierTo(-radius * 0.6, radius * 0.8, -radius * 0.75, radius * 0.15)
            ..lineTo(-radius * 0.75, -radius * 0.6)
            ..close(),
          paint,
        );
      case BrushTipKind.flowerEight:
        for (int i = 0; i < 8; i++) {
          final double a = i * pi / 4;
          canvas.drawCircle(Offset(cos(a) * radius * 0.6, sin(a) * radius * 0.6), radius * 0.32, paint);
        }
        canvas.drawCircle(Offset.zero, radius * 0.3, paint);
      case BrushTipKind.diamondRing:
        canvas.drawPath(
          Path()
            ..fillType = PathFillType.evenOdd
            ..addPath(_polygon(4, radius), Offset.zero)
            ..addPath(_polygon(4, radius * 0.55), Offset.zero),
          paint,
        );
      case BrushTipKind.wave:
        final Paint stroke = _strokePaint(paint, radius * 0.14);
        final Path path = Path();
        const int n = 40;
        for (int i = 0; i <= n; i++) {
          final double t = i / n;
          final double x = -radius + 2 * radius * t;
          final double y = sin(t * 2 * pi) * radius * 0.5;
          i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
        }
        canvas.drawPath(path, stroke);
      case BrushTipKind.infinity:
        final Paint stroke = _strokePaint(paint, radius * 0.13);
        final Path path = Path();
        const int n = 80;
        for (int i = 0; i <= n; i++) {
          final double t = i / n * 2 * pi;
          final double x = cos(t) * radius;
          final double y = sin(t) * cos(t) * radius;
          i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
        }
        canvas.drawPath(path, stroke);
      case BrushTipKind.flame:
        canvas.drawPath(
          Path()
            ..moveTo(0, -radius)
            ..cubicTo(radius * 0.65, -radius * 0.3, radius * 0.5, radius * 0.45, 0, radius)
            ..cubicTo(-radius * 0.5, radius * 0.45, -radius * 0.65, -radius * 0.3, 0, -radius)
            ..close(),
          paint,
        );
      case BrushTipKind.feather:
        final Paint stroke = _strokePaint(paint, radius * 0.05);
        canvas.drawLine(Offset(0, radius), Offset(0, -radius), stroke);
        for (int i = 0; i < 9; i++) {
          final double t = i / 8;
          final double y = radius - t * 2 * radius;
          final double len = radius * 0.55 * (1 - t * 0.6);
          canvas.drawLine(Offset(0, y), Offset(len, y - len * 0.5), stroke);
          canvas.drawLine(Offset(0, y), Offset(-len, y - len * 0.5), stroke);
        }
      case BrushTipKind.crosshair:
        final Paint stroke = _strokePaint(paint, radius * 0.07);
        canvas.drawCircle(Offset.zero, radius * 0.9, stroke);
        canvas.drawCircle(Offset.zero, radius * 0.45, stroke);
        canvas.drawLine(Offset(-radius, 0), Offset(radius, 0), stroke);
        canvas.drawLine(Offset(0, -radius), Offset(0, radius), stroke);
      case BrushTipKind.paw:
        canvas.drawOval(
          Rect.fromCenter(center: Offset(0, radius * 0.25), width: radius * 1.1, height: radius * 1.0),
          paint,
        );
        final double toeR = radius * 0.28;
        canvas.drawCircle(Offset(-radius * 0.55, -radius * 0.35), toeR, paint);
        canvas.drawCircle(Offset(-radius * 0.2, -radius * 0.65), toeR, paint);
        canvas.drawCircle(Offset(radius * 0.2, -radius * 0.65), toeR, paint);
        canvas.drawCircle(Offset(radius * 0.55, -radius * 0.35), toeR, paint);
      case BrushTipKind.crown:
        canvas.drawPath(
          Path()
            ..moveTo(-radius, radius * 0.5)
            ..lineTo(-radius, -radius * 0.3)
            ..lineTo(-radius * 0.5, radius * 0.1)
            ..lineTo(0, -radius * 0.6)
            ..lineTo(radius * 0.5, radius * 0.1)
            ..lineTo(radius, -radius * 0.3)
            ..lineTo(radius, radius * 0.5)
            ..close(),
          paint,
        );
      case BrushTipKind.bowtie:
        canvas.drawPath(
          Path()
            ..moveTo(-radius, -radius * 0.6)
            ..lineTo(0, 0)
            ..lineTo(-radius, radius * 0.6)
            ..close()
            ..moveTo(radius, -radius * 0.6)
            ..lineTo(0, 0)
            ..lineTo(radius, radius * 0.6)
            ..close(),
          paint,
        );
      case BrushTipKind.butterfly:
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(-radius * 0.45, -radius * 0.35),
              width: radius * 0.85,
              height: radius * 1.0),
          paint,
        );
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(radius * 0.45, -radius * 0.35),
              width: radius * 0.85,
              height: radius * 1.0),
          paint,
        );
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(-radius * 0.38, radius * 0.45),
              width: radius * 0.7,
              height: radius * 0.8),
          paint,
        );
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(radius * 0.38, radius * 0.45),
              width: radius * 0.7,
              height: radius * 0.8),
          paint,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: radius * 0.22, height: radius * 1.5),
          paint,
        );
      case BrushTipKind.mapleLeaf:
        const List<double> lobes = <double>[1.0, 0.42, 0.86, 0.38, 0.96, 0.38, 0.86, 0.42];
        final Path leafPath = Path();
        for (int i = 0; i < lobes.length; i++) {
          final double a = -pi / 2 + i * 2 * pi / lobes.length;
          final Offset p = Offset(cos(a) * radius * lobes[i], sin(a) * radius * lobes[i]);
          i == 0 ? leafPath.moveTo(p.dx, p.dy) : leafPath.lineTo(p.dx, p.dy);
        }
        leafPath.close();
        canvas.drawPath(leafPath, paint);
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset(0, radius * 0.8), width: radius * 0.12, height: radius * 0.5),
          paint,
        );
      case BrushTipKind.gem:
        final Paint stroke = _strokePaint(paint, radius * 0.09);
        final Path gemPath = Path()
          ..moveTo(-radius * 0.9, -radius * 0.35)
          ..lineTo(-radius * 0.5, -radius * 0.8)
          ..lineTo(radius * 0.5, -radius * 0.8)
          ..lineTo(radius * 0.9, -radius * 0.35)
          ..lineTo(0, radius)
          ..close();
        canvas.drawPath(gemPath, stroke);
        canvas.drawLine(
            Offset(-radius * 0.9, -radius * 0.35), Offset(radius * 0.9, -radius * 0.35), stroke);
        canvas.drawLine(
            Offset(-radius * 0.5, -radius * 0.8), Offset(-radius * 0.25, -radius * 0.35), stroke);
        canvas.drawLine(
            Offset(radius * 0.5, -radius * 0.8), Offset(radius * 0.25, -radius * 0.35), stroke);
        canvas.drawLine(Offset(-radius * 0.25, -radius * 0.35), Offset(0, radius), stroke);
        canvas.drawLine(Offset(radius * 0.25, -radius * 0.35), Offset(0, radius), stroke);
      case BrushTipKind.atom:
        final Paint stroke = _strokePaint(paint, radius * 0.09);
        for (int i = 0; i < 3; i++) {
          canvas.save();
          canvas.rotate(i * pi / 3);
          canvas.drawOval(
            Rect.fromCenter(center: Offset.zero, width: radius * 2, height: radius * 0.8),
            stroke,
          );
          canvas.restore();
        }
        canvas.drawCircle(Offset.zero, radius * 0.22, paint);
      case BrushTipKind.puzzle:
        final Path body = Path()
          ..addRect(
              Rect.fromCenter(center: Offset.zero, width: radius * 1.5, height: radius * 1.5));
        final Path tab = Path()
          ..addOval(Rect.fromCircle(center: Offset(radius * 0.75, 0), radius: radius * 0.3));
        final Path notch = Path()
          ..addOval(Rect.fromCircle(center: Offset(-radius * 0.75, 0), radius: radius * 0.3));
        canvas.drawPath(
          Path.combine(
            PathOperation.difference,
            Path.combine(PathOperation.union, body, tab),
            notch,
          ),
          paint,
        );
      case BrushTipKind.anchor:
        final Paint stroke = _strokePaint(paint, radius * 0.14);
        canvas.drawLine(Offset(0, -radius * 0.55), Offset(0, radius * 0.8), stroke);
        canvas.drawLine(
            Offset(-radius * 0.5, -radius * 0.35), Offset(radius * 0.5, -radius * 0.35), stroke);
        canvas.drawCircle(Offset(0, -radius * 0.75), radius * 0.22, stroke);
        canvas.drawArc(
          Rect.fromCircle(center: Offset(0, radius * 0.2), radius: radius * 0.7),
          pi * 0.15,
          pi * 0.7,
          false,
          stroke,
        );
      case BrushTipKind.fish:
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(radius * 0.12, 0), width: radius * 1.5, height: radius * 0.9),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(-radius * 0.55, 0)
            ..lineTo(-radius, -radius * 0.5)
            ..lineTo(-radius, radius * 0.5)
            ..close(),
          paint,
        );
      case BrushTipKind.cloud:
        canvas.drawCircle(Offset(-radius * 0.45, radius * 0.1), radius * 0.45, paint);
        canvas.drawCircle(Offset(0, -radius * 0.15), radius * 0.6, paint);
        canvas.drawCircle(Offset(radius * 0.5, radius * 0.1), radius * 0.42, paint);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(0, radius * 0.35), width: radius * 1.8, height: radius * 0.6),
            Radius.circular(radius * 0.3),
          ),
          paint,
        );
      case BrushTipKind.pineTree:
        for (int i = 0; i < 3; i++) {
          final double y = -radius + i * radius * 0.55;
          final double halfW = radius * (0.45 + i * 0.22);
          canvas.drawPath(
            Path()
              ..moveTo(0, y)
              ..lineTo(halfW, y + radius * 0.62)
              ..lineTo(-halfW, y + radius * 0.62)
              ..close(),
            paint,
          );
        }
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset(0, radius * 0.82), width: radius * 0.22, height: radius * 0.45),
          paint,
        );
      case BrushTipKind.rocket:
        canvas.drawPath(
          Path()
            ..moveTo(0, -radius)
            ..quadraticBezierTo(radius * 0.45, -radius * 0.3, radius * 0.35, radius * 0.4)
            ..lineTo(-radius * 0.35, radius * 0.4)
            ..quadraticBezierTo(-radius * 0.45, -radius * 0.3, 0, -radius)
            ..close(),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(radius * 0.35, radius * 0.1)
            ..lineTo(radius * 0.8, radius * 0.62)
            ..lineTo(radius * 0.35, radius * 0.62)
            ..close()
            ..moveTo(-radius * 0.35, radius * 0.1)
            ..lineTo(-radius * 0.8, radius * 0.62)
            ..lineTo(-radius * 0.35, radius * 0.62)
            ..close(),
          paint,
        );
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset(0, radius * 0.58), width: radius * 0.3, height: radius * 0.28),
          paint,
        );
      case BrushTipKind.lightbulb:
        canvas.drawCircle(Offset(0, -radius * 0.25), radius * 0.6, paint);
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset(0, radius * 0.42), width: radius * 0.45, height: radius * 0.35),
          paint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(0, radius * 0.74), width: radius * 0.5, height: radius * 0.35),
            Radius.circular(radius * 0.08),
          ),
          paint,
        );
      case BrushTipKind.bell:
        canvas.drawPath(
          Path()
            ..moveTo(-radius * 0.7, radius * 0.45)
            ..quadraticBezierTo(-radius * 0.65, -radius * 0.6, 0, -radius * 0.7)
            ..quadraticBezierTo(radius * 0.65, -radius * 0.6, radius * 0.7, radius * 0.45)
            ..close(),
          paint,
        );
        canvas.drawCircle(Offset(0, radius * 0.72), radius * 0.16, paint);
        canvas.drawCircle(Offset(0, -radius * 0.8), radius * 0.14, paint);
      case BrushTipKind.key:
        final Paint stroke = _strokePaint(paint, radius * 0.16);
        canvas.drawCircle(Offset(-radius * 0.5, 0), radius * 0.32, stroke);
        canvas.drawLine(Offset(-radius * 0.18, 0), Offset(radius * 0.85, 0), stroke);
        canvas.drawLine(Offset(radius * 0.55, 0), Offset(radius * 0.55, radius * 0.3), stroke);
        canvas.drawLine(Offset(radius * 0.8, 0), Offset(radius * 0.8, radius * 0.36), stroke);
      case BrushTipKind.hourglass:
        canvas.drawPath(
          Path()
            ..moveTo(-radius * 0.6, -radius * 0.72)
            ..lineTo(radius * 0.6, -radius * 0.72)
            ..lineTo(0, 0)
            ..close()
            ..moveTo(-radius * 0.6, radius * 0.72)
            ..lineTo(radius * 0.6, radius * 0.72)
            ..lineTo(0, 0)
            ..close(),
          paint,
        );
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset(0, -radius * 0.82), width: radius * 1.5, height: radius * 0.16),
          paint,
        );
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset(0, radius * 0.82), width: radius * 1.5, height: radius * 0.16),
          paint,
        );
      case BrushTipKind.ghost:
        canvas.drawPath(
          Path()
            ..moveTo(-radius * 0.7, radius * 0.7)
            ..lineTo(-radius * 0.7, -radius * 0.1)
            ..quadraticBezierTo(-radius * 0.7, -radius * 0.9, 0, -radius * 0.9)
            ..quadraticBezierTo(radius * 0.7, -radius * 0.9, radius * 0.7, -radius * 0.1)
            ..lineTo(radius * 0.7, radius * 0.7)
            ..lineTo(radius * 0.35, radius * 0.45)
            ..lineTo(0, radius * 0.7)
            ..lineTo(-radius * 0.35, radius * 0.45)
            ..close(),
          paint,
        );
      case BrushTipKind.mushroom:
        canvas.drawArc(
          Rect.fromCircle(center: Offset(0, -radius * 0.05), radius: radius * 0.9),
          pi,
          pi,
          true,
          paint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(0, radius * 0.45), width: radius * 0.55, height: radius * 0.95),
            Radius.circular(radius * 0.16),
          ),
          paint,
        );
      // ---- 空心轮廓类 / Outline family ----
      case BrushTipKind.outlineCircle:
        canvas.drawCircle(Offset.zero, radius * 0.85, _strokePaint(paint, radius * 0.14));
      case BrushTipKind.outlineSquare:
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: radius * 1.7, height: radius * 1.7),
          _strokePaint(paint, radius * 0.14),
        );
      case BrushTipKind.outlineTriangle:
        canvas.drawPath(_polygon(3, radius * 0.9), _strokePaint(paint, radius * 0.14));
      case BrushTipKind.outlineHexagon:
        canvas.drawPath(_polygon(6, radius * 0.9), _strokePaint(paint, radius * 0.14));
      case BrushTipKind.outlineStar:
        canvas.drawPath(
          _star(5, radius * 0.95, radius * 0.42),
          _strokePaint(paint, radius * 0.13),
        );
      case BrushTipKind.outlineHeart:
        canvas.drawPath(_heart(radius * 0.9), _strokePaint(paint, radius * 0.13));

      // ---- 字符类 / Glyph family ----
      case BrushTipKind.glyphStar:
        _drawGlyph(canvas, '✦', radius, paint);
      case BrushTipKind.glyphFlower:
        _drawGlyph(canvas, '✿', radius, paint);
      case BrushTipKind.glyphSnow:
        _drawGlyph(canvas, '❄', radius, paint);
      case BrushTipKind.glyphHeart:
        _drawGlyph(canvas, '♥', radius, paint);
      case BrushTipKind.glyphNote:
        _drawGlyph(canvas, '♪', radius, paint);
      case BrushTipKind.glyphClover:
        _drawGlyph(canvas, '☘', radius, paint);

      case BrushTipKind.spatter:
        for (int i = 0; i < 12; i++) {
          final double dx = _jitter(seed, index, i * 2) * radius;
          final double dy = _jitter(seed, index, i * 2 + 1) * radius;
          if (dx * dx + dy * dy <= radius * radius) {
            final double r = radius * 0.28 * (0.4 + (_jitter(seed, index, 500 + i) + 1) / 2 * 0.6);
            canvas.drawCircle(Offset(dx, dy), r, paint);
          }
        }
      case BrushTipKind.chalk:
        final double speck = (radius * 0.22).clamp(0.5, double.infinity);
        for (int i = 0; i < 16; i++) {
          final double dx = _jitter(seed, index, i * 2) * radius;
          final double dy = _jitter(seed, index, i * 2 + 1) * radius;
          if (dx * dx + dy * dy <= radius * radius) {
            canvas.drawRect(
              Rect.fromCenter(center: Offset(dx, dy), width: speck, height: speck),
              paint,
            );
          }
        }
      case BrushTipKind.scatter:
        for (int i = 0; i < 6; i++) {
          final double dx = _jitter(seed, index, i) * radius * 1.8;
          final double dy = _jitter(seed, index, 100 + i) * radius * 0.6;
          final double r = radius * 0.3 * (0.5 + (_jitter(seed, index, 200 + i) + 1) / 2 * 0.5);
          canvas.drawCircle(Offset(dx, dy), r, paint);
        }
    }
  }

  /// 以原点为中心绘制一个字符笔尖
  ///
  /// 用 [painting.TextPainter] 把字符排版后居中绘制，字号取笔尖直径。
  /// 颜色与透明度沿用当前画笔颜色。
  ///
  /// Draw a glyph tip centered at the origin. Lays the character out with
  /// [painting.TextPainter] at a font size matching the tip diameter, using the
  /// current brush color.
  static void _drawGlyph(Canvas canvas, String ch, double radius, Paint paint) {
    if (radius <= 0) {
      return;
    }
    final painting.TextPainter tp = painting.TextPainter(
      text: painting.TextSpan(
        text: ch,
        style: painting.TextStyle(fontSize: radius * 2, color: paint.color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  }

  /// 由填充画笔派生一支描边画笔（雪花、螺旋等线状笔尖用）
  ///
  /// Derive a stroke paint from the fill paint (for line-based tips like
  /// snowflake and spiral)
  static Paint _strokePaint(Paint fill, double width) {
    return Paint()
      ..color = fill.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = fill.maskFilter
      ..isAntiAlias = true;
  }

  /// 以原点为中心的心形
  ///
  /// Heart centered at the origin
  static Path _heart(double radius) {
    final Path path = Path();
    const int n = 60;
    for (int i = 0; i <= n; i++) {
      final double t = i / n * 2 * pi;
      final double x = 16 * pow(sin(t), 3).toDouble();
      final double y = 13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t);
      final double px = x / 16 * radius;
      final double py = -y / 16 * radius;
      i == 0 ? path.moveTo(px, py) : path.lineTo(px, py);
    }
    path.close();
    return path;
  }

  /// 以原点为中心的叶片（尖椭圆）
  ///
  /// Leaf (pointed oval) centered at the origin
  static Path _leaf(double radius) {
    return Path()
      ..moveTo(0, -radius)
      ..quadraticBezierTo(radius, 0, 0, radius)
      ..quadraticBezierTo(-radius, 0, 0, -radius)
      ..close();
  }

  /// 以原点为中心、顶点朝上的正多边形
  ///
  /// Regular polygon centered at the origin, first vertex pointing up
  static Path _polygon(int sides, double radius) {
    final Path path = Path();
    for (int i = 0; i < sides; i++) {
      final double a = -pi / 2 + i * 2 * pi / sides;
      final Offset p = Offset(radius * cos(a), radius * sin(a));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    return path;
  }

  /// 以原点为中心的星形
  ///
  /// Star centered at the origin
  static Path _star(int count, double outer, double inner) {
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

  /// 稳定的伪随机抖动 [-1, 1]（纹理类笔尖用）
  ///
  /// Stable pseudo-random jitter in [-1, 1] (for textured tips)
  static double _jitter(int seed, int index, int channel) {
    final int s = (seed + index * 374761393 + channel * 668265263) & 0x7fffffff;
    return Random(s).nextDouble() * 2 - 1;
  }
}
