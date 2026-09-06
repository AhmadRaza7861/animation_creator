import 'dart:math';
import 'package:flutter/material.dart';
import '../paint_contents/paint_content_decoder.dart';
import '../paint_contents/paint_content.dart';

/// 镜像绘制包装器
/// Wraps any PaintContent and renders it symmetrically across a mirror axis.
class MirrorContent extends PaintContent {
  MirrorContent(
    this.child,
    this.mirrorCenter, [
    this.mirrorAngle = pi / 2,
  ]) : mirrorX = mirrorCenter.dx {
    paint = child.paint;
  }

  /// Convenience constructor for legacy X-axis mirror
  MirrorContent.fromX(this.child, this.mirrorX)
      : mirrorCenter = Offset(mirrorX, 0),
        mirrorAngle = pi / 2 {
    paint = child.paint;
  }

  final PaintContent child;

  /// 镜像中心点
  /// Mirror center point
  final Offset mirrorCenter;

  /// 镜像对称轴角度（弧度）
  /// Mirror symmetry axis angle in radians
  final double mirrorAngle;

  /// X轴镜像中心（保持向后兼容）
  /// X-axis mirror center for backwards compatibility
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
    // 正常绘制 / Normal drawing
    child.draw(canvas, size, deeper);

    // 镜像对称绘制 / Mirrored drawing across symmetry axis
    canvas.save();
    canvas.translate(mirrorCenter.dx, mirrorCenter.dy);
    canvas.rotate(mirrorAngle);
    canvas.scale(1, -1);
    canvas.rotate(-mirrorAngle);
    canvas.translate(-mirrorCenter.dx, -mirrorCenter.dy);
    child.draw(canvas, size, deeper);
    canvas.restore();
  }

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'mirrorX': mirrorCenter.dx,
      'mirrorY': mirrorCenter.dy,
      'mirrorAngle': mirrorAngle,
      'child': child.toJson(),
    };
  }

  factory MirrorContent.fromJson(Map<String, dynamic> data) {
    final double mx = (data['mirrorX'] as num?)?.toDouble() ?? 0.0;
    final double my = (data['mirrorY'] as num?)?.toDouble() ?? 0.0;
    final double mAngle = (data['mirrorAngle'] as num?)?.toDouble() ?? (pi / 2);
    return MirrorContent(
      decodePaintContent(data['child']['type'] as String, data['child'] as Map<String, dynamic>)!,
      Offset(mx, my),
      mAngle,
    );
  }

  @override
  MirrorContent copy() => MirrorContent(child.copy(), mirrorCenter, mirrorAngle);
}

/// 4向/象限十字镜像绘制包装器
/// Wraps any PaintContent and renders it symmetrically across 4 quadrants (2 perpendicular axes).
class QuadMirrorContent extends PaintContent {
  QuadMirrorContent(
    this.child,
    this.mirrorCenter, [
    this.mirrorAngle = 0.0,
  ]) {
    paint = child.paint;
  }

  final PaintContent child;

  /// 镜像中心点
  /// Mirror center point
  final Offset mirrorCenter;

  /// 镜像主对称轴角度（弧度）
  /// Primary symmetry axis angle in radians
  final double mirrorAngle;

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
    // 1. 原始象限绘制 / Quadrant 1 (Original)
    child.draw(canvas, size, deeper);

    // 2. 主轴镜像（上下反射） / Quadrant 2 (Reflected across Primary Axis)
    canvas.save();
    canvas.translate(mirrorCenter.dx, mirrorCenter.dy);
    canvas.rotate(mirrorAngle);
    canvas.scale(1, -1);
    canvas.rotate(-mirrorAngle);
    canvas.translate(-mirrorCenter.dx, -mirrorCenter.dy);
    child.draw(canvas, size, deeper);
    canvas.restore();

    // 3. 垂直轴镜像（左右反射） / Quadrant 3 (Reflected across Perpendicular Axis)
    canvas.save();
    canvas.translate(mirrorCenter.dx, mirrorCenter.dy);
    canvas.rotate(mirrorAngle);
    canvas.scale(-1, 1);
    canvas.rotate(-mirrorAngle);
    canvas.translate(-mirrorCenter.dx, -mirrorCenter.dy);
    child.draw(canvas, size, deeper);
    canvas.restore();

    // 4. 双轴/对角镜像（对角象限反射） / Quadrant 4 (Reflected across Both Axes / 180° rotation)
    canvas.save();
    canvas.translate(mirrorCenter.dx, mirrorCenter.dy);
    canvas.rotate(mirrorAngle);
    canvas.scale(-1, -1);
    canvas.rotate(-mirrorAngle);
    canvas.translate(-mirrorCenter.dx, -mirrorCenter.dy);
    child.draw(canvas, size, deeper);
    canvas.restore();
  }

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'mirrorX': mirrorCenter.dx,
      'mirrorY': mirrorCenter.dy,
      'mirrorAngle': mirrorAngle,
      'child': child.toJson(),
    };
  }

  factory QuadMirrorContent.fromJson(Map<String, dynamic> data) {
    final double mx = (data['mirrorX'] as num?)?.toDouble() ?? 0.0;
    final double my = (data['mirrorY'] as num?)?.toDouble() ?? 0.0;
    final double mAngle = (data['mirrorAngle'] as num?)?.toDouble() ?? 0.0;
    return QuadMirrorContent(
      decodePaintContent(data['child']['type'] as String, data['child'] as Map<String, dynamic>)!,
      Offset(mx, my),
      mAngle,
    );
  }

  @override
  QuadMirrorContent copy() => QuadMirrorContent(child.copy(), mirrorCenter, mirrorAngle);
}

