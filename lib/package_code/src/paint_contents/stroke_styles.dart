import 'dart:math';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';
import 'freehand_line.dart';

/// 沿路径重复的波形类型 / Waveform patterns repeated along the path
enum LinePattern { saw, zigzag, gear, heartbeat }

/// 稳定伪随机 [-1,1] / Stable pseudo-random in [-1, 1]
double _rand(int seed, int i, int ch) {
  final int s = (seed + i * 374761393 + ch * 668265263) & 0x7fffffff;
  return Random(s).nextDouble() * 2 - 1;
}

int _seedOf(List<Offset> points) {
  if (points.isEmpty) {
    return 1;
  }
  return ((points.first.dx.toInt() * 73856093) ^ (points.first.dy.toInt() * 19349663)) & 0x7fffffff;
}

// ---------------------------------------------------------------------------
// 波形笔迹 / Waveform strokes (Saw, Zigzag, Gear, Heartbeat)
// ---------------------------------------------------------------------------

/// 波形笔迹基类
///
/// 沿平滑后的笔迹路径按周期生成波形（锯齿、之字、齿轮、心电图），并以细线描边。
/// 波幅与周期都随画笔粗细缩放。
///
/// Waveform stroke base class. Walks the smoothed path and displaces each
/// sample along the path normal by a repeating waveform (saw, zigzag, gear,
/// heartbeat), then strokes the result. Amplitude and period scale with the
/// stroke width.
abstract class PatternLine extends FreehandLine {
  PatternLine({super.minPointDistance, this.amplitude = 1.0, this.period = 1.6});

  PatternLine.data({
    super.minPointDistance,
    this.amplitude = 1.0,
    this.period = 1.6,
    required super.points,
    required super.paint,
  }) : super.data();

  /// 波幅（相对画笔粗细）/ Amplitude relative to the stroke width
  final double amplitude;

  /// 周期（相对画笔粗细）/ Period relative to the stroke width
  final double period;

  LinePattern get pattern;

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (points.length < 2) {
      return;
    }

    final double width = paint.strokeWidth;
    final double amp = width * amplitude;
    final double per = (width * period).clamp(2.0, double.infinity);
    final double step = (per / 10).clamp(0.5, double.infinity);

    final Paint line = paint.copyWith(
      style: PaintingStyle.stroke,
      strokeWidth: (width * 0.2).clamp(1.0, double.infinity),
      strokeCap: StrokeCap.round,
      strokeJoin: StrokeJoin.round,
    );

    final Path out = Path();
    bool started = false;

    for (final PathMetric metric in buildSmoothPath().computeMetrics()) {
      double d = 0;
      while (d <= metric.length) {
        final Tangent? t = metric.getTangentForOffset(d);
        if (t != null) {
          final double off = _wave(d / per) * amp;
          final Offset p = t.position + Offset(-sin(t.angle) * off, cos(t.angle) * off);
          if (!started) {
            out.moveTo(p.dx, p.dy);
            started = true;
          } else {
            out.lineTo(p.dx, p.dy);
          }
        }
        d += step;
      }
    }

    canvas.drawPath(out, line);
  }

  /// 单周期波形，返回 [-1, 1] / Single-period waveform returning [-1, 1]
  double _wave(double x) {
    final double f = x - x.floorToDouble();
    switch (pattern) {
      case LinePattern.saw:
        return 2 * f - 1;
      case LinePattern.zigzag:
        return 4 * (f - 0.5).abs() - 1;
      case LinePattern.gear:
        return f < 0.5 ? 1 : -1;
      case LinePattern.heartbeat:
        if (f < 0.45 || f > 0.75) {
          return 0;
        }
        if (f < 0.50) {
          return -0.25 * ((f - 0.45) / 0.05);
        }
        if (f < 0.58) {
          return (f - 0.50) / 0.08;
        }
        if (f < 0.66) {
          return 1 - 2 * ((f - 0.58) / 0.08);
        }
        return -1 + ((f - 0.66) / 0.09);
    }
  }

  @override
  Map<String, dynamic> toContentJson() => <String, dynamic>{
        ...baseJson(),
        'amplitude': amplitude,
        'period': period,
      };
}

/// 锯齿笔迹 / Saw stroke
class SawLine extends PatternLine {
  SawLine({super.minPointDistance, super.amplitude, super.period});

