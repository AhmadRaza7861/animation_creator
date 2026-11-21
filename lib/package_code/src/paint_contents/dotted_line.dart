import 'dart:ui';

import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';
import 'freehand_line.dart';

/// 点线画笔
///
/// 与普通画笔（`SimpleLine`）手感完全一致，但沿线条以等间距绘制圆点。
/// 圆点大小与间距均按画笔粗细（`strokeWidth`）等比缩放，因此调大粗细滑块
/// 时圆点之间依然保持清晰的间隔，而不会连成一条实线。
///
/// Dotted pen. Behaves exactly like the normal pen (`SimpleLine`), but draws
/// evenly spaced dots along the stroke path. Both the dot size and the spacing
/// scale with the stroke width, so increasing the width slider keeps clear gaps
/// between dots instead of merging them into a solid line.
class DottedLine extends FreehandLine {
  DottedLine({
    super.minPointDistance,
    this.spacingRatio = 2.0,
  });

  DottedLine.data({
    super.minPointDistance,
    this.spacingRatio = 2.0,
    required super.points,
    required super.paint,
  }) : super.data();

  factory DottedLine.fromJson(Map<String, dynamic> data) {
    return DottedLine.data(
      minPointDistance: (data['minPointDistance'] ?? 2.0) as double,
      // 兼容旧字段名 dotSpacing（绝对像素），旧数据回退为默认比例
      spacingRatio: (data['spacingRatio'] ?? 2.0) as double,
      points: (data['points'] as List<dynamic>)
          .map((dynamic e) => jsonToOffset(e as Map<String, dynamic>))
          .toList(),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
  }

  /// 相邻圆点圆心间距相对画笔粗细的倍数
  ///
  /// Distance between adjacent dot centers, as a multiple of the stroke width
  final double spacingRatio;

  @override
  String get contentType => 'DottedLine';

  @override
  bool get supportsActiveRangeBaking => true;

  @override
  void drawCommittedRange(Canvas canvas, Size size, int startSample, int endSample) {
    _drawRange(canvas, size, startSample, endSample, includeTail: false);
  }

  @override
  void drawLiveFromSample(Canvas canvas, Size size, int startSample) {
    _drawRange(canvas, size, startSample, null, includeTail: true);
  }

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (points.isEmpty) {
      return;
    }
    if (points.length == 1) {
      final Paint dotPaint = paint.copyWith(style: PaintingStyle.fill);
      canvas.drawCircle(points.first, paint.strokeWidth / 2, dotPaint);
      return;
    }

    _drawRange(canvas, size, 0, null, includeTail: true);
  }

  void _drawRange(
    Canvas canvas,
    Size size,
    int startSample,
    int? endSample, {
    required bool includeTail,
  }) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      if (includeTail) draw(canvas, size, false);
      return;
    }
    final double width = paint.strokeWidth;
    final double radius = width / 2;
    final Paint dotPaint = paint.copyWith(style: PaintingStyle.fill);
    final double diameter = width > 0 ? width : 1.0;
    final double step = (width * spacingRatio).clamp(diameter, double.infinity);
    final int sig = Object.hash(baseStyleSignature, spacingRatio);
    sampleSmooth(step);

    drawSampleSlice(canvas, size, startSample, endSample, includeTail, sig,
        (Canvas target, int startIdx, int endIdx, bool isTail) {
      for (int i = startIdx; i < endIdx; i++) {
        target.drawCircle(
          Offset(strokeCache.getX(i, isTail), strokeCache.getY(i, isTail)),
          radius,
          dotPaint,
        );
      }
    });
  }

  @override
  DottedLine copy() => DottedLine.data(
        minPointDistance: minPointDistance,
        spacingRatio: spacingRatio,
        points: List<Offset>.from(points),
        paint: paint.copyWith(),
      );

  @override
  Map<String, dynamic> toContentJson() => <String, dynamic>{
        ...baseJson(),
        'spacingRatio': spacingRatio,
      };
}
