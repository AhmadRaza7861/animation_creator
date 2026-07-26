import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';
import 'paint_content.dart';

/// 拖拽绘制图形基类
///
/// 按下记录起点，拖动更新终点，图形绘制在两点构成的矩形内。
/// 子类只需实现 [drawShape] 即可获得一致的拖拽绘制行为。
/// 图形沿用当前画笔样式，因此描边/填充由画笔的 `style` 决定。
///
/// Drag-to-draw shape base class.
///
/// Press records the start point, dragging updates the end point, and the shape
/// is drawn inside the rectangle spanned by the two. Subclasses only implement
/// [drawShape]. Shapes honour the current paint style, so stroke vs fill is
/// controlled by the brush's `style`.
abstract class DragShape extends PaintContent {
  DragShape();

  DragShape.data({
    required this.startPoint,
    required this.endPoint,
    required Paint paint,
  }) : super.paint(paint);

  /// 起点 / Start point
  Offset? startPoint;

  /// 终点 / End point
  Offset? endPoint;

  @override
  void startDraw(Offset p) {
    startPoint = p;
    endPoint = p;
  }

  @override
  void drawing(Offset p) => endPoint = p;

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    final Offset? a = startPoint;
    final Offset? b = endPoint;
    if (a == null || b == null) {
      return;
    }
    drawShape(canvas, Rect.fromPoints(a, b), a, b, paint);
  }

  /// 在 [rect] 内绘制图形；[start]/[end] 为原始拖拽端点（有方向的图形会用到）
  ///
  /// Draw the shape inside [rect]. [start] / [end] are the raw drag endpoints,
  /// used by directional shapes such as arrows.
  void drawShape(Canvas canvas, Rect rect, Offset start, Offset end, Paint paint);

  @override
  Map<String, dynamic> toContentJson() => <String, dynamic>{
        'startPoint': startPoint?.toJson(),
        'endPoint': endPoint?.toJson(),
        'paint': paint.toJson(),
      };
}

// ---------------------------------------------------------------------------
// 通用路径工具 / Shared path helpers
// ---------------------------------------------------------------------------

