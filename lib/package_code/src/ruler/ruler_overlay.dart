import 'dart:math';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../drawing_controller.dart';
import '../helper/ex_value_builder.dart';
import 'ruler_config.dart';

/// 尺子覆盖层组件，完美契合应用橙色主色调（App Theme ColorConstants.primary）与高透玻璃质感
/// Ruler overlay widget, perfectly aligned with app theme and see-through glassmorphic design
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
            // 1. The visual transparent ruler body, measurement ticks, and guidelines
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: RulerPainter(config, controller.getColor),
                ),
              ),
            ),
            // 2. The interactive transparent handles layer (hidden when locked)
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
    final List<Widget> handles = [];

    // ---------------- LINE RULER HANDLES ----------------
    if (config.type == RulerType.line) {
      final double dx = cos(config.angle);
      final double dy = sin(config.angle);
      final Offset p1 = config.center + Offset(dx, dy) * config.scale;
      final Offset p2 = config.center - Offset(dx, dy) * config.scale;

      // Center move knob with degree readout
      final double deg = (((config.angle * 180 / pi) % 360 + 360) % 360);
      handles.add(
        _buildKnob(
          position: config.center,
          type: _KnobType.centerMove,
          badgeText: '${deg.round()}°',
          badgeOffset: const Offset(0, -30),
          onDrag: (d) {
            _update(config, config.copyWith(center: config.center + d.delta));
          },
        ),
      );

      // Pivot knob P1
      handles.add(
        _buildKnob(
          position: p1,
          type: _KnobType.pivot,
          onDrag: (d) {
            final newP1 = p1 + d.delta;
            final newCenter = (newP1 + p2) / 2;
            final newAngle = atan2(newP1.dy - p2.dy, newP1.dx - p2.dx);
            final newScale = (newP1 - p2).distance / 2;
            _update(
              config,
              config.copyWith(
                center: newCenter,
                angle: newAngle,
                scale: max(20, newScale),
              ),
            );
          },
        ),
      );

      // Pivot knob P2
      handles.add(
        _buildKnob(
          position: p2,
          type: _KnobType.pivot,
          onDrag: (d) {
            final newP2 = p2 + d.delta;
            final newCenter = (p1 + newP2) / 2;
            final newAngle = atan2(p1.dy - newP2.dy, p1.dx - newP2.dx);
            final newScale = (p1 - newP2).distance / 2;
            _update(
              config,
              config.copyWith(
                center: newCenter,
                angle: newAngle,
                scale: max(20, newScale),
              ),
            );
          },
        ),
      );
    }

    // ---------------- CIRCLE / ELLIPSE RULER HANDLES ----------------
    else if (config.type == RulerType.circle) {
      final double cosA = cos(config.angle);
      final double sinA = sin(config.angle);
      final double cosPerp = cos(config.angle - pi / 2);
      final double sinPerp = sin(config.angle - pi / 2);

      final Offset rightNode = config.center + Offset(cosA, sinA) * config.scale;
      final Offset topNode = config.center + Offset(cosPerp, sinPerp) * config.scaleY;

      // Center move knob
      final bool isUniformCircle = (config.scale - config.scaleY).abs() < 1.0;
      final String dimensionText = isUniformCircle
          ? 'R: ${config.scale.round()}px'
          : '${(config.scale * 2).round()} × ${(config.scaleY * 2).round()}px';

      handles.add(
        _buildKnob(
          position: config.center,
          type: _KnobType.centerMove,
          badgeText: dimensionText,
          badgeOffset: const Offset(0, -30),
          onDrag: (d) {
            _update(config, config.copyWith(center: config.center + d.delta));
          },
        ),
      );

      // Width / Radius Knob
      handles.add(
        _buildKnob(
          position: rightNode,
          type: _KnobType.resizeHorizontal,
          angle: config.angle,
          onDrag: (d) {
            final newPos = rightNode + d.delta;
            final newScale = (newPos - config.center).distance;
            final newAngle = atan2(newPos.dy - config.center.dy, newPos.dx - config.center.dx);
            _update(
              config,
              config.copyWith(
                scale: max(15, newScale),
                scaleY: isUniformCircle ? max(15, newScale) : config.scaleY,
                angle: newAngle,
              ),
            );
          },
        ),
      );

      // Height Knob (for ellipse scaling)
      handles.add(
        _buildKnob(
          position: topNode,
          type: _KnobType.resizeVertical,
          angle: config.angle,
          onDrag: (d) {
            final newPos = topNode + d.delta;
            final double dx = newPos.dx - config.center.dx;
            final double dy = newPos.dy - config.center.dy;
            final double localY = dx * cosPerp + dy * sinPerp;
            _update(config, config.copyWith(scaleY: max(15, localY.abs())));
          },
        ),
      );
    }

    // ---------------- BOX / RECTANGLE RULER HANDLES ----------------
    else if (config.type == RulerType.box) {
      final double cosA = cos(config.angle);
      final double sinA = sin(config.angle);
      final double cosPerp = cos(config.angle + pi / 2);
      final double sinPerp = sin(config.angle + pi / 2);

      final Offset rightNode = config.center + Offset(cosA, sinA) * config.scale;
      final Offset bottomNode = config.center + Offset(cosPerp, sinPerp) * config.scaleY;

      // Center move knob
      final String dimensionText =
          '${(config.scale * 2).round()} × ${(config.scaleY * 2).round()}px';

      handles.add(
        _buildKnob(
          position: config.center,
          type: _KnobType.centerMove,
          badgeText: dimensionText,
          badgeOffset: const Offset(0, -30),
          onDrag: (d) {
            _update(config, config.copyWith(center: config.center + d.delta));
          },
        ),
      );

      // Width knob (right edge)
      handles.add(
        _buildKnob(
          position: rightNode,
          type: _KnobType.resizeHorizontal,
          angle: config.angle,
          onDrag: (d) {
            final newPos = rightNode + d.delta;
            final newScale = (newPos - config.center).distance;
            final newAngle = atan2(newPos.dy - config.center.dy, newPos.dx - config.center.dx);
            _update(config, config.copyWith(scale: max(20, newScale), angle: newAngle));
          },
        ),
      );

      // Height knob (bottom edge)
      handles.add(
        _buildKnob(
          position: bottomNode,
          type: _KnobType.resizeVertical,
          angle: config.angle,
          onDrag: (d) {
            final newPos = bottomNode + d.delta;
            final double dx = newPos.dx - config.center.dx;
            final double dy = newPos.dy - config.center.dy;
            final double localY = dx * cosPerp + dy * sinPerp;
            _update(config, config.copyWith(scaleY: max(20, localY.abs())));
          },
        ),
      );
    }

    // ---------------- MIRROR / SYMMETRY RULER HANDLES ----------------
    else if (config.type == RulerType.mirror) {
      final double dx = cos(config.angle);
      final double dy = sin(config.angle);
      final Offset p1 = config.center + Offset(dx, dy) * config.scale;
      final Offset p2 = config.center - Offset(dx, dy) * config.scale;

      // Center move knob with degree readout
      final double deg = (((config.angle * 180 / pi) % 360 + 360) % 360);
      handles.add(
        _buildKnob(
          position: config.center,
          type: _KnobType.mirrorCenter,
          badgeText: '${deg.round()}°',
          badgeOffset: const Offset(0, -30),
          onDrag: (d) {
            _update(
              config,
              config.copyWith(
                center: config.center + d.delta,
              ),
            );
          },
        ),
      );

      // Pivot knob P1 (Top point)
      handles.add(
        _buildKnob(
          position: p1,
          type: _KnobType.pivot,
          onDrag: (d) {
            final newP1 = p1 + d.delta;
            final newCenter = (newP1 + p2) / 2;
            final newAngle = atan2(newP1.dy - p2.dy, newP1.dx - p2.dx);
            final newScale = (newP1 - p2).distance / 2;
            _update(
              config,
              config.copyWith(
                center: newCenter,
                angle: newAngle,
                scale: max(30, newScale),
              ),
            );
          },
        ),
      );

      // Pivot knob P2 (Bottom point)
      handles.add(
        _buildKnob(
          position: p2,
          type: _KnobType.pivot,
          onDrag: (d) {
            final newP2 = p2 + d.delta;
            final newCenter = (p1 + newP2) / 2;
            final newAngle = atan2(p1.dy - newP2.dy, p1.dx - newP2.dx);
            final newScale = (p1 - newP2).distance / 2;
            _update(
              config,
              config.copyWith(
                center: newCenter,
                angle: newAngle,
                scale: max(30, newScale),
              ),
            );
          },
        ),
      );
    }

    // ---------------- 4-WAY QUADRANT MIRROR HANDLES ----------------
    else if (config.type == RulerType.quadMirror) {
      final double dx = cos(config.angle);
      final double dy = sin(config.angle);
      final Offset p1 = config.center + Offset(dx, dy) * config.scale;

      // Center move knob with degree readout
      final double deg = (((config.angle * 180 / pi) % 360 + 360) % 360);
      handles.add(
        _buildKnob(
          position: config.center,
          type: _KnobType.mirrorCenter,
          badgeText: '4-MIRR ${deg.round()}°',
          badgeOffset: const Offset(0, -30),
          onDrag: (d) {
            _update(
              config,
              config.copyWith(
                center: config.center + d.delta,
              ),
            );
          },
        ),
      );

      // Pivot knob P1 (Rotation / Arm Length)
      handles.add(
        _buildKnob(
          position: p1,
          type: _KnobType.pivot,
          onDrag: (d) {
            final newP1 = p1 + d.delta;
            final newAngle = atan2(newP1.dy - config.center.dy, newP1.dx - config.center.dx);
            final newScale = (newP1 - config.center).distance;
            _update(
              config,
              config.copyWith(
                angle: newAngle,
                scale: max(30, newScale),
              ),
            );
          },
        ),
      );
    }

    return handles;
  }

  Widget _buildKnob({
    required Offset position,
    required _KnobType type,
    String? badgeText,
    Offset badgeOffset = Offset.zero,
    double angle = 0.0,
    required void Function(DragUpdateDetails) onDrag,
  }) {
    // 48x48 touch hit-target for effortless precision touch without bloating the visual handle
    const double touchSize = 48.0;

    return Positioned(
      left: position.dx - touchSize / 2,
      top: position.dy - touchSize / 2,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Semi-transparent measurement badge (angle degrees or dimensions)
          if (badgeText != null)
            Positioned(
              left: (touchSize / 2) + badgeOffset.dx - 36,
              top: (touchSize / 2) + badgeOffset.dy - 12,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ColorConstants.darkText.withValues(alpha: 0.50),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ),

          // Interactive GestureDetector with transparent/glassmorphic visual
          GestureDetector(
            onPanUpdate: onDrag,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: touchSize,
              height: touchSize,
              child: Center(
                child: _buildKnobVisual(type, angle),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKnobVisual(_KnobType type, double angle) {
    switch (type) {
      case _KnobType.centerMove:
        return Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.28),
            shape: BoxShape.circle,
            border: Border.all(
              color: ColorConstants.primary.withValues(alpha: 0.9),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: ColorConstants.primary.withValues(alpha: 0.18),
                blurRadius: 6,
                spreadRadius: 0,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.open_with_rounded,
              color: ColorConstants.primary,
              size: 18,
            ),
          ),
        );

      case _KnobType.pivot:
        return Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.28),
            shape: BoxShape.circle,
            border: Border.all(
              color: ColorConstants.primary.withValues(alpha: 0.9),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: ColorConstants.primary.withValues(alpha: 0.18),
                blurRadius: 4,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: ColorConstants.primary.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );

      case _KnobType.resizeHorizontal:
        return Transform.rotate(
          angle: angle,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.28),
              shape: BoxShape.circle,
              border: Border.all(
                color: ColorConstants.primary.withValues(alpha: 0.9),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: ColorConstants.primary.withValues(alpha: 0.18),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.swap_horiz_rounded,
                color: ColorConstants.primary,
                size: 18,
              ),
            ),
          ),
        );

      case _KnobType.resizeVertical:
        return Transform.rotate(
          angle: angle,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.28),
              shape: BoxShape.circle,
              border: Border.all(
                color: ColorConstants.primary.withValues(alpha: 0.9),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: ColorConstants.primary.withValues(alpha: 0.18),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.swap_vert_rounded,
                color: ColorConstants.primary,
                size: 18,
              ),
            ),
          ),
        );

      case _KnobType.mirrorCenter:
        return Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.28),
            shape: BoxShape.circle,
            border: Border.all(
              color: ColorConstants.primary.withValues(alpha: 0.9),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: ColorConstants.primary.withValues(alpha: 0.22),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.flip_rounded,
              color: ColorConstants.primary,
              size: 18,
            ),
          ),
        );

      case _KnobType.mirrorGrip:
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.28),
            shape: BoxShape.circle,
            border: Border.all(
              color: ColorConstants.primary.withValues(alpha: 0.9),
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: ColorConstants.primary.withValues(alpha: 0.15),
                blurRadius: 4,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.compare_arrows_rounded,
              color: ColorConstants.primary,
              size: 15,
            ),
          ),
        );
    }
  }
}

