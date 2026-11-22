import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';
import 'brush_cache.dart';
import 'freehand_line.dart';

/// 稳定伪随机 [-1,1] / Stable zero-allocation pseudo-random in [-1, 1]
double _rand(int seed, int i, int ch) {
  int s = (seed + i * 374761393 + ch * 668265263) & 0x7fffffff;
  s = ((s ^ (s >> 13)) * 1274126177) & 0x7fffffff;
  return (s / 0x3fffffff) - 1.0;
}

/// 稳定伪随机 [0,1] / Stable pseudo-random in [0, 1]
double _rand01(int seed, int i, int ch) => (_rand(seed, i, ch) + 1) / 2;

/// Well-mixed stable random in [0, 1] (murmur3 finaliser). [_rand] is cheap
/// but adjacent channels correlate, which shows up as diagonal/diamond
/// patterns when thousands of tiny grains are scattered.
double _grainRand01(int seed, int i, int ch) {
  int h = (seed ^ (i * 0x9E3779B1) ^ (ch * 0x85EBCA77)) & 0xffffffff;
  h ^= h >> 16;
  h = (h * 0x85ebca6b) & 0xffffffff;
  h ^= h >> 13;
  h = (h * 0xc2b2ae35) & 0xffffffff;
  h ^= h >> 16;
  return h / 0xffffffff;
}

double _grainRand(int seed, int i, int ch) => _grainRand01(seed, i, ch) * 2 - 1;

Color _lighten(Color c, double amt) {
  final HSLColor h = HSLColor.fromColor(c);
  return h.withLightness((h.lightness + amt).clamp(0.0, 1.0)).toColor();
}

Color _darken(Color c, double amt) {
  final HSLColor h = HSLColor.fromColor(c);
  return h.withLightness((h.lightness - amt).clamp(0.0, 1.0)).toColor();
}

List<Offset> _pointsFromJson(dynamic raw) => (raw as List<dynamic>)
    .map((dynamic e) => jsonToOffset(e as Map<String, dynamic>))
    .toList();

/// 预设笔迹基类
///
/// 提供沿平滑路径行走的工具方法，供各种预设笔刷复用。
///
/// Base class for preset strokes. Provides a helper that walks the smoothed
/// path at a fixed step, handing each sample's tangent, distance and total
/// length to a callback.
abstract class PresetStroke extends FreehandLine {
  PresetStroke({super.minPointDistance});

  PresetStroke.data({super.minPointDistance, required super.points, required super.paint})
      : super.data();

  int get seed {
    if (points.isEmpty) {
      return 1;
    }
    return ((points.first.dx.toInt() * 73856093) ^ (points.first.dy.toInt() * 19349663)) &
        0x7fffffff;
  }

  /// 沿路径行走 / Walk along the smoothed path (O(1) incremental sampling).
  void walk(double step, void Function(ui.Tangent t, double d, double total, int i) fn) {
    final double s = step.clamp(2.0, double.infinity);
    final ChunkedStrokeCache cache = sampleSmooth(s);
    final double total = cache.totalLength;
    int idx = 0;

    final int frozen = cache.frozenCount;
    for (int j = 0; j < frozen; j++) {
      final Offset pos = Offset(cache.xs[j], cache.ys[j]);
      final double ang = cache.angles[j];
      fn(ui.Tangent.fromAngle(pos, ang), cache.distances[j], total, idx++);
    }
    final int tail = cache.tailCount;
    for (int j = 0; j < tail; j++) {
      final Offset pos = Offset(cache.tailXs[j], cache.tailYs[j]);
      final double ang = cache.tailAngles[j];
      fn(ui.Tangent.fromAngle(pos, ang), cache.tailDistances[j], total, idx++);
    }
  }

  /// Same as [walkChunked] but renders an explicit slice `[startSample..endSample)`.
  void walkChunkedRange(
    ui.Canvas canvas,
    ui.Size size,
    double step,
    int extraSig,
    int startSample,
    int? endSample,
    bool includeTail,
    void Function(
      ui.Canvas target,
      double x,
      double y,
      double angle,
      double d,
      int i,
    ) fn,
  ) {
    final double s = step.clamp(2.0, double.infinity);
    final int sig = Object.hash(baseStyleSignature, s, seed, extraSig);
    sampleSmooth(s);
    drawSampleSlice(canvas, size, startSample, endSample, includeTail, sig, (
      ui.Canvas target,
      int startIdx,
      int endIdx,
      bool isTail,
    ) {
      for (int i = startIdx; i < endIdx; i++) {
        fn(
          target,
          strokeCache.getX(i, isTail),
          strokeCache.getY(i, isTail),
          strokeCache.getAngle(i, isTail),
          strokeCache.getDist(i, isTail),
          strokeCache.globalIndex(i, isTail),
        );
      }
    });
  }

  /// Chunked incremental walk for presets whose per-dab visuals depend only on
  /// `(tangent, d, i)` and not global `total` length.
  void walkChunked(
    ui.Canvas canvas,
    ui.Size size,
    double step,
    int extraSig,
    void Function(
      ui.Canvas target,
      double x,
      double y,
      double angle,
      double d,
      int i,
    ) fn,
  ) {
    final double s = step.clamp(2.0, double.infinity);
    final int sig = Object.hash(baseStyleSignature, s, seed, extraSig);
    drawChunkedSamples(canvas, size, s, sig, (
      ui.Canvas target,
      int startIdx,
      int endIdx,
      bool isTail,
    ) {
      for (int i = startIdx; i < endIdx; i++) {
        fn(
          target,
          strokeCache.getX(i, isTail),
          strokeCache.getY(i, isTail),
          strokeCache.getAngle(i, isTail),
          strokeCache.getDist(i, isTail),
          strokeCache.globalIndex(i, isTail),
        );
      }
    });
  }

  /// 路径法线方向 / Normal direction of the path at a tangent
  Offset normalOf(ui.Tangent t) => Offset(-sin(t.angle), cos(t.angle));

  /// 路径切线方向 / Tangent direction
  Offset dirOf(ui.Tangent t) => Offset(cos(t.angle), sin(t.angle));
}

// ---------------------------------------------------------------------------
// 钢笔类 / Pen family
// ---------------------------------------------------------------------------

/// 断续钢笔（Pen Choppy）：边缘呈规律扇贝状起伏的实线
///
/// Choppy pen: a solid line whose edge undulates in a regular scalloped rhythm.
class ChoppyLine extends PresetStroke {
  ChoppyLine({super.minPointDistance});

  ChoppyLine.data({super.minPointDistance, required super.points, required super.paint})
      : super.data();

  factory ChoppyLine.fromJson(Map<String, dynamic> d) => ChoppyLine.data(
        minPointDistance: (d['minPointDistance'] ?? 2.0) as double,
        points: _pointsFromJson(d['points']),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  String get contentType => 'ChoppyLine';

  @override
  void draw(ui.Canvas canvas, ui.Size size, bool deeper) {
    if (points.isEmpty) {
      return;
    }
    final double w = paint.strokeWidth;
    final Paint fill = paint.copyWith(style: PaintingStyle.fill);
    if (points.length == 1) {
      canvas.drawCircle(points.first, w / 2, fill);
      return;
    }
    walk(w * 0.12, (ui.Tangent t, double d, double total, int i) {
      final double scale = 1 + 0.2 * sin(d / (w * 0.45));
      canvas.drawCircle(t.position, (w / 2) * scale, fill);
    });
  }

  @override
  ChoppyLine copy() => ChoppyLine.data(
        minPointDistance: minPointDistance,
        points: List<Offset>.from(points),
        paint: paint.copyWith(),
      );

  @override
  Map<String, dynamic> toContentJson() => baseJson();
}

/// 粗糙钢笔（Rough Pen）：边缘随机破碎的实线
///
/// Rough pen: a solid line with a randomly broken, ragged edge.
class RoughPenLine extends PresetStroke {
  RoughPenLine({super.minPointDistance});

