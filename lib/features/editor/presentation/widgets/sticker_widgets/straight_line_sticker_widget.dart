import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class ActiveStraightLineSticker {
  ActiveStraightLineSticker({
    required this.id,
    required this.startPoint,
    required this.endPoint,
    required this.paint,
    this.type = 'StraightLine',
  });

  final String id;
  Offset startPoint;
  Offset endPoint;
  Paint paint;
  final String type;
}

class StraightLineStickerWidget extends StatefulWidget {
  const StraightLineStickerWidget({
    super.key,
    required this.data,
    required this.onUpdate,
    required this.onDelete,
    required this.onConfirm,
    this.onSnap,
    this.onUpdateEnd,
  });

  final ActiveStraightLineSticker data;
  final Function(Offset start, Offset end) onUpdate;
  final VoidCallback onDelete;
  final VoidCallback onConfirm;
  final Offset Function(Offset rawPoint, Offset anchor)? onSnap;
  final VoidCallback? onUpdateEnd;

  @override
  State<StraightLineStickerWidget> createState() => _StraightLineStickerWidgetState();
}

class _StraightLineStickerWidgetState extends State<StraightLineStickerWidget> {
  late Offset _startPoint;
  late Offset _endPoint;

  Offset? _rawDragStart;
  Offset? _rawDragEnd;

  @override
  void initState() {
    super.initState();
    _startPoint = widget.data.startPoint;
    _endPoint = widget.data.endPoint;
  }

  @override
  void didUpdateWidget(covariant StraightLineStickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data.startPoint != oldWidget.data.startPoint ||
        widget.data.endPoint != oldWidget.data.endPoint) {
      _startPoint = widget.data.startPoint;
      _endPoint = widget.data.endPoint;
    }
  }

  void _onPanStartEndpoint(DragStartDetails details, bool isStart) {
    if (isStart) {
      _rawDragStart = _startPoint;
    } else {
      _rawDragEnd = _endPoint;
    }
  }

  void _onPanUpdateEndpoint(DragUpdateDetails details, bool isStart) {
    setState(() {
      if (isStart) {
        _rawDragStart = (_rawDragStart ?? _startPoint) + details.delta;
        _startPoint = widget.onSnap != null ? widget.onSnap!(_rawDragStart!, _endPoint) : _rawDragStart!;
      } else {
        _rawDragEnd = (_rawDragEnd ?? _endPoint) + details.delta;
        _endPoint = widget.onSnap != null ? widget.onSnap!(_rawDragEnd!, _startPoint) : _rawDragEnd!;
      }
    });
    widget.onUpdate(_startPoint, _endPoint);
  }

  void _onPanUpdateLine(DragUpdateDetails details) {
    setState(() {
      _startPoint += details.delta;
      _endPoint += details.delta;
    });
    widget.onUpdate(_startPoint, _endPoint);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background layer: painter and line body hit test
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.deferToChild,
            onPanUpdate: _onPanUpdateLine,
            onPanEnd: (_) => widget.onUpdateEnd?.call(),
            onDoubleTap: widget.onConfirm,
            child: CustomPaint(
              painter: _StraightLinePainter(startPoint: _startPoint, endPoint: _endPoint),
            ),
          ),
        ),
        
        // Start point hot zone
        Positioned(
          left: _startPoint.dx - 24,
          top: _startPoint.dy - 24,
          width: 48,
          height: 48,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) => _onPanStartEndpoint(d, true),
            onPanUpdate: (d) => _onPanUpdateEndpoint(d, true),
            onPanEnd: (_) => widget.onUpdateEnd?.call(),
            child: Container(
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.transparent),
            ),
          ),
        ),

        // End point hot zone
        Positioned(
          left: _endPoint.dx - 24,
          top: _endPoint.dy - 24,
          width: 48,
          height: 48,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) => _onPanStartEndpoint(d, false),
            onPanUpdate: (d) => _onPanUpdateEndpoint(d, false),
            onPanEnd: (_) => widget.onUpdateEnd?.call(),
            child: Container(
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.transparent),
            ),
          ),
        ),
      ],
    );
  }
}

class _StraightLinePainter extends CustomPainter {
  final Offset startPoint;
  final Offset endPoint;

  _StraightLinePainter({required this.startPoint, required this.endPoint});

  @override
  bool? hitTest(Offset position) {
    // Check if the tap position is within a reasonable distance (e.g., 25 pixels) from the line segment
    final math.Point<double> pA = math.Point(startPoint.dx, startPoint.dy);
    final math.Point<double> pB = math.Point(endPoint.dx, endPoint.dy);
    final math.Point<double> pP = math.Point(position.dx, position.dy);

    final double abX = pB.x - pA.x;
    final double abY = pB.y - pA.y;
    final double apX = pP.x - pA.x;
    final double apY = pP.y - pA.y;

    final double squaredLengthAB = abX * abX + abY * abY;
    if (squaredLengthAB == 0) {
      return apX * apX + apY * apY <= 25.0 * 25.0;
    }

    double t = (apX * abX + apY * abY) / squaredLengthAB;
    t = t.clamp(0.0, 1.0);

    final double projectionX = pA.x + abX * t;
    final double projectionY = pA.y + abY * t;
    
    final double distSq = math.pow(pP.x - projectionX, 2).toDouble() + math.pow(pP.y - projectionY, 2).toDouble();
    return distSq <= 25.0 * 25.0;
  }

  void drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint, {List<double> dashArray = const [5, 5]}) {
    final double distance = (p2 - p1).distance;
    if (distance <= 0) return;
    final Offset direction = (p2 - p1) / distance;
    
    double drawnLength = 0.0;
    int phase = 0;
    
    while (drawnLength < distance) {
      double dashLength = dashArray[phase % dashArray.length];
      if (drawnLength + dashLength > distance) {
        dashLength = distance - drawnLength;
      }
      
      if (phase % 2 == 0) {
        canvas.drawLine(
          p1 + direction * drawnLength,
          p1 + direction * (drawnLength + dashLength),
          paint,
        );
      }
      drawnLength += dashLength;
      phase++;
    }
  }

  void drawDashedCircle(Canvas canvas, Offset center, double radius, Paint paint, {List<double> dashArray = const [5, 5]}) {
    final Path path = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    
    for (ui.PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      int phase = 0;
      while (distance < metric.length) {
        final double dashLength = dashArray[phase % dashArray.length];
        
        if (phase % 2 == 0) {
          canvas.drawPath(
            metric.extractPath(distance, distance + dashLength),
            paint,
          );
        }
        distance += dashLength;
        phase++;
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Solid blue line
    final Paint linePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawLine(startPoint, endPoint, linePaint);

    // 2. Solid blue circle endpoints
    final Paint solidBlue = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    canvas.drawCircle(startPoint, 8, solidBlue);
    canvas.drawCircle(endPoint, 8, solidBlue);

    // 3. Highlight/Border for visibility
    final Paint outlinePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(startPoint, 8, outlinePaint);
    canvas.drawCircle(endPoint, 8, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant _StraightLinePainter oldDelegate) {
    return oldDelegate.startPoint != startPoint || oldDelegate.endPoint != endPoint;
  }
}
