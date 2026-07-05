import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package_code/src/paint_contents/simple_line.dart';

class ActiveFreehandLineSticker {
  ActiveFreehandLineSticker({
    required this.id,
    required this.content,
  });

  final String id;
  final FreehandLine content;
}

class FreehandLineStickerWidget extends StatefulWidget {
  const FreehandLineStickerWidget({
    super.key,
    required this.data,
    required this.onUpdate,
    required this.onDelete,
    required this.onConfirm,
    this.onSnap,
    this.onUpdateEnd,
  });

  final ActiveFreehandLineSticker data;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;
  final VoidCallback onConfirm;
  final Offset Function(Offset rawPoint, Offset anchor)? onSnap;
  final VoidCallback? onUpdateEnd;

  @override
  State<FreehandLineStickerWidget> createState() => _FreehandLineStickerWidgetState();
}

class _FreehandLineStickerWidgetState extends State<FreehandLineStickerWidget> {
  @override
  Widget build(BuildContext context) {
    final points = widget.data.content.points;
    if (points == null || points.isEmpty) return const SizedBox.shrink();

    final Offset startPoint = points.first;
    final Offset endPoint = points.last;

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
              painter: _FreehandLineStickerPainter(content: widget.data.content),
            ),
          ),
        ),
        
        // Start point handle
        Positioned(
          left: startPoint.dx - 24,
          top: startPoint.dy - 24,
          width: 48,
          height: 48,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (d) => _onPanUpdateEndpoint(d, true),
            onPanEnd: (_) => widget.onUpdateEnd?.call(),
            child: _buildHandleIcon(),
          ),
        ),

        // End point handle
        Positioned(
          left: endPoint.dx - 24,
          top: endPoint.dy - 24,
          width: 48,
          height: 48,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (d) => _onPanUpdateEndpoint(d, false),
            onPanEnd: (_) => widget.onUpdateEnd?.call(),
            child: _buildHandleIcon(),
          ),
        ),
      ],
    );
  }

  Widget _buildHandleIcon() {
    return Center(
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4),
          ],
        ),
      ),
    );
  }

  void _onPanUpdateEndpoint(DragUpdateDetails details, bool isStart) {
    setState(() {
      final points = widget.data.content.points;
      if (points != null && points.isNotEmpty) {
        if (isStart) {
          // Continue/Prepend logic
          final Offset firstPoint = points.first;
          final Offset delta = details.delta;
          final double distance = delta.distance;

          // Note: for parallel line snapping, the anchor is typically the *other* end or a stable prior point.
          // Since FreehandLine is an array of points, we use the opposite end of the stroke segment as anchor to maintain axis tracing.
          final Offset anchor = points.length > 1 ? points[1] : points.last;

          Offset newPoint;
          if (distance > widget.data.content.minPointDistance) {
            newPoint = firstPoint + delta;
            if (widget.onSnap != null) newPoint = widget.onSnap!(newPoint, anchor);
            points.insert(0, newPoint);
          } else {
            newPoint = points[0] + delta;
            if (widget.onSnap != null) newPoint = widget.onSnap!(newPoint, anchor);
            points[0] = newPoint;
          }
        } else {
          // Continue/Append logic
          final Offset lastPoint = points.last;
          final Offset delta = details.delta;
          final double distance = delta.distance;
          
          final Offset anchor = points.length > 1 ? points[points.length - 2] : points.first;

          Offset newPoint;
          if (distance > widget.data.content.minPointDistance) {
            newPoint = lastPoint + delta;
            if (widget.onSnap != null) newPoint = widget.onSnap!(newPoint, anchor);
            points.add(newPoint);
          } else {
            newPoint = points[points.length - 1] + delta;
            if (widget.onSnap != null) newPoint = widget.onSnap!(newPoint, anchor);
            points[points.length - 1] = newPoint;
          }
        }
      }
    });
    widget.onUpdate();
  }

  void _onPanUpdateLine(DragUpdateDetails details) {
    setState(() {
      final points = widget.data.content.points;
      if (points != null) {
        for (int i = 0; i < points.length; i++) {
          points[i] += details.delta;
        }
      }
    });
    widget.onUpdate();
  }
}

class _FreehandLineStickerPainter extends CustomPainter {
  final FreehandLine content;

  _FreehandLineStickerPainter({required this.content});

  @override
  bool? hitTest(Offset position) {
    final Path path = content.getPath();
    // Hit test with some tolerance
    return path.contains(position) || _isNearPath(path, position);
  }

  bool _isNearPath(Path path, Offset position) {
    for (ui.PathMetric metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 5) {
        final tangent = metric.getTangentForOffset(d);
        if (tangent != null && (tangent.position - position).distance < 20) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  void paint(Canvas canvas, Size size) {
    content.draw(canvas, size, false);
    
    // Draw endpoint indicators even in painter if needed, but Stack handles it usually.
    // For snapshot we might want them.
  }

  @override
  bool shouldRepaint(covariant _FreehandLineStickerPainter oldDelegate) {
    return true;
  }
}