  RoughPenLine.data({super.minPointDistance, required super.points, required super.paint})
      : super.data();

  factory RoughPenLine.fromJson(Map<String, dynamic> d) => RoughPenLine.data(
        minPointDistance: (d['minPointDistance'] ?? 2.0) as double,
        points: _pointsFromJson(d['points']),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  String get contentType => 'RoughPenLine';

  @override
  void draw(ui.Canvas canvas, ui.Size size, bool deeper) {
    if (points.isEmpty) {
      return;
    }
    final double w = paint.strokeWidth;
    final Paint fill = paint.copyWith(style: PaintingStyle.fill);
    if (points.length == 1) {
      canvas.drawCircle(points.first, w / 2, fill);
      return;
    }
    walk(w * 0.12, (ui.Tangent t, double d, double total, int i) {
      final double r = (w / 2) * (0.7 + _rand01(seed, i, 1) * 0.5);
      final Offset off = normalOf(t) * (_rand(seed, i, 2) * w * 0.14);
      canvas.drawCircle(t.position + off, r, fill);
    });
  }

  @override
  RoughPenLine copy() => RoughPenLine.data(
        minPointDistance: minPointDistance,
        points: List<Offset>.from(points),
        paint: paint.copyWith(),
      );

  @override
  Map<String, dynamic> toContentJson() => baseJson();
}

/// 墨线（Ink / Dip Pen）：两端收笔的锥形线条，可选起笔墨点
///
/// Ink line: a tapered stroke, optionally with an ink blob at the start
/// (dip-pen style).
class InkLine extends PresetStroke {
  InkLine({super.minPointDistance, this.startBlob = false, this.endTaper = 0.8});

  InkLine.data({
    super.minPointDistance,
    this.startBlob = false,
    this.endTaper = 0.8,
    required super.points,
    required super.paint,
  }) : super.data();

  factory InkLine.fromJson(Map<String, dynamic> d) => InkLine.data(
        minPointDistance: (d['minPointDistance'] ?? 2.0) as double,
        startBlob: (d['startBlob'] ?? false) as bool,
        endTaper: (d['endTaper'] ?? 0.8) as double,
        points: _pointsFromJson(d['points']),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  /// 起笔是否有墨点 / Whether an ink blob starts the stroke
  final bool startBlob;

  /// 收笔变细的程度 / How much the stroke thins toward the end
  final double endTaper;

  @override
  String get contentType => 'InkLine';

  @override
  void draw(ui.Canvas canvas, ui.Size size, bool deeper) {
    if (points.isEmpty) {
      return;
    }
    final double w = paint.strokeWidth;
    final Paint fill = paint.copyWith(style: PaintingStyle.fill);
    if (points.length == 1) {
      canvas.drawCircle(points.first, w / 2, fill);
      return;
    }
    walk(w * 0.1, (ui.Tangent t, double d, double total, int i) {
      final double x = total <= 0 ? 0 : d / total;
      final double prof = (1 - endTaper * x).clamp(0.12, 1.0);
      canvas.drawCircle(t.position, (w / 2) * prof, fill);
      if (startBlob && x < 0.05) {
        canvas.drawCircle(t.position, (w / 2) * 1.35, fill);
      }
    });
  }

  @override
  InkLine copy() => InkLine.data(
        minPointDistance: minPointDistance,
        startBlob: startBlob,
        endTaper: endTaper,
        points: List<Offset>.from(points),
        paint: paint.copyWith(),
      );

  @override
  Map<String, dynamic> toContentJson() =>
      <String, dynamic>{...baseJson(), 'startBlob': startBlob, 'endTaper': endTaper};
}

// ---------------------------------------------------------------------------
// 铅笔 / 蜡笔 / 颗粒类 / Pencil, crayon and grain family
// ---------------------------------------------------------------------------

/// 石墨/蜡质颗粒笔迹（Pencil / Crayon / Grain）
///
/// 沿笔迹撒下大量细小颗粒，通过 [density]（密度）、[opacity]（浓淡）、
/// [spread]（横向散布）、[speck]（颗粒大小）可模拟 H / HB / 6B 铅笔、蜡笔与颗粒笔。
///
/// Graphite / waxy grain stroke. Scatters many fine specks along the path;
/// [density], [opacity], [spread] and [speck] reproduce H / HB / 6B pencils,
/// crayon and grain brushes.
class PencilLine extends PresetStroke {
  PencilLine({
    super.minPointDistance,
    this.density = 10,
    this.opacity = 0.55,
    this.spread = 1.0,
    this.speck = 0.09,
    this.core = 0.4,
  });

  PencilLine.data({
    super.minPointDistance,
    this.density = 10,
    this.opacity = 0.55,
    this.spread = 1.0,
    this.speck = 0.09,
    this.core = 0.4,
    required super.points,
    required super.paint,
  }) : super.data();

