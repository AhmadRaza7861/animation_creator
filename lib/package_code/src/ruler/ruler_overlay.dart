import 'dart:math';
import 'package:flutter/material.dart';

import '../drawing_controller.dart';
import '../helper/ex_value_builder.dart';
import 'ruler_config.dart';

/// 尺子覆盖层组件，用于在画布上渲染尺子的指导线和可拖拽的手柄
/// Ruler overlay widget, renders ruler guidelines and draggable handles on canvas
class RulerOverlay extends StatelessWidget {
  const RulerOverlay({super.key, required this.controller});

  final DrawingController controller;

  @override
  Widget build(BuildContext context) {
    return ExValueBuilder<RulerConfig>(
      valueListenable: controller.rulerConfig,
      builder: (context, config, _) {
        if (config.type == RulerType.none) {
          return const SizedBox.shrink();
        }

        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            // The dashed lines layer
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  child: CustomPaint(
                    painter: RulerPainter(config, controller.getColor),
                  ),
                ),
              ),
            ),
            // The interactive handles layer
            if (!config.isLocked) ..._buildHandles(config),
          ],
        );
      },
    );
  }

  void _update(RulerConfig config, RulerConfig newConfig) {
    controller.rulerConfig.value = newConfig;
  }

  List<Widget> _buildHandles(RulerConfig config) {
    List<Widget> handles = [];

    // Center handle (Moves the entire ruler)
    handles.add(
      _buildKnob(
        position: config.center,
        isSquare: true,
        onDrag: (d) {
          _update(config, config.copyWith(center: config.center + d.delta));
        },
      ),
    );

    if (config.type == RulerType.line) {
      // Line has angle knobs on both sides
      final Offset p1 = config.center + Offset(cos(config.angle), sin(config.angle)) * config.scale;
      final Offset p2 = config.center - Offset(cos(config.angle), sin(config.angle)) * config.scale;

      handles.add(
        _buildKnob(
          position: p1,
          isSquare: false,
          onDrag: (d) {
            final newP1 = p1 + d.delta;
            // Center is midway between newP1 and fixed p2
            final newCenter = (newP1 + p2) / 2;
            final newAngle = atan2(newP1.dy - p2.dy, newP1.dx - p2.dx);
            final newScale = (newP1 - p2).distance / 2;
            _update(config, config.copyWith(center: newCenter, angle: newAngle, scale: max(10, newScale)));
          },
        ),
      );
      handles.add(
        _buildKnob(
          position: p2,
          isSquare: false,
          onDrag: (d) {
            final newP2 = p2 + d.delta;
            // Center is midway between fixed p1 and newP2
            final newCenter = (p1 + newP2) / 2;
            // Preserve polarity so angle reflects p1 to p2 orientation correctly
            final newAngle = atan2(p1.dy - newP2.dy, p1.dx - newP2.dx);
            final newScale = (p1 - newP2).distance / 2;
            _update(config, config.copyWith(center: newCenter, angle: newAngle, scale: max(10, newScale)));
          },
        ),
      );
    } 
    else if (config.type == RulerType.circle) {
      // Circle has a radius knob (horizontal)
      final Offset rightNode = config.center + Offset(cos(config.angle), sin(config.angle)) * config.scale;
      handles.add(
        _buildKnob(
          position: rightNode,
          isSquare: false,
          onDrag: (d) {
            final newPos = rightNode + d.delta;
            final newScale = (newPos - config.center).distance;
            final newAngle = atan2(newPos.dy - config.center.dy, newPos.dx - config.center.dx);
            _update(config, config.copyWith(scale: max(10, newScale), angle: newAngle));
          },
        ),
      );
      // Ellipse vertical knob (top edge) matching screenshot
      final Offset topNode = config.center + Offset(cos(config.angle - pi/2), sin(config.angle - pi/2)) * config.scaleY;
      handles.add(
        _buildKnob(
          position: topNode,
          isSquare: false,
          onDrag: (d) {
            final newPos = topNode + d.delta;
            final double dx = newPos.dx - config.center.dx;
            final double dy = newPos.dy - config.center.dy;
            final double localY = dx * cos(config.angle - pi/2) + dy * sin(config.angle - pi/2);
            _update(config, config.copyWith(scaleY: max(10, localY.abs())));
          },
        ),
      );
    } 
    else if (config.type == RulerType.box) {
      // Box has width and height knobs
      // Width knob (right edge)
      final Offset rightNode = config.center + Offset(cos(config.angle), sin(config.angle)) * config.scale;
      handles.add(
        _buildKnob(
          position: rightNode,
          isSquare: false,
          onDrag: (d) {
            final newPos = rightNode + d.delta;
            final newScale = (newPos - config.center).distance;
            final newAngle = atan2(newPos.dy - config.center.dy, newPos.dx - config.center.dx);
            _update(config, config.copyWith(scale: max(10, newScale), angle: newAngle));
          },
        ),
      );

      // Height knob (bottom edge)
      final Offset bottomNode = config.center + Offset(cos(config.angle + pi/2), sin(config.angle + pi/2)) * config.scaleY;
      handles.add(
        _buildKnob(
          position: bottomNode,
          isSquare: false,
          onDrag: (d) {
            final newPos = bottomNode + d.delta;
            final double dx = newPos.dx - config.center.dx;
            final double dy = newPos.dy - config.center.dy;
            final double localY = dx * cos(config.angle + pi/2) + dy * sin(config.angle + pi/2);
            _update(config, config.copyWith(scaleY: max(10, localY.abs())));
          },
        ),
      );
    }
    // Mirror has no additional knobs (just moves horizontally)
    else if (config.type == RulerType.mirror) {
       // Only allow moving the X coordinate
       handles.clear();
       handles.add(
        _buildKnob(
          position: Offset(config.center.dx, config.center.dy),
          isSquare: true,
          onDrag: (d) {
            _update(config, config.copyWith(center: Offset(config.center.dx + d.delta.dx, config.center.dy)));
          },
        ),
      );
       handles.add(
        _buildKnob(
          position: Offset(config.center.dx, config.center.dy - 100),
          isSquare: false,
          onDrag: (d) {
            _update(config, config.copyWith(center: Offset(config.center.dx + d.delta.dx, config.center.dy)));
          },
        ),
      );
    }

    return handles;
  }

  Widget _buildKnob({
    required Offset position,
    required bool isSquare,
    required void Function(DragUpdateDetails) onDrag,
  }) {
    return Positioned(
      left: position.dx - 12, // center the 24x24 box
      top: position.dy - 12,
      child: GestureDetector(
        onPanUpdate: onDrag,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: isSquare ? null : BorderRadius.circular(12),
            border: Border.all(color: Colors.black, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class RulerPainter extends CustomPainter {
  RulerPainter(this.config, this.color);

  final RulerConfig config;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (config.type == RulerType.none) return;

    final Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw dashed path
    Path path = Path();

    if (config.type == RulerType.line) {
      final double dx = cos(config.angle);
      final double dy = sin(config.angle);
      // Infinite line through center
      final Offset p1 = config.center - Offset(dx, dy) * 4000;
      final Offset p2 = config.center + Offset(dx, dy) * 4000;
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p2.dx, p2.dy);
    } else if (config.type == RulerType.circle || config.type == RulerType.box) {
      final Rect rect = Rect.fromCenter(center: Offset.zero, width: config.scale * 2, height: config.scaleY * 2);
      if (config.type == RulerType.circle) {
        path.addOval(rect);
      } else {
        path.addRect(rect);
      }
    } else if (config.type == RulerType.mirror) {
      final Offset p1 = Offset(config.center.dx, -4000);
      final Offset p2 = Offset(config.center.dx, 4000);
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p2.dx, p2.dy);
    }

    // Apply rotation for box and ellipse
    if (config.type == RulerType.box || config.type == RulerType.circle) {
      canvas.save();
      canvas.translate(config.center.dx, config.center.dy);
      canvas.rotate(config.angle);
      _drawDashedPath(canvas, path, paint);
      canvas.restore();
    } else {
      _drawDashedPath(canvas, path, paint);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final double nextDistance = min(distance + (draw ? 4.0 : 4.0), metric.length);
        if (draw) {
          canvas.drawPath(metric.extractPath(distance, nextDistance), paint);
        }
        distance = nextDistance;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant RulerPainter oldDelegate) {
    return oldDelegate.config != config || oldDelegate.color != color;
  }
}