/// 在矩形内生成内接多边形 / Regular polygon inscribed in a rect
Path _polyInRect(Rect r, int sides, {double rotation = -pi / 2}) {
  final Offset c = r.center;
  final double rx = r.width / 2;
  final double ry = r.height / 2;
  final Path p = Path();
  for (int i = 0; i < sides; i++) {
    final double a = rotation + i * 2 * pi / sides;
    final Offset pt = Offset(c.dx + rx * cos(a), c.dy + ry * sin(a));
    i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  p.close();
  return p;
}

/// 在矩形内生成内接星形 / Star inscribed in a rect
Path _starInRect(Rect r, int count, double innerRatio) {
  final Offset c = r.center;
  final double rx = r.width / 2;
  final double ry = r.height / 2;
  final Path p = Path();
  final int total = count * 2;
  for (int i = 0; i < total; i++) {
    final double k = i.isEven ? 1.0 : innerRatio;
    final double a = -pi / 2 + i * pi / count;
    final Offset pt = Offset(c.dx + rx * k * cos(a), c.dy + ry * k * sin(a));
    i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  p.close();
  return p;
}

/// 按相对坐标在矩形内生成折线图形 / Build a polygon from fractional coordinates
Path _fracPath(Rect r, List<Offset> frac) {
  final Path p = Path();
  for (int i = 0; i < frac.length; i++) {
    final Offset pt =
        Offset(r.left + frac[i].dx * r.width, r.top + frac[i].dy * r.height);
    i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  p.close();
  return p;
}

// ---------------------------------------------------------------------------
// 具体图形 / Concrete shapes
// ---------------------------------------------------------------------------

/// 三角形 / Triangle
class TriangleShape extends DragShape {
  TriangleShape();
  TriangleShape.data({required super.startPoint, required super.endPoint, required super.paint})
      : super.data();
  factory TriangleShape.fromJson(Map<String, dynamic> d) => TriangleShape.data(
        startPoint: jsonToOffset(d['startPoint'] as Map<String, dynamic>),
        endPoint: jsonToOffset(d['endPoint'] as Map<String, dynamic>),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  String get contentType => 'TriangleShape';

  @override
  void drawShape(Canvas canvas, Rect r, Offset s, Offset e, Paint paint) => canvas.drawPath(
        _fracPath(r, const <Offset>[Offset(0.5, 0), Offset(1, 1), Offset(0, 1)]),
        paint,
      );

  @override
  TriangleShape copy() => TriangleShape();
}

/// 直角三角形 / Right triangle
class RightTriangleShape extends DragShape {
  RightTriangleShape();
  RightTriangleShape.data(
      {required super.startPoint, required super.endPoint, required super.paint})
      : super.data();
  factory RightTriangleShape.fromJson(Map<String, dynamic> d) => RightTriangleShape.data(
        startPoint: jsonToOffset(d['startPoint'] as Map<String, dynamic>),
        endPoint: jsonToOffset(d['endPoint'] as Map<String, dynamic>),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  String get contentType => 'RightTriangleShape';

  @override
  void drawShape(Canvas canvas, Rect r, Offset s, Offset e, Paint paint) => canvas.drawPath(
        _fracPath(r, const <Offset>[Offset(0, 0), Offset(0, 1), Offset(1, 1)]),
        paint,
      );

  @override
  RightTriangleShape copy() => RightTriangleShape();
}

/// 菱形 / Diamond
class DiamondShape extends DragShape {
  DiamondShape();
  DiamondShape.data({required super.startPoint, required super.endPoint, required super.paint})
      : super.data();
  factory DiamondShape.fromJson(Map<String, dynamic> d) => DiamondShape.data(
        startPoint: jsonToOffset(d['startPoint'] as Map<String, dynamic>),
        endPoint: jsonToOffset(d['endPoint'] as Map<String, dynamic>),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  String get contentType => 'DiamondShape';

  @override
  void drawShape(Canvas canvas, Rect r, Offset s, Offset e, Paint paint) =>
      canvas.drawPath(_polyInRect(r, 4), paint);

  @override
  DiamondShape copy() => DiamondShape();
}

/// 五边形 / Pentagon
class PentagonShape extends DragShape {
  PentagonShape();
  PentagonShape.data({required super.startPoint, required super.endPoint, required super.paint})
      : super.data();
  factory PentagonShape.fromJson(Map<String, dynamic> d) => PentagonShape.data(
        startPoint: jsonToOffset(d['startPoint'] as Map<String, dynamic>),
        endPoint: jsonToOffset(d['endPoint'] as Map<String, dynamic>),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  String get contentType => 'PentagonShape';

  @override
  void drawShape(Canvas canvas, Rect r, Offset s, Offset e, Paint paint) =>
      canvas.drawPath(_polyInRect(r, 5), paint);

  @override
  PentagonShape copy() => PentagonShape();
}

/// 六边形 / Hexagon
class HexagonShape extends DragShape {
  HexagonShape();
  HexagonShape.data({required super.startPoint, required super.endPoint, required super.paint})
      : super.data();
  factory HexagonShape.fromJson(Map<String, dynamic> d) => HexagonShape.data(
        startPoint: jsonToOffset(d['startPoint'] as Map<String, dynamic>),
        endPoint: jsonToOffset(d['endPoint'] as Map<String, dynamic>),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  String get contentType => 'HexagonShape';

  @override
  void drawShape(Canvas canvas, Rect r, Offset s, Offset e, Paint paint) =>
      canvas.drawPath(_polyInRect(r, 6, rotation: 0), paint);

  @override
  HexagonShape copy() => HexagonShape();
}

/// 星形 / Star
class StarShape extends DragShape {
  StarShape();
  StarShape.data({required super.startPoint, required super.endPoint, required super.paint})
      : super.data();
  factory StarShape.fromJson(Map<String, dynamic> d) => StarShape.data(
        startPoint: jsonToOffset(d['startPoint'] as Map<String, dynamic>),
        endPoint: jsonToOffset(d['endPoint'] as Map<String, dynamic>),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  String get contentType => 'StarShape';

  @override
  void drawShape(Canvas canvas, Rect r, Offset s, Offset e, Paint paint) =>
      canvas.drawPath(_starInRect(r, 5, 0.45), paint);

  @override
  StarShape copy() => StarShape();
}

/// 椭圆 / Ellipse
class EllipseShape extends DragShape {
  EllipseShape();
  EllipseShape.data({required super.startPoint, required super.endPoint, required super.paint})
      : super.data();
  factory EllipseShape.fromJson(Map<String, dynamic> d) => EllipseShape.data(
        startPoint: jsonToOffset(d['startPoint'] as Map<String, dynamic>),
        endPoint: jsonToOffset(d['endPoint'] as Map<String, dynamic>),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  String get contentType => 'EllipseShape';

  @override
  void drawShape(Canvas canvas, Rect r, Offset s, Offset e, Paint paint) =>
      canvas.drawOval(r, paint);

  @override
  EllipseShape copy() => EllipseShape();
}

/// 圆角矩形 / Rounded rectangle
class RoundedRectShape extends DragShape {
  RoundedRectShape();
  RoundedRectShape.data(
      {required super.startPoint, required super.endPoint, required super.paint})
      : super.data();
  factory RoundedRectShape.fromJson(Map<String, dynamic> d) => RoundedRectShape.data(
        startPoint: jsonToOffset(d['startPoint'] as Map<String, dynamic>),
        endPoint: jsonToOffset(d['endPoint'] as Map<String, dynamic>),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  String get contentType => 'RoundedRectShape';

  @override
  void drawShape(Canvas canvas, Rect r, Offset s, Offset e, Paint paint) => canvas.drawRRect(
        RRect.fromRectAndRadius(r, Radius.circular(min(r.width, r.height) * 0.18)),
        paint,
      );

  @override
  RoundedRectShape copy() => RoundedRectShape();
}

/// 平行四边形 / Parallelogram
class ParallelogramShape extends DragShape {
  ParallelogramShape();
  ParallelogramShape.data(
      {required super.startPoint, required super.endPoint, required super.paint})
      : super.data();
  factory ParallelogramShape.fromJson(Map<String, dynamic> d) => ParallelogramShape.data(
        startPoint: jsonToOffset(d['startPoint'] as Map<String, dynamic>),
        endPoint: jsonToOffset(d['endPoint'] as Map<String, dynamic>),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  String get contentType => 'ParallelogramShape';

  @override
  void drawShape(Canvas canvas, Rect r, Offset s, Offset e, Paint paint) => canvas.drawPath(
        _fracPath(r,
            const <Offset>[Offset(0.25, 0), Offset(1, 0), Offset(0.75, 1), Offset(0, 1)]),
        paint,
      );

  @override
  ParallelogramShape copy() => ParallelogramShape();
}

/// 梯形 / Trapezoid
class TrapezoidShape extends DragShape {
  TrapezoidShape();
  TrapezoidShape.data({required super.startPoint, required super.endPoint, required super.paint})
      : super.data();
  factory TrapezoidShape.fromJson(Map<String, dynamic> d) => TrapezoidShape.data(
        startPoint: jsonToOffset(d['startPoint'] as Map<String, dynamic>),
        endPoint: jsonToOffset(d['endPoint'] as Map<String, dynamic>),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  String get contentType => 'TrapezoidShape';

  @override
  void drawShape(Canvas canvas, Rect r, Offset s, Offset e, Paint paint) => canvas.drawPath(
        _fracPath(r,
            const <Offset>[Offset(0.2, 0), Offset(0.8, 0), Offset(1, 1), Offset(0, 1)]),
        paint,
      );

  @override
  TrapezoidShape copy() => TrapezoidShape();
}

/// 十字 / 加号 / Cross (plus)
class CrossShape extends DragShape {
  CrossShape();
  CrossShape.data({required super.startPoint, required super.endPoint, required super.paint})
      : super.data();
  factory CrossShape.fromJson(Map<String, dynamic> d) => CrossShape.data(
        startPoint: jsonToOffset(d['startPoint'] as Map<String, dynamic>),
        endPoint: jsonToOffset(d['endPoint'] as Map<String, dynamic>),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  String get contentType => 'CrossShape';

  @override
  void drawShape(Canvas canvas, Rect r, Offset s, Offset e, Paint paint) => canvas.drawPath(
        _fracPath(r, const <Offset>[
          Offset(0.34, 0), Offset(0.66, 0), Offset(0.66, 0.34), Offset(1, 0.34),
          Offset(1, 0.66), Offset(0.66, 0.66), Offset(0.66, 1), Offset(0.34, 1),
          Offset(0.34, 0.66), Offset(0, 0.66), Offset(0, 0.34), Offset(0.34, 0.34),
        ]),
        paint,
      );

  @override
  CrossShape copy() => CrossShape();
}

/// 闪电 / Lightning bolt
class LightningShape extends DragShape {
  LightningShape();
  LightningShape.data({required super.startPoint, required super.endPoint, required super.paint})
      : super.data();
  factory LightningShape.fromJson(Map<String, dynamic> d) => LightningShape.data(
        startPoint: jsonToOffset(d['startPoint'] as Map<String, dynamic>),
        endPoint: jsonToOffset(d['endPoint'] as Map<String, dynamic>),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  String get contentType => 'LightningShape';

  @override
  void drawShape(Canvas canvas, Rect r, Offset s, Offset e, Paint paint) => canvas.drawPath(
        _fracPath(r, const <Offset>[
          Offset(0.55, 0), Offset(0.15, 0.55), Offset(0.45, 0.55),
          Offset(0.3, 1), Offset(0.85, 0.4), Offset(0.5, 0.4),
        ]),
        paint,
      );

  @override
  LightningShape copy() => LightningShape();
}

/// 心形 / Heart
class HeartShape extends DragShape {
  HeartShape();
  HeartShape.data({required super.startPoint, required super.endPoint, required super.paint})
      : super.data();
  factory HeartShape.fromJson(Map<String, dynamic> d) => HeartShape.data(
        startPoint: jsonToOffset(d['startPoint'] as Map<String, dynamic>),
        endPoint: jsonToOffset(d['endPoint'] as Map<String, dynamic>),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  String get contentType => 'HeartShape';

  @override
  void drawShape(Canvas canvas, Rect r, Offset s, Offset e, Paint paint) {
    final Offset c = r.center;
    final Path p = Path();
    const int n = 60;
    for (int i = 0; i <= n; i++) {
      final double t = i / n * 2 * pi;
      final double x = 16 * pow(sin(t), 3).toDouble();
      final double y = 13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t);
      final Offset pt = Offset(c.dx + x / 17 * (r.width / 2), c.dy - y / 17 * (r.height / 2));
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    p.close();
    canvas.drawPath(p, paint);
  }

  @override
  HeartShape copy() => HeartShape();
}

/// 对话气泡 / Speech bubble
class SpeechBubbleShape extends DragShape {
  SpeechBubbleShape();
  SpeechBubbleShape.data(
      {required super.startPoint, required super.endPoint, required super.paint})
      : super.data();
  factory SpeechBubbleShape.fromJson(Map<String, dynamic> d) => SpeechBubbleShape.data(
        startPoint: jsonToOffset(d['startPoint'] as Map<String, dynamic>),
        endPoint: jsonToOffset(d['endPoint'] as Map<String, dynamic>),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  String get contentType => 'SpeechBubbleShape';

  @override
  void drawShape(Canvas canvas, Rect r, Offset s, Offset e, Paint paint) {
    final Rect body = Rect.fromLTRB(r.left, r.top, r.right, r.bottom - r.height * 0.22);
    if (body.isEmpty) {
      return;
    }
    final Path bubble = Path()
      ..addRRect(RRect.fromRectAndRadius(
        body,
        Radius.circular(min(body.width, body.height) * 0.2),
      ));
    final Path tail = Path()
      ..moveTo(body.left + body.width * 0.26, body.bottom - 1)
      ..lineTo(body.left + body.width * 0.30, r.bottom)
      ..lineTo(body.left + body.width * 0.48, body.bottom - 1)
      ..close();
    canvas.drawPath(Path.combine(ui.PathOperation.union, bubble, tail), paint);
  }

  @override
  SpeechBubbleShape copy() => SpeechBubbleShape();
}

/// 云朵 / Cloud
class CloudShape extends DragShape {
  CloudShape();
  CloudShape.data({required super.startPoint, required super.endPoint, required super.paint})
      : super.data();
  factory CloudShape.fromJson(Map<String, dynamic> d) => CloudShape.data(
        startPoint: jsonToOffset(d['startPoint'] as Map<String, dynamic>),
        endPoint: jsonToOffset(d['endPoint'] as Map<String, dynamic>),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  @override
  String get contentType => 'CloudShape';

  @override
  void drawShape(Canvas canvas, Rect r, Offset s, Offset e, Paint paint) {
    if (r.isEmpty) {
      return;
    }
    final double w = r.width;
    final double h = r.height;
    Path p = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(r.left + w * 0.30, r.top + h * 0.58),
          width: w * 0.46,
          height: h * 0.62));
    for (final Rect oval in <Rect>[
      Rect.fromCenter(
          center: Offset(r.left + w * 0.52, r.top + h * 0.42), width: w * 0.52, height: h * 0.72),
      Rect.fromCenter(
          center: Offset(r.left + w * 0.74, r.top + h * 0.58), width: w * 0.44, height: h * 0.58),
    ]) {
      p = Path.combine(ui.PathOperation.union, p, Path()..addOval(oval));
    }
    p = Path.combine(
      ui.PathOperation.union,
      p,
      Path()
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(r.left + w * 0.14, r.top + h * 0.6, r.right - w * 0.12, r.bottom),
          Radius.circular(h * 0.2),
        )),
    );
    canvas.drawPath(p, paint);
  }

  @override
  CloudShape copy() => CloudShape();
}

/// 箭头 / Arrow
///
/// 从起点指向终点，箭头方向随拖拽方向变化。
///
/// Points from the start to the end of the drag, so the arrow follows the drag
/// direction.
class ArrowShape extends DragShape {
  ArrowShape({this.doubleHeaded = false});

  ArrowShape.data({
    this.doubleHeaded = false,
    required super.startPoint,
    required super.endPoint,
    required super.paint,
  }) : super.data();

  factory ArrowShape.fromJson(Map<String, dynamic> d) => ArrowShape.data(
        doubleHeaded: (d['doubleHeaded'] ?? false) as bool,
        startPoint: jsonToOffset(d['startPoint'] as Map<String, dynamic>),
        endPoint: jsonToOffset(d['endPoint'] as Map<String, dynamic>),
        paint: jsonToPaint(d['paint'] as Map<String, dynamic>),
      );

  /// 是否双向箭头 / Whether both ends have arrow heads
  final bool doubleHeaded;

  @override
  String get contentType => 'ArrowShape';

  @override
  void drawShape(Canvas canvas, Rect r, Offset s, Offset e, Paint paint) {
    final Offset delta = e - s;
    final double len = delta.distance;
    if (len < 1) {
      return;
    }
    final Offset u = delta / len;
    final Offset n = Offset(-u.dy, u.dx);
    final double head = min(len * 0.32, paint.strokeWidth * 5 + 14);
    final double halfW = head * 0.5;
    final Paint fill = paint.copyWith(style: PaintingStyle.fill);

    final Offset tailEnd = e - u * head;
    final Offset shaftStart = doubleHeaded ? s + u * head : s;
    canvas.drawLine(shaftStart, tailEnd, paint);

    canvas.drawPath(
      Path()
        ..moveTo(e.dx, e.dy)
        ..lineTo(tailEnd.dx + n.dx * halfW, tailEnd.dy + n.dy * halfW)
        ..lineTo(tailEnd.dx - n.dx * halfW, tailEnd.dy - n.dy * halfW)
        ..close(),
      fill,
    );

    if (doubleHeaded) {
      canvas.drawPath(
        Path()
          ..moveTo(s.dx, s.dy)
          ..lineTo(shaftStart.dx + n.dx * halfW, shaftStart.dy + n.dy * halfW)
          ..lineTo(shaftStart.dx - n.dx * halfW, shaftStart.dy - n.dy * halfW)
          ..close(),
        fill,
      );
    }
  }

  @override
  ArrowShape copy() => ArrowShape(doubleHeaded: doubleHeaded);

  @override
  Map<String, dynamic> toContentJson() =>
      <String, dynamic>{...super.toContentJson(), 'doubleHeaded': doubleHeaded};
}