  SawLine.data({
    super.minPointDistance,
    super.amplitude,
    super.period,
    required super.points,
    required super.paint,
  }) : super.data();

  factory SawLine.fromJson(Map<String, dynamic> d) => SawLine.data(
        minPointDistance: (d['minPointDistance'] ?? 2.0) as double,
        amplitude: (d['amplitude'] ?? 1.0) as double,
        period: (d['period'] ?? 1.6) as double,
        points: (d['points'] as List<dynamic>)
            .map((dynamic e) => jsonToOffset(e as Map<String, dynamic>))
            .toList(),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  LinePattern get pattern => LinePattern.saw;

  @override
  String get contentType => 'SawLine';

  @override
  SawLine copy() => SawLine(minPointDistance: minPointDistance, amplitude: amplitude, period: period);
}

/// 之字笔迹 / Zigzag stroke
class ZigzagLine extends PatternLine {
  ZigzagLine({super.minPointDistance, super.amplitude, super.period});

  ZigzagLine.data({
    super.minPointDistance,
    super.amplitude,
    super.period,
    required super.points,
    required super.paint,
  }) : super.data();

  factory ZigzagLine.fromJson(Map<String, dynamic> d) => ZigzagLine.data(
        minPointDistance: (d['minPointDistance'] ?? 2.0) as double,
        amplitude: (d['amplitude'] ?? 1.0) as double,
        period: (d['period'] ?? 1.6) as double,
        points: (d['points'] as List<dynamic>)
            .map((dynamic e) => jsonToOffset(e as Map<String, dynamic>))
            .toList(),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  LinePattern get pattern => LinePattern.zigzag;

  @override
  String get contentType => 'ZigzagLine';

  @override
  ZigzagLine copy() =>
      ZigzagLine(minPointDistance: minPointDistance, amplitude: amplitude, period: period);
}

/// 齿轮（方波）笔迹 / Gear (square wave) stroke
class GearLine extends PatternLine {
  GearLine({super.minPointDistance, super.amplitude, super.period});

  GearLine.data({
    super.minPointDistance,
    super.amplitude,
    super.period,
    required super.points,
    required super.paint,
  }) : super.data();

  factory GearLine.fromJson(Map<String, dynamic> d) => GearLine.data(
        minPointDistance: (d['minPointDistance'] ?? 2.0) as double,
        amplitude: (d['amplitude'] ?? 1.0) as double,
        period: (d['period'] ?? 1.6) as double,
        points: (d['points'] as List<dynamic>)
            .map((dynamic e) => jsonToOffset(e as Map<String, dynamic>))
            .toList(),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  LinePattern get pattern => LinePattern.gear;

  @override
  String get contentType => 'GearLine';

  @override
  GearLine copy() =>
      GearLine(minPointDistance: minPointDistance, amplitude: amplitude, period: period);
}

/// 心电图笔迹 / Heartbeat (ECG) stroke
class HeartbeatLine extends PatternLine {
  HeartbeatLine({super.minPointDistance, super.amplitude, super.period = 3.0});

  HeartbeatLine.data({
    super.minPointDistance,
    super.amplitude,
    super.period = 3.0,
    required super.points,
    required super.paint,
  }) : super.data();

  factory HeartbeatLine.fromJson(Map<String, dynamic> d) => HeartbeatLine.data(
        minPointDistance: (d['minPointDistance'] ?? 2.0) as double,
        amplitude: (d['amplitude'] ?? 1.0) as double,
        period: (d['period'] ?? 3.0) as double,
        points: (d['points'] as List<dynamic>)
            .map((dynamic e) => jsonToOffset(e as Map<String, dynamic>))
            .toList(),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  LinePattern get pattern => LinePattern.heartbeat;

  @override
  String get contentType => 'HeartbeatLine';

  @override
  HeartbeatLine copy() =>
      HeartbeatLine(minPointDistance: minPointDistance, amplitude: amplitude, period: period);
}

// ---------------------------------------------------------------------------
// 其它笔迹风格 / Other stroke styles
// ---------------------------------------------------------------------------

/// 毛发笔迹 / Hair stroke
///
/// 沿笔迹绘制多条平行细线（带轻微起伏），形成成束的发丝效果。
///
/// Draws several thin parallel strands along the stroke with slight waviness,
/// producing a bundled-hair look.
class HairLine extends FreehandLine {
  HairLine({super.minPointDistance, this.strands = 7});

