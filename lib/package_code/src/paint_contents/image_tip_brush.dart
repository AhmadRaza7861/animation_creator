import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';
import 'brush_stamps.dart';
import 'freehand_line.dart';

/// 图像笔尖笔刷（Photoshop 位图笔尖方式）
///
/// 沿笔迹路径反复“盖章”一张灰度纹理图（来自 [BrushStampLibrary]），并用 `srcIn`
/// 颜色滤镜着色为当前画笔颜色，从而获得柔边喷枪、颗粒、飞溅等真实位图笔触。
/// 尺寸取自画笔粗细，间距、角度、翻转、硬度（模糊）均可配置。
///
/// Image tip brush (Photoshop bitmap-tip approach).
///
/// Repeatedly stamps a grayscale texture image (from [BrushStampLibrary]) along
/// the stroke path, tinting it to the current brush color with a `srcIn` color
/// filter — yielding real bitmap-style strokes (soft airbrush, grain, splatter).
/// Size comes from the stroke width; spacing, angle, flip and hardness (blur)
/// are configurable.
class ImageTipBrush extends FreehandLine {
  ImageTipBrush({
    super.minPointDistance,
    required this.stampKey,
    this.spacing = 0.2,
    this.angle = 0.0,
    this.hardness = 1.0,
    this.flipX = false,
    this.flipY = false,
    this.followPath = false,
  });

  ImageTipBrush.data({
    super.minPointDistance,
    required this.stampKey,
    this.spacing = 0.2,
    this.angle = 0.0,
    this.hardness = 1.0,
    this.flipX = false,
    this.flipY = false,
    this.followPath = false,
    required super.points,
    required super.paint,
  }) : super.data();

  factory ImageTipBrush.fromJson(Map<String, dynamic> data) => ImageTipBrush.data(
        minPointDistance: (data['minPointDistance'] ?? 2.0) as double,
        stampKey: (data['stampKey'] ?? 'softRound') as String,
        spacing: (data['spacing'] ?? 0.2) as double,
        angle: (data['angle'] ?? 0.0) as double,
        hardness: (data['hardness'] ?? 1.0) as double,
        flipX: (data['flipX'] ?? false) as bool,
        flipY: (data['flipY'] ?? false) as bool,
        followPath: (data['followPath'] ?? false) as bool,
        points: (data['points'] as List<dynamic>)
            .map((dynamic e) => jsonToOffset(e as Map<String, dynamic>))
            .toList(),
        paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
      );

  /// 纹理键（对应 [kBrushStamps]）/ Texture key (see [kBrushStamps])
  final String stampKey;

  /// 间距（相对直径的倍数）/ Spacing as a multiple of the diameter
  final double spacing;

  /// 角度（度）/ Angle in degrees
  final double angle;

  /// 硬度 0-1（越低边缘越柔）/ Hardness 0-1 (lower = softer edge)
  final double hardness;

  /// 水平翻转 / Flip horizontally
  final bool flipX;

  /// 垂直翻转 / Flip vertically
  final bool flipY;

  /// 是否随笔迹方向旋转 / Whether the stamp rotates to follow the stroke
  final bool followPath;

  @override
  String get contentType => 'ImageTipBrush';

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (points.isEmpty) {
      return;
    }

    final ui.Image image = BrushStampLibrary.instance.get(stampKey);
    final double width = paint.strokeWidth;
    final double radius = width / 2;
    final double angleRad = angle * 3.1415926535897932 / 180;

    final Paint tint = Paint()
      ..colorFilter = ColorFilter.mode(paint.color, BlendMode.srcIn)
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.medium;
    final double sigma = radius * (1 - hardness) * 0.6;
    if (sigma > 0) {
      tint.maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);
    }

    final Rect src =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

    if (points.length == 1) {
      _stamp(canvas, image, src, points.first, radius, angleRad, tint);
      return;
    }

    final double frac = spacing > 0 ? spacing : 0.05;
    final double step = (width * frac).clamp(0.5, double.infinity);
    final Path path = buildSmoothPath();

    for (final ui.PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance <= metric.length) {
        final ui.Tangent? tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          _stamp(
            canvas,
            image,
            src,
            tangent.position,
            radius,
            (followPath ? tangent.angle : 0) + angleRad,
            tint,
          );
        }
        distance += step;
      }
    }
  }

  void _stamp(
    Canvas canvas,
    ui.Image image,
    Rect src,
    Offset center,
    double radius,
    double angle,
    Paint paint,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.scale(flipX ? -1 : 1, flipY ? -1 : 1);
    canvas.drawImageRect(
      image,
      src,
      Rect.fromCenter(center: Offset.zero, width: radius * 2, height: radius * 2),
      paint,
    );
    canvas.restore();
  }

  @override
  ImageTipBrush copy() => ImageTipBrush(
        minPointDistance: minPointDistance,
        stampKey: stampKey,
        spacing: spacing,
        angle: angle,
        hardness: hardness,
        flipX: flipX,
        flipY: flipY,
        followPath: followPath,
      );

  @override
  Map<String, dynamic> toContentJson() => <String, dynamic>{
        ...baseJson(),
        'stampKey': stampKey,
        'spacing': spacing,
        'angle': angle,
        'hardness': hardness,
        'flipX': flipX,
        'flipY': flipY,
        'followPath': followPath,
      };
}