  factory PencilLine.fromJson(Map<String, dynamic> d) => PencilLine.data(
        minPointDistance: (d['minPointDistance'] ?? 2.0) as double,
        density: (d['density'] ?? 10) as int,
        opacity: (d['opacity'] ?? 0.55) as double,
        spread: (d['spread'] ?? 1.0) as double,
        speck: (d['speck'] ?? 0.09) as double,
        core: d['core'] != null
            ? (d['core'] as num).toDouble()
            : _legacyCoreFor(d),
        points: _pointsFromJson(d['points']),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  /// Strokes saved before `core` existed: the "Speckled Grain" preset
  /// (density 18, spread 1.3) is pure speckle, every other pencil gets a core.
  static double _legacyCoreFor(Map<String, dynamic> d) {
    final num? density = d['density'] as num?;
    final num? spread = d['spread'] as num?;
    if (density == 18 && spread != null && (spread - 1.3).abs() < 1e-6) {
      return 0;
    }
    return 0.4;
  }

  /// 每步撒下的颗粒数 / Specks per step
  final int density;

  /// 整体浓淡 / Overall darkness
  final double opacity;

  /// 横向散布（相对粗细）/ Lateral spread relative to width
  final double spread;

  /// 颗粒大小（相对粗细）/ Speck size relative to width
  final double speck;

  /// 实心笔芯浓度（0 = 纯颗粒）/ Strength of the continuous graphite core
  /// relative to [opacity]. 0 disables the core (pure speckle brushes).
  final double core;

  @override
  String get contentType => 'PencilLine';

  @override
  bool get supportsActiveRangeBaking => true;

  @override
  void drawCommittedRange(ui.Canvas canvas, ui.Size size, int startSample, int endSample) {
    // Baked prefix holds grain only; the continuous core is redrawn whole by
    // [drawLiveFromSample] so it never gets split at bake boundaries.
    _drawPencilRange(
      canvas,
      size,
      startSample,
      endSample,
      includeTail: false,
      drawCore: false,
    );
  }

  @override
  void drawLiveFromSample(ui.Canvas canvas, ui.Size size, int startSample) {
    _drawPencilRange(
      canvas,
      size,
      startSample,
      null,
      includeTail: true,
      drawCore: true,
    );
  }

  @override
  void draw(ui.Canvas canvas, ui.Size size, bool deeper) {
    if (points.isEmpty) {
      return;
    }
    _drawPencilRange(canvas, size, 0, null, includeTail: true, drawCore: true);
  }

  void _drawPencilRange(
    ui.Canvas canvas,
    ui.Size size,
    int startSample,
    int? endSample, {
    required bool includeTail,
    required bool drawCore,
  }) {
    if (points.isEmpty) return;
    final double w = paint.strokeWidth;
    if (w <= 0) return;

    // A real pencil stroke is a soft continuous graphite core with fine grain
    // on top. Grains stay tiny (≈1–2 px) at every brush size and their count
    // scales with the covered area, so wide strokes get *more* grain instead
    // of bigger, sparser dots.
    final double step = (w * 0.3).clamp(2.0, double.infinity);
    final double baseAlpha = (paint.color.a * opacity).clamp(0.0, 1.0);
    final Color baseCol = paint.color;
    final int curSeed = seed;
    final double grainR = (0.35 + w * speck * 0.3).clamp(0.4, 1.1);
    final double halfSpread = w * spread * 0.5;
    final double coverage = (density / 24.0).clamp(0.25, 0.8);
    final int grainsPerSample =
        (coverage * (2 * halfSpread * step) / (pi * grainR * grainR))
            .ceil()
            .clamp(1, 200);
    final double coreAlpha = (baseAlpha * core).clamp(0.0, 1.0);

    // Copy the user's paint so shaders, mask/colour/image filters survive.
    // The core is ONE continuous path (round joins, no self-overlap), so
    // curves get neither outer gaps nor darker inner overlap stripes.
    if (drawCore && coreAlpha > 0) {
      final Paint corePaint = paint.copyWith(
        style: PaintingStyle.stroke,
        strokeWidth: w * 0.55,
        strokeCap: StrokeCap.round,
        strokeJoin: StrokeJoin.round,
        color: baseCol.withValues(alpha: coreAlpha),
      );
      if (points.length < 2) {
        if (includeTail) {
          canvas.drawCircle(
            points.first,
            w * 0.275,
            paint.copyWith(
              style: PaintingStyle.fill,
              color: corePaint.color,
            ),
          );
        }
      } else {
        canvas.drawPath(buildSmoothPath(), corePaint);
      }
    }

    final Paint grainPaint = paint.copyWith(
      style: PaintingStyle.stroke,
      strokeCap: StrokeCap.round,
      strokeWidth: grainR * 2,
    );

    // Grains are batched into a few alpha buckets → 3 draw calls per range
    // instead of one drawCircle per speck.
    const List<double> bucketAlpha = <double>[0.35, 0.65, 1.0];
    final List<List<double>> buckets =
        <List<double>>[<double>[], <double>[], <double>[]];

    void emitGrains(double x, double y, double angle, int i) {
      // Flutter's `Tangent.angle` is `-atan2(dy, dx)` (y flipped), so the
      // direction vector is (cos, -sin). Using +sin mirrors the normal and
      // makes grain spread *along* diagonal strokes instead of across them.
      final double dx = cos(angle);
      final double dy = -sin(angle);
      for (int k = 0; k < grainsPerSample; k++) {
        final int ch = k * 4;
        // Triangular distribution: denser graphite toward the stroke centre.
        final double off =
            (_grainRand(curSeed, i, ch) + _grainRand(curSeed, i, ch + 1)) *
                0.5 *
                halfSpread;
        final double along = _grainRand(curSeed, i, ch + 2) * step * 0.5;
        final int b = (_grainRand01(curSeed, i, ch + 3) * 2.999).floor();
        buckets[b]
          ..add(x - dy * off + dx * along)
          ..add(y + dx * off + dy * along);
      }
    }

    void flushGrains(ui.Canvas target) {
      for (int b = 0; b < buckets.length; b++) {
        if (buckets[b].isEmpty) continue;
        grainPaint.color = baseCol.withValues(alpha: baseAlpha * bucketAlpha[b]);
        target.drawRawPoints(
          ui.PointMode.points,
          Float32List.fromList(buckets[b]),
          grainPaint,
        );
        buckets[b].clear();
      }
    }

    if (points.length < 2) {
      if (!includeTail) return;
      final Offset p0 = points.first;
      emitGrains(p0.dx, p0.dy, 0, 0);
      flushGrains(canvas);
      return;
    }

    sampleSmooth(step);
    final ChunkedStrokeCache c = strokeCache;
    final int sig = Object.hash(
      baseStyleSignature,
      step,
      curSeed,
      Object.hash(density, opacity, spread, speck, 'pencil-v5'),
    );
    drawSampleSlice(canvas, size, startSample, endSample, includeTail, sig, (
      ui.Canvas target,
      int startIdx,
      int endIdx,
      bool isTail,
    ) {
      for (int j = startIdx; j < endIdx; j++) {
        emitGrains(
          c.getX(j, isTail),
          c.getY(j, isTail),
          c.getAngle(j, isTail),
          c.globalIndex(j, isTail),
        );
      }
      flushGrains(target);
    });
  }

  @override
  PencilLine copy() => PencilLine.data(
        minPointDistance: minPointDistance,
        density: density,
        opacity: opacity,
        spread: spread,
        speck: speck,
        core: core,
        points: List<Offset>.from(points),
        paint: paint.copyWith(),
      );

  @override
  Map<String, dynamic> toContentJson() => <String, dynamic>{
        ...baseJson(),
        'density': density,
        'opacity': opacity,
        'spread': spread,
        'speck': speck,
        'core': core,
      };
}

// ---------------------------------------------------------------------------
// 网点 / 排线 / Halftone and hatching
// ---------------------------------------------------------------------------

/// 网点笔迹（Halftone）：沿笔迹排列成网格的圆点带
///
/// Halftone stroke: a band of grid-aligned dots following the path.
class HalftoneLine extends PresetStroke {
  HalftoneLine({super.minPointDistance, this.gridRatio = 0.34});

  HalftoneLine.data({
    super.minPointDistance,
    this.gridRatio = 0.34,
    required super.points,
    required super.paint,
  }) : super.data();

  factory HalftoneLine.fromJson(Map<String, dynamic> d) => HalftoneLine.data(
        minPointDistance: (d['minPointDistance'] ?? 2.0) as double,
        gridRatio: (d['gridRatio'] ?? 0.34) as double,
        points: _pointsFromJson(d['points']),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  /// 网格间距（相对粗细）/ Grid spacing relative to width
  final double gridRatio;

  @override
  String get contentType => 'HalftoneLine';

  @override
  void draw(ui.Canvas canvas, ui.Size size, bool deeper) {
    if (points.length < 2) {
      return;
    }
    final double w = paint.strokeWidth;
    final double g = (w * gridRatio).clamp(1.5, double.infinity);
    final Paint fill = paint.copyWith(style: PaintingStyle.fill);
    final int lanes = (w * 0.55 / g).floor();

    walk(g, (ui.Tangent t, double d, double total, int i) {
      final Offset n = normalOf(t);
      for (int k = -lanes; k <= lanes; k++) {
        canvas.drawCircle(t.position + n * (k * g), g * 0.28, fill);
      }
    });
  }

  @override
  HalftoneLine copy() => HalftoneLine.data(
        minPointDistance: minPointDistance,
        gridRatio: gridRatio,
        points: List<Offset>.from(points),
        paint: paint.copyWith(),
      );

  @override
  Map<String, dynamic> toContentJson() =>
      <String, dynamic>{...baseJson(), 'gridRatio': gridRatio};
}

/// 排线笔迹（Halftone Hatch）：沿笔迹重复的斜向短线
///
/// Hatch stroke: repeating diagonal strokes along the path. [rightward]
/// switches between "/" and "\" hatching.
class HatchLine extends PresetStroke {
  HatchLine({super.minPointDistance, this.rightward = true});

  HatchLine.data({
    super.minPointDistance,
    this.rightward = true,
    required super.points,
    required super.paint,
  }) : super.data();

