import 'package:flutter/material.dart';
import '../paint_contents/paint_content_decoder.dart';

import '../paint_contents/paint_content.dart';

/// 镜像绘制包装器
/// Wraps any PaintContent and renders it symmetrically across a mirror axis.
class MirrorContent extends PaintContent {
  MirrorContent(this.child, this.mirrorX) {
    paint = child.paint;
  }

  final PaintContent child;
  
  /// X轴镜像中心
  /// X-axis mirror center
  final double mirrorX;

  @override
  set paint(Paint p) {
    super.paint = p;
    child.paint = p;
  }

  @override
  void startDraw(Offset startPoint) {
    child.startDraw(startPoint);
  }

  @override
  void drawing(Offset nowPaint) {
    child.drawing(nowPaint);
  }

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    // 正常绘制
    // Normal drawing
    child.draw(canvas, size, deeper);

    // 镜像绘制
    // Mirrored drawing
    canvas.save();
    canvas.translate(mirrorX * 2, 0);
    canvas.scale(-1, 1);
    child.draw(canvas, size, deeper);
    canvas.restore();
  }

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'mirrorX': mirrorX,
      'child': child.toJson(),
    };
  }

  factory MirrorContent.fromJson(Map<String, dynamic> data) {
    return MirrorContent(
      decodePaintContent(data['child']['type'] as String, data['child'] as Map<String, dynamic>)!,
      data['mirrorX'] as double,
    );
  }

  @override
  MirrorContent copy() => MirrorContent(child.copy(), mirrorX);
}