  HairLine.data({
    super.minPointDistance,
    this.strands = 7,
    required super.points,
    required super.paint,
  }) : super.data();

  factory HairLine.fromJson(Map<String, dynamic> d) => HairLine.data(
        minPointDistance: (d['minPointDistance'] ?? 2.0) as double,
        strands: (d['strands'] ?? 7) as int,
        points: (d['points'] as List<dynamic>)
            .map((dynamic e) => jsonToOffset(e as Map<String, dynamic>))
            .toList(),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  /// 发丝数量 / Number of strands
  final int strands;

  @override
  String get contentType => 'HairLine';

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (points.length < 2) {
      return;
    }

    final double width = paint.strokeWidth;
    final int seed = _seedOf(points);
    final Paint hair = paint.copyWith(
      style: PaintingStyle.stroke,
      strokeWidth: (width * 0.08).clamp(0.6, double.infinity),
      strokeCap: StrokeCap.round,
    );

    final List<PathMetric> metrics = buildSmoothPath().computeMetrics().toList();
    final double step = (width * 0.25).clamp(1.0, double.infinity);

    for (int s = 0; s < strands; s++) {
      final double base = strands == 1 ? 0 : (s / (strands - 1) - 0.5) * width;
      final Path strand = Path();
      bool started = false;

      for (final PathMetric metric in metrics) {
        double d = 0;
        while (d <= metric.length) {
          final Tangent? t = metric.getTangentForOffset(d);
          if (t != null) {
            // 轻微起伏，让发丝不完全平行
            final double waver = sin(d / (width * 2) + s) * width * 0.12;
            final double off = base + waver + _rand(seed, s, (d ~/ 8)) * width * 0.05;
            final Offset p = t.position + Offset(-sin(t.angle) * off, cos(t.angle) * off);
            if (!started) {
              strand.moveTo(p.dx, p.dy);
              started = true;
            } else {
              strand.lineTo(p.dx, p.dy);
            }
          }
          d += step;
        }
      }
      canvas.drawPath(strand, hair);
    }
  }

  @override
  HairLine copy() => HairLine(minPointDistance: minPointDistance, strands: strands);

  @override
  Map<String, dynamic> toContentJson() => <String, dynamic>{...baseJson(), 'strands': strands};
}

/// 像素笔迹 / Pixel stroke
///
/// 将笔迹吸附到网格，绘制成马赛克式的方块，形成像素画效果。
///
/// Snaps the stroke to a grid and fills whole cells, giving a pixel-art look.
class PixelLine extends FreehandLine {
  PixelLine({super.minPointDistance});

  PixelLine.data({super.minPointDistance, required super.points, required super.paint})
      : super.data();

  factory PixelLine.fromJson(Map<String, dynamic> d) => PixelLine.data(
        minPointDistance: (d['minPointDistance'] ?? 2.0) as double,
        points: (d['points'] as List<dynamic>)
            .map((dynamic e) => jsonToOffset(e as Map<String, dynamic>))
            .toList(),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  String get contentType => 'PixelLine';

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (points.isEmpty) {
      return;
    }

    final double cell = paint.strokeWidth.clamp(2.0, double.infinity);
    final Paint fill = paint.copyWith(style: PaintingStyle.fill);
    final Set<int> seen = <int>{};

    void put(Offset p) {
      final int cx = (p.dx / cell).floor();
      final int cy = (p.dy / cell).floor();
      if (seen.add((cx * 73856093) ^ (cy * 19349663))) {
        canvas.drawRect(Rect.fromLTWH(cx * cell, cy * cell, cell, cell), fill);
      }
    }

    if (points.length == 1) {
      put(points.first);
      return;
    }

    final double step = (cell / 2).clamp(0.5, double.infinity);
    for (final PathMetric metric in buildSmoothPath().computeMetrics()) {
      double d = 0;
      while (d <= metric.length) {
        final Tangent? t = metric.getTangentForOffset(d);
        if (t != null) {
          put(t.position);
        }
        d += step;
      }
    }
  }

  @override
  PixelLine copy() => PixelLine(minPointDistance: minPointDistance);

  @override
  Map<String, dynamic> toContentJson() => baseJson();
}

/// 渐变笔迹 / Gradient stroke
///
/// 沿笔迹用线性渐变着色（当前颜色渐变到偏移色相的颜色）。
///
/// Strokes the path with a linear gradient from the current color to a
/// hue-shifted variant.
class GradientLine extends FreehandLine {
  GradientLine({super.minPointDistance, this.hueShift = 60});