  factory HatchLine.fromJson(Map<String, dynamic> d) => HatchLine.data(
        minPointDistance: (d['minPointDistance'] ?? 2.0) as double,
        rightward: (d['rightward'] ?? true) as bool,
        points: _pointsFromJson(d['points']),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  /// true 为 “/” 方向，false 为 “\” 方向 / true = "/", false = "\"
  final bool rightward;

  @override
  String get contentType => 'HatchLine';

  @override
  void draw(ui.Canvas canvas, ui.Size size, bool deeper) {
    if (points.length < 2) {
      return;
    }
    final double w = paint.strokeWidth;
    final Paint line = paint.copyWith(
      style: PaintingStyle.stroke,
      strokeWidth: (w * 0.12).clamp(1.0, double.infinity),
      strokeCap: StrokeCap.butt,
    );
    final double inv = 1 / sqrt(2);
    final Offset dir = rightward ? Offset(inv, -inv) : Offset(inv, inv);
    final double half = w * 0.6;

    walk(w * 0.3, (ui.Tangent t, double d, double total, int i) {
      canvas.drawLine(t.position - dir * half, t.position + dir * half, line);
    });
  }

  @override
  HatchLine copy() => HatchLine.data(
        minPointDistance: minPointDistance,
        rightward: rightward,
        points: List<Offset>.from(points),
        paint: paint.copyWith(),
      );

  @override
  Map<String, dynamic> toContentJson() =>
      <String, dynamic>{...baseJson(), 'rightward': rightward};
}

// ---------------------------------------------------------------------------
// 方块 / 马赛克 / Blocks and mosaic
// ---------------------------------------------------------------------------

/// 马赛克笔迹（Mosaic）：网格方块，每格明度随机变化
///
/// Mosaic stroke: grid-snapped tiles whose lightness varies per cell.
class MosaicLine extends PresetStroke {
  MosaicLine({super.minPointDistance});

  MosaicLine.data({super.minPointDistance, required super.points, required super.paint})
      : super.data();

  factory MosaicLine.fromJson(Map<String, dynamic> d) => MosaicLine.data(
        minPointDistance: (d['minPointDistance'] ?? 2.0) as double,
        points: _pointsFromJson(d['points']),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  String get contentType => 'MosaicLine';

  @override
  void draw(ui.Canvas canvas, ui.Size size, bool deeper) {
    if (points.isEmpty) {
      return;
    }
    final double cell = paint.strokeWidth.clamp(2.0, double.infinity);
    final Set<int> seen = <int>{};
    final Paint cellPaint = paint.copyWith(style: PaintingStyle.fill);

    void put(Offset p) {
      final int cx = (p.dx / cell).floor();
      final int cy = (p.dy / cell).floor();
      final int key = (cx * 73856093) ^ (cy * 19349663);
      if (!seen.add(key)) {
        return;
      }
      final double t = _rand01(seed, key & 0xffff, 9);
      final Color col = t > 0.5 ? _lighten(paint.color, (t - 0.5) * 0.5) : _darken(paint.color, (0.5 - t) * 0.4);
      cellPaint.color = col;
      canvas.drawRect(
        Rect.fromLTWH(cx * cell, cy * cell, cell, cell),
        cellPaint,
      );
    }

    if (points.length == 1) {
      put(points.first);
      return;
    }
    walk(cell / 2, (ui.Tangent t, double d, double total, int i) => put(t.position));
  }

  @override
  MosaicLine copy() => MosaicLine.data(
        minPointDistance: minPointDistance,
        points: List<Offset>.from(points),
        paint: paint.copyWith(),
      );

  @override
  Map<String, dynamic> toContentJson() => baseJson();
}

// ---------------------------------------------------------------------------
// 3D 立体类 / 3D styles
// ---------------------------------------------------------------------------

/// 立体笔迹（3D Brush）：用径向渐变模拟受光的圆管
///
/// 3D tube stroke: each dab is shaded with a radial gradient (highlight toward
/// the upper-left) so the stroke reads as a lit cylinder.
class TubeLine extends PresetStroke {
  TubeLine({super.minPointDistance});

  TubeLine.data({super.minPointDistance, required super.points, required super.paint})
      : super.data();

  factory TubeLine.fromJson(Map<String, dynamic> d) => TubeLine.data(
        minPointDistance: (d['minPointDistance'] ?? 2.0) as double,
        points: _pointsFromJson(d['points']),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  String get contentType => 'TubeLine';

  /// 生成立体质感的画笔 / Build the shaded dab paint
  Paint shadedDab(Offset center, double r, Color base) {
    return Paint()
      ..isAntiAlias = true
      ..shader = ui.Gradient.radial(
        center + Offset(-r * 0.35, -r * 0.35),
        r * 1.6,
        <Color>[_lighten(base, 0.34), base, _darken(base, 0.26)],
        <double>[0.0, 0.55, 1.0],
      );
  }

  @override
  bool get supportsActiveRangeBaking => true;

  @override
  void drawCommittedRange(ui.Canvas canvas, ui.Size size, int startSample, int endSample) {
    _drawRange(canvas, size, startSample, endSample, includeTail: false);
  }

  @override
  void drawLiveFromSample(ui.Canvas canvas, ui.Size size, int startSample) {
    _drawRange(canvas, size, startSample, null, includeTail: true);
  }

  @override
  void draw(ui.Canvas canvas, ui.Size size, bool deeper) {
    if (points.isEmpty) {
      return;
    }
    if (points.length == 1) {
      final double w = paint.strokeWidth;
      final double r = w / 2;
      if (r <= 0) return;
      final ui.Image? sphere = ProceduralStampCaches.getShadedSphereStamp(paint.color);
      if (sphere == null) {
        canvas.drawCircle(points.first, r, shadedDab(points.first, r, paint.color));
        return;
      }
      const double tileS = ProceduralStampCaches.sphereTileSize;
      AtlasStampDrawer.drawBatch(
        canvas: canvas,
        stamp: sphere,
        srcSize: tileS,
        targetRadius: r,
        stampRefRadius: (tileS * 0.5) - 1.0,
        xs: <double>[points.first.dx],
        ys: <double>[points.first.dy],
        angles: const <double>[0.0],
      );
      return;
    }
    _drawRange(canvas, size, 0, null, includeTail: true);
  }

  void _drawRange(
    ui.Canvas canvas,
    ui.Size size,
    int startSample,
    int? endSample, {
    required bool includeTail,
  }) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      if (includeTail) draw(canvas, size, false);
      return;
    }
    final double w = paint.strokeWidth;
    final double r = w / 2;
    if (r <= 0) return;
    final ui.Image? sphere = ProceduralStampCaches.getShadedSphereStamp(paint.color);
    if (sphere == null) {
      walk(w * 0.12, (ui.Tangent t, double d, double total, int i) {
        canvas.drawCircle(t.position, r, shadedDab(t.position, r, paint.color));
      });
      return;
    }

    const double tileS = ProceduralStampCaches.sphereTileSize;
    final double refR = (tileS * 0.5) - 1.0;
    final double step = (w * 0.12).clamp(2.0, double.infinity);
    final ChunkedStrokeCache cache = sampleSmooth(step);

    final int safeStart = startSample.clamp(0, cache.frozenCount);
    final int safeEnd = (endSample ?? cache.frozenCount).clamp(safeStart, cache.frozenCount);
    if (safeStart < safeEnd) {
      AtlasStampDrawer.drawBatch(
        canvas: canvas,
        stamp: sphere,
        srcSize: tileS,
        targetRadius: r,
        stampRefRadius: refR,
        xs: cache.xs,
        ys: cache.ys,
        angles: List<double>.filled(cache.frozenCount, 0.0, growable: false),
        start: safeStart,
        end: safeEnd,
      );
    }
    if (includeTail && cache.tailCount > 0) {
      AtlasStampDrawer.drawBatch(
        canvas: canvas,
        stamp: sphere,
        srcSize: tileS,
        targetRadius: r,
        stampRefRadius: refR,
        xs: cache.tailXs,
        ys: cache.tailYs,
        angles: List<double>.filled(cache.tailCount, 0.0, growable: false),
      );
    }
  }