enum _KnobType {
  centerMove,
  pivot,
  resizeHorizontal,
  resizeVertical,
  mirrorCenter,
  mirrorGrip,
}

/// CustomPainter that renders see-through frosted acrylic straightedges, compasses, precision tick marks, and guidelines
class RulerPainter extends CustomPainter {
  RulerPainter(this.config, this.color);

  final RulerConfig config;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (config.type == RulerType.none) return;

    switch (config.type) {
      case RulerType.line:
        _paintLineRuler(canvas, size);
        break;
      case RulerType.circle:
        _paintCircleRuler(canvas, size);
        break;
      case RulerType.box:
        _paintBoxRuler(canvas, size);
        break;
      case RulerType.mirror:
        _paintMirrorRuler(canvas, size);
        break;
      case RulerType.quadMirror:
        _paintQuadMirrorRuler(canvas, size);
        break;
      case RulerType.none:
        break;
    }
  }

  // ==========================================
  // 1. STRAIGHTEDGE / LINE RULER (See-Through)
  // ==========================================
  void _paintLineRuler(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(config.center.dx, config.center.dy);
    canvas.rotate(config.angle);

    const double rulerHalfHeight = 32.0;
    const double rulerExtent = 3500.0;

    // 1. Highly Transparent Frosted Acrylic Ruler Body (Canvas art clearly visible below)
    final Rect rulerRect = Rect.fromLTRB(
      -rulerExtent,
      -rulerHalfHeight,
      rulerExtent,
      rulerHalfHeight,
    );

    final Paint bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.35),
          const Color(0xFFF8FAFC).withValues(alpha: 0.20),
          Colors.white.withValues(alpha: 0.35),
        ],
      ).createShader(rulerRect)
      ..style = PaintingStyle.fill;

    canvas.drawRect(rulerRect, bodyPaint);

    // 2. Crisp Edge Borders
    final Paint edgePaint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      const Offset(-rulerExtent, -rulerHalfHeight),
      const Offset(rulerExtent, -rulerHalfHeight),
      edgePaint,
    );
    canvas.drawLine(
      const Offset(-rulerExtent, rulerHalfHeight),
      const Offset(rulerExtent, rulerHalfHeight),
      edgePaint,
    );

    // 3. Protractor arc at center (Transparent)
    final Paint protractorArcPaint = Paint()
      ..color = ColorConstants.primary.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 36.0, protractorArcPaint);

    final Paint protractorRingPaint = Paint()
      ..color = ColorConstants.primary.withValues(alpha: 0.25)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset.zero, 36.0, protractorRingPaint);

    // Protractor degree radial notches
    final Paint protractorTickPaint = Paint()
      ..color = ColorConstants.primary.withValues(alpha: 0.4)
      ..strokeWidth = 1.0;
    for (int deg = 0; deg < 360; deg += 30) {
      final double rad = deg * pi / 180;
      final Offset pStart = Offset(cos(rad) * 31, sin(rad) * 31);
      final Offset pEnd = Offset(cos(rad) * 36, sin(rad) * 36);
      canvas.drawLine(pStart, pEnd, protractorTickPaint);
    }

    // 4. Precision Measurement Graduations along top & bottom edges
    final Paint majorTickPaint = Paint()
      ..color = const Color(0xFF475569).withValues(alpha: 0.75)
      ..strokeWidth = 1.2;
    final Paint mediumTickPaint = Paint()
      ..color = const Color(0xFF64748B).withValues(alpha: 0.65)
      ..strokeWidth = 1.0;
    final Paint minorTickPaint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.5)
      ..strokeWidth = 0.8;

    final TextStyle numeralStyle = TextStyle(
      color: const Color(0xFF64748B).withValues(alpha: 0.8),
      fontSize: 8.5,
      fontWeight: FontWeight.w600,
    );

    // Draw ticks from -1500 to +1500 relative to center
    const double tickRange = 1600.0;
    for (double x = -tickRange; x <= tickRange; x += 5.0) {
      final int val = x.round();
      if (val % 50 == 0) {
        // Major tick (12px)
        canvas.drawLine(
          Offset(x, -rulerHalfHeight),
          Offset(x, -rulerHalfHeight + 12),
          majorTickPaint,
        );
        canvas.drawLine(
          Offset(x, rulerHalfHeight),
          Offset(x, rulerHalfHeight - 12),
          majorTickPaint,
        );

        // Numerals on top side (skip 0 to avoid center knob overlap)
        if (val.abs() >= 50 && val.abs() % 100 == 0 && val.abs() <= 800) {
          final TextPainter tp = TextPainter(
            text: TextSpan(
              text: '${(val.abs() / 10).round()}',
              style: numeralStyle,
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(
            canvas,
            Offset(x - tp.width / 2, -rulerHalfHeight + 13),
          );
        }
      } else if (val % 25 == 0) {
        // Medium tick (8px)
        canvas.drawLine(
          Offset(x, -rulerHalfHeight),
          Offset(x, -rulerHalfHeight + 8),
          mediumTickPaint,
        );
        canvas.drawLine(
          Offset(x, rulerHalfHeight),
          Offset(x, rulerHalfHeight - 8),
          mediumTickPaint,
        );
      } else {
        // Minor tick (4px)
        canvas.drawLine(
          Offset(x, -rulerHalfHeight),
          Offset(x, -rulerHalfHeight + 4),
          minorTickPaint,
        );
        canvas.drawLine(
          Offset(x, rulerHalfHeight),
          Offset(x, rulerHalfHeight - 4),
          minorTickPaint,
        );
      }
    }

    // 5. Center Snap Guideline (Drawing Axis)
    final Paint snapGlowPaint = Paint()
      ..color = ColorConstants.primary.withValues(alpha: 0.12)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      const Offset(-rulerExtent, 0),
      const Offset(rulerExtent, 0),
      snapGlowPaint,
    );

    final Paint snapAxisPaint = Paint()
      ..color = ColorConstants.primary.withValues(alpha: 0.9)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    _drawDashedLine(
      canvas,
      const Offset(-rulerExtent, 0),
      const Offset(rulerExtent, 0),
      snapAxisPaint,
      dashLength: 7.0,
      gapLength: 4.0,
    );

    canvas.restore();
  }

  // ==========================================
  // 2. CIRCLE / ELLIPSE RULER (See-Through)
  // ==========================================
  void _paintCircleRuler(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(config.center.dx, config.center.dy);
    canvas.rotate(config.angle);

    final Rect ellipseRect = Rect.fromCenter(
      center: Offset.zero,
      width: config.scale * 2,
      height: config.scaleY * 2,
    );

    // 1. Translucent Stencil Fill (Soft whisper of color so user sees canvas below)
    final Paint fillPaint = Paint()
      ..color = ColorConstants.primary.withValues(alpha: 0.02)
      ..style = PaintingStyle.fill;
    canvas.drawOval(ellipseRect, fillPaint);

    // 2. Center Crosshairs
    final Paint crosshairPaint = Paint()
      ..color = ColorConstants.primary.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;
    _drawDashedLine(
      canvas,
      Offset(-config.scale, 0),
      Offset(config.scale, 0),
      crosshairPaint,
      dashLength: 4.0,
      gapLength: 4.0,
    );
    _drawDashedLine(
      canvas,
      Offset(0, -config.scaleY),
      Offset(0, config.scaleY),
      crosshairPaint,
      dashLength: 4.0,
      gapLength: 4.0,
    );

    // 3. Main Outline
    final Paint mainStroke = Paint()
      ..color = ColorConstants.primary.withValues(alpha: 0.9)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final Path ovalPath = Path()..addOval(ellipseRect);
    _drawDashedPath(canvas, ovalPath, mainStroke, dashLength: 8.0, gapLength: 4.0);

    // 4. Subtle Outer Halo Ring
    final Paint haloStroke = Paint()
      ..color = ColorConstants.primary.withValues(alpha: 0.12)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;
    canvas.drawOval(ellipseRect, haloStroke);

    // 5. Compass degree notch marks along the perimeter
    final Paint tickPaint = Paint()
      ..color = ColorConstants.primary.withValues(alpha: 0.6)
      ..strokeWidth = 1.2;
    for (int deg = 0; deg < 360; deg += 30) {
      final double rad = deg * pi / 180;
      final double cosR = cos(rad);
      final double sinR = sin(rad);
      final Offset outerPt = Offset(config.scale * cosR, config.scaleY * sinR);
      final Offset innerPt = Offset(
        (config.scale - 7.0) * cosR,
        (config.scaleY - 7.0) * sinR,
      );
      canvas.drawLine(innerPt, outerPt, tickPaint);
    }

    canvas.restore();
  }

  // ==========================================
  // 3. BOX / RECTANGLE RULER (See-Through)
  // ==========================================
  void _paintBoxRuler(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(config.center.dx, config.center.dy);
    canvas.rotate(config.angle);

    final double w = config.scale;
    final double h = config.scaleY;
    final Rect boxRect = Rect.fromCenter(
      center: Offset.zero,
      width: w * 2,
      height: h * 2,
    );

    // 1. Translucent Stencil Fill
    final Paint fillPaint = Paint()
      ..color = ColorConstants.primary.withValues(alpha: 0.02)
      ..style = PaintingStyle.fill;
    canvas.drawRect(boxRect, fillPaint);

    // 2. Center Crosshairs
    final Paint crosshairPaint = Paint()
      ..color = ColorConstants.primary.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;
    _drawDashedLine(
      canvas,
      Offset(-w, 0),
      Offset(w, 0),
      crosshairPaint,
      dashLength: 4.0,
      gapLength: 4.0,
    );
    _drawDashedLine(
      canvas,
      Offset(0, -h),
      Offset(0, h),
      crosshairPaint,
      dashLength: 4.0,
      gapLength: 4.0,
    );

    // 3. Main Box Dashed Outline
    final Paint boxStroke = Paint()
      ..color = ColorConstants.primary.withValues(alpha: 0.9)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    final Path boxPath = Path()..addRect(boxRect);
    _drawDashedPath(canvas, boxPath, boxStroke, dashLength: 8.0, gapLength: 4.0);

    // 4. CAD-style Corner Brackets / L-accents at all 4 corners
    final Paint bracketPaint = Paint()
      ..color = ColorConstants.primary.withValues(alpha: 0.95)
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    const double cornerLen = 14.0;
    // Top-Left
    canvas.drawLine(Offset(-w, -h), Offset(-w + cornerLen, -h), bracketPaint);
    canvas.drawLine(Offset(-w, -h), Offset(-w, -h + cornerLen), bracketPaint);
    // Top-Right
    canvas.drawLine(Offset(w, -h), Offset(w - cornerLen, -h), bracketPaint);
    canvas.drawLine(Offset(w, -h), Offset(w, -h + cornerLen), bracketPaint);
    // Bottom-Left
    canvas.drawLine(Offset(-w, h), Offset(-w + cornerLen, h), bracketPaint);
    canvas.drawLine(Offset(-w, h), Offset(-w, h - cornerLen), bracketPaint);
    // Bottom-Right
    canvas.drawLine(Offset(w, h), Offset(w - cornerLen, h), bracketPaint);
    canvas.drawLine(Offset(w, h), Offset(w, h - cornerLen), bracketPaint);

    canvas.restore();
  }

  // ==========================================
  // 4. MIRROR / SYMMETRY RULER (App Theme Primary)
  // ==========================================
  void _paintMirrorRuler(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(config.center.dx, config.center.dy);
    canvas.rotate(config.angle);

    const double lineExtent = 4000.0;

    // 1. Soft glowing background band matching App Theme Primary
    final Paint glowPaint = Paint()
      ..color = ColorConstants.primary.withValues(alpha: 0.09)
      ..strokeWidth = 14.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(-lineExtent, 0), const Offset(lineExtent, 0), glowPaint);

    // 2. Dashed Symmetry Axis Line in Primary Color
    final Paint mirrorStroke = Paint()
      ..color = ColorConstants.primary.withValues(alpha: 0.95)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    _drawDashedLine(
      canvas,
      const Offset(-lineExtent, 0),
      const Offset(lineExtent, 0),
      mirrorStroke,
      dashLength: 8.0,
      gapLength: 4.0,
    );

    // 3. Symmetrical reflection chevrons along the axis in Primary Color
    final Paint chevronPaint = Paint()
      ..color = ColorConstants.primary.withValues(alpha: 0.6)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    for (double d = -500; d <= 500; d += 100) {
      if (d.abs() < 40) continue; // skip center knob area
      // Upper chevron
      final Path topPath = Path()
        ..moveTo(d - 6, -12)
        ..lineTo(d, -6)
        ..lineTo(d + 6, -12);
      canvas.drawPath(topPath, chevronPaint);

      // Lower chevron
      final Path bottomPath = Path()
        ..moveTo(d - 6, 12)
        ..lineTo(d, 6)
        ..lineTo(d + 6, 12);
      canvas.drawPath(bottomPath, chevronPaint);
    }

    canvas.restore();
  }

  // ==========================================
  // 5. 4-WAY QUADRANT MIRROR RULER
  // ==========================================
  void _paintQuadMirrorRuler(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(config.center.dx, config.center.dy);
    canvas.rotate(config.angle);

    const double lineExtent = 4000.0;

    // 1. Soft glowing background cross bands
    final Paint glowPaint = Paint()
      ..color = ColorConstants.primary.withValues(alpha: 0.09)
      ..strokeWidth = 12.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(-lineExtent, 0), const Offset(lineExtent, 0), glowPaint);
    canvas.drawLine(const Offset(0, -lineExtent), const Offset(0, lineExtent), glowPaint);

    // 2. Dashed Symmetry Cross Lines in Primary Color
    final Paint mirrorStroke = Paint()
      ..color = ColorConstants.primary.withValues(alpha: 0.95)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    _drawDashedLine(
      canvas,
      const Offset(-lineExtent, 0),
      const Offset(lineExtent, 0),
      mirrorStroke,
      dashLength: 8.0,
      gapLength: 4.0,
    );
    _drawDashedLine(
      canvas,
      const Offset(0, -lineExtent),
      const Offset(0, lineExtent),
      mirrorStroke,
      dashLength: 8.0,
      gapLength: 4.0,
    );

    // 3. Center protractor ring
    final Paint ringPaint = Paint()
      ..color = ColorConstants.primary.withValues(alpha: 0.25)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset.zero, 36.0, ringPaint);

    // 4. Symmetrical reflection chevrons along all 4 arms
    final Paint chevronPaint = Paint()
      ..color = ColorConstants.primary.withValues(alpha: 0.6)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    for (double d = -500; d <= 500; d += 100) {
      if (d.abs() < 50) continue; // skip center knob area
      // Horizontal arm chevrons
      final Path topH = Path()
        ..moveTo(d - 6, -10)
        ..lineTo(d, -5)
        ..lineTo(d + 6, -10);
      canvas.drawPath(topH, chevronPaint);
      final Path botH = Path()
        ..moveTo(d - 6, 10)
        ..lineTo(d, 5)
        ..lineTo(d + 6, 10);
      canvas.drawPath(botH, chevronPaint);

      // Vertical arm chevrons
      final Path leftV = Path()
        ..moveTo(-10, d - 6)
        ..lineTo(-5, d)
        ..lineTo(-10, d + 6);
      canvas.drawPath(leftV, chevronPaint);
      final Path rightV = Path()
        ..moveTo(10, d - 6)
        ..lineTo(5, d)
        ..lineTo(10, d + 6);
      canvas.drawPath(rightV, chevronPaint);
    }

    canvas.restore();
  }

  // ==========================================
  // HELPER DRAWING METHODS
  // ==========================================
  void _drawDashedLine(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Paint paint, {
    double dashLength = 6.0,
    double gapLength = 4.0,
  }) {
    final double distance = (p2 - p1).distance;
    final Offset dir = (p2 - p1) / distance;
    double current = 0.0;

    while (current < distance) {
      final double end = min(current + dashLength, distance);
      canvas.drawLine(p1 + dir * current, p1 + dir * end, paint);
      current += dashLength + gapLength;
    }
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    double dashLength = 6.0,
    double gapLength = 4.0,
  }) {
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double nextDistance = min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, nextDistance), paint);
        distance = nextDistance + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant RulerPainter oldDelegate) {
    return oldDelegate.config != config || oldDelegate.color != color;
  }
}
