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
  void draw(Canvas canvas, Size size, bool deeper) {
    if (points.isEmpty) {
      return;
    }

    final double width = paint.strokeWidth;
    final double radius = width / 2;
    // 圆点用填充绘制，避免描边模式下出现空心圆
    final Paint dotPaint = paint.copyWith(style: PaintingStyle.fill);

    if (points.length == 1) {
      canvas.drawCircle(points.first, radius, dotPaint);
      return;
    }

    // 间距随画笔粗细缩放，并保证至少不小于圆点直径以防重叠/死循环
    final double diameter = width > 0 ? width : 1.0;
    final double step = (width * spacingRatio).clamp(diameter, double.infinity);

    final Path source = buildSmoothPath();
    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance <= metric.length) {
        final Tangent? tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          canvas.drawCircle(tangent.position, radius, dotPaint);
        }
        distance += step;
      }
    }
  }

  @override
  DottedLine copy() => DottedLine(
        minPointDistance: minPointDistance,
        spacingRatio: spacingRatio,
      );

  @override
  Map<String, dynamic> toContentJson() => <String, dynamic>{
        ...baseJson(),
        'spacingRatio': spacingRatio,
      };
}