  @override
  TubeLine copy() => TubeLine.data(
        minPointDistance: minPointDistance,
        points: List<Offset>.from(points),
        paint: paint.copyWith(),
      );

  @override
  Map<String, dynamic> toContentJson() => baseJson();
}

/// 糖果拐杖（3D Candy Cane）：立体圆管 + 交替的白色条纹
///
/// Candy cane stroke: the 3D tube with alternating white stripes banded along
/// the path.
class CandyCaneLine extends TubeLine {
  CandyCaneLine({super.minPointDistance});

  CandyCaneLine.data({super.minPointDistance, required super.points, required super.paint})
      : super.data();

  factory CandyCaneLine.fromJson(Map<String, dynamic> d) => CandyCaneLine.data(
        minPointDistance: (d['minPointDistance'] ?? 2.0) as double,
        points: _pointsFromJson(d['points']),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  String get contentType => 'CandyCaneLine';

  @override
  bool get supportsActiveRangeBaking => true;

  @override
  void drawCommittedRange(ui.Canvas canvas, ui.Size size, int startSample, int endSample) {
    _drawCandyRange(canvas, size, startSample, endSample, includeTail: false);
  }

  @override
  void drawLiveFromSample(ui.Canvas canvas, ui.Size size, int startSample) {
    _drawCandyRange(canvas, size, startSample, null, includeTail: true);
  }

  @override
  void draw(ui.Canvas canvas, ui.Size size, bool deeper) {
    if (points.isEmpty) {
      return;
    }
    if (points.length == 1) {
      final double w = paint.strokeWidth;
      final double r = w / 2;
      if (r <= 0) return;
      final ui.Image? primarySphere =
          ProceduralStampCaches.getShadedSphereStamp(paint.color);
      if (primarySphere == null) {
        canvas.drawCircle(points.first, r, shadedDab(points.first, r, paint.color));
        return;
      }
      const double tileS = ProceduralStampCaches.sphereTileSize;
      AtlasStampDrawer.drawBatch(
        canvas: canvas,
        stamp: primarySphere,
        srcSize: tileS,
        targetRadius: r,
        stampRefRadius: (tileS * 0.5) - 1.0,
        xs: <double>[points.first.dx],
        ys: <double>[points.first.dy],
        angles: const <double>[0.0],
      );
      return;
    }
    _drawCandyRange(canvas, size, 0, null, includeTail: true);
  }

  void _drawCandyRange(
    ui.Canvas canvas,
    ui.Size size,
    int startSample,
    int? endSample, {
    required bool includeTail,
  }) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      if (includeTail) draw(canvas, size, false);
      return;
    }
    final double w = paint.strokeWidth;
    final double r = w / 2;
    if (r <= 0) return;
    final double stripe = (w * 0.85).clamp(2.0, double.infinity);
    final double step = (w * 0.1).clamp(2.0, double.infinity);

    final ui.Image? primarySphere =
        ProceduralStampCaches.getShadedSphereStamp(paint.color);
    final ui.Image? whiteSphere =
        ProceduralStampCaches.getShadedSphereStamp(const Color(0xFFFFFFFF));

    if (primarySphere == null || whiteSphere == null) {
      walkChunkedRange(canvas, size, step, 0, startSample, endSample, includeTail, (
        ui.Canvas target,
        double x,
        double y,
        double angle,
        double d,
        int i,
      ) {
        final bool white = (d / stripe).floor().isOdd;
        final Color base = white ? const Color(0xFFFFFFFF) : paint.color;
        final Offset pos = Offset(x, y);
        target.drawCircle(pos, r, shadedDab(pos, r, base));
      });
      return;
    }

    const double tileS = ProceduralStampCaches.sphereTileSize;
    final double refR = (tileS * 0.5) - 1.0;
    final int sig = Object.hash(baseStyleSignature, stripe);
    sampleSmooth(step);
    drawSampleSlice(canvas, size, startSample, endSample, includeTail, sig, (
      ui.Canvas target,
      int startIdx,
      int endIdx,
      bool isTail,
    ) {
      final Paint imgPaint = Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.low;
      const Rect srcRect = Rect.fromLTWH(0, 0, tileS, tileS);
      final double drawDiameter = (tileS * r) / refR;
      for (int i = startIdx; i < endIdx; i++) {
        final double d = strokeCache.getDist(i, isTail);
        final bool white = (d / stripe).floor().isOdd;
        final ui.Image img = white ? whiteSphere : primarySphere;
        target.drawImageRect(
          img,
          srcRect,
          Rect.fromCenter(
            center: Offset(strokeCache.getX(i, isTail), strokeCache.getY(i, isTail)),
            width: drawDiameter,
            height: drawDiameter,
          ),
          imgPaint,
        );
      }
    });
  }

  @override
  CandyCaneLine copy() => CandyCaneLine.data(
        minPointDistance: minPointDistance,
        points: List<Offset>.from(points),
        paint: paint.copyWith(),
      );
}

// ---------------------------------------------------------------------------
// 装饰 / 多彩类 / Decorative and multi-color
// ---------------------------------------------------------------------------

/// 星光笔迹（Sparkles）：散布的四角星闪光
///
/// Sparkles stroke: four-point star glints scattered around the path.
class SparklesLine extends PresetStroke {
  SparklesLine({super.minPointDistance});

  SparklesLine.data({super.minPointDistance, required super.points, required super.paint})
      : super.data();

  factory SparklesLine.fromJson(Map<String, dynamic> d) => SparklesLine.data(
        minPointDistance: (d['minPointDistance'] ?? 2.0) as double,
        points: _pointsFromJson(d['points']),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  String get contentType => 'SparklesLine';

  Path _sparkle(double s) => Path()
    ..moveTo(0, -s)
    ..quadraticBezierTo(0, 0, s, 0)
    ..quadraticBezierTo(0, 0, 0, s)
    ..quadraticBezierTo(0, 0, -s, 0)
    ..quadraticBezierTo(0, 0, 0, -s)
    ..close();

  @override
  void draw(ui.Canvas canvas, ui.Size size, bool deeper) {
    if (points.length < 2) {
      return;
    }
    final double w = paint.strokeWidth;
    final Paint fill = paint.copyWith(style: PaintingStyle.fill);

    walk(w * 0.85, (ui.Tangent t, double d, double total, int i) {
      for (int k = 0; k < 2; k++) {
        final Offset off =
            Offset(_rand(seed, i, k * 2) * w * 1.2, _rand(seed, i, k * 2 + 1) * w * 1.2);
        final double s = w * (0.22 + _rand01(seed, i, 70 + k) * 0.5);
        canvas.save();
        canvas.translate(t.position.dx + off.dx, t.position.dy + off.dy);
        canvas.rotate(_rand(seed, i, 90 + k) * pi);
        canvas.drawPath(_sparkle(s), fill);
        canvas.restore();
      }
    });
  }

  @override
  SparklesLine copy() => SparklesLine.data(
        minPointDistance: minPointDistance,
        points: List<Offset>.from(points),
        paint: paint.copyWith(),
      );

  @override
  Map<String, dynamic> toContentJson() => baseJson();
}

/// 彩针笔迹（Sprinkles）：散布的彩色小短棒
///
/// Sprinkles stroke: small rotated dashes scattered in random bright colors.
class SprinklesLine extends PresetStroke {
  SprinklesLine({super.minPointDistance});

  SprinklesLine.data({super.minPointDistance, required super.points, required super.paint})
      : super.data();

