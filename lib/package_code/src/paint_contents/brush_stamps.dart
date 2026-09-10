import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 图像笔尖描述 / Image brush stamp descriptor
class BrushStamp {
  const BrushStamp(this.key, this.label, this.defaultSize);

  final String key;
  final String label;
  final int defaultSize;
}

/// 内置图像笔尖列表 / Built-in image stamps
const List<BrushStamp> kBrushStamps = <BrushStamp>[
  BrushStamp('softRound', 'Soft Round', 40),
  BrushStamp('spray', 'Airbrush', 45),
  BrushStamp('spatter', 'Spatter', 48),
  BrushStamp('chalk', 'Chalk', 44),
  BrushStamp('grunge', 'Grunge', 50),
  BrushStamp('cloud', 'Cloud', 55),
  BrushStamp('star', 'Soft Star', 40),
  BrushStamp('halftone', 'Halftone', 46),
  BrushStamp('bristleTex', 'Bristle', 48),
  BrushStamp('splatter', 'Ink Splatter', 55),
  BrushStamp('smoke', 'Smoke', 60),
  BrushStamp('hatch', 'Cross Hatch', 46),
  BrushStamp('dots', 'Dot Grid', 44),
  BrushStamp('crackle', 'Crackle', 52),
  BrushStamp('fur', 'Fur', 50),
  BrushStamp('watercolor', 'Watercolor', 58),
  BrushStamp('glitter', 'Glitter', 48),
  BrushStamp('scratches', 'Scratches', 50),
  BrushStamp('bubbles', 'Bubbles', 52),
  BrushStamp('sand', 'Sand', 46),
  BrushStamp('mesh', 'Mesh', 46),
  BrushStamp('confettiTex', 'Confetti', 52),
  BrushStamp('galaxy', 'Galaxy', 56),
  BrushStamp('rake', 'Rake', 48),
  BrushStamp('embers', 'Embers', 52),
  BrushStamp('snowDots', 'Snow', 50),
  BrushStamp('marble', 'Marble', 56),
  BrushStamp('weave', 'Weave', 46),
  BrushStamp('honeycomb', 'Honeycomb', 50),
  BrushStamp('rainStreaks', 'Rain', 52),
  BrushStamp('cobweb', 'Cobweb', 52),
  BrushStamp('cells', 'Cells', 50),
  BrushStamp('inkDrops', 'Ink Drops', 56),
  BrushStamp('staticNoise', 'Static', 46),
  BrushStamp('orangePeel', 'Orange Peel', 52),
  BrushStamp('bokeh', 'Bokeh', 60),
  BrushStamp('hearts', 'Hearts', 52),
  BrushStamp('musicNotes', 'Music', 52),
  BrushStamp('lace', 'Lace', 54),
  BrushStamp('petals', 'Petals', 54),
  BrushStamp('circuit', 'Circuit', 50),
  BrushStamp('ripplesTex', 'Ripples', 54),
  BrushStamp('starGlow', 'Star Glow', 56),
];

/// 图像笔尖库
///
/// 运行时用 [ui.Picture.toImageSync] 同步烘焙出一组灰度笔尖纹理并缓存。纹理以
/// 白色 + 透明度绘制，绘制时通过 `srcIn` 颜色滤镜着色为当前画笔颜色，从而实现
/// 类似 Photoshop 位图笔尖的柔边与颗粒质感——无需外部 .abr / png 资源。
///
/// Brush Stamp Library
///
/// Bakes a set of grayscale tip textures at runtime via [ui.Picture.toImageSync]
/// and caches them. Textures are drawn as white + alpha, then tinted to the
/// current brush color with a `srcIn` color filter at draw time — giving
/// Photoshop-like soft/grainy bitmap tips without any external .abr / png asset.
class BrushStampLibrary {
  BrushStampLibrary._();

  static final BrushStampLibrary instance = BrushStampLibrary._();

  final Map<String, ui.Image> _cache = <String, ui.Image>{};

  /// 烘焙分辨率 / Bake resolution
  static const double _res = 128;

