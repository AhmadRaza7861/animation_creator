import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../paint_extension/ex_paint.dart';
import 'paint_content.dart';

/// 填充工具绘制内容
///
/// 通过点击位置进行油漆桶填充
/// 存储填充后的图片数据
class FillContent extends PaintContent {
  FillContent();

  FillContent.data({
    required this.image,
    required Paint paint,
  }) : super.paint(paint);

  factory FillContent.fromJson(Map<String, dynamic> data) {
    // FillContent image is decoded asynchronously just like ImageContent.
    // However, if the decode hasn't happened yet, it might return an empty FillContent.
    return FillContent.data(
      image: null, // Will be replaced asynchronously
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
  }

  /// 填充后的图片（包含透明度，仅包含填充部分）
  ui.Image? image;
  String? cachedBase64Image;

  @override
  String get contentType => 'FillContent';

  @override
  void startDraw(Offset startPoint) {}

  @override
  void drawing(Offset nowPoint) {}

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (image != null) {
      canvas.drawImage(image!, Offset.zero, paint);
    }
  }

  @override
  FillContent copy() => FillContent.data(
    image: image,
    paint: paint.copyWith(),
  )..cachedBase64Image = cachedBase64Image;

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
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