  factory SprinklesLine.fromJson(Map<String, dynamic> d) => SprinklesLine.data(
        minPointDistance: (d['minPointDistance'] ?? 2.0) as double,
        points: _pointsFromJson(d['points']),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  String get contentType => 'SprinklesLine';

  @override
  bool get supportsActiveRangeBaking => true;

  @override
  void drawCommittedRange(ui.Canvas canvas, ui.Size size, int startSample, int endSample) {
    _drawSprinklesRange(canvas, size, startSample, endSample, includeTail: false);
  }

  @override
  void drawLiveFromSample(ui.Canvas canvas, ui.Size size, int startSample) {
    _drawSprinklesRange(canvas, size, startSample, null, includeTail: true);
  }

  @override
  void draw(ui.Canvas canvas, ui.Size size, bool deeper) {
    _drawSprinklesRange(canvas, size, 0, null, includeTail: true);
  }

  void _drawSprinklesRange(
    ui.Canvas canvas,
    ui.Size size,
    int startSample,
    int? endSample, {
    required bool includeTail,
  }) {
    if (points.length < 2) {
      return;
    }
    final double w = paint.strokeWidth;
    final int curSeed = seed;
    final Paint workPaint = Paint()..isAntiAlias = true;
    final RRect pill = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: w * 0.5, height: w * 0.17),
      Radius.circular(w * 0.09),
    );

    walkChunkedRange(canvas, size, w * 0.6, 0, startSample, endSample, includeTail, (
      ui.Canvas target,
      double x,
      double y,
      double angle,
      double d,
      int i,
    ) {
      for (int k = 0; k < 2; k++) {
        final double ox = _rand(curSeed, i, k * 2) * w * 1.1;
        final double oy = _rand(curSeed, i, k * 2 + 1) * w * 1.1;
        workPaint.color =
            HSVColor.fromAHSV(1, _rand01(curSeed, i, 60 + k) * 360, 0.85, 1)
                .toColor();
        target.save();
        target.translate(x + ox, y + oy);
        target.rotate(_rand(curSeed, i, 120 + k) * pi);
        target.drawRRect(pill, workPaint);
        target.restore();
      }
    });
  }

  @override
  SprinklesLine copy() => SprinklesLine.data(
        minPointDistance: minPointDistance,
        points: List<Offset>.from(points),
        paint: paint.copyWith(),
      );

  @override
  Map<String, dynamic> toContentJson() => baseJson();
}

/// 噪点笔迹（Static）：随机彩色/黑色方块
///
/// Static stroke: random colored and black blocks, like TV static.
class StaticLine extends PresetStroke {
  StaticLine({super.minPointDistance});

  StaticLine.data({super.minPointDistance, required super.points, required super.paint})
      : super.data();

  factory StaticLine.fromJson(Map<String, dynamic> d) => StaticLine.data(
        minPointDistance: (d['minPointDistance'] ?? 2.0) as double,
        points: _pointsFromJson(d['points']),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  String get contentType => 'StaticLine';

  @override
  bool get supportsActiveRangeBaking => true;

  @override
  void drawCommittedRange(ui.Canvas canvas, ui.Size size, int startSample, int endSample) {
    _drawStaticRange(canvas, size, startSample, endSample, includeTail: false);
  }

  @override
  void drawLiveFromSample(ui.Canvas canvas, ui.Size size, int startSample) {
    _drawStaticRange(canvas, size, startSample, null, includeTail: true);
  }

  @override
  void draw(ui.Canvas canvas, ui.Size size, bool deeper) {
    _drawStaticRange(canvas, size, 0, null, includeTail: true);
  }

  void _drawStaticRange(
    ui.Canvas canvas,
    ui.Size size,
    int startSample,
    int? endSample, {
    required bool includeTail,
  }) {
    if (points.length < 2) {
      return;
    }
    final double w = paint.strokeWidth;
    final int curSeed = seed;
    final Paint workPaint = Paint();

    walkChunkedRange(canvas, size, w * 0.5, 0, startSample, endSample, includeTail, (
      ui.Canvas target,
      double x,
      double y,
      double angle,
      double d,
      int i,
    ) {
      for (int k = 0; k < 2; k++) {
        final Offset off =
            Offset(_rand(curSeed, i, k * 2) * w * 1.1, _rand(curSeed, i, k * 2 + 1) * w * 0.9);
        final double pick = _rand01(curSeed, i, 40 + k);
        workPaint.color = pick < 0.4
            ? const Color(0xFF000000)
            : HSVColor.fromAHSV(1, _rand01(curSeed, i, 80 + k) * 360, 0.9, 1).toColor();
        target.drawRect(
          Rect.fromCenter(
            center: Offset(x + off.dx, y + off.dy),
            width: w * (0.45 + _rand01(curSeed, i, 140 + k) * 0.8),
            height: w * 0.32,
          ),
          workPaint,
        );
      }
    });
  }

  @override
  StaticLine copy() => StaticLine.data(
        minPointDistance: minPointDistance,
        points: List<Offset>.from(points),
        paint: paint.copyWith(),
      );

  @override
  Map<String, dynamic> toContentJson() => baseJson();
}

// ---------------------------------------------------------------------------
// 新增特色笔刷 / Brand New Signature Preset Strokes
// ---------------------------------------------------------------------------

/// 霓虹辉光笔迹（Neon Glow）：多层高斯发光与高亮内芯
class NeonGlowLine extends PresetStroke {
  NeonGlowLine({super.minPointDistance});

  NeonGlowLine.data({super.minPointDistance, required super.points, required super.paint})
      : super.data();

  factory NeonGlowLine.fromJson(Map<String, dynamic> d) => NeonGlowLine.data(
        minPointDistance: (d['minPointDistance'] ?? 2.0) as double,
        points: _pointsFromJson(d['points']),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  String get contentType => 'NeonGlowLine';

  @override
  void draw(ui.Canvas canvas, ui.Size size, bool deeper) {
    if (points.length < 2) return;
    final Path path = buildSmoothPath();
    final double w = paint.strokeWidth;
    final Color base = paint.color;

    // Outer aura
    canvas.drawPath(
      path,
      Paint()
        ..color = base.withValues(alpha: 0.25)
        ..strokeWidth = w * 2.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.8)
        ..isAntiAlias = true,
    );

    // Medium glow
    canvas.drawPath(
      path,
      Paint()
        ..color = base.withValues(alpha: 0.6)
        ..strokeWidth = w * 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.3)
        ..isAntiAlias = true,
    );

    // Inner bright colored core
    canvas.drawPath(
      path,
      Paint()
        ..color = base
        ..strokeWidth = w * 0.7
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );

    // Core white neon hot spot
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..strokeWidth = (w * 0.28).clamp(1.0, double.infinity)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
  }

  @override
  NeonGlowLine copy() => NeonGlowLine.data(
        minPointDistance: minPointDistance,
        points: List<Offset>.from(points),
        paint: paint.copyWith(),
      );

  @override
  Map<String, dynamic> toContentJson() => baseJson();
}

/// 彩虹流光笔迹（Rainbow Line）：沿路径平滑过渡七彩光谱
class RainbowLine extends PresetStroke {
  RainbowLine({super.minPointDistance});

  RainbowLine.data({super.minPointDistance, required super.points, required super.paint})
      : super.data();

