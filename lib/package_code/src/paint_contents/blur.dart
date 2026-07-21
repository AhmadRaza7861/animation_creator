import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../draw_path/draw_path.dart';
import '../paint_extension/ex_paint.dart';
import 'paint_content.dart';

/// 模糊画笔，用于柔化底层图像像素
/// 
/// Blur brush, used to soften underlying image pixels
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
      image: null, // Asynchronously populated by _loadCanvasData
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

    // 1. Save a layer bounding the entire canvas with layer opacity support
    final double opacity = paint.color.a;
    final Paint layerPaint = Paint();
    if (opacity < 1.0) {
      layerPaint.color = Colors.white.withValues(alpha: opacity);
    }
    canvas.saveLayer(canvasRect, layerPaint);

    // 2. Draw the blurred snapshot image scaled accurately to canvasRect
    final double sigma = (strength * 10.0) * (paint.strokeWidth / 20.0).clamp(0.5, 2.0);
    final Paint blurPaint = Paint()
      ..filterQuality = ui.FilterQuality.high
      ..imageFilter = ui.ImageFilter.blur(
        sigmaX: sigma,
        sigmaY: sigma,
        tileMode: ui.TileMode.clamp,
      );

    canvas.drawImageRect(image!, srcRect, canvasRect, blurPaint);

    // 3. Draw the stroke path with dstIn to mask out everything EXCEPT the path bounds.
    // Apply strokeCap & strokeJoin round with a controlled maskBlurRadius for exact preview matching.
    final Paint maskPaint = Paint()..blendMode = BlendMode.dstIn;
    canvas.saveLayer(canvasRect, maskPaint);

    final double maskBlurRadius = (paint.strokeWidth * 0.2).clamp(1.0, 6.0);
    final Paint strokePaint = paint.copyWith()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, maskBlurRadius)
      ..blendMode = BlendMode.srcOver;

    canvas.drawPath(path.path, strokePaint);
    canvas.restore();

    // 4. Restore the original canvas state
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