  /// 直接用 Canvas 矢量绘制指定笔尖印章（0 纹理烘焙、0 GPU 阻塞、极速渲染）
  /// Direct vector drawing of stamp tip without bitmap baking
  void paintDirect(
    Canvas canvas,
    String key,
    Offset center,
    double radius,
    Color color, {
    double angle = 0.0,
    bool flipX = false,
    bool flipY = false,
    double hardness = 1.0,
  }) {
    final double s = radius * 2;
    if (s <= 0) return;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (angle != 0.0) canvas.rotate(angle);
    if (flipX || flipY) canvas.scale(flipX ? -1.0 : 1.0, flipY ? -1.0 : 1.0);
    final double scale = s / _res;
    canvas.scale(scale, scale);
    canvas.translate(-_res / 2, -_res / 2);

    final double alpha = hardness < 0.99 ? (0.35 + hardness * 0.65) : 1.0;
    final Color effectiveColor = color.withValues(alpha: color.opacity * alpha);
    _paint(canvas, key, _res, effectiveColor);
    canvas.restore();
  }

  /// 获取（并缓存）指定纹理 / Get (and cache) a texture
  ui.Image get(String key) => _cache.putIfAbsent(key, () => _bake(key));

  /// 异步预热全部笔尖纹理（已升级为直绘，保持空实现兼容）
  void prewarmAsync() {}