  factory RainbowLine.fromJson(Map<String, dynamic> d) => RainbowLine.data(
        minPointDistance: (d['minPointDistance'] ?? 2.0) as double,
        points: _pointsFromJson(d['points']),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  String get contentType => 'RainbowLine';

  @override
  void draw(ui.Canvas canvas, ui.Size size, bool deeper) {
    if (points.length < 2) return;
    final double w = paint.strokeWidth;
    final double step = (w * 0.2).clamp(1.0, 6.0);
    final Paint segPaint = Paint()
      ..strokeWidth = w
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    Offset? prev;

    walk(step, (ui.Tangent t, double d, double total, int i) {
      if (prev != null) {
        final double progress = total > 0 ? (d / total) : 0;
        final double hue = (progress * 360 * 1.5) % 360;
        segPaint.color = HSVColor.fromAHSV(1.0, hue, 0.9, 1.0).toColor();
        canvas.drawLine(prev!, t.position, segPaint);
      }
      prev = t.position;
    });
  }

  @override
  RainbowLine copy() => RainbowLine.data(
        minPointDistance: minPointDistance,
        points: List<Offset>.from(points),
        paint: paint.copyWith(),
      );

  @override
  Map<String, dynamic> toContentJson() => baseJson();
}

/// 双轨丝带笔迹（Ribbon Line）：动态扭转的双边缘丝带
class RibbonLine extends PresetStroke {
  RibbonLine({super.minPointDistance});

  RibbonLine.data({super.minPointDistance, required super.points, required super.paint})
      : super.data();

  factory RibbonLine.fromJson(Map<String, dynamic> d) => RibbonLine.data(
        minPointDistance: (d['minPointDistance'] ?? 2.0) as double,
        points: _pointsFromJson(d['points']),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  String get contentType => 'RibbonLine';

  @override
  void draw(ui.Canvas canvas, ui.Size size, bool deeper) {
    if (points.length < 2) return;
    final double w = paint.strokeWidth;
    final double half = w * 0.6;
    final Path path1 = Path();
    final Path path2 = Path();
    final Path fillStrip = Path();
    bool first = true;
    final List<Offset> leftPoints = [];
    final List<Offset> rightPoints = [];

    walk(2.0, (ui.Tangent t, double d, double total, int i) {
      final Offset n = normalOf(t);
      final double wave = sin(d * 0.05) * 0.35 + 0.65;
      final Offset p1 = t.position + n * (half * wave);
      final Offset p2 = t.position - n * (half * wave);

      leftPoints.add(p1);
      rightPoints.add(p2);

      if (first) {
        path1.moveTo(p1.dx, p1.dy);
        path2.moveTo(p2.dx, p2.dy);
        first = false;
      } else {
        path1.lineTo(p1.dx, p1.dy);
        path2.lineTo(p2.dx, p2.dy);
      }
    });

    if (leftPoints.isNotEmpty && rightPoints.isNotEmpty) {
      fillStrip.moveTo(leftPoints.first.dx, leftPoints.first.dy);
      for (final p in leftPoints) {
        fillStrip.lineTo(p.dx, p.dy);
      }
      for (final p in rightPoints.reversed) {
        fillStrip.lineTo(p.dx, p.dy);
      }
      fillStrip.close();

      // Semi-transparent ribbon body
      canvas.drawPath(
        fillStrip,
        Paint()
          ..color = paint.color.withValues(alpha: 0.35)
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );

      // Border lines
      final Paint borderPaint = Paint()
        ..color = paint.color
        ..strokeWidth = (w * 0.15).clamp(1.0, 4.0)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      canvas.drawPath(path1, borderPaint);
      canvas.drawPath(path2, borderPaint);
    }
  }

  @override
  RibbonLine copy() => RibbonLine.data(
        minPointDistance: minPointDistance,
        points: List<Offset>.from(points),
        paint: paint.copyWith(),
      );

  @override
  Map<String, dynamic> toContentJson() => baseJson();
}

/// 星座连线笔迹（Constellation Line）：星光节点与几何连线
class ConstellationLine extends PresetStroke {
  ConstellationLine({super.minPointDistance});

  ConstellationLine.data({super.minPointDistance, required super.points, required super.paint})
      : super.data();

  factory ConstellationLine.fromJson(Map<String, dynamic> d) => ConstellationLine.data(
        minPointDistance: (d['minPointDistance'] ?? 2.0) as double,
        points: _pointsFromJson(d['points']),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  String get contentType => 'ConstellationLine';

  @override
  void draw(ui.Canvas canvas, ui.Size size, bool deeper) {
    if (points.length < 2) return;
    final double w = paint.strokeWidth;
    final List<Offset> stars = [];

    // Central thin connector line
    canvas.drawPath(
      buildSmoothPath(),
      Paint()
        ..color = paint.color.withValues(alpha: 0.4)
        ..strokeWidth = (w * 0.12).clamp(0.8, 3.0)
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true,
    );

    walk(w * 1.5, (ui.Tangent t, double d, double total, int i) {
      final Offset offset = normalOf(t) * (_rand(seed, i, 1) * w * 0.8);
      stars.add(t.position + offset);
    });

    // Draw cross connections and star nodes
    final Paint linePaint = Paint()
      ..color = paint.color.withValues(alpha: 0.3)
      ..strokeWidth = 0.8
      ..isAntiAlias = true;

    for (int i = 0; i < stars.length; i++) {
      if (i > 0) canvas.drawLine(stars[i - 1], stars[i], linePaint);
      if (i > 1 && _rand01(seed, i, 7) > 0.4) {
        canvas.drawLine(stars[i - 2], stars[i], linePaint);
      }

      // Star glint
      final Offset st = stars[i];
      final double starR = (w * 0.25).clamp(2.0, 8.0);
      canvas.drawCircle(
        st,
        starR,
        Paint()
          ..color = paint.color
          ..isAntiAlias = true,
      );
      canvas.drawCircle(
        st,
        starR * 0.5,
        Paint()
          ..color = Colors.white
          ..isAntiAlias = true,
      );
    }
  }

  @override
  ConstellationLine copy() => ConstellationLine.data(
        minPointDistance: minPointDistance,
        points: List<Offset>.from(points),
        paint: paint.copyWith(),
      );

  @override
  Map<String, dynamic> toContentJson() => baseJson();
}

/// 铁链链条笔迹（Chain Line）：沿切线方向的金属环链
class ChainLine extends PresetStroke {
  ChainLine({super.minPointDistance});

  ChainLine.data({super.minPointDistance, required super.points, required super.paint})
      : super.data();

  factory ChainLine.fromJson(Map<String, dynamic> d) => ChainLine.data(
        minPointDistance: (d['minPointDistance'] ?? 2.0) as double,
        points: _pointsFromJson(d['points']),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  String get contentType => 'ChainLine';

  @override
  void draw(ui.Canvas canvas, ui.Size size, bool deeper) {
    if (points.length < 2) return;
    final double w = paint.strokeWidth;
    final double linkLen = w * 1.1;

    walk(linkLen * 0.7, (ui.Tangent t, double d, double total, int i) {
      canvas.save();
      canvas.translate(t.position.dx, t.position.dy);
      canvas.rotate(t.angle);

      final bool isAlt = i % 2 == 0;
      final double rW = linkLen;
      final double rH = isAlt ? (w * 0.6) : (w * 0.35);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: rW, height: rH),
          Radius.circular(rH / 2),
        ),
        Paint()
          ..color = paint.color
          ..strokeWidth = (w * 0.18).clamp(1.5, 6.0)
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true,
      );
      canvas.restore();
    });
  }

  @override
  ChainLine copy() => ChainLine.data(
        minPointDistance: minPointDistance,
        points: List<Offset>.from(points),
        paint: paint.copyWith(),
      );

  @override
  Map<String, dynamic> toContentJson() => baseJson();
}

/// 电弧闪电笔迹（Electric Arc Line）：高压动态等离子电弧
class ElectricArcLine extends PresetStroke {
  ElectricArcLine({super.minPointDistance});

  ElectricArcLine.data({super.minPointDistance, required super.points, required super.paint})
      : super.data();

