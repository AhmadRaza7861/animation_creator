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

  /// 获取（并缓存）指定纹理 / Get (and cache) a texture
  ui.Image get(String key) => _cache.putIfAbsent(key, () => _bake(key));

  ui.Image _bake(String key) {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, _res, _res));
    _paint(canvas, key, _res);
    return recorder.endRecording().toImageSync(_res.toInt(), _res.toInt());
  }

  void _paint(Canvas canvas, String key, double s) {
    final double c = s / 2;
    final Offset center = Offset(c, c);
    final Paint white = Paint()
      ..color = Colors.white
      ..isAntiAlias = true;

    switch (key) {
      case 'softRound':
        canvas.drawCircle(
          center,
          c,
          Paint()
            ..isAntiAlias = true
            ..shader = ui.Gradient.radial(center, c, <Color>[
              Colors.white,
              Colors.white.withValues(alpha: 0),
            ], <double>[0.0, 1.0]),
        );

      case 'spray':
        // 中心密集、向外稀疏的喷雾
        final Random rnd = Random(11);
        for (int i = 0; i < 900; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * rnd.nextDouble();
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          canvas.drawCircle(
            p,
            s * 0.006 + rnd.nextDouble() * s * 0.008,
            Paint()..color = Colors.white.withValues(alpha: 0.5),
          );
        }

      case 'spatter':
        final Random rnd = Random(7);
        for (int i = 0; i < 150; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          canvas.drawCircle(p, s * 0.008 + rnd.nextDouble() * s * 0.04, white);
        }

      case 'chalk':
        canvas.save();
        canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: c)));
        final Random rnd = Random(3);
        for (int i = 0; i < 1100; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * rnd.nextDouble();
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          canvas.drawRect(
            Rect.fromCenter(center: p, width: s * 0.02, height: s * 0.02),
            Paint()..color = Colors.white.withValues(alpha: 0.3 + rnd.nextDouble() * 0.5),
          );
        }
        canvas.restore();

      case 'grunge':
        canvas.save();
        canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: c)));
        final Random rnd = Random(19);
        for (int i = 0; i < 1400; i++) {
          final Offset p = Offset(rnd.nextDouble() * s, rnd.nextDouble() * s);
          final double d = (p - center).distance;
          final double edge = (1 - d / c).clamp(0.0, 1.0);
          canvas.drawCircle(
            p,
            s * 0.008 + rnd.nextDouble() * s * 0.012,
            Paint()..color = Colors.white.withValues(alpha: rnd.nextDouble() * edge),
          );
        }
        canvas.restore();

      case 'cloud':
        final Random rnd = Random(23);
        for (int i = 0; i < 26; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * 0.6 * rnd.nextDouble();
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          final double blob = c * (0.25 + rnd.nextDouble() * 0.35);
          canvas.drawCircle(
            p,
            blob,
            Paint()
              ..isAntiAlias = true
              ..shader = ui.Gradient.radial(p, blob, <Color>[
                Colors.white.withValues(alpha: 0.5),
                Colors.white.withValues(alpha: 0),
              ]),
          );
        }

      case 'star':
        canvas.drawPath(
          _star(center, 5, c, c * 0.42),
          Paint()
            ..isAntiAlias = true
            ..shader = ui.Gradient.radial(center, c, <Color>[
              Colors.white,
              Colors.white.withValues(alpha: 0.15),
            ]),
        );

      case 'halftone':
        // 网点：由内向外逐渐变小的圆点阵列
        const double gap = _res / 11;
        for (double y = gap / 2; y < s; y += gap) {
          for (double x = gap / 2; x < s; x += gap) {
            final Offset p = Offset(x, y);
            final double d = (p - center).distance;
            if (d > c) {
              continue;
            }
            final double dot = (gap / 2) * (1 - d / c);
            if (dot > 0.4) {
              canvas.drawCircle(p, dot, white);
            }
          }
        }

      case 'bristleTex':
        // 鬃毛纹理：多条粗细不一的横向条纹
        canvas.save();
        canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: c)));
        final Random rnd = Random(31);
        for (int i = 0; i < 60; i++) {
          final double y = rnd.nextDouble() * s;
          canvas.drawLine(
            Offset(0, y),
            Offset(s, y),
            Paint()
              ..color = Colors.white.withValues(alpha: 0.25 + rnd.nextDouble() * 0.5)
              ..strokeWidth = s * (0.004 + rnd.nextDouble() * 0.01),
          );
        }
        canvas.restore();

      case 'splatter':
        final Random rnd = Random(43);
        canvas.drawCircle(center, c * 0.4, white);
        for (int i = 0; i < 90; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          canvas.drawCircle(p, s * 0.006 + rnd.nextDouble() * s * 0.045, white);
        }

      case 'smoke':
        // 烟雾：多层稀薄的柔和团块
        final Random rnd = Random(53);
        for (int i = 0; i < 40; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * 0.7 * rnd.nextDouble();
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          final double blob = c * (0.2 + rnd.nextDouble() * 0.4);
          canvas.drawCircle(
            p,
            blob,
            Paint()
              ..isAntiAlias = true
              ..shader = ui.Gradient.radial(p, blob, <Color>[
                Colors.white.withValues(alpha: 0.22),
                Colors.white.withValues(alpha: 0),
              ]),
          );
        }

      case 'hatch':
        // 交叉排线
        canvas.save();
        canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: c)));
        final Paint line = Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..strokeWidth = s * 0.012;
        for (double d = -s; d < s * 2; d += s * 0.12) {
          canvas.drawLine(Offset(d, 0), Offset(d - s, s), line);
          canvas.drawLine(Offset(d, 0), Offset(d + s, s), line);
        }
        canvas.restore();

      case 'dots':
        // 均匀圆点阵
        const double gap = _res / 12;
        for (double y = gap / 2; y < s; y += gap) {
          for (double x = gap / 2; x < s; x += gap) {
            final Offset p = Offset(x, y);
            if ((p - center).distance <= c) {
              canvas.drawCircle(p, gap * 0.22, white);
            }
          }
        }

      case 'crackle':
        // 裂纹：随机细线
        canvas.save();
        canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: c)));
        final Random rnd = Random(61);
        final Paint crack = Paint()
          ..color = Colors.white.withValues(alpha: 0.8)
          ..strokeWidth = s * 0.008
          ..strokeCap = StrokeCap.round;
        for (int i = 0; i < 60; i++) {
          Offset p = Offset(rnd.nextDouble() * s, rnd.nextDouble() * s);
          for (int j = 0; j < 4; j++) {
            final double a = rnd.nextDouble() * 2 * pi;
            final Offset q = p + Offset(cos(a), sin(a)) * s * 0.1;
            canvas.drawLine(p, q, crack);
            p = q;
          }
        }
        canvas.restore();

      case 'fur':
        // 皮毛：由中心向外发散的短线
        final Random rnd = Random(67);
        final Paint hair = Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..strokeWidth = s * 0.008
          ..strokeCap = StrokeCap.round;
        for (int i = 0; i < 240; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double r0 = c * rnd.nextDouble();
          final double len = s * (0.05 + rnd.nextDouble() * 0.1);
          final Offset p0 = Offset(c + cos(a) * r0, c + sin(a) * r0);
          final Offset p1 = p0 + Offset(cos(a), sin(a)) * len;
          canvas.drawLine(p0, p1, hair);
        }

      case 'watercolor':
        // 水彩：多层不规则的低透明团块
        final Random rnd = Random(71);
        for (int i = 0; i < 60; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * 0.55 * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          canvas.drawCircle(
            p,
            c * (0.25 + rnd.nextDouble() * 0.35),
            Paint()..color = Colors.white.withValues(alpha: 0.06),
          );
        }

      case 'glitter':
        // 闪粉：稀疏、明暗不一的小点
        final Random rnd = Random(83);
        for (int i = 0; i < 130; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          canvas.drawCircle(
            p,
            s * 0.006 + rnd.nextDouble() * s * 0.02,
            Paint()..color = Colors.white.withValues(alpha: 0.35 + rnd.nextDouble() * 0.65),
          );
        }

      case 'scratches':
        // 划痕：随机直线
        canvas.save();
        canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: c)));
        final Random rnd = Random(89);
        final Paint sc = Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..strokeWidth = s * 0.006
          ..strokeCap = StrokeCap.round;
        for (int i = 0; i < 44; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final Offset p0 = Offset(rnd.nextDouble() * s, rnd.nextDouble() * s);
          final Offset p1 = p0 + Offset(cos(a), sin(a)) * s * (0.15 + rnd.nextDouble() * 0.35);
          canvas.drawLine(p0, p1, sc);
        }
        canvas.restore();

      case 'bubbles':
        // 气泡：大小不一的圆环
        final Random rnd = Random(97);
        for (int i = 0; i < 20; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * 0.9 * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          canvas.drawCircle(
            p,
            s * (0.03 + rnd.nextDouble() * 0.1),
            Paint()
              ..color = Colors.white.withValues(alpha: 0.5 + rnd.nextDouble() * 0.5)
              ..style = PaintingStyle.stroke
              ..strokeWidth = s * 0.01,
          );
        }

      case 'sand':
        // 细沙：致密的极小颗粒
        canvas.save();
        canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: c)));
        final Random rnd = Random(101);
        for (int i = 0; i < 2600; i++) {
          final Offset p = Offset(rnd.nextDouble() * s, rnd.nextDouble() * s);
          canvas.drawCircle(
            p,
            s * 0.004,
            Paint()..color = Colors.white.withValues(alpha: 0.2 + rnd.nextDouble() * 0.5),
          );
        }
        canvas.restore();

      case 'mesh':
        // 网格
        canvas.save();
        canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: c)));
        final Paint grid = Paint()
          ..color = Colors.white.withValues(alpha: 0.6)
          ..strokeWidth = s * 0.01;
        for (double d = 0; d <= s; d += s * 0.11) {
          canvas.drawLine(Offset(d, 0), Offset(d, s), grid);
          canvas.drawLine(Offset(0, d), Offset(s, d), grid);
        }
        canvas.restore();

      case 'confettiTex':
        // 彩纸：散布并旋转的小方块/三角
        final Random rnd = Random(103);
        for (int i = 0; i < 40; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * 0.9 * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          canvas.save();
          canvas.translate(p.dx, p.dy);
          canvas.rotate(rnd.nextDouble() * 2 * pi);
          final double sz = s * (0.03 + rnd.nextDouble() * 0.04);
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: sz, height: sz * 0.6),
            white,
          );
          canvas.restore();
        }

      case 'galaxy':
        // 星系：中心密集、外围稀疏的星点，夹杂少量亮星
        canvas.save();
        canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: c)));
        final Random rnd = Random(109);
        for (int i = 0; i < 700; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * rnd.nextDouble() * rnd.nextDouble();
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          canvas.drawCircle(
            p,
            s * 0.004 + rnd.nextDouble() * s * 0.006,
            Paint()..color = Colors.white.withValues(alpha: 0.3 + rnd.nextDouble() * 0.7),
          );
        }
        canvas.restore();

      case 'rake':
        // 排刷：等距的平行粗线
        canvas.save();
        canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: c)));
        final Paint bar = Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..strokeWidth = s * 0.04;
        for (double y = s * 0.08; y < s; y += s * 0.16) {
          canvas.drawLine(Offset(0, y), Offset(s, y), bar);
        }
        canvas.restore();

      case 'embers':
        // 火星：柔光小点
        final Random rnd = Random(113);
        for (int i = 0; i < 60; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          final double g = s * (0.02 + rnd.nextDouble() * 0.05);
          canvas.drawCircle(
            p,
            g,
            Paint()
              ..isAntiAlias = true
              ..shader = ui.Gradient.radial(p, g, <Color>[
                Colors.white,
                Colors.white.withValues(alpha: 0),
              ]),
          );
        }

      case 'snowDots':
        // 雪：大小不一的柔和白点
        final Random rnd = Random(127);
        for (int i = 0; i < 90; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          final double g = s * (0.015 + rnd.nextDouble() * 0.06);
          canvas.drawCircle(
            p,
            g,
            Paint()
              ..isAntiAlias = true
              ..shader = ui.Gradient.radial(p, g, <Color>[
                Colors.white.withValues(alpha: 0.9),
                Colors.white.withValues(alpha: 0),
              ]),
          );
        }

      case 'marble':
        // 大理石：低透明的随机曲线纹路
        canvas.save();
        canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: c)));
        final Random rnd = Random(131);
        for (int i = 0; i < 30; i++) {
          Offset p = Offset(rnd.nextDouble() * s, rnd.nextDouble() * s);
          final Path vein = Path()..moveTo(p.dx, p.dy);
          for (int j = 0; j < 5; j++) {
            final Offset ctrl = p + Offset((rnd.nextDouble() - 0.5) * s * 0.4, (rnd.nextDouble() - 0.5) * s * 0.4);
            final Offset q = p + Offset((rnd.nextDouble() - 0.5) * s * 0.5, (rnd.nextDouble() - 0.5) * s * 0.5);
            vein.quadraticBezierTo(ctrl.dx, ctrl.dy, q.dx, q.dy);
            p = q;
          }
          canvas.drawPath(
            vein,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.15)
              ..style = PaintingStyle.stroke
              ..strokeWidth = s * 0.012,
          );
        }
        canvas.restore();

      case 'weave':
        // 编织：纵横交错的短条
        canvas.save();
        canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: c)));
        const double cell = _res / 9;
        for (int r = 0; r < 9; r++) {
          for (int col = 0; col < 9; col++) {
            final bool horiz = (r + col).isEven;
            final Offset o = Offset(col * cell + cell / 2, r * cell + cell / 2);
            final Rect rect = horiz
                ? Rect.fromCenter(center: o, width: cell * 0.9, height: cell * 0.45)
                : Rect.fromCenter(center: o, width: cell * 0.45, height: cell * 0.9);
            canvas.drawRect(rect, Paint()..color = Colors.white.withValues(alpha: 0.75));
          }
        }
        canvas.restore();

      case 'honeycomb':
        // 蜂窝：六边形网格
        canvas.save();
        canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: c)));
        final Paint hex = Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.012;
        final double hr = s * 0.11;
        for (int row = -1; row < 7; row++) {
          for (int col = -1; col < 7; col++) {
            final double cx = col * hr * 1.5;
            final double cy = row * hr * sqrt(3) + (col.isEven ? 0 : hr * sqrt(3) / 2);
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
        canvas.restore();

      case 'rainStreaks':
        // 雨丝：倾斜的柔和条纹
        canvas.save();
        canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: c)));
        final Random rnd = Random(137);
        final Paint drop = Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..strokeWidth = s * 0.008
          ..strokeCap = StrokeCap.round;
        for (int i = 0; i < 55; i++) {
          final Offset p0 = Offset(rnd.nextDouble() * s, rnd.nextDouble() * s);
          final Offset p1 = p0 + Offset(s * 0.12, s * 0.28);
          canvas.drawLine(p0, p1, drop);
        }
        canvas.restore();

      case 'cobweb':
        // 蛛网：放射状与同心多边形
        final Paint web = Paint()
          ..color = Colors.white.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.008;
        const int spokes = 12;
        for (int i = 0; i < spokes; i++) {
          final double a = i * 2 * pi / spokes;
          canvas.drawLine(center, center + Offset(cos(a), sin(a)) * c, web);
        }
        for (int ring = 1; ring <= 5; ring++) {
          final double rr = c * ring / 5;
          final Path poly = Path();
          for (int i = 0; i <= spokes; i++) {
            final double a = i * 2 * pi / spokes;
            final Offset p = center + Offset(cos(a), sin(a)) * rr;
            i == 0 ? poly.moveTo(p.dx, p.dy) : poly.lineTo(p.dx, p.dy);
          }
          canvas.drawPath(poly, web);
        }

      case 'cells':
        // 细胞：随机大小的圆环相互重叠
        canvas.save();
        canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: c)));
        final Random rnd = Random(139);
        for (int i = 0; i < 40; i++) {
          final Offset p = Offset(rnd.nextDouble() * s, rnd.nextDouble() * s);
          canvas.drawCircle(
            p,
            s * (0.05 + rnd.nextDouble() * 0.12),
            Paint()
              ..color = Colors.white.withValues(alpha: 0.5)
              ..style = PaintingStyle.stroke
              ..strokeWidth = s * 0.008,
          );
        }
        canvas.restore();

      case 'inkDrops':
        // 墨滴：几团大柔块 + 拖尾小滴
        final Random rnd = Random(149);
        for (int i = 0; i < 5; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * 0.5 * rnd.nextDouble();
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          canvas.drawCircle(p, c * (0.2 + rnd.nextDouble() * 0.22), white);
        }
        for (int i = 0; i < 40; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          canvas.drawCircle(p, s * 0.004 + rnd.nextDouble() * s * 0.02, white);
        }

      case 'staticNoise':
        // 电视雪花：致密随机白点
        canvas.save();
        canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: c)));
        final Random rnd = Random(151);
        for (int i = 0; i < 2200; i++) {
          final Offset p = Offset(rnd.nextDouble() * s, rnd.nextDouble() * s);
          canvas.drawCircle(
            p,
            s * 0.006,
            Paint()..color = Colors.white.withValues(alpha: 0.4 + rnd.nextDouble() * 0.6),
          );
        }
        canvas.restore();

      case 'orangePeel':
        // 橘皮：大小不一的凹坑状斑点
        canvas.save();
        canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: c)));
        final Random rnd = Random(157);
        for (int i = 0; i < 320; i++) {
          final Offset p = Offset(rnd.nextDouble() * s, rnd.nextDouble() * s);
          final double d = (p - center).distance;
          final double edge = (1 - d / c).clamp(0.0, 1.0);
          canvas.drawCircle(
            p,
            s * (0.008 + rnd.nextDouble() * 0.022),
            Paint()..color = Colors.white.withValues(alpha: (0.15 + rnd.nextDouble() * 0.5) * edge),
          );
        }
        canvas.restore();

      case 'bokeh':
        // 散景：明暗不一的光斑，部分为柔和光环
        final Random rnd = Random(163);
        for (int i = 0; i < 22; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * 0.85 * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          final double g = s * (0.05 + rnd.nextDouble() * 0.12);
          if (rnd.nextBool()) {
            canvas.drawCircle(
              p,
              g,
              Paint()
                ..isAntiAlias = true
                ..shader = ui.Gradient.radial(p, g, <Color>[
                  Colors.white.withValues(alpha: 0.55),
                  Colors.white.withValues(alpha: 0.05),
                ]),
            );
          } else {
            canvas.drawCircle(
              p,
              g,
              Paint()
                ..color = Colors.white.withValues(alpha: 0.5)
                ..style = PaintingStyle.stroke
                ..strokeWidth = s * 0.012,
            );
          }
        }

      case 'hearts':
        // 心形散布
        final Random rnd = Random(167);
        for (int i = 0; i < 9; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * 0.8 * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          final double hs = s * (0.05 + rnd.nextDouble() * 0.06);
          canvas.save();
          canvas.translate(p.dx, p.dy);
          canvas.rotate((rnd.nextDouble() - 0.5) * 1.2);
          final Path h = Path();
          for (int k = 0; k <= 40; k++) {
            final double t = k / 40 * 2 * pi;
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
        // 音符散布
        final Random rnd = Random(173);
        for (int i = 0; i < 7; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * 0.75 * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          final double ns = s * (0.08 + rnd.nextDouble() * 0.05);
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
        // 蕾丝：放射状小圆与同心细弧
        final Paint thin = Paint()
          ..color = Colors.white.withValues(alpha: 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.008;
        for (int ring = 1; ring <= 3; ring++) {
          final double rr = c * ring / 3.2;
          canvas.drawCircle(center, rr, thin);
          final int n = 8 * ring;
          for (int i = 0; i < n; i++) {
            final double a = i * 2 * pi / n;
            final Offset p = center + Offset(cos(a), sin(a)) * rr;
            canvas.drawCircle(p, s * 0.022, thin);
          }
        }

      case 'petals':
        // 花瓣：随机旋转散布的尖椭圆
        final Random rnd = Random(179);
        for (int i = 0; i < 11; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * 0.78 * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          final double ps = s * (0.07 + rnd.nextDouble() * 0.06);
          canvas.save();
          canvas.translate(p.dx, p.dy);
          canvas.rotate(rnd.nextDouble() * 2 * pi);
          canvas.drawPath(
            Path()
              ..moveTo(0, -ps)
              ..quadraticBezierTo(ps * 0.75, 0, 0, ps)
              ..quadraticBezierTo(-ps * 0.75, 0, 0, -ps)
              ..close(),
            Paint()..color = Colors.white.withValues(alpha: 0.55 + rnd.nextDouble() * 0.45),
          );
          canvas.restore();
        }

      case 'circuit':
        // 电路板：直角走线与焊盘
        canvas.save();
        canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: c)));
        final Random rnd = Random(181);
        final Paint trace = Paint()
          ..color = Colors.white.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.012;
        for (int i = 0; i < 16; i++) {
          Offset p = Offset(rnd.nextDouble() * s, rnd.nextDouble() * s);
          final Path route = Path()..moveTo(p.dx, p.dy);
          for (int j = 0; j < 3; j++) {
            final bool horiz = rnd.nextBool();
            final double len = s * (0.08 + rnd.nextDouble() * 0.18);
            p = horiz ? Offset(p.dx + len, p.dy) : Offset(p.dx, p.dy + len);
            route.lineTo(p.dx, p.dy);
          }
          canvas.drawPath(route, trace);
          canvas.drawCircle(p, s * 0.018, white);
        }
        canvas.restore();

      case 'ripplesTex':
        // 涟漪：若干组同心圆环
        final Random rnd = Random(191);
        for (int i = 0; i < 6; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * 0.55 * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          final double maxR = s * (0.08 + rnd.nextDouble() * 0.16);
          for (int k = 1; k <= 3; k++) {
            canvas.drawCircle(
              p,
              maxR * k / 3,
              Paint()
                ..color = Colors.white.withValues(alpha: 0.6 - k * 0.12)
                ..style = PaintingStyle.stroke
                ..strokeWidth = s * 0.01,
            );
          }
        }

      case 'starGlow':
        // 星芒：带光晕的四角星闪光
        final Random rnd = Random(193);
        for (int i = 0; i < 8; i++) {
          final double a = rnd.nextDouble() * 2 * pi;
          final double rr = c * 0.75 * sqrt(rnd.nextDouble());
          final Offset p = Offset(c + cos(a) * rr, c + sin(a) * rr);
          final double g = s * (0.05 + rnd.nextDouble() * 0.09);
          canvas.drawCircle(
            p,
            g * 1.4,
            Paint()
              ..isAntiAlias = true
              ..shader = ui.Gradient.radial(p, g * 1.4, <Color>[
                Colors.white.withValues(alpha: 0.5),
                Colors.white.withValues(alpha: 0),
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
