import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../draw_path/draw_path.dart';
import '../paint_extension/ex_paint.dart';
import 'paint_content.dart';

/// 模糊画笔，用于柔化底层图像像素 (Progressive Soft Blur Engine)
///
/// Blur brush: smoothly softens underlying drawing pixels with gentle Gaussian diffusion and feathered masking
class BlurContent extends PaintContent {
  BlurContent({this.strength = 0.5});

  BlurContent.data({
    required this.path,
    required Paint paint,
    this.strength = 0.5,
    this.image,
  }) : super.paint(paint);

  factory BlurContent.fromJson(Map<String, dynamic> data) {
    return BlurContent.data(
      path: DrawPath.fromJson(data['path'] as Map<String, dynamic>),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
      strength: (data['strength'] ?? 0.5) as double,
      image: null,
    );
  }

  DrawPath path = DrawPath();
  double strength;

  /// Snapshotted background image
  ui.Image? image;
  String? cachedBase64Image;

  @override
  String get contentType => 'BlurContent';

  /// Store pixel data to sample from
  void setImageData(ui.Image imageData) {
    image = imageData;
  }

  @override
  void startDraw(Offset startPoint) {
    path.moveTo(startPoint.dx, startPoint.dy);
  }

  @override
  void drawing(Offset nowPoint) {
    path.lineTo(nowPoint.dx, nowPoint.dy);
  }

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (image == null) return;

    final Rect canvasRect = Offset.zero & size;
    final Rect srcRect = Rect.fromLTWH(
      0,
      0,
      image!.width.toDouble(),
      image!.height.toDouble(),
    );

    final double strokeWidth = paint.strokeWidth;
    final double maskFeather = (strokeWidth * 0.35).clamp(3.0, 16.0);
    final double sigma = (3.5 + strength * 8.0) * (strokeWidth / 22.0).clamp(0.6, 2.5);
    final double eraseAlpha = (0.35 + strength * 0.45).clamp(0.25, 0.80);

    // 1. Softly attenuate the sharp base artwork under the brush path
    final Paint softErasePaint = Paint()
      ..blendMode = BlendMode.dstOut
      ..color = Colors.black.withValues(alpha: eraseAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, maskFeather);
    canvas.drawPath(path.path, softErasePaint);

    // 2. Composite Gaussian-blurred snapshot masked to brush path using single saveLayer with BlendMode.srcIn
    final double addAlpha = (0.40 + strength * 0.55).clamp(0.25, 0.95);
    canvas.saveLayer(canvasRect, Paint()..color = Colors.white.withValues(alpha: addAlpha));

    final Paint strokeMaskPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, maskFeather);
    canvas.drawPath(path.path, strokeMaskPaint);

    final Paint blurPaint = Paint()
      ..blendMode = BlendMode.srcIn
      ..filterQuality = ui.FilterQuality.high
      ..imageFilter = ui.ImageFilter.blur(
        sigmaX: sigma,
        sigmaY: sigma,
        tileMode: ui.TileMode.clamp,
      );

    canvas.drawImageRect(image!, srcRect, canvasRect, blurPaint);
    canvas.restore();
  }

  @override
  BlurContent copy() => BlurContent.data(
        path: path.copy(),
        paint: paint.copyWith(),
        strength: strength,
        image: image,
      )..cachedBase64Image = cachedBase64Image;

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'path': path.toJson(),
      'paint': paint.toJson(),
      'strength': strength,
      'imageDataBase64': cachedBase64Image,
    };
  }

  @override
  Future<void> prepareExport() async {
    if (image != null && cachedBase64Image == null) {
      final ByteData? byteData = await image!.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        cachedBase64Image = base64Encode(pngBytes);
      }
    }
  }
}
