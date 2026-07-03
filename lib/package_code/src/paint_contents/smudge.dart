import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';
import 'paint_content.dart';

class SmudgeStamp {
  const SmudgeStamp(this.position, this.dragOffset);

  final Offset position;
  final Offset dragOffset;

  Map<String, dynamic> toJson() => {
        'position': position.toJson(),
        'dragOffset': dragOffset.toJson(),
      };

  factory SmudgeStamp.fromJson(Map<String, dynamic> json) => SmudgeStamp(
        jsonToOffset(json['position']),
        jsonToOffset(json['dragOffset']),
      );
}

/// 涂抹画笔，用于混合和拖拽像素
/// 
/// Smudge brush, used to blend and drag pixels
class SmudgeContent extends PaintContent {
  SmudgeContent({this.strength = 0.5});

  SmudgeContent.data({
    required this.stamps,
    required this.strength,
    required Paint paint,
    this.image,
  }) : super.paint(paint);

  factory SmudgeContent.fromJson(Map<String, dynamic> data) {
    return SmudgeContent.data(
      stamps: (data['stamps'] as List<dynamic>)
          .map((e) => SmudgeStamp.fromJson(e as Map<String, dynamic>))
          .toList(),
      strength: (data['strength'] ?? 0.5) as double,
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
      image: null, // Asynchronously populated by _loadCanvasData
    );
  }

  /// Accumulated timestamps of drawing positions and drag vector offsets
  List<SmudgeStamp> stamps = [];

  double strength;

  ui.Image? image;
  String? cachedBase64Image;
  Offset? _lastPoint;
  Offset _currentDragOffset = Offset.zero;

  @override
  String get contentType => 'SmudgeContent';

  void setImageData(ui.Image imageData) {
    image = imageData;
  }

  @override
  void startDraw(Offset startPoint) {
    stamps.clear();
    _lastPoint = startPoint;
    _currentDragOffset = Offset.zero;
    stamps.add(SmudgeStamp(startPoint, _currentDragOffset));
  }

  @override
  void drawing(Offset nowPoint) {
    if (_lastPoint != null) {
      final Offset delta = nowPoint - _lastPoint!;
      
      // Interpolate points if delta is too large
      final double distance = delta.distance;
      final int steps = (distance / 2.0).ceil(); 

      for (int i = 1; i <= steps; i++) {
        final double t = i / steps;
        final Offset interpolatedPoint = Offset.lerp(_lastPoint!, nowPoint, t)!;
        
        // Add to drag accumulation
        final Offset smallDelta = delta / steps.toDouble();
        _currentDragOffset += smallDelta;

        // Apply decay to drag offset based on strength (0 = fast decay / hard drag, 1 = slow decay / long drag)
        final double decayFactor = 0.85 + (strength * 0.14); // Range 0.85 to 0.99
        _currentDragOffset *= decayFactor;

        stamps.add(SmudgeStamp(interpolatedPoint, _currentDragOffset));
      }
    }

    _lastPoint = nowPoint;
  }

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (image == null || stamps.isEmpty) return;

    // We stamp circles along the path containing the image shader, offset by current drag
    for (final stamp in stamps) {
      final double dragDx = stamp.dragOffset.dx;
      final double dragDy = stamp.dragOffset.dy;

      // Ensure we drag *from* where the color was initially grabbed
      // To simulate dragging color to the current point, we need to sample the image backward
      final Matrix4 matrix = Matrix4.identity()
        ..translate(dragDx, dragDy);

      final ui.ImageShader shader = ui.ImageShader(
        image!,
        ui.TileMode.clamp,
        ui.TileMode.clamp,
        matrix.storage,
      );

      // Using blendMode helps overlay smudges gradually over themselves
      final Paint smudgePaint = Paint()
        ..shader = shader
        ..style = PaintingStyle.fill
        ..blendMode = BlendMode.srcOver;

      canvas.drawCircle(stamp.position, paint.strokeWidth / 2, smudgePaint);
    }
  }

  @override
  SmudgeContent copy() => SmudgeContent.data(
        stamps: List.from(stamps),
        strength: strength,
        paint: paint.copyWith(),
        image: image,
      )..cachedBase64Image = cachedBase64Image;

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'stamps': stamps.map((e) => e.toJson()).toList(),
      'strength': strength,
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
