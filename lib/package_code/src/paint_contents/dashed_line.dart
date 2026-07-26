import 'dart:ui';

import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';
import 'freehand_line.dart';

/// 虚线画笔
///
/// 与普通画笔（`SimpleLine`）手感完全一致，但将线条渲染为等间距的短划线。
/// 划线长度与间隔按画笔粗细（`strokeWidth`）等比缩放，因此调大粗细滑块时
/// 依然能保持清晰的虚线样式，而不会糊成一条实线。
///
/// Dashed pen. Behaves exactly like the normal pen (`SimpleLine`), but renders
/// the stroke as evenly spaced dashes. The dash and gap lengths scale with the
/// stroke width, so increasing the width slider keeps a clean dashed pattern
/// instead of collapsing into a solid line.
class DashedLine extends FreehandLine {
  DashedLine({
    super.minPointDistance,
    this.dashRatio = 3.0,
    this.gapRatio = 2.0,
  });

  DashedLine.data({
    super.minPointDistance,
    this.dashRatio = 3.0,
    this.gapRatio = 2.0,
    required super.points,
    required super.paint,
  }) : super.data();

  factory DashedLine.fromJson(Map<String, dynamic> data) {
    return DashedLine.data(
      minPointDistance: (data['minPointDistance'] ?? 2.0) as double,
      dashRatio: (data['dashRatio'] ?? 3.0) as double,
      gapRatio: (data['gapRatio'] ?? 2.0) as double,
      points: (data['points'] as List<dynamic>)
          .map((dynamic e) => jsonToOffset(e as Map<String, dynamic>))
          .toList(),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
  }

  /// 单个划线长度相对画笔粗细的倍数 / Dash length as a multiple of the stroke width
  final double dashRatio;

  /// 划线间隔相对画笔粗细的倍数 / Gap length as a multiple of the stroke width
  final double gapRatio;

  @override
  String get contentType => 'DashedLine';

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (points.isEmpty) {
      return;
    }

    // 单点绘制为一个小圆点
    if (points.length == 1) {
      canvas.drawCircle(points.first, paint.strokeWidth / 2, paint);
      return;
    }

    // 划线与间隔随画笔粗细缩放，保证任意粗细下都清晰可见
    final double width = paint.strokeWidth;
    final double dash = (width * dashRatio).clamp(1.0, double.infinity);
    final double gap = (width * gapRatio).clamp(1.0, double.infinity);

    final Path source = buildSmoothPath();
    final Path dashed = Path();

    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double end = distance + dash;
        final double dashEnd = end < metric.length ? end : metric.length;
        dashed.addPath(metric.extractPath(distance, dashEnd), Offset.zero);
        distance = end + gap;
      }
    }

    canvas.drawPath(dashed, paint);
  }

  @override
  DashedLine copy() => DashedLine(
        minPointDistance: minPointDistance,
        dashRatio: dashRatio,
        gapRatio: gapRatio,
      );

  @override
  Map<String, dynamic> toContentJson() => <String, dynamic>{
        ...baseJson(),
        'dashRatio': dashRatio,
        'gapRatio': gapRatio,
      };
}