  GradientLine.data({
    super.minPointDistance,
    this.hueShift = 60,
    required super.points,
    required super.paint,
  }) : super.data();

  factory GradientLine.fromJson(Map<String, dynamic> d) => GradientLine.data(
        minPointDistance: (d['minPointDistance'] ?? 2.0) as double,
        hueShift: (d['hueShift'] ?? 60) as double,
        points: (d['points'] as List<dynamic>)
            .map((dynamic e) => jsonToOffset(e as Map<String, dynamic>))
            .toList(),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  /// 渐变终点的色相偏移（度）/ Hue shift of the gradient end color (degrees)
  final double hueShift;

  @override
  String get contentType => 'GradientLine';

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (points.length < 2) {
      return;
    }

    final Path path = buildSmoothPath();
    final Rect b = path.getBounds();
    if (b.isEmpty) {
      return;
    }

    final HSVColor hsv = HSVColor.fromColor(paint.color);
    final Color end = hsv.withHue((hsv.hue + hueShift) % 360).toColor();

    final Paint grad = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = paint.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..shader = ui.Gradient.linear(b.topLeft, b.bottomRight, <Color>[paint.color, end]);

    canvas.drawPath(path, grad);
  }

  @override
  GradientLine copy() => GradientLine(minPointDistance: minPointDistance, hueShift: hueShift);

  @override
  Map<String, dynamic> toContentJson() => <String, dynamic>{...baseJson(), 'hueShift': hueShift};
}

/// 素描笔迹 / Sketch stroke
///
/// 用多道带抖动的细线反复描绘同一条笔迹，形成手绘草图的毛糙感。
///
/// Draws the same stroke several times with jittered thin lines, producing a
/// scratchy hand-sketched look.
class SketchLine extends FreehandLine {
  SketchLine({super.minPointDistance, this.passes = 4});

  SketchLine.data({
    super.minPointDistance,
    this.passes = 4,
    required super.points,
    required super.paint,
  }) : super.data();

  factory SketchLine.fromJson(Map<String, dynamic> d) => SketchLine.data(
        minPointDistance: (d['minPointDistance'] ?? 2.0) as double,
        passes: (d['passes'] ?? 4) as int,
        points: (d['points'] as List<dynamic>)
            .map((dynamic e) => jsonToOffset(e as Map<String, dynamic>))
            .toList(),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  /// 重复描绘的道数 / Number of overlapping passes
  final int passes;

  @override
  String get contentType => 'SketchLine';

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (points.length < 2) {
      return;
    }

    final double width = paint.strokeWidth;
    final int seed = _seedOf(points);
    final Paint pen = paint.copyWith(
      style: PaintingStyle.stroke,
      strokeWidth: (width * 0.22).clamp(0.6, double.infinity),
      strokeCap: StrokeCap.round,
      color: paint.color.withValues(alpha: paint.color.a * 0.55),
    );

    final List<PathMetric> metrics = buildSmoothPath().computeMetrics().toList();
    final double step = (width * 0.4).clamp(1.0, double.infinity);

    for (int pass = 0; pass < passes; pass++) {
      final Path scratch = Path();
      bool started = false;
      int i = 0;

      for (final PathMetric metric in metrics) {
        double d = 0;
        while (d <= metric.length) {
          final Tangent? t = metric.getTangentForOffset(d);
          if (t != null) {
            final double off = _rand(seed, pass * 1000 + i, 3) * width * 0.45;
            final double along = _rand(seed, pass * 1000 + i, 7) * width * 0.2;
            final Offset p = t.position +
                Offset(-sin(t.angle) * off + cos(t.angle) * along,
                    cos(t.angle) * off + sin(t.angle) * along);
            if (!started) {
              scratch.moveTo(p.dx, p.dy);
              started = true;
            } else {
              scratch.lineTo(p.dx, p.dy);
            }
          }
          i++;
          d += step;
        }
      }
      canvas.drawPath(scratch, pen);
    }
  }

  @override
  SketchLine copy() => SketchLine(minPointDistance: minPointDistance, passes: passes);

  @override
  Map<String, dynamic> toContentJson() => <String, dynamic>{...baseJson(), 'passes': passes};
}
