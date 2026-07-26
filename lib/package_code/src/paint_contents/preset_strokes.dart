import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';
import 'freehand_line.dart';

/// 稳定伪随机 [-1,1] / Stable pseudo-random in [-1, 1]
double _rand(int seed, int i, int ch) {
  final int s = (seed + i * 374761393 + ch * 668265263) & 0x7fffffff;
  return Random(s).nextDouble() * 2 - 1;
}

/// 稳定伪随机 [0,1] / Stable pseudo-random in [0, 1]
double _rand01(int seed, int i, int ch) => (_rand(seed, i, ch) + 1) / 2;

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

  /// 沿路径行走 / Walk along the smoothed path
  void walk(double step, void Function(ui.Tangent t, double d, double total, int i) fn) {
    final double s = step.clamp(0.5, double.infinity);
    final List<ui.PathMetric> ms = buildSmoothPath().computeMetrics().toList();
    final double total = ms.fold<double>(0, (double a, ui.PathMetric m) => a + m.length);
    int i = 0;
    double acc = 0;
    for (final ui.PathMetric m in ms) {
      double d = 0;
      while (d <= m.length) {
        final ui.Tangent? t = m.getTangentForOffset(d);
        if (t != null) {
          fn(t, acc + d, total, i);
        }
        i++;
        d += s;
      }
      acc += m.length;
    }
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
  ChoppyLine copy() => ChoppyLine(minPointDistance: minPointDistance);

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
  RoughPenLine copy() => RoughPenLine(minPointDistance: minPointDistance);

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
  InkLine copy() =>
      InkLine(minPointDistance: minPointDistance, startBlob: startBlob, endTaper: endTaper);

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
  });

  PencilLine.data({
    super.minPointDistance,
    this.density = 10,
    this.opacity = 0.55,
    this.spread = 1.0,
    this.speck = 0.09,
    required super.points,
    required super.paint,
  }) : super.data();

  factory PencilLine.fromJson(Map<String, dynamic> d) => PencilLine.data(
        minPointDistance: (d['minPointDistance'] ?? 2.0) as double,
        density: (d['density'] ?? 10) as int,
        opacity: (d['opacity'] ?? 0.55) as double,
        spread: (d['spread'] ?? 1.0) as double,
        speck: (d['speck'] ?? 0.09) as double,
        points: _pointsFromJson(d['points']),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  /// 每步撒下的颗粒数 / Specks per step
  final int density;

  /// 整体浓淡 / Overall darkness
  final double opacity;

  /// 横向散布（相对粗细）/ Lateral spread relative to width
  final double spread;

  /// 颗粒大小（相对粗细）/ Speck size relative to width
  final double speck;

  @override
  String get contentType => 'PencilLine';

  @override
  void draw(ui.Canvas canvas, ui.Size size, bool deeper) {
    if (points.isEmpty) {
      return;
    }
    final double w = paint.strokeWidth;
    final double baseAlpha = paint.color.a * opacity;

    walk(w * 0.3, (ui.Tangent t, double d, double total, int i) {
      final Offset n = normalOf(t);
      final Offset dir = dirOf(t);
      for (int k = 0; k < density; k++) {
        final double off = _rand(seed, i, k * 2) * w * spread * 0.5;
        final double along = _rand(seed, i, k * 2 + 1) * w * 0.25;
        final Offset p = t.position + n * off + dir * along;
        final double a = (baseAlpha * (0.25 + _rand01(seed, i, 200 + k) * 0.75)).clamp(0.0, 1.0);
        canvas.drawCircle(
          p,
          (w * speck).clamp(0.35, double.infinity),
          paint.copyWith(style: PaintingStyle.fill, color: paint.color.withValues(alpha: a)),
        );
      }
    });
  }

  @override
  PencilLine copy() => PencilLine(
        minPointDistance: minPointDistance,
        density: density,
        opacity: opacity,
        spread: spread,
        speck: speck,
      );

  @override
  Map<String, dynamic> toContentJson() => <String, dynamic>{
        ...baseJson(),
        'density': density,
        'opacity': opacity,
        'spread': spread,
        'speck': speck,
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
  HalftoneLine copy() => HalftoneLine(minPointDistance: minPointDistance, gridRatio: gridRatio);

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
  HatchLine copy() => HatchLine(minPointDistance: minPointDistance, rightward: rightward);

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

    void put(Offset p) {
      final int cx = (p.dx / cell).floor();
      final int cy = (p.dy / cell).floor();
      final int key = (cx * 73856093) ^ (cy * 19349663);
      if (!seen.add(key)) {
        return;
      }
      final double t = _rand01(seed, key & 0xffff, 9);
      final Color col = t > 0.5 ? _lighten(paint.color, (t - 0.5) * 0.5) : _darken(paint.color, (0.5 - t) * 0.4);
      canvas.drawRect(
        Rect.fromLTWH(cx * cell, cy * cell, cell, cell),
        paint.copyWith(style: PaintingStyle.fill, color: col),
      );
    }

    if (points.length == 1) {
      put(points.first);
      return;
    }
    walk(cell / 2, (ui.Tangent t, double d, double total, int i) => put(t.position));
  }

  @override
  MosaicLine copy() => MosaicLine(minPointDistance: minPointDistance);

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
  void draw(ui.Canvas canvas, ui.Size size, bool deeper) {
    if (points.isEmpty) {
      return;
    }
    final double w = paint.strokeWidth;
    final double r = w / 2;
    if (points.length == 1) {
      canvas.drawCircle(points.first, r, shadedDab(points.first, r, paint.color));
      return;
    }
    walk(w * 0.12, (ui.Tangent t, double d, double total, int i) {
      canvas.drawCircle(t.position, r, shadedDab(t.position, r, paint.color));
    });
  }

  @override
  TubeLine copy() => TubeLine(minPointDistance: minPointDistance);

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
  void draw(ui.Canvas canvas, ui.Size size, bool deeper) {
    if (points.isEmpty) {
      return;
    }
    final double w = paint.strokeWidth;
    final double r = w / 2;
    final double stripe = (w * 0.85).clamp(2.0, double.infinity);

    if (points.length == 1) {
      canvas.drawCircle(points.first, r, shadedDab(points.first, r, paint.color));
      return;
    }
    walk(w * 0.1, (ui.Tangent t, double d, double total, int i) {
      final bool white = (d / stripe).floor().isOdd;
      final Color base = white ? const Color(0xFFFFFFFF) : paint.color;
      canvas.drawCircle(t.position, r, shadedDab(t.position, r, base));
    });
  }

  @override
  CandyCaneLine copy() => CandyCaneLine(minPointDistance: minPointDistance);
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
  SparklesLine copy() => SparklesLine(minPointDistance: minPointDistance);

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
  void draw(ui.Canvas canvas, ui.Size size, bool deeper) {
    if (points.length < 2) {
      return;
    }
    final double w = paint.strokeWidth;

    walk(w * 0.6, (ui.Tangent t, double d, double total, int i) {
      for (int k = 0; k < 2; k++) {
        final Offset off =
            Offset(_rand(seed, i, k * 2) * w * 1.1, _rand(seed, i, k * 2 + 1) * w * 1.1);
        final Color col =
            HSVColor.fromAHSV(1, _rand01(seed, i, 60 + k) * 360, 0.85, 1).toColor();
        canvas.save();
        canvas.translate(t.position.dx + off.dx, t.position.dy + off.dy);
        canvas.rotate(_rand(seed, i, 120 + k) * pi);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: w * 0.5, height: w * 0.17),
            Radius.circular(w * 0.09),
          ),
          Paint()
            ..color = col
            ..isAntiAlias = true,
        );
        canvas.restore();
      }
    });
  }

  @override
  SprinklesLine copy() => SprinklesLine(minPointDistance: minPointDistance);

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
  void draw(ui.Canvas canvas, ui.Size size, bool deeper) {
    if (points.length < 2) {
      return;
    }
    final double w = paint.strokeWidth;

    walk(w * 0.5, (ui.Tangent t, double d, double total, int i) {
      for (int k = 0; k < 2; k++) {
        final Offset off =
            Offset(_rand(seed, i, k * 2) * w * 1.1, _rand(seed, i, k * 2 + 1) * w * 0.9);
        final double pick = _rand01(seed, i, 40 + k);
        final Color col = pick < 0.4
            ? const Color(0xFF000000)
            : HSVColor.fromAHSV(1, _rand01(seed, i, 80 + k) * 360, 0.9, 1).toColor();
        canvas.drawRect(
          Rect.fromCenter(
            center: t.position + off,
            width: w * (0.45 + _rand01(seed, i, 140 + k) * 0.8),
            height: w * 0.32,
          ),
          Paint()..color = col,
        );
      }
    });
  }

  @override
  StaticLine copy() => StaticLine(minPointDistance: minPointDistance);

  @override
  Map<String, dynamic> toContentJson() => baseJson();
}
