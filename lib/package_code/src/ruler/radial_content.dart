import 'dart:math';
import 'package:flutter/material.dart';
import '../paint_contents/paint_content_decoder.dart';
import '../paint_contents/paint_content.dart';

/// 径向万花筒对称绘制包装器
/// Wraps any PaintContent and renders it replicated symmetrically across radial sectors.
class RadialContent extends PaintContent {
  RadialContent(
    this.child,
    this.center, [
    this.sectors = 8,
    this.startAngle = 0.0,
  ]) {
    paint = child.paint;
  }

  final PaintContent child;

  /// 中心点
  /// Radial symmetry center point
  final Offset center;

  /// 分区数量（默认8扇区）
  /// Number of radial sectors
  final int sectors;

  /// 旋转初始角（弧度）
  /// Base orientation angle in radians
  final double startAngle;

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
    // 基础绘制 / Base sector
    child.draw(canvas, size, deeper);

    final double step = 2 * pi / max(2, sectors);
    for (int i = 1; i < sectors; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(startAngle + i * step);
      canvas.rotate(-startAngle);
      canvas.translate(-center.dx, -center.dy);
      child.draw(canvas, size, deeper);
      canvas.restore();
    }
  }

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'centerX': center.dx,
      'centerY': center.dy,
      'sectors': sectors,
      'startAngle': startAngle,
      'child': child.toJson(),
    };
  }

  factory RadialContent.fromJson(Map<String, dynamic> data) {
    final double cx = (data['centerX'] as num?)?.toDouble() ?? 0.0;
    final double cy = (data['centerY'] as num?)?.toDouble() ?? 0.0;
    final int sec = (data['sectors'] as num?)?.toInt() ?? 8;
    final double sAngle = (data['startAngle'] as num?)?.toDouble() ?? 0.0;
    return RadialContent(
      decodePaintContent(data['child']['type'] as String, data['child'] as Map<String, dynamic>)!,
      Offset(cx, cy),
      sec,
      sAngle,
    );
  }

  @override
  RadialContent copy() => RadialContent(child.copy(), center, sectors, startAngle);
}