  factory ElectricArcLine.fromJson(Map<String, dynamic> d) => ElectricArcLine.data(
        minPointDistance: (d['minPointDistance'] ?? 2.0) as double,
        points: _pointsFromJson(d['points']),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  String get contentType => 'ElectricArcLine';

  @override
  void draw(ui.Canvas canvas, ui.Size size, bool deeper) {
    if (points.length < 2) return;
    final double w = paint.strokeWidth;
    final Path mainArc = Path();
    final Path branchArc = Path();
    bool first = true;

    walk(w * 0.4, (ui.Tangent t, double d, double total, int i) {
      final double jitter = _rand(seed, i, 9) * w * 0.6;
      final Offset p = t.position + normalOf(t) * jitter;

      if (first) {
        mainArc.moveTo(p.dx, p.dy);
        first = false;
      } else {
        mainArc.lineTo(p.dx, p.dy);
      }

      if (_rand01(seed, i, 15) > 0.65) {
        final Offset b = p + normalOf(t) * (_rand(seed, i, 20) * w * 1.2);
        branchArc.moveTo(p.dx, p.dy);
        branchArc.lineTo(b.dx, b.dy);
      }
    });

    // Outer electric glow
    canvas.drawPath(
      mainArc,
      Paint()
        ..color = paint.color.withValues(alpha: 0.45)
        ..strokeWidth = w * 1.4
        ..style = PaintingStyle.stroke
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.4)
        ..isAntiAlias = true,
    );

    // Sharp jagged core
    canvas.drawPath(
      mainArc,
      Paint()
        ..color = Colors.white
        ..strokeWidth = (w * 0.25).clamp(1.2, 4.0)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );

    // Branches
    canvas.drawPath(
      branchArc,
      Paint()
        ..color = paint.color.withValues(alpha: 0.7)
        ..strokeWidth = (w * 0.15).clamp(0.8, 2.5)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );
  }

  @override
  ElectricArcLine copy() => ElectricArcLine.data(
        minPointDistance: minPointDistance,
        points: List<Offset>.from(points),
        paint: paint.copyWith(),
      );

  @override
  Map<String, dynamic> toContentJson() => baseJson();
}

/// 泡泡轨迹笔迹（Bubble Trail Line）：高光立体透明泡泡串
class BubbleTrailLine extends PresetStroke {
  BubbleTrailLine({super.minPointDistance});

  BubbleTrailLine.data({super.minPointDistance, required super.points, required super.paint})
      : super.data();

  factory BubbleTrailLine.fromJson(Map<String, dynamic> d) => BubbleTrailLine.data(
        minPointDistance: (d['minPointDistance'] ?? 2.0) as double,
        points: _pointsFromJson(d['points']),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  String get contentType => 'BubbleTrailLine';

  @override
  void draw(ui.Canvas canvas, ui.Size size, bool deeper) {
    if (points.length < 2) return;
    final double w = paint.strokeWidth;

    walk(w * 0.6, (ui.Tangent t, double d, double total, int i) {
      final double r = w * (0.3 + _rand01(seed, i, 3) * 0.5);
      final Offset center = t.position + normalOf(t) * (_rand(seed, i, 1) * w * 0.5);

      // Bubble rim
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = paint.color.withValues(alpha: 0.6)
          ..strokeWidth = (r * 0.15).clamp(1.0, 3.0)
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true,
      );

      // Bubble body soft tint
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = paint.color.withValues(alpha: 0.12)
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );

      // Specular glare reflection
      final Offset glare = center + Offset(-r * 0.35, -r * 0.35);
      canvas.drawCircle(
        glare,
        r * 0.25,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
    });
  }

  @override
  BubbleTrailLine copy() => BubbleTrailLine.data(
        minPointDistance: minPointDistance,
        points: List<Offset>.from(points),
        paint: paint.copyWith(),
      );

  @override
  Map<String, dynamic> toContentJson() => baseJson();
}

/// 音频声波笔迹（Audio Spectrum Line）：律动跳跃的音频均衡器频谱
class AudioSpectrumLine extends PresetStroke {
  AudioSpectrumLine({super.minPointDistance});

  AudioSpectrumLine.data({super.minPointDistance, required super.points, required super.paint})
      : super.data();

  factory AudioSpectrumLine.fromJson(Map<String, dynamic> d) => AudioSpectrumLine.data(
        minPointDistance: (d['minPointDistance'] ?? 2.0) as double,
        points: _pointsFromJson(d['points']),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  String get contentType => 'AudioSpectrumLine';

  @override
  bool get supportsActiveRangeBaking => true;

  @override
  void drawCommittedRange(ui.Canvas canvas, ui.Size size, int startSample, int endSample) {
    _drawAudioRange(canvas, size, startSample, endSample, includeTail: false);
  }

  @override
  void drawLiveFromSample(ui.Canvas canvas, ui.Size size, int startSample) {
    _drawAudioRange(canvas, size, startSample, null, includeTail: true);
  }

  @override
  void draw(ui.Canvas canvas, ui.Size size, bool deeper) {
    _drawAudioRange(canvas, size, 0, null, includeTail: true);
  }

  void _drawAudioRange(
    ui.Canvas canvas,
    ui.Size size,
    int startSample,
    int? endSample, {
    required bool includeTail,
  }) {
    if (points.length < 2) return;
    final double w = paint.strokeWidth;
    final double barWidth = (w * 0.2).clamp(1.5, 6.0);
    final int curSeed = seed;
    final Paint barPaint = Paint()
      ..color = paint.color
      ..strokeWidth = barWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    walkChunkedRange(canvas, size, barWidth * 2.2, 0, startSample, endSample, includeTail, (
      ui.Canvas target,
      double x,
      double y,
      double angle,
      double d,
      int i,
    ) {
      final double h = w * (0.3 + sin(i * 0.7).abs() * 0.9 + _rand01(curSeed, i, 5) * 0.4);
      final double nx = -sin(angle) * (h * 0.5);
      final double ny = cos(angle) * (h * 0.5);
      target.drawLine(
        Offset(x + nx, y + ny),
        Offset(x - nx, y - ny),
        barPaint,
      );
    });
  }

  @override
  AudioSpectrumLine copy() => AudioSpectrumLine.data(
        minPointDistance: minPointDistance,
        points: List<Offset>.from(points),
        paint: paint.copyWith(),
      );

  @override
  Map<String, dynamic> toContentJson() => baseJson();
}

/// 缝线刺绣笔迹（Stitch Line）：逼真衣物缝线与交叉十字绣
class StitchLine extends PresetStroke {
  StitchLine({super.minPointDistance});

  StitchLine.data({super.minPointDistance, required super.points, required super.paint})
      : super.data();

  factory StitchLine.fromJson(Map<String, dynamic> d) => StitchLine.data(
        minPointDistance: (d['minPointDistance'] ?? 2.0) as double,
        points: _pointsFromJson(d['points']),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  String get contentType => 'StitchLine';

  @override
  void draw(ui.Canvas canvas, ui.Size size, bool deeper) {
    if (points.length < 2) return;
    final double w = paint.strokeWidth;
    final double stitchLen = w * 0.8;

    walk(stitchLen * 1.5, (ui.Tangent t, double d, double total, int i) {
      canvas.save();
      canvas.translate(t.position.dx, t.position.dy);
      canvas.rotate(t.angle);

      final double s = stitchLen * 0.4;
      // Cross stitch X
      final Paint thread = Paint()
        ..color = paint.color
        ..strokeWidth = (w * 0.18).clamp(1.5, 4.5)
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      canvas.drawLine(Offset(-s, -s), Offset(s, s), thread);
      canvas.drawLine(Offset(-s, s), Offset(s, -s), thread);

      canvas.restore();
    });
  }

  @override
  StitchLine copy() => StitchLine.data(
        minPointDistance: minPointDistance,
        points: List<Offset>.from(points),
        paint: paint.copyWith(),
      );

  @override
  Map<String, dynamic> toContentJson() => baseJson();
}