  ui.Image _bake(String key) {
    try {
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, _res, _res));
      _paint(canvas, key, _res, Colors.white);
      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = picture.toImageSync(_res.toInt(), _res.toInt());
      picture.dispose();
      return image;
    } catch (_) {
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, _res, _res));
      canvas.drawCircle(
        const Offset(_res / 2, _res / 2),
        _res / 2,
        Paint()..color = Colors.white..isAntiAlias = true,
      );
      final ui.Picture picture = recorder.endRecording();
      final ui.Image fallback = picture.toImageSync(_res.toInt(), _res.toInt());
      picture.dispose();
      return fallback;
    }
  }

  void _paint(Canvas canvas, String key, double s, [Color color = Colors.white]) {
    final double c = s / 2;
    final Offset center = Offset(c, c);
    final Paint white = Paint()
      ..color = color
      ..isAntiAlias = true;

    switch (key) {
      case 'softRound':
        canvas.drawCircle(
          center,
          c,
          Paint()
            ..isAntiAlias = true
            ..shader = ui.Gradient.radial(center, c, <Color>[
              color,
              color.withValues(alpha: 0),
            ], <double>[0.0, 1.0]),
        );

      case 'spray':
        final Random rnd = Random(11);
        for (int i = 0; i < 28; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          canvas.drawCircle(
            p,
            s * 0.01 + rnd.nextDouble() * s * 0.018,
            Paint()
              ..color = color.withValues(alpha: (color.a * 0.55).clamp(0.0, 1.0))
              ..isAntiAlias = true,
          );
        }

      case 'spatter':
        final Random rnd = Random(7);
        for (int i = 0; i < 16; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          canvas.drawCircle(p, s * 0.012 + rnd.nextDouble() * s * 0.038, white);
        }

      case 'chalk':
        final Random rnd = Random(3);
        for (int i = 0; i < 28; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          final double sz = s * (0.025 + rnd.nextDouble() * 0.035);
          canvas.drawRect(
            Rect.fromCenter(center: p, width: sz, height: sz),
            Paint()
              ..color = color.withValues(alpha: (color.a * (0.3 + rnd.nextDouble() * 0.5)).clamp(0.0, 1.0))
              ..isAntiAlias = true,
          );
        }

      case 'grunge':
        final Random rnd = Random(19);
        for (int i = 0; i < 30; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          final double edge = (1 - rr / c).clamp(0.0, 1.0);
          canvas.drawCircle(
            p,
            s * 0.012 + rnd.nextDouble() * s * 0.025,
            Paint()
              ..color = color.withValues(alpha: (color.a * (0.2 + rnd.nextDouble() * 0.7) * edge).clamp(0.0, 1.0))
              ..isAntiAlias = true,
          );
        }

      case 'cloud':
        final Random rnd = Random(23);
        for (int i = 0; i < 5; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * 0.55 * rnd.nextDouble();
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          final double blob = c * (0.35 + rnd.nextDouble() * 0.4);
          canvas.drawCircle(
            p,
            blob,
            Paint()
              ..isAntiAlias = true
              ..shader = ui.Gradient.radial(p, blob, <Color>[
                color.withValues(alpha: (color.a * 0.45).clamp(0.0, 1.0)),
                color.withValues(alpha: 0),
              ]),
          );
        }

      case 'star':
        canvas.drawPath(
          _star(center, 5, c, c * 0.42),
          Paint()
            ..isAntiAlias = true
            ..shader = ui.Gradient.radial(center, c, <Color>[
              color,
              color.withValues(alpha: (color.a * 0.15).clamp(0.0, 1.0)),
            ]),
        );

      case 'halftone':
        const double gap = _res / 6;
        for (double y = gap / 2; y < s; y += gap) {
          for (double x = gap / 2; x < s; x += gap) {
            final Offset p = Offset(x, y);
            final double d = (p - center).distance;
            if (d > c) continue;
            final double dot = (gap / 2) * (1 - d / c);
            if (dot > 0.4) {
              canvas.drawCircle(p, dot, white);
            }
          }
        }

      case 'bristleTex':
        final Random rnd = Random(31);
        for (int i = 0; i < 14; i++) {
          final double dy = (rnd.nextDouble() - 0.5) * s * 0.85;
          final double chord = 2 * sqrt(max(0.0, c * c - dy * dy));
          final double half = chord / 2;
          final double y = c + dy;
          canvas.drawLine(
            Offset(c - half, y),
            Offset(c + half, y),
            Paint()
              ..color = color.withValues(alpha: (color.a * (0.35 + rnd.nextDouble() * 0.5)).clamp(0.0, 1.0))
              ..strokeWidth = s * (0.012 + rnd.nextDouble() * 0.02)
              ..isAntiAlias = true,
          );
        }

      case 'splatter':
        final Random rnd = Random(43);
        canvas.drawCircle(center, c * 0.35, white);
        for (int i = 0; i < 14; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          canvas.drawCircle(p, s * 0.012 + rnd.nextDouble() * s * 0.04, white);
        }

      case 'smoke':
        final Random rnd = Random(53);
        for (int i = 0; i < 5; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * 0.65 * rnd.nextDouble();
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          final double blob = c * (0.3 + rnd.nextDouble() * 0.45);
          canvas.drawCircle(
            p,
            blob,
            Paint()
              ..isAntiAlias = true
              ..shader = ui.Gradient.radial(p, blob, <Color>[
                color.withValues(alpha: (color.a * 0.28).clamp(0.0, 1.0)),
                color.withValues(alpha: 0),
              ]),
          );
        }

      case 'hatch':
        final Paint line = Paint()
          ..color = color.withValues(alpha: (color.a * 0.7).clamp(0.0, 1.0))
          ..strokeWidth = s * 0.022
          ..isAntiAlias = true;
        const double step = _res / 6;
        for (double dy = -c + step; dy < c; dy += step) {
          final double chord = 2 * sqrt(max(0.0, c * c - dy * dy));
          final double len = (chord / 2) * 0.85;
          final Offset p = Offset(c, c + dy);
          canvas.drawLine(p + Offset(-len, -len * 0.5), p + Offset(len, len * 0.5), line);
          canvas.drawLine(p + Offset(-len, len * 0.5), p + Offset(len, -len * 0.5), line);
        }

      case 'dots':
        const double gap = _res / 7;
        for (double y = gap / 2; y < s; y += gap) {
          for (double x = gap / 2; x < s; x += gap) {
            final Offset p = Offset(x, y);
            if ((p - center).distance <= c) {
              canvas.drawCircle(p, gap * 0.25, white);
            }
          }
        }

      case 'crackle':
        final Random rnd = Random(61);
        final Paint crack = Paint()
          ..color = color.withValues(alpha: (color.a * 0.8).clamp(0.0, 1.0))
          ..strokeWidth = s * 0.014
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true;
        for (int i = 0; i < 8; i++) {
          final double a0 = rnd.nextDouble() * 2 * pi;
          final double r0 = c * 0.3 * rnd.nextDouble();
          Offset p = Offset(c + cos(a0) * r0, c + sin(a0) * r0);
          for (int j = 0; j < 3; j++) {
            final double a = rnd.nextDouble() * 2 * pi;
            final double stepLen = s * (0.07 + rnd.nextDouble() * 0.09);
            final Offset q = p + Offset(cos(a), sin(a)) * stepLen;
            if ((q - center).distance <= c) {
              canvas.drawLine(p, q, crack);
              p = q;
            }
          }
        }

      case 'fur':
        final Random rnd = Random(67);
        final Paint hair = Paint()
          ..color = color.withValues(alpha: (color.a * 0.7).clamp(0.0, 1.0))
          ..strokeWidth = s * 0.012
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true;
        for (int i = 0; i < 22; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double r0 = c * 0.6 * rnd.nextDouble();
          final double len = s * (0.08 + rnd.nextDouble() * 0.12);
          final Offset p0 = Offset(c + cos(a) * r0, c + sin(a) * r0);
          final Offset p1 = p0 + Offset(cos(a), sin(a)) * len;
          canvas.drawLine(p0, p1, hair);
        }

      case 'watercolor':
        final Random rnd = Random(71);
        for (int i = 0; i < 8; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * 0.5 * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          canvas.drawCircle(
            p,
            c * (0.3 + rnd.nextDouble() * 0.35),
            Paint()
              ..color = color.withValues(alpha: (color.a * 0.14).clamp(0.0, 1.0))
              ..isAntiAlias = true,
          );
        }

      case 'glitter':
        final Random rnd = Random(83);
        for (int i = 0; i < 15; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          canvas.drawCircle(
            p,
            s * 0.01 + rnd.nextDouble() * s * 0.022,
            Paint()
              ..color = color.withValues(alpha: (color.a * (0.4 + rnd.nextDouble() * 0.6)).clamp(0.0, 1.0))
              ..isAntiAlias = true,
          );
        }

      case 'scratches':
        final Random rnd = Random(89);
        final Paint sc = Paint()
          ..color = color.withValues(alpha: (color.a * 0.75).clamp(0.0, 1.0))
          ..strokeWidth = s * 0.012
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true;
        for (int i = 0; i < 8; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * 0.65 * sqrt(rnd.nextDouble());
          final Offset mid = Offset(c + cos(a) * rr, c + sin(a) * rr);
          final double slant = (rnd.nextDouble() - 0.5) * 0.8;
          final double len = s * (0.15 + rnd.nextDouble() * 0.22);
          final Offset d = Offset(cos(slant), sin(slant)) * (len / 2);
          canvas.drawLine(mid - d, mid + d, sc);
        }

      case 'bubbles':
        final Random rnd = Random(97);
        for (int i = 0; i < 5; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * 0.75 * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          canvas.drawCircle(
            p,
            s * (0.05 + rnd.nextDouble() * 0.1),
            Paint()
              ..color = color.withValues(alpha: (color.a * (0.5 + rnd.nextDouble() * 0.5)).clamp(0.0, 1.0))
              ..style = PaintingStyle.stroke
              ..strokeWidth = s * 0.018
              ..isAntiAlias = true,
          );
        }

      case 'sand':
        final Random rnd = Random(101);
        for (int i = 0; i < 35; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          canvas.drawCircle(
            p,
            s * 0.012,
            Paint()
              ..color = color.withValues(alpha: (color.a * (0.35 + rnd.nextDouble() * 0.65)).clamp(0.0, 1.0))
              ..isAntiAlias = true,
          );
        }

      case 'mesh':
        final Paint grid = Paint()
          ..color = color.withValues(alpha: (color.a * 0.65).clamp(0.0, 1.0))
          ..strokeWidth = s * 0.016
          ..isAntiAlias = true;
        const double step = _res / 6;
        for (double dy = -c + step; dy < c; dy += step) {
          final double chord = 2 * sqrt(max(0.0, c * c - dy * dy));
          final double halfChord = chord / 2;
          canvas.drawLine(Offset(c - halfChord, c + dy), Offset(c + halfChord, c + dy), grid);
          canvas.drawLine(Offset(c + dy, c - halfChord), Offset(c + dy, c + halfChord), grid);
        }

      case 'confettiTex':
        final Random rnd = Random(103);
        for (int i = 0; i < 7; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * 0.8 * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          canvas.save();
          canvas.translate(p.dx, p.dy);
          canvas.rotate(rnd.nextDouble() * 2 * pi);
          final double sz = s * (0.05 + rnd.nextDouble() * 0.06);
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: sz, height: sz * 0.6),
            white,
          );
          canvas.restore();
        }

      case 'galaxy':
        final Random rnd = Random(109);
        for (int i = 0; i < 25; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * pow(rnd.nextDouble(), 1.5);
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          canvas.drawCircle(
            p,
            s * 0.009 + rnd.nextDouble() * s * 0.018,
            Paint()
              ..color = color.withValues(alpha: (color.a * (0.4 + rnd.nextDouble() * 0.6)).clamp(0.0, 1.0))
              ..isAntiAlias = true,
          );
        }

      case 'rake':
        final Paint bar = Paint()
          ..color = color.withValues(alpha: (color.a * 0.85).clamp(0.0, 1.0))
          ..strokeWidth = s * 0.055
          ..isAntiAlias = true;
        for (double dy = -c * 0.7; dy <= c * 0.7; dy += c * 0.45) {
          final double chord = 2 * sqrt(max(0.0, c * c - dy * dy));
          final double half = chord / 2;
          canvas.drawLine(Offset(c - half, c + dy), Offset(c + half, c + dy), bar);
        }

      case 'embers':
        final Random rnd = Random(113);
        for (int i = 0; i < 8; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * 0.85 * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          final double g = s * (0.04 + rnd.nextDouble() * 0.07);
          canvas.drawCircle(
            p,
            g,
            Paint()
              ..isAntiAlias = true
              ..shader = ui.Gradient.radial(p, g, <Color>[
                color,
                color.withValues(alpha: 0),
              ]),
          );
        }

      case 'snowDots':
        final Random rnd = Random(127);
        for (int i = 0; i < 10; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * 0.85 * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          final double g = s * (0.03 + rnd.nextDouble() * 0.07);
          canvas.drawCircle(
            p,
            g,
            Paint()
              ..isAntiAlias = true
              ..shader = ui.Gradient.radial(p, g, <Color>[
                color.withValues(alpha: (color.a * 0.9).clamp(0.0, 1.0)),
                color.withValues(alpha: 0),
              ]),
          );
        }

      case 'marble':
        final Random rnd = Random(131);
        for (int i = 0; i < 5; i++) {
          final double a0 = rnd.nextDouble() * 2 * pi;
          final double r0 = c * 0.5 * rnd.nextDouble();
          Offset p = Offset(c + cos(a0) * r0, c + sin(a0) * r0);
          final Path vein = Path()..moveTo(p.dx, p.dy);
          for (int j = 0; j < 3; j++) {
            final Offset ctrl = p + Offset((rnd.nextDouble() - 0.5) * s * 0.3, (rnd.nextDouble() - 0.5) * s * 0.3);
            final Offset q = p + Offset((rnd.nextDouble() - 0.5) * s * 0.35, (rnd.nextDouble() - 0.5) * s * 0.35);
            if ((q - center).distance <= c) {
              vein.quadraticBezierTo(ctrl.dx, ctrl.dy, q.dx, q.dy);
              p = q;
            }
          }
          canvas.drawPath(
            vein,
            Paint()
              ..color = color.withValues(alpha: (color.a * 0.4).clamp(0.0, 1.0))
              ..style = PaintingStyle.stroke
              ..strokeWidth = s * 0.02
              ..isAntiAlias = true,
          );
        }

      case 'weave':
        const double cell = _res / 5;
        for (int r = 0; r < 5; r++) {
          for (int col = 0; col < 5; col++) {
            final Offset o = Offset(col * cell + cell / 2, r * cell + cell / 2);
            if ((o - center).distance > c * 0.95) continue;
            final bool horiz = (r + col).isEven;
            final Rect rect = horiz
                ? Rect.fromCenter(center: o, width: cell * 0.85, height: cell * 0.4)
                : Rect.fromCenter(center: o, width: cell * 0.4, height: cell * 0.85);
            canvas.drawRect(
              rect,
              Paint()
                ..color = color.withValues(alpha: (color.a * 0.75).clamp(0.0, 1.0))
                ..isAntiAlias = true,
            );
          }
        }

      case 'honeycomb':
        final Paint hex = Paint()
          ..color = color.withValues(alpha: (color.a * 0.75).clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.018
          ..isAntiAlias = true;
        final double hr = s * 0.16;
        for (int row = -2; row <= 2; row++) {
          for (int col = -2; col <= 2; col++) {
            final double cx = c + col * hr * 1.5;
            final double cy = c + row * hr * sqrt(3) + (col.isEven ? 0 : hr * sqrt(3) / 2);
            final Offset hexCenter = Offset(cx, cy);
            if ((hexCenter - center).distance > c * 0.9) continue;
            final Path hp = Path();
            for (int k = 0; k < 6; k++) {
              final double a = k * pi / 3;
              final Offset p = Offset(cx + hr * cos(a), cy + hr * sin(a));
              k == 0 ? hp.moveTo(p.dx, p.dy) : hp.lineTo(p.dx, p.dy);
            }
            hp.close();
            canvas.drawPath(hp, hex);
          }
        }

      case 'rainStreaks':
        final Random rnd = Random(137);
        final Paint drop = Paint()
          ..color = color.withValues(alpha: (color.a * 0.6).clamp(0.0, 1.0))
          ..strokeWidth = s * 0.016
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true;
        for (int i = 0; i < 10; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * 0.75 * sqrt(rnd.nextDouble());
          final Offset p0 = Offset(c + cos(a) * rr, c + sin(a) * rr);
          final Offset p1 = p0 + Offset(s * 0.08, s * 0.22);
          canvas.drawLine(p0, p1, drop);
        }

      case 'cobweb':
        final Paint web = Paint()
          ..color = color.withValues(alpha: (color.a * 0.6).clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.012
          ..isAntiAlias = true;
        const int spokes = 8;
        for (int i = 0; i < spokes; i++) {
          final double a = i * 2 * pi / spokes;
          canvas.drawLine(center, center + Offset(cos(a), sin(a)) * c, web);
        }
        for (int ring = 1; ring <= 3; ring++) {
          final double rr = c * ring / 3;
          final Path poly = Path();
          for (int i = 0; i <= spokes; i++) {
            final double a = i * 2 * pi / spokes;
            final Offset p = center + Offset(cos(a), sin(a)) * rr;
            i == 0 ? poly.moveTo(p.dx, p.dy) : poly.lineTo(p.dx, p.dy);
          }
          canvas.drawPath(poly, web);
        }

      case 'cells':
        final Random rnd = Random(139);
        for (int i = 0; i < 8; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * 0.75 * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          canvas.drawCircle(
            p,
            s * (0.06 + rnd.nextDouble() * 0.12),
            Paint()
              ..color = color.withValues(alpha: (color.a * 0.6).clamp(0.0, 1.0))
              ..style = PaintingStyle.stroke
              ..strokeWidth = s * 0.016
              ..isAntiAlias = true,
          );
        }

      case 'inkDrops':
        final Random rnd = Random(149);
        for (int i = 0; i < 3; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * 0.45 * rnd.nextDouble();
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          canvas.drawCircle(p, c * (0.22 + rnd.nextDouble() * 0.22), white);
        }
        for (int i = 0; i < 8; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          canvas.drawCircle(p, s * 0.01 + rnd.nextDouble() * s * 0.022, white);
        }

      case 'staticNoise':
        final Random rnd = Random(151);
        for (int i = 0; i < 30; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          canvas.drawCircle(
            p,
            s * 0.014,
            Paint()
              ..color = color.withValues(alpha: (color.a * (0.4 + rnd.nextDouble() * 0.6)).clamp(0.0, 1.0))
              ..isAntiAlias = true,
          );
        }

      case 'orangePeel':
        final Random rnd = Random(157);
        for (int i = 0; i < 22; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          final double edge = (1 - rr / c).clamp(0.0, 1.0);
          canvas.drawCircle(
            p,
            s * (0.014 + rnd.nextDouble() * 0.024),
            Paint()
              ..color = color.withValues(alpha: (color.a * (0.25 + rnd.nextDouble() * 0.5) * edge).clamp(0.0, 1.0))
              ..isAntiAlias = true,
          );
        }

      case 'bokeh':
        final Random rnd = Random(163);
        for (int i = 0; i < 5; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * 0.75 * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          final double g = s * (0.08 + rnd.nextDouble() * 0.14);
          if (rnd.nextBool()) {
            canvas.drawCircle(
              p,
              g,
              Paint()
                ..isAntiAlias = true
                ..shader = ui.Gradient.radial(p, g, <Color>[
                  color.withValues(alpha: (color.a * 0.55).clamp(0.0, 1.0)),
                  color.withValues(alpha: (color.a * 0.05).clamp(0.0, 1.0)),
                ]),
            );
          } else {
            canvas.drawCircle(
              p,
              g,
              Paint()
                ..color = color.withValues(alpha: (color.a * 0.55).clamp(0.0, 1.0))
                ..style = PaintingStyle.stroke
                ..strokeWidth = s * 0.018
                ..isAntiAlias = true,
            );
          }
        }

      case 'hearts':
        final Random rnd = Random(167);
        for (int i = 0; i < 3; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * 0.7 * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          final double hs = s * (0.08 + rnd.nextDouble() * 0.08);
          canvas.save();
          canvas.translate(p.dx, p.dy);
          canvas.rotate((rnd.nextDouble() - 0.5) * 1.2);
          final Path h = Path();
          for (int k = 0; k <= 24; k++) {
            final double t = k / 24 * 2 * pi;
            final double x = 16 * pow(sin(t), 3).toDouble();
            final double y =
                13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t);
            final double px = x / 16 * hs;
            final double py = -y / 16 * hs;
            k == 0 ? h.moveTo(px, py) : h.lineTo(px, py);
          }
          h.close();
          canvas.drawPath(h, white);
          canvas.restore();
        }

      case 'musicNotes':
        final Random rnd = Random(173);
        for (int i = 0; i < 2; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * 0.65 * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          final double ns = s * (0.1 + rnd.nextDouble() * 0.06);
          canvas.save();
          canvas.translate(p.dx, p.dy);
          canvas.rotate((rnd.nextDouble() - 0.5) * 0.8);
          canvas.drawOval(
            Rect.fromCenter(
                center: Offset(-ns * 0.35, ns * 0.55), width: ns * 0.7, height: ns * 0.5),
            white,
          );
          canvas.drawRect(
            Rect.fromLTWH(-ns * 0.06, -ns, ns * 0.12, ns * 1.6),
            white,
          );
          canvas.drawPath(
            Path()
              ..moveTo(ns * 0.06, -ns)
              ..lineTo(ns * 0.5, -ns * 0.7)
              ..lineTo(ns * 0.06, -ns * 0.45)
              ..close(),
            white,
          );
          canvas.restore();
        }

      case 'lace':
        final Paint thin = Paint()
          ..color = color.withValues(alpha: (color.a * 0.75).clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.014
          ..isAntiAlias = true;
        for (int ring = 1; ring <= 2; ring++) {
          final double rr = c * ring / 2.2;
          canvas.drawCircle(center, rr, thin);
          final int n = 6 * ring;
          for (int i = 0; i < n; i++) {
            final double a = i * 2 * pi / n;
            final Offset p = center + Offset(cos(a), sin(a)) * rr;
            canvas.drawCircle(p, s * 0.025, thin);
          }
        }

      case 'petals':
        final Random rnd = Random(179);
        for (int i = 0; i < 4; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * 0.7 * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          final double ps = s * (0.1 + rnd.nextDouble() * 0.07);
          canvas.save();
          canvas.translate(p.dx, p.dy);
          canvas.rotate(rnd.nextDouble() * 2 * pi);
          canvas.drawPath(
            Path()
              ..moveTo(0, -ps)
              ..quadraticBezierTo(ps * 0.75, 0, 0, ps)
              ..quadraticBezierTo(-ps * 0.75, 0, 0, -ps)
              ..close(),
            Paint()
              ..color = color.withValues(alpha: (color.a * (0.55 + rnd.nextDouble() * 0.45)).clamp(0.0, 1.0))
              ..isAntiAlias = true,
          );
          canvas.restore();
        }

      case 'circuit':
        final Random rnd = Random(181);
        final Paint trace = Paint()
          ..color = color.withValues(alpha: (color.a * 0.85).clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.02
          ..isAntiAlias = true;
        for (int i = 0; i < 5; i++) {
          final double a0 = rnd.nextDouble() * 2 * pi;
          final double r0 = c * 0.55 * rnd.nextDouble();
          Offset p = Offset(c + cos(a0) * r0, c + sin(a0) * r0);
          final Path route = Path()..moveTo(p.dx, p.dy);
          for (int j = 0; j < 2; j++) {
            final bool horiz = rnd.nextBool();
            final double len = s * (0.08 + rnd.nextDouble() * 0.14);
            final Offset nextP = horiz ? Offset(p.dx + len, p.dy) : Offset(p.dx, p.dy + len);
            if ((nextP - center).distance <= c) {
              route.lineTo(nextP.dx, nextP.dy);
              p = nextP;
            }
          }
          canvas.drawPath(route, trace);
          canvas.drawCircle(p, s * 0.022, white);
        }

      case 'ripplesTex':
        final Random rnd = Random(191);
        for (int i = 0; i < 3; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * 0.5 * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          final double maxR = s * (0.12 + rnd.nextDouble() * 0.16);
          for (int k = 1; k <= 2; k++) {
            canvas.drawCircle(
              p,
              maxR * k / 2,
              Paint()
                ..color = color.withValues(alpha: (color.a * (0.6 - k * 0.18)).clamp(0.0, 1.0))
                ..style = PaintingStyle.stroke
                ..strokeWidth = s * 0.015
                ..isAntiAlias = true,
            );
          }
        }

      case 'starGlow':
        final Random rnd = Random(193);
        for (int i = 0; i < 3; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * 0.7 * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          final double g = s * (0.08 + rnd.nextDouble() * 0.11);
          canvas.drawCircle(
            p,
            g * 1.4,
            Paint()
              ..isAntiAlias = true
              ..shader = ui.Gradient.radial(p, g * 1.4, <Color>[
                color.withValues(alpha: (color.a * 0.5).clamp(0.0, 1.0)),
                color.withValues(alpha: 0),
              ]),
          );
          canvas.save();
          canvas.translate(p.dx, p.dy);
          canvas.drawPath(
            Path()
              ..moveTo(0, -g)
              ..quadraticBezierTo(0, 0, g, 0)
              ..quadraticBezierTo(0, 0, 0, g)
              ..quadraticBezierTo(0, 0, -g, 0)
              ..quadraticBezierTo(0, 0, 0, -g)
              ..close(),
            white,
          );
          canvas.restore();
        }

      default:
        canvas.drawCircle(center, c, white);
    }
  }

  Path _star(Offset center, int count, double outer, double inner) {
    final Path path = Path();
    final int total = count * 2;
    for (int i = 0; i < total; i++) {
      final double r = i.isEven ? outer : inner;
      final double a = -pi / 2 + i * pi / count;
      final Offset p = Offset(center.dx + r * cos(a), center.dy + r * sin(a));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    return path;
  }
}
