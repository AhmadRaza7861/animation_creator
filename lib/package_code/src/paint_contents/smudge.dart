import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';
import 'paint_content.dart';

class SmudgePoint {
  const SmudgePoint(this.point, this.delta);

  final Offset point;
  final Offset delta;

  Map<String, dynamic> toJson() => {
        'point': point.toJson(),
        'delta': delta.toJson(),
      };

  factory SmudgePoint.fromJson(Map<String, dynamic> json) => SmudgePoint(
        jsonToOffset(json['point']),
        jsonToOffset(json['delta']),
      );
}

/// 涂抹画笔，用于混合和拖拽像素 (Directional Motion Segment Smudge Engine)
/// 
/// Smudge brush, used to blend and drag pixels along touch gesture vectors
class SmudgeContent extends PaintContent {
  SmudgeContent({this.strength = 0.5});

  SmudgeContent.data({
    required this.points,
    required this.strength,
    required Paint paint,
    this.image,
  }) : super.paint(paint);

  factory SmudgeContent.fromJson(Map<String, dynamic> data) {
    return SmudgeContent.data(
      points: (data['points'] as List<dynamic>?)
              ?.map((e) => SmudgePoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      strength: (data['strength'] ?? 0.5) as double,
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
      image: null,
    );
  }

  List<SmudgePoint> points = [];
  double strength;

  ui.Image? image;
  String? cachedBase64Image;
  Offset? _lastPoint;

  @override
  String get contentType => 'SmudgeContent';

  void setImageData(ui.Image imageData) {
    image = imageData;
  }

  @override
  void startDraw(Offset startPoint) {
    points.clear();
    _lastPoint = startPoint;
    points.add(SmudgePoint(startPoint, Offset.zero));
  }

  @override
  void drawing(Offset nowPoint) {
    if (_lastPoint != null) {
      final Offset delta = nowPoint - _lastPoint!;
      if (delta.distance > 0.5) {
        points.add(SmudgePoint(nowPoint, delta));
        _lastPoint = nowPoint;
      }
    }
  }

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (image == null || points.isEmpty) return;

    final double scaleX = size.width / image!.width.toDouble();
    final double scaleY = size.height / image!.height.toDouble();
    final double strokeWidth = paint.strokeWidth;
    final double opacity = (paint.color.a * (0.7 + strength * 0.3)).clamp(0.1, 1.0);

    final Rect canvasRect = Offset.zero & size;
    final Paint layerPaint = Paint();
    if (opacity < 1.0) {
      layerPaint.color = Colors.white.withValues(alpha: opacity);
    }
    canvas.saveLayer(canvasRect, layerPaint);

    if (points.length == 1) {
      final SmudgePoint p = points[0];
      final Matrix4 matrix = Matrix4.identity()
        ..scaleByDouble(scaleX, scaleY, 1.0, 1.0);
      final ui.ImageShader shader = ui.ImageShader(
        image!,
        ui.TileMode.clamp,
        ui.TileMode.clamp,
        matrix.storage,
      );
      final Paint smudgePaint = Paint()
        ..shader = shader
        ..style = PaintingStyle.fill
        ..filterQuality = ui.FilterQuality.high;
      canvas.drawCircle(p.point, strokeWidth / 2.0, smudgePaint);
      canvas.restore();
      return;
    }

    for (int i = 1; i < points.length; i++) {
      final SmudgePoint prev = points[i - 1];
      final SmudgePoint curr = points[i];

      // Motion pull vector along gesture direction
      final double pullFactor = 1.0 + (strength * 2.5);
      final Offset sampleOffset = curr.delta * pullFactor;

      // Matrix maps snapshot pixels into stroke motion direction
      final Matrix4 matrix = Matrix4.identity()
        ..scaleByDouble(scaleX, scaleY, 1.0, 1.0)
        ..translateByDouble(-sampleOffset.dx, -sampleOffset.dy, 0.0, 1.0);

      final ui.ImageShader shader = ui.ImageShader(
        image!,
        ui.TileMode.clamp,
        ui.TileMode.clamp,
        matrix.storage,
      );

      final Paint smudgePaint = Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..filterQuality = ui.FilterQuality.high
        ..blendMode = BlendMode.srcOver;

      canvas.drawLine(prev.point, curr.point, smudgePaint);
    }

    canvas.restore();
  }

  @override
  SmudgeContent copy() => SmudgeContent.data(
        points: List.from(points),
        strength: strength,
        paint: paint.copyWith(),
        image: image,
      )..cachedBase64Image = cachedBase64Image;

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'points': points.map((e) => e.toJson()).toList(),
      'strength': strength,
      'paint': paint.toJson(),
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
