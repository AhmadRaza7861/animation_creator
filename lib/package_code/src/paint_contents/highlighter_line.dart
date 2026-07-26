import 'dart:ui';

import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';
import 'freehand_line.dart';

/// 荧光笔 / 马克笔
///
/// 与普通画笔（`SimpleLine`）手感完全一致，但使用半透明、更粗、方形笔帽的
/// 画笔进行绘制，并采用叠加混合模式，呈现出荧光笔的高亮效果。
///
/// Highlighter / marker pen. Behaves exactly like the normal pen
/// (`SimpleLine`), but paints with a semi-transparent, thicker, square-capped
/// brush using a multiply blend mode to produce a highlighter effect.
class HighlighterLine extends FreehandLine {
  HighlighterLine({
    super.minPointDistance,
    this.opacity = 0.4,
    this.widthFactor = 4.0,
  });

  HighlighterLine.data({
    super.minPointDistance,
    this.opacity = 0.4,
    this.widthFactor = 4.0,
    required super.points,
    required super.paint,
  }) : super.data();

  factory HighlighterLine.fromJson(Map<String, dynamic> data) {
    return HighlighterLine.data(
      minPointDistance: (data['minPointDistance'] ?? 2.0) as double,
      opacity: (data['opacity'] ?? 0.4) as double,
      widthFactor: (data['widthFactor'] ?? 4.0) as double,
      points: (data['points'] as List<dynamic>)
          .map((dynamic e) => jsonToOffset(e as Map<String, dynamic>))
          .toList(),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
  }

  /// 高亮不透明度（0-1）/ Highlight opacity (0-1)
  final double opacity;

  /// 相对普通画笔的加粗倍数 / Width multiplier relative to the normal pen
  final double widthFactor;

  @override
  String get contentType => 'HighlighterLine';

  /// 生成荧光笔画笔样式
  ///
  /// Build the highlighter brush style
  Paint get _markerPaint => paint.copyWith(
        color: paint.color.withValues(alpha: opacity),
        strokeWidth: paint.strokeWidth * widthFactor,
        strokeCap: StrokeCap.square,
        strokeJoin: StrokeJoin.round,
        style: PaintingStyle.stroke,
        blendMode: BlendMode.multiply,
      );

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (points.isEmpty) {
      return;
    }

    final Paint markerPaint = _markerPaint;

    if (points.length == 1) {
      canvas.drawCircle(points.first, markerPaint.strokeWidth / 2, markerPaint);
      return;
    }

    canvas.drawPath(buildSmoothPath(), markerPaint);
  }

  @override
  HighlighterLine copy() => HighlighterLine(
        minPointDistance: minPointDistance,
        opacity: opacity,
        widthFactor: widthFactor,
      );

  @override
  Map<String, dynamic> toContentJson() => <String, dynamic>{
        ...baseJson(),
        'opacity': opacity,
        'widthFactor': widthFactor,
      };
}
