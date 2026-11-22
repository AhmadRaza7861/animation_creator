import 'dart:math';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/painting.dart' as painting;

import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';
import 'brush_cache.dart';
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

  // ⚠️ Saved strokes store `kind.index`: ALWAYS append new kinds at the end,
  // never insert or reorder, or existing drawings change tips.
  // ---- v2 tips ----
  // Shapes
  roundedSquare,
  semicircle,
  capsule,
  parallelogram,
  trapezoid,
  // Stars
  sparkle,
  compassStar,
  // Symbols
  smiley,
  speechBubble,
  eye,
  house,
  mapPin,
  chevron,
  // Nature
  bird,
  mountain,
  roundTree,
  tulip,
  apple,
  bone,
  // Pattern textures (static)
  hatch,
  crossHatch,
  halftone,
  scales,
  bricks,
  zigzag,
  stitch,
  // Scatter textures (randomized per dab)
  rain,
  bubbles,
  glitter,
  fur,
  starfield,
  snowfall,
  petals,
  heartScatter,
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
        kind: _kindFromIndex(data['kind']),
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

  /// Saved index → kind. Unknown/invalid values (e.g. a project saved by a
  /// newer app version with more tips) fall back to round instead of crashing.
  static BrushTipKind _kindFromIndex(Object? raw) {
    final int? i = raw is num ? raw.toInt() : null;
    if (i == null || i < 0 || i >= BrushTipKind.values.length) {
      return BrushTipKind.round;
    }
    return BrushTipKind.values[i];
  }

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

  static final BoundedImageCache<String> _stampCache =
      BoundedImageCache<String>(maxEntries: 36);

  static const double _tileSize = 160.0;

  static void clearStampCache() => _stampCache.clear();

  static bool _isRandomizedKind(BrushTipKind kind) => switch (kind) {
        BrushTipKind.grassClump ||
        BrushTipKind.leafScatter ||
        BrushTipKind.bristle ||
        BrushTipKind.dryBrush ||
        BrushTipKind.stipple ||
        BrushTipKind.charcoal ||
        BrushTipKind.sponge ||
        BrushTipKind.splash ||
        BrushTipKind.spatter ||
        BrushTipKind.chalk ||
        BrushTipKind.scatter ||
        BrushTipKind.rain ||
        BrushTipKind.bubbles ||
        BrushTipKind.glitter ||
        BrushTipKind.fur ||
        BrushTipKind.starfield ||
        BrushTipKind.snowfall ||
        BrushTipKind.petals ||
        BrushTipKind.heartScatter => true,
        _ => false,
      };

  static bool _isHeavyStaticKind(BrushTipKind kind) =>
      !_isRandomizedKind(kind) &&
      kind != BrushTipKind.round &&
      kind != BrushTipKind.square &&
      kind != BrushTipKind.diamond;

  static ui.Image? _getBakedTipStamp({
    required BrushTipKind kind,
    required double roundness,
    required double hardness,
    int variant = 0,
  }) {
    final int rq = (roundness.clamp(0.02, 1.0) * 20).round();
    final int hq = (hardness.clamp(0.0, 1.0) * 20).round();
    final String key = '${kind.index}_${rq}_${hq}_$variant';
    final double qRound = (rq / 20.0).clamp(0.02, 1.0);
    final double qHard = (hq / 20.0).clamp(0.0, 1.0);
    // Keep extra margin inside 160x160 for blur halos & scatter radius.
    final double refR = qHard < 0.99
        ? (_isRandomizedKind(kind) ? 22.0 : 28.0)
        : 60.0;

    return _stampCache.getOrBake(key, () {
      try {
        final ui.PictureRecorder rec = ui.PictureRecorder();
        final Canvas c = Canvas(rec, const Rect.fromLTWH(0, 0, _tileSize, _tileSize));
        c.translate(_tileSize * 0.5, _tileSize * 0.5);
        if (qRound < 0.99) {
          c.scale(1.0, qRound);
        }
        final double sigma = qHard < 0.99 ? refR * (1.0 - qHard) * 0.9 : 0.0;
        final Paint p = Paint()
          ..color = const Color(0xFFFFFFFF)
          ..style = PaintingStyle.fill
          ..isAntiAlias = true
          ..maskFilter =
              sigma > 0 ? MaskFilter.blur(BlurStyle.normal, sigma) : null;
        _drawShape(c, kind, refR, p, 42 + variant * 97, variant);
        final ui.Picture pic = rec.endRecording();
        final ui.Image img = pic.toImageSync(_tileSize.toInt(), _tileSize.toInt());
        pic.dispose();
        return img;
      } catch (_) {
        return null;
      }
    });
  }

  @override
  bool get supportsActiveRangeBaking => true;

  @override
  void drawCommittedRange(Canvas canvas, Size size, int startSample, int endSample) {
    _drawTipRange(canvas, size, startSample, endSample, includeTail: false);
  }

  @override
  void drawLiveFromSample(Canvas canvas, Size size, int startSample) {
    _drawTipRange(canvas, size, startSample, null, includeTail: true);
  }

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (points.isEmpty) {
      return;
    }

    final double width = paint.strokeWidth;
    final double radius = width / 2;
    if (radius <= 0) return;

    if (points.length == 1) {
      final double angleRad = angle * pi / 180;
      final bool isSoft = hardness < 0.99;
      final bool isRandomized = _isRandomizedKind(kind);
      final bool useStamp = isSoft || _isHeavyStaticKind(kind);
      if (useStamp) {
        final ui.Image? stamp = _getBakedTipStamp(
          kind: kind,
          roundness: roundness,
          hardness: hardness,
          variant: 0,
        );
        if (stamp != null) {
          final double refR =
              isSoft ? (isRandomized ? 22.0 : 28.0) : 60.0;
          AtlasStampDrawer.drawBatch(
            canvas: canvas,
            stamp: stamp,
            srcSize: _tileSize,
            targetRadius: radius,
            stampRefRadius: refR,
            xs: <double>[points.first.dx],
            ys: <double>[points.first.dy],
            angles: <double>[angleRad],
            tint: paint.color,
            flipX: flipX,
            flipY: flipY,
          );
          return;
        }
      }
      final Paint tipPaint = _tipPaint(paint, radius);
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

    _drawTipRange(canvas, size, 0, null, includeTail: true);
  }

  void _drawTipRange(
    Canvas canvas,
    Size size,
    int startSample,
    int? endSample, {
    required bool includeTail,
  }) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      if (includeTail) draw(canvas, size, false);
      return;
    }

    final double width = paint.strokeWidth;
    final double radius = width / 2;
    if (radius <= 0) return;
    final double angleRad = angle * pi / 180;
    final bool isSoft = hardness < 0.99;
    final bool isRandomized = _isRandomizedKind(kind);
    final double frac = spacing > 0 ? spacing : 0.08;
    final double step = (width * frac).clamp(2.5, double.infinity);
    final ChunkedStrokeCache cache = sampleSmooth(step);
    final int safeStart = startSample.clamp(0, cache.frozenCount);
    final int safeEnd = (endSample ?? cache.frozenCount).clamp(safeStart, cache.frozenCount);

    // Fast GPU atlas path for all soft tips (0 runtime MaskFilter.blur!) and
    // complex static tips (0 runtime TextPainter/Path.combine/trig loops!).
    if ((isSoft && !isRandomized) || (!isRandomized && _isHeavyStaticKind(kind))) {
      final ui.Image? stamp = _getBakedTipStamp(
        kind: kind,
        roundness: roundness,
        hardness: hardness,
      );
      if (stamp != null) {
        final double refR = isSoft ? 28.0 : 60.0;
        if (safeStart < safeEnd) {
          final int len = safeEnd - safeStart;
          final List<double> effectiveAngles = followPath
              ? List<double>.generate(
                  len,
                  (int k) => cache.angles[safeStart + k] + angleRad,
                  growable: false,
                )
              : List<double>.filled(len, angleRad, growable: false);
          AtlasStampDrawer.drawBatch(
            canvas: canvas,
            stamp: stamp,
            srcSize: _tileSize,
            targetRadius: radius,
            stampRefRadius: refR,
            xs: safeStart == 0 && safeEnd == cache.frozenCount
                ? cache.xs
                : cache.xs.sublist(safeStart, safeEnd),
            ys: safeStart == 0 && safeEnd == cache.frozenCount
                ? cache.ys
                : cache.ys.sublist(safeStart, safeEnd),
            angles: effectiveAngles,
            tint: paint.color,
            flipX: flipX,
            flipY: flipY,
          );
        }
        if (includeTail && cache.tailCount > 0) {
          final List<double> tailAng = followPath
              ? List<double>.generate(
                  cache.tailCount,
                  (int k) => cache.tailAngles[k] + angleRad,
                  growable: false,
                )
              : List<double>.filled(cache.tailCount, angleRad, growable: false);
          AtlasStampDrawer.drawBatch(
            canvas: canvas,
            stamp: stamp,
            srcSize: _tileSize,
            targetRadius: radius,
            stampRefRadius: refR,
            xs: cache.tailXs,
            ys: cache.tailYs,
            angles: tailAng,
            tint: paint.color,
            flipX: flipX,
            flipY: flipY,
          );
        }
        return;
      }
    }

    // Soft randomized tips (`hardness < 0.99`): bucket into 4 pre-blurred
    // deterministic variant stamps instead of running 20 Gaussian blurs/dab.
    if (isSoft && isRandomized) {
      const int variants = 4;
      final List<ui.Image?> stamps = List<ui.Image?>.generate(
        variants,
        (int v) => _getBakedTipStamp(
          kind: kind,
          roundness: roundness,
          hardness: hardness,
          variant: v,
        ),
      );
      if (!stamps.contains(null)) {
        final List<List<double>> bucketX = List.generate(variants, (_) => <double>[]);
        final List<List<double>> bucketY = List.generate(variants, (_) => <double>[]);
        final List<List<double>> bucketA = List.generate(variants, (_) => <double>[]);
        for (int i = safeStart; i < safeEnd; i++) {
          final int v = i & 3;
          bucketX[v].add(cache.xs[i]);
          bucketY[v].add(cache.ys[i]);
          bucketA[v].add((followPath ? cache.angles[i] : 0.0) + angleRad);
        }
        if (includeTail) {
          final int frozenOffset = cache.frozenCount;
          for (int i = 0; i < cache.tailCount; i++) {
            final int v = (frozenOffset + i) & 3;
            bucketX[v].add(cache.tailXs[i]);
            bucketY[v].add(cache.tailYs[i]);
            bucketA[v].add((followPath ? cache.tailAngles[i] : 0.0) + angleRad);
          }
        }
        for (int v = 0; v < variants; v++) {
          if (bucketX[v].isEmpty) continue;
          AtlasStampDrawer.drawBatch(
            canvas: canvas,
            stamp: stamps[v]!,
            srcSize: _tileSize,
            targetRadius: radius,
            stampRefRadius: 22.0,
            xs: bucketX[v],
            ys: bucketY[v],
            angles: bucketA[v],
            tint: paint.color,
            flipX: flipX,
            flipY: flipY,
          );
        }
        return;
      }
    }

    // Crisp vector tips: incremental sampling + chunked `ui.Picture` baking.
    final Paint tipPaint = _tipPaint(paint, radius);
    final int seedVal = _seed;
    final int sig = Object.hash(
      baseStyleSignature,
      kind.index,
      angle,
      roundness,
      hardness,
      spacing,
      flipX,
      flipY,
      followPath,
      seedVal,
    );

    drawSampleSlice(canvas, size, safeStart, safeEnd, includeTail, sig,
        (Canvas target, int startIdx, int endIdx, bool isTail) {
      for (int i = startIdx; i < endIdx; i++) {
        final double x = strokeCache.getX(i, isTail);
        final double y = strokeCache.getY(i, isTail);
        final double ang = followPath ? strokeCache.getAngle(i, isTail) : 0.0;
        final int globalIdx = strokeCache.globalIndex(i, isTail);
        paintDab(
          target,
          Offset(x, y),
          radius,
          kind: kind,
          paint: tipPaint,
          angle: ang + angleRad,
          roundness: roundness,
          flipX: flipX,
          flipY: flipY,
          seed: seedVal,
          index: globalIdx,
        );
      }
    });
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
  TipBrush copy() => TipBrush.data(
        minPointDistance: minPointDistance,
        kind: kind,
        angle: angle,
        roundness: roundness,
        hardness: hardness,
        spacing: spacing,
        flipX: flipX,
        flipY: flipY,
        followPath: followPath,
        points: List<Offset>.from(points),
        paint: paint.copyWith(),
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
    if (angle == 0 && roundness >= 0.99 && !flipX && !flipY && kind == BrushTipKind.round) {
      canvas.drawCircle(center, radius, paint);
      return;
    }
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (angle != 0) {
      canvas.rotate(angle);
    }
    if (flipX || flipY || roundness < 0.99) {
      canvas.scale(
        flipX ? -1 : 1,
        (flipY ? -1 : 1) * (roundness <= 0 ? 0.02 : roundness),
      );
    }
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
        for (int i = 0; i < 8; i++) {
          final double y = _jitter(seed, index, i) * radius;
          final double x0 = -radius * (0.6 + 0.4 * ((_jitter(seed, index, 40 + i) + 1) / 2));
          final double x1 = radius * (0.6 + 0.4 * ((_jitter(seed, index, 80 + i) + 1) / 2));
          canvas.drawLine(Offset(x0, y), Offset(x1, y), stroke);
        }
      case BrushTipKind.dryBrush:
        // 干枯笔触：断续的短划
        final Paint stroke = _strokePaint(paint, radius * 0.08);
        for (int i = 0; i < 10; i++) {
          final double y = _jitter(seed, index, i) * radius;
          final double cx = _jitter(seed, index, 60 + i) * radius * 0.7;
          final double half = radius * 0.14 * (0.5 + (_jitter(seed, index, 120 + i) + 1) / 2);
          if (cx * cx + y * y <= radius * radius) {
            canvas.drawLine(Offset(cx - half, y), Offset(cx + half, y), stroke);
          }
        }
      case BrushTipKind.stipple:
        // 点画：大量细小圆点
        for (int i = 0; i < 20; i++) {
          final double dx = _jitter(seed, index, i * 2) * radius;
          final double dy = _jitter(seed, index, i * 2 + 1) * radius;
          if (dx * dx + dy * dy <= radius * radius) {
            canvas.drawCircle(Offset(dx, dy), radius * 0.07, paint);
          }
        }
      case BrushTipKind.charcoal:
        // 炭笔：密集且大小不一的颗粒
        for (int i = 0; i < 20; i++) {
          final double dx = _jitter(seed, index, i * 2) * radius;
          final double dy = _jitter(seed, index, i * 2 + 1) * radius;
          if (dx * dx + dy * dy <= radius * radius) {
            final double s = radius * 0.18 * (0.4 + (_jitter(seed, index, 300 + i) + 1) / 2 * 0.6);
            canvas.drawRect(Rect.fromCenter(center: Offset(dx, dy), width: s, height: s), paint);
          }
        }
      case BrushTipKind.sponge:
        // 海绵：多孔的小环
        final Paint stroke = _strokePaint(paint, radius * 0.06);
        for (int i = 0; i < 8; i++) {
          final double dx = _jitter(seed, index, i * 2) * radius * 0.9;
          final double dy = _jitter(seed, index, i * 2 + 1) * radius * 0.9;
          final double r = radius * 0.25 * (0.4 + (_jitter(seed, index, 220 + i) + 1) / 2 * 0.6);
          canvas.drawCircle(Offset(dx, dy), r, stroke);
        }
      case BrushTipKind.splash:
        // 墨点飞溅：中心大块 + 四散小滴
        canvas.drawCircle(Offset.zero, radius * 0.45, paint);
        for (int i = 0; i < 8; i++) {
          final double dx = _jitter(seed, index, i * 2) * radius * 1.1;
          final double dy = _jitter(seed, index, i * 2 + 1) * radius * 1.1;
          final double r = radius * 0.18 * (0.3 + (_jitter(seed, index, 260 + i) + 1) / 2 * 0.7);
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

      default:
        _drawShapeV2(canvas, kind, radius, paint, seed, index);
    }
  }

  /// v2 tips. Kept separate so the original switch stays untouched.
  static void _drawShapeV2(
    Canvas canvas,
    BrushTipKind kind,
    double r,
    Paint paint,
    int seed,
    int index,
  ) {
    // Well-mixed randoms for scatter tips. `_jitter` correlates adjacent
    // channels, which bunches x/y pairs into a narrow diagonal band.
    double rnd(int ch) => _mixedRand01(seed, index, ch);
    double jit(int ch) => rnd(ch) * 2 - 1;

    switch (kind) {
      // ---- Shapes ----
      case BrushTipKind.roundedSquare:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 2),
            Radius.circular(r * 0.45),
          ),
          paint,
        );
      case BrushTipKind.semicircle:
        canvas.drawArc(
          Rect.fromCircle(center: Offset(0, r * 0.4), radius: r),
          pi,
          pi,
          true,
          paint,
        );
      case BrushTipKind.capsule:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 0.9),
            Radius.circular(r * 0.45),
          ),
          paint,
        );
      case BrushTipKind.parallelogram:
        canvas.drawPath(
          _poly(<Offset>[
            Offset(-r, r * 0.6),
            Offset(-r * 0.4, -r * 0.6),
            Offset(r, -r * 0.6),
            Offset(r * 0.4, r * 0.6),
          ]),
          paint,
        );
      case BrushTipKind.trapezoid:
        canvas.drawPath(
          _poly(<Offset>[
            Offset(-r, r * 0.6),
            Offset(-r * 0.5, -r * 0.6),
            Offset(r * 0.5, -r * 0.6),
            Offset(r, r * 0.6),
          ]),
          paint,
        );

      // ---- Stars ----
      case BrushTipKind.sparkle:
        canvas.drawPath(_sparklePath(Offset.zero, r), paint);
        canvas.drawPath(_sparklePath(Offset(r * 0.68, -r * 0.68), r * 0.3), paint);
      case BrushTipKind.compassStar:
        final Path p = Path();
        for (int i = 0; i < 16; i++) {
          final double rad = i.isOdd ? r * 0.16 : (i % 4 == 0 ? r : r * 0.58);
          final double a = -pi / 2 + i * pi / 8;
          final Offset o = Offset(cos(a) * rad, sin(a) * rad);
          i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
        }
        canvas.drawPath(p..close(), paint);

      // ---- Symbols ----
      case BrushTipKind.smiley:
        canvas.drawPath(
          Path()
            ..fillType = PathFillType.evenOdd
            ..addOval(Rect.fromCircle(center: Offset.zero, radius: r))
            ..addOval(Rect.fromCircle(center: Offset(-r * 0.34, -r * 0.25), radius: r * 0.13))
            ..addOval(Rect.fromCircle(center: Offset(r * 0.34, -r * 0.25), radius: r * 0.13))
            ..moveTo(-r * 0.5, r * 0.12)
            ..quadraticBezierTo(0, r * 0.78, r * 0.5, r * 0.12)
            ..quadraticBezierTo(0, r * 0.5, -r * 0.5, r * 0.12)
            ..close(),
          paint,
        );
      case BrushTipKind.speechBubble:
        canvas.drawPath(
          Path.combine(
            PathOperation.union,
            Path()
              ..addRRect(RRect.fromRectAndRadius(
                Rect.fromLTRB(-r, -r * 0.8, r, r * 0.4),
                Radius.circular(r * 0.38),
              )),
            _poly(<Offset>[
              Offset(-r * 0.45, r * 0.3),
              Offset(-r * 0.6, r),
              Offset(0, r * 0.3),
            ]),
          ),
          paint,
        );
      case BrushTipKind.eye:
        canvas.drawPath(
          Path()
            ..fillType = PathFillType.evenOdd
            ..moveTo(-r, 0)
            ..quadraticBezierTo(0, -r * 0.9, r, 0)
            ..quadraticBezierTo(0, r * 0.9, -r, 0)
            ..close()
            ..addOval(Rect.fromCircle(center: Offset.zero, radius: r * 0.38))
            ..addOval(Rect.fromCircle(center: Offset.zero, radius: r * 0.18)),
          paint,
        );
      case BrushTipKind.house:
        canvas.drawPath(
          Path()
            ..fillType = PathFillType.evenOdd
            ..addPath(
              _poly(<Offset>[
                Offset(-r * 0.8, r),
                Offset(-r * 0.8, -r * 0.1),
                Offset(0, -r),
                Offset(r * 0.8, -r * 0.1),
                Offset(r * 0.8, r),
              ]),
              Offset.zero,
            )
            ..addRect(Rect.fromLTRB(-r * 0.2, r * 0.35, r * 0.2, r)),
          paint,
        );
      case BrushTipKind.mapPin:
        canvas.drawPath(
          Path.combine(
            PathOperation.difference,
            Path.combine(
              PathOperation.union,
              Path()..addOval(Rect.fromCircle(center: Offset(0, -r * 0.3), radius: r * 0.65)),
              _poly(<Offset>[Offset(-r * 0.56, -r * 0.05), Offset(0, r), Offset(r * 0.56, -r * 0.05)]),
            ),
            Path()..addOval(Rect.fromCircle(center: Offset(0, -r * 0.3), radius: r * 0.26)),
          ),
          paint,
        );
      case BrushTipKind.chevron:
        canvas.drawPath(
          _poly(<Offset>[
            Offset(-r * 0.6, -r),
            Offset(0, -r),
            Offset(r * 0.6, 0),
            Offset(0, r),
            Offset(-r * 0.6, r),
            Offset(0, 0),
          ]),
          paint,
        );

      // ---- Nature ----
      case BrushTipKind.bird:
        canvas.drawPath(
          // Wing tips at ±0.9r so the round line caps stay inside the tile.
          Path()
            ..moveTo(-r * 0.9, -r * 0.1)
            ..quadraticBezierTo(-r * 0.45, -r * 0.65, 0, r * 0.15)
            ..quadraticBezierTo(r * 0.45, -r * 0.65, r * 0.9, -r * 0.1),
          _strokePaint(paint, r * 0.17),
        );
      case BrushTipKind.mountain:
        canvas.drawPath(
          _poly(<Offset>[
            Offset(-r, r * 0.7),
            Offset(-r * 0.45, -r * 0.3),
            Offset(-r * 0.15, r * 0.1),
            Offset(r * 0.3, -r * 0.85),
            Offset(r, r * 0.7),
          ]),
          paint,
        );
      case BrushTipKind.roundTree:
        canvas.drawCircle(Offset(0, -r * 0.3), r * 0.65, paint);
        canvas.drawRect(Rect.fromLTRB(-r * 0.12, r * 0.2, r * 0.12, r), paint);
      case BrushTipKind.tulip:
        canvas.drawPath(
          Path()
            ..moveTo(-r * 0.5, -r * 0.75)
            ..lineTo(-r * 0.25, -r * 0.42)
            ..lineTo(0, -r * 0.85)
            ..lineTo(r * 0.25, -r * 0.42)
            ..lineTo(r * 0.5, -r * 0.75)
            ..quadraticBezierTo(r * 0.55, r * 0.05, 0, r * 0.1)
            ..quadraticBezierTo(-r * 0.55, r * 0.05, -r * 0.5, -r * 0.75)
            ..close(),
          paint,
        );
        canvas.drawLine(Offset(0, r * 0.05), Offset(0, r * 0.94), _strokePaint(paint, r * 0.1));
        canvas.drawPath(
          Path()
            ..moveTo(0, r * 0.85)
            ..quadraticBezierTo(r * 0.5, r * 0.75, r * 0.5, r * 0.3)
            ..quadraticBezierTo(r * 0.1, r * 0.42, 0, r * 0.85)
            ..close(),
          paint,
        );
      case BrushTipKind.apple:
        canvas.drawPath(
          Path()
            ..moveTo(0, -r * 0.45)
            ..cubicTo(r * 0.9, -r * 0.85, r * 1.0, r * 0.55, r * 0.2, r * 0.85)
            ..quadraticBezierTo(0, r * 0.75, -r * 0.2, r * 0.85)
            ..cubicTo(-r * 1.0, r * 0.55, -r * 0.9, -r * 0.85, 0, -r * 0.45)
            ..close(),
          paint,
        );
        canvas.drawLine(
          Offset(0, -r * 0.45),
          Offset(r * 0.08, -r * 0.85),
          _strokePaint(paint, r * 0.1),
        );
        canvas.drawPath(
          Path()
            ..moveTo(r * 0.1, -r * 0.62)
            ..quadraticBezierTo(r * 0.35, -r * 0.98, r * 0.6, -r * 0.78)
            ..quadraticBezierTo(r * 0.32, -r * 0.55, r * 0.1, -r * 0.62)
            ..close(),
          paint,
        );
      case BrushTipKind.bone:
        canvas.drawRect(Rect.fromLTRB(-r * 0.65, -r * 0.18, r * 0.65, r * 0.18), paint);
        for (final Offset o in <Offset>[
          Offset(-r * 0.7, -r * 0.2),
          Offset(-r * 0.7, r * 0.2),
          Offset(r * 0.7, -r * 0.2),
          Offset(r * 0.7, r * 0.2),
        ]) {
          canvas.drawCircle(o, r * 0.26, paint);
        }

      // ---- Pattern textures (clipped to the tip circle) ----
      case BrushTipKind.hatch:
      case BrushTipKind.crossHatch:
        final Paint stroke = _strokePaint(paint, r * 0.09);
        canvas.save();
        canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r)));
        final int passes = kind == BrushTipKind.crossHatch ? 2 : 1;
        for (int pass = 0; pass < passes; pass++) {
          canvas.save();
          canvas.rotate(pass == 0 ? -pi / 4 : pi / 4);
          for (int i = -4; i <= 4; i++) {
            final double x = i * r * 0.26;
            canvas.drawLine(Offset(x, -r), Offset(x, r), stroke);
          }
          canvas.restore();
        }
        canvas.restore();
      case BrushTipKind.halftone:
        const int n = 3;
        final double cell = r / n;
        for (int gx = -n; gx <= n; gx++) {
          for (int gy = -n; gy <= n; gy++) {
            final Offset o = Offset(gx * cell, gy * cell);
            final double d = o.distance / r;
            if (d < 1.0) {
              canvas.drawCircle(o, cell * 0.48 * (1 - d * 0.75), paint);
            }
          }
        }
      case BrushTipKind.scales:
        final Paint stroke = _strokePaint(paint, r * 0.08);
        canvas.save();
        canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r)));
        final double s = r * 0.34;
        for (int row = -3; row <= 3; row++) {
          final double shift = row.isOdd ? s : 0;
          for (int col = -3; col <= 3; col++) {
            canvas.drawArc(
              Rect.fromCircle(center: Offset(col * s * 2 + shift, row * s), radius: s),
              0,
              pi,
              false,
              stroke,
            );
          }
        }
        canvas.restore();
      case BrushTipKind.bricks:
        canvas.save();
        canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r)));
        final double bh = r * 0.4;
        final double bw = r * 0.8;
        final double gap = r * 0.08;
        for (int row = -3; row <= 2; row++) {
          final double y = row * bh;
          final double shift = row.isOdd ? bw / 2 : 0;
          for (int col = -3; col <= 2; col++) {
            final double x = col * bw + shift;
            canvas.drawRect(Rect.fromLTWH(x + gap / 2, y + gap / 2, bw - gap, bh - gap), paint);
          }
        }
        canvas.restore();
      case BrushTipKind.zigzag:
        // Span ±0.88r so the round caps (half of 0.16r) stay inside the tile.
        final Path p = Path()..moveTo(-r * 0.88, r * 0.35);
        for (int i = 1; i <= 5; i++) {
          p.lineTo(-r * 0.88 + i * r * 0.352, i.isOdd ? -r * 0.35 : r * 0.35);
        }
        canvas.drawPath(p, _strokePaint(paint, r * 0.16));
      case BrushTipKind.stitch:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: r * 1.4, height: r * 0.26),
            Radius.circular(r * 0.13),
          ),
          paint,
        );

      // ---- Scatter textures (random per dab) ----
      case BrushTipKind.rain:
        final Paint stroke = _strokePaint(paint, r * 0.07);
        for (int i = 0; i < 7; i++) {
          final double x = jit(i * 2) * r * 0.85;
          final double y = jit(i * 2 + 1) * r * 0.6;
          final double len = r * (0.3 + rnd(40 + i) * 0.35);
          canvas.drawLine(Offset(x, y - len / 2), Offset(x - len * 0.3, y + len / 2), stroke);
        }
      case BrushTipKind.bubbles:
        final Paint stroke = _strokePaint(paint, r * 0.06);
        for (int i = 0; i < 6; i++) {
          final double br = r * (0.1 + rnd(60 + i) * 0.25);
          final double reach = r - br - r * 0.04; // + half the outline width
          final Offset o = Offset(jit(i * 2) * reach, jit(i * 2 + 1) * reach);
          canvas.drawCircle(o, br, stroke);
          canvas.drawCircle(o + Offset(-br * 0.35, -br * 0.35), br * 0.15, paint);
        }
      case BrushTipKind.glitter:
        for (int i = 0; i < 8; i++) {
          final double s = r * (0.1 + rnd(80 + i) * 0.22);
          // Keep each sparkle fully inside the tip circle.
          final Offset o = Offset(
            jit(i * 2) * (r - s),
            jit(i * 2 + 1) * (r - s),
          );
          canvas.drawPath(_sparklePath(o, s), paint);
        }
      case BrushTipKind.fur:
        final Paint stroke = _strokePaint(paint, r * 0.05);
        for (int i = 0; i < 12; i++) {
          // Base + lean stay within ~0.85r so strands don't clip the tile.
          final double bx = jit(i) * r * 0.6;
          final double tipX = bx + jit(30 + i) * r * 0.25;
          final double tipY = -r * (0.4 + rnd(60 + i) * 0.55);
          canvas.drawPath(
            Path()
              ..moveTo(bx, r * 0.7)
              ..quadraticBezierTo(bx, (r * 0.7 + tipY) / 2, tipX, tipY),
            stroke,
          );
        }
      case BrushTipKind.starfield:
        for (int i = 0; i < 7; i++) {
          final double s = r * (0.1 + rnd(90 + i) * 0.2);
          canvas.save();
          canvas.translate(
            jit(i * 2) * (r - s),
            jit(i * 2 + 1) * (r - s),
          );
          canvas.rotate(jit(120 + i) * pi / 5);
          canvas.drawPath(_star(5, s, s * 0.45), paint);
          canvas.restore();
        }
      case BrushTipKind.snowfall:
        for (int i = 0; i < 10; i++) {
          final double dr = r * (0.05 + rnd(70 + i) * 0.11);
          canvas.drawCircle(
            Offset(
              jit(i * 2) * (r - dr),
              jit(i * 2 + 1) * (r - dr),
            ),
            dr,
            paint,
          );
        }
      case BrushTipKind.petals:
        for (int i = 0; i < 6; i++) {
          canvas.save();
          canvas.translate(
            jit(i * 2) * r * 0.75,
            jit(i * 2 + 1) * r * 0.75,
          );
          canvas.rotate(jit(150 + i) * pi);
          final double s = r * (0.16 + rnd(170 + i) * 0.1);
          canvas.drawPath(
            Path()
              ..moveTo(0, -s)
              ..quadraticBezierTo(s * 0.9, -s * 0.2, 0, s)
              ..quadraticBezierTo(-s * 0.9, -s * 0.2, 0, -s)
              ..close(),
            paint,
          );
          canvas.restore();
        }
      case BrushTipKind.heartScatter:
        for (int i = 0; i < 5; i++) {
          final double s = r * (0.15 + rnd(190 + i) * 0.15);
          canvas.save();
          canvas.translate(
            jit(i * 2) * (r - s),
            jit(i * 2 + 1) * (r - s),
          );
          canvas.rotate(jit(210 + i) * 0.5);
          canvas.drawPath(_heart(s), paint);
          canvas.restore();
        }
      default:
        canvas.drawCircle(Offset.zero, r, paint);
    }
  }

  /// Stable well-mixed random in [0, 1] (murmur3 finaliser).
  static double _mixedRand01(int seed, int index, int channel) {
    int h = (seed ^ (index * 0x9E3779B1) ^ (channel * 0x85EBCA77)) & 0xffffffff;
    h ^= h >> 16;
    h = (h * 0x85ebca6b) & 0xffffffff;
    h ^= h >> 13;
    h = (h * 0xc2b2ae35) & 0xffffffff;
    h ^= h >> 16;
    return h / 0xffffffff;
  }

  static Path _poly(List<Offset> pts) {
    final Path p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      p.lineTo(pts[i].dx, pts[i].dy);
    }
    return p..close();
  }

  /// Four-point curved "twinkle" star.
  static Path _sparklePath(Offset c, double r) {
    final double k = r * 0.12;
    return Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + k, c.dy - k, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + k, c.dy + k, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - k, c.dy + k, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - k, c.dy - k, c.dx, c.dy - r)
      ..close();
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

  static final Paint _reusableStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  /// 由填充画笔派生一支描边画笔（雪花、螺旋等线状笔尖用）
  ///
  /// Derive a stroke paint from the fill paint (for line-based tips like
  /// snowflake and spiral)
  static Paint _strokePaint(Paint fill, double width) {
    return _reusableStrokePaint
      ..color = fill.color
      ..strokeWidth = width
      ..maskFilter = fill.maskFilter;
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

  /// 稳定的伪随机抖动 [-1, 1]（纹理类笔尖用，0 内存分配）
  ///
  /// Stable zero-allocation pseudo-random jitter in [-1, 1] (for textured tips)
  static double _jitter(int seed, int index, int channel) {
    int s = (seed + index * 374761393 + channel * 668265263) & 0x7fffffff;
    s = ((s ^ (s >> 13)) * 1274126177) & 0x7fffffff;
    return (s / 0x3fffffff) - 1.0;
  }
}
