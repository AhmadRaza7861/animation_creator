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
  BlurContent();

  BlurContent.data({
    required this.path,
    required Paint paint,
    this.image,
  }) : super.paint(paint);

  factory BlurContent.fromJson(Map<String, dynamic> data) {
    return BlurContent.data(
      path: DrawPath.fromJson(data['path'] as Map<String, dynamic>),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
      image: null, // Asynchronously populated by _loadCanvasData
    );
  }

  DrawPath path = DrawPath();

  /// Paint for the stroke path itself (used to mask the blur)
  late Paint _maskPaint;

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

    // Use a mask paint derived from the config but optimized for masking out the blurred image
    _maskPaint = paint.copyWith()
      ..color = Colors.black
      ..blendMode = BlendMode.dstIn; // Keep only pixels where the image overlaps the stroked path

    // 1. Save a layer bounding the entire canvas
    canvas.saveLayer(Offset.zero & size, Paint());

    // 2. Draw the blurred image into the layer
    // The blur sigma derives from our strength parameter (e.g. 0.0 - 1.0 mapped to 0 - 20)
    // Here we're interpreting paint.strokeWidth loosely as a proxy, or ideally we'd pass strength directly if available.
    // However, since we don't have direct access to 'strength' in the 'paint' object, we'll map strokeWidth.
    // For now, let's blur up to 10 pixels radius
    final double sigma = paint.strokeWidth * 0.5;
    
    final Paint blurPaint = Paint()
      ..imageFilter = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, tileMode: ui.TileMode.clamp);
    
    canvas.drawImage(image!, Offset.zero, blurPaint);

    // 3. Draw the stroke path with dstIn to mask out everything EXCEPT the path bounds
    // This effectively causes the blur effect to ONLY exist where our path is drawn
    canvas.saveLayer(Offset.zero & size, _maskPaint);
    final Paint regularStrokePaint = paint.copyWith()
      ..color = Colors.black
      ..blendMode = BlendMode.srcOver;
    canvas.drawPath(path.path, regularStrokePaint);
    canvas.restore();

    // 4. Restore the original canvas state (the layer is composited down)
    canvas.restore();
  }

  @override
  BlurContent copy() => BlurContent.data(
        path: path.copy(),
        paint: paint.copyWith(),
        image: image,
      )..cachedBase64Image = cachedBase64Image;

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'path': path.toJson(),
      'paint': paint.toJson(),
      'imageDataBase64': cachedBase64Image,
    };
  }

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
