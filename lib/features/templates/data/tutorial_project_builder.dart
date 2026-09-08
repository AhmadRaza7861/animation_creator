import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class TutorialProjectBuilder {
  // Calibrated coordinate space matching mobile canvas dimensions (16:9 aspect ratio)
  static const double canvasW = 360.0;
  static const double canvasH = 202.5;

  static Map<String, dynamic> _buildPaintMap({
    required Color color,
    required double strokeWidth,
    PaintingStyle style = PaintingStyle.stroke,
    StrokeCap strokeCap = StrokeCap.round,
    StrokeJoin strokeJoin = StrokeJoin.round,
  }) {
    return {
      'blendMode': BlendMode.srcOver.index,
      'color': color.toARGB32(),
      'filterQuality': FilterQuality.none.index,
      'invertColors': false,
      'isAntiAlias': true,
      'strokeCap': strokeCap.index,
      'strokeJoin': strokeJoin.index,
      'strokeWidth': strokeWidth,
      'style': style.index,
      'colorFilter': null,
      'imageFilter': null,
      'maskFilter': null,
    };
  }

  static Map<String, dynamic> buildCircleContent({
    required Offset center,
    required double radius,
    required Color color,
    double strokeWidth = 3.5,
    bool isEllipse = false,
    double rx = 0,
    double ry = 0,
    PaintingStyle style = PaintingStyle.stroke,
  }) {
    final double rX = isEllipse ? rx : radius;
    final double rY = isEllipse ? ry : radius;
    return {
      'type': 'Circle',
      'isEllipse': isEllipse,
      'startFromCenter': true,
      'center': {'dx': center.dx, 'dy': center.dy},
      'radius': radius,
      'startPoint': {'dx': center.dx - rX, 'dy': center.dy - rY},
      'endPoint': {'dx': center.dx + rX, 'dy': center.dy + rY},
      'paint': _buildPaintMap(color: color, strokeWidth: strokeWidth, style: style),
    };
  }

  static Map<String, dynamic> buildStraightLineContent({
    required Offset p1,
    required Offset p2,
    required Color color,
    double strokeWidth = 2.5,
  }) {
    return {
      'type': 'StraightLine',
      'startPoint': {'dx': p1.dx, 'dy': p1.dy},
      'endPoint': {'dx': p2.dx, 'dy': p2.dy},
      'paint': _buildPaintMap(color: color, strokeWidth: strokeWidth),
    };
  }

  static Map<String, dynamic> buildSmoothLineContent({
    required List<Offset> points,
    required Color color,
    double strokeWidth = 3.5,
  }) {
    return {
      'type': 'SmoothLine',
      'brushPrecision': 0.4,
      'minPointDistance': 2.0,
      'useBezierCurve': true,
      'smoothLevel': 1,
      'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
      'strokeWidthList': List.filled(points.length, strokeWidth),
      'paint': _buildPaintMap(color: color, strokeWidth: strokeWidth),
    };
  }

  static Map<String, dynamic> buildRectangleContent({
    required Offset p1,
    required Offset p2,
    required Color color,
    double strokeWidth = 2.5,
    PaintingStyle style = PaintingStyle.stroke,
  }) {
    return {
      'type': 'Rectangle',
      'startPoint': {'dx': p1.dx, 'dy': p1.dy},
      'endPoint': {'dx': p2.dx, 'dy': p2.dy},
      'paint': _buildPaintMap(color: color, strokeWidth: strokeWidth, style: style),
    };
  }

  static Map<String, dynamic> _wrapCanvas({
    required List<Map<String, dynamic>> guideHistory,
    required List<Map<String, dynamic>> animHistory,
  }) {
    // Combine all strokes into a single standard layer so that the Eraser tool
    // and all editing tools can erase/modify every stroke on the canvas.
    final List<Map<String, dynamic>> combinedHistory = [
      ...guideHistory,
      ...animHistory,
    ];

    return {
      'size': {'width': canvasW, 'height': canvasH},
      'backgroundColor': Colors.white.toARGB32(),
      'layers': [
        {
          'id': 'layer_0',
          'name': 'Background',
          'isVisible': true,
          'isLocked': false,
          'opacity': 1.0,
          'blendMode': BlendMode.srcOver.index,
          'currentIndex': combinedHistory.length,
          'history': combinedHistory,
        }
      ],
      'activeLayerId': 'layer_0',
    };
  }

  static Map<String, dynamic> _wrapProjectState({
    required String title,
    required int fps,
    required List<Map<String, dynamic>> canvases,
  }) {
    return {
      'globalBackground': {
        'color': Colors.white.toARGB32(),
        'imagePath': null,
        'imageOpacity': 1.0,
        'pattern': null,
      },
      'aspectRatio': 16.0 / 9.0,
      'fps': fps,
      'projectName': title,
      'strokeWidth': 4.0,
      'strokeColor': const Color(0xFFEF4444).toARGB32(),
      'colorOpacity': 1.0,
      'exportType': 'Mp4',
      'enableStickers': true,
      'canvases': canvases,
    };
  }

  // =========================================================================
  // 1. BOUNCING BALL (12 frames)
  // =========================================================================
  static Map<String, dynamic> buildBouncingBallProject() {
    const int frameCount = 12;
    const double floorY = 170.0;
    const double apexY = 35.0;
    const double ballX = 180.0;
    const double radius = 16.0;

    final List<Map<String, dynamic>> canvases = [];

    final List<double> heights = [
      apexY,
      apexY + 14,
      apexY + 38,
      apexY + 74,
      apexY + 118,
      floorY - radius,
      floorY, // 6: squash
      floorY - radius - 20, // 7: stretch
      apexY + 95,
      apexY + 50,
      apexY + 18,
      apexY + 4,
    ];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildStraightLineContent(
        p1: const Offset(40, floorY),
        p2: const Offset(320, floorY),
        color: const Color(0xFF94A3B8),
        strokeWidth: 2.5,
      ));

      guide.add(buildStraightLineContent(
        p1: const Offset(ballX, apexY - 10),
        p2: const Offset(ballX, floorY),
        color: const Color(0xFF38BDF8),
        strokeWidth: 1.8,
      ));

      for (int t = 0; t <= 5; t++) {
        final double ty = heights[t];
        guide.add(buildStraightLineContent(
          p1: Offset(ballX + 26, ty),
          p2: Offset(ballX + 34, ty),
          color: const Color(0xFF0284C7),
          strokeWidth: 1.5,
        ));
      }

      if (i == 6) {
        anim.add(buildCircleContent(
          center: Offset(ballX, floorY - 8),
          radius: radius,
          isEllipse: true,
          rx: 24,
          ry: 8,
          color: const Color(0xFFEF4444),
          strokeWidth: 4.0,
        ));
      } else if (i == 5 || i == 7) {
        final cy = heights[i];
        anim.add(buildCircleContent(
          center: Offset(ballX, cy),
          radius: radius,
          isEllipse: true,
          rx: 11,
          ry: 23,
          color: const Color(0xFFEF4444),
          strokeWidth: 4.0,
        ));
      } else {
        final cy = heights[i];
        anim.add(buildCircleContent(
          center: Offset(ballX, cy),
          radius: radius,
          color: const Color(0xFFEF4444),
          strokeWidth: 4.0,
        ));
      }

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Bouncing Ball', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 2. PENDULUM SWING (16 frames)
  // =========================================================================
  static Map<String, dynamic> buildPendulumSwingProject() {
    const int frameCount = 16;
    const Offset pivot = Offset(180, 25);
    const double length = 115.0;
    const double maxAngle = 0.62;

    final List<Map<String, dynamic>> canvases = [];

    final List<Offset> arcPoints = [];
    for (double a = -maxAngle; a <= maxAngle + 0.02; a += 0.05) {
      arcPoints.add(Offset(
        pivot.dx + length * math.sin(a),
        pivot.dy + length * math.cos(a),
      ));
    }

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildCircleContent(
        center: pivot,
        radius: 4,
        color: const Color(0xFF64748B),
        strokeWidth: 2,
        style: PaintingStyle.fill,
      ));
      guide.add(buildSmoothLineContent(
        points: arcPoints,
        color: const Color(0xFF38BDF8),
        strokeWidth: 1.8,
      ));

      for (int k = 0; k < frameCount; k++) {
        final double tickAngle = maxAngle * math.sin(2 * math.pi * k / frameCount);
        final bx = pivot.dx + length * math.sin(tickAngle);
        final by = pivot.dy + length * math.cos(tickAngle);
        guide.add(buildStraightLineContent(
          p1: Offset(bx, by - 4),
          p2: Offset(bx, by + 4),
          color: const Color(0xFF0284C7),
          strokeWidth: 1.5,
        ));
      }

      final double angle = maxAngle * math.sin(2 * math.pi * i / frameCount);
      final Offset bobCenter = Offset(
        pivot.dx + length * math.sin(angle),
        pivot.dy + length * math.cos(angle),
      );

      anim.add(buildStraightLineContent(
        p1: pivot,
        p2: bobCenter,
        color: const Color(0xFF1E293B),
        strokeWidth: 3.0,
      ));
      anim.add(buildCircleContent(
        center: bobCenter,
        radius: 14,
        color: const Color(0xFFEF4444),
        strokeWidth: 4.0,
      ));

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Pendulum Swing', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 3. SHAPE MORPHING (16 frames)
  // =========================================================================
  static Map<String, dynamic> buildShapeMorphingProject() {
    const int frameCount = 16;
    const Offset center = Offset(180, 101.25);
    const double size = 48.0;

    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildRectangleContent(
        p1: Offset(center.dx - size, center.dy - size),
        p2: Offset(center.dx + size, center.dy + size),
        color: const Color(0xFFCBD5E1),
        strokeWidth: 1.5,
      ));
      guide.add(buildCircleContent(
        center: center,
        radius: size,
        color: const Color(0xFF38BDF8),
        strokeWidth: 1.5,
      ));

      final double t = (1 - math.cos(2 * math.pi * i / frameCount)) / 2;
      final List<Offset> polyPoints = [];
      const int steps = 40;
      for (int s = 0; s <= steps; s++) {
        final double theta = s * (2 * math.pi / steps);
        final double cx = size * math.cos(theta);
        final double cy = size * math.sin(theta);
        final double maxCoord = math.max(cx.abs(), cy.abs());
        final double scale = maxCoord > 0 ? size / maxCoord : 1.0;
        final double sx = cx * scale;
        final double sy = cy * scale;

        final double px = center.dx + cx * (1 - t) + sx * t;
        final double py = center.dy + cy * (1 - t) + sy * t;
        polyPoints.add(Offset(px, py));
      }

      anim.add(buildSmoothLineContent(
        points: polyPoints,
        color: const Color(0xFF8B5CF6),
        strokeWidth: 4.0,
      ));

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Shape Morphing', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 4. SPINNING STAR (16 frames)
  // =========================================================================
  static Map<String, dynamic> buildSpinningStarProject() {
    const int frameCount = 16;
    const Offset center = Offset(180, 101.25);
    const double rOuter = 55.0;
    const double rInner = 26.0;

    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildCircleContent(
        center: center,
        radius: rOuter,
        color: const Color(0xFF38BDF8),
        strokeWidth: 1.5,
      ));
      guide.add(buildStraightLineContent(
        p1: Offset(center.dx, center.dy - rOuter - 10),
        p2: Offset(center.dx, center.dy + rOuter + 10),
        color: const Color(0xFF94A3B8),
        strokeWidth: 1.2,
      ));
      guide.add(buildStraightLineContent(
        p1: Offset(center.dx - rOuter - 10, center.dy),
        p2: Offset(center.dx + rOuter + 10, center.dy),
        color: const Color(0xFF94A3B8),
        strokeWidth: 1.2,
      ));

      final double rot = (i * 2 * math.pi / frameCount) - math.pi / 2;
      final List<Offset> starPoints = [];
      for (int k = 0; k <= 10; k++) {
        final double angle = rot + k * (math.pi / 5);
        final double r = (k % 2 == 0) ? rOuter : rInner;
        starPoints.add(Offset(
          center.dx + r * math.cos(angle),
          center.dy + r * math.sin(angle),
        ));
      }

      anim.add(buildSmoothLineContent(
        points: starPoints,
        color: const Color(0xFFF59E0B),
        strokeWidth: 3.5,
      ));

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Spinning Star', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 5. WAVE MOTION (16 frames)
  // =========================================================================
  static Map<String, dynamic> buildWaveMotionProject() {
    const int frameCount = 16;
    const double baselineY = 101.25;
    const double amplitude = 32.0;
    const double wavelength = 140.0;
    const double startX = 40.0;
    const double endX = 320.0;

    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildStraightLineContent(
        p1: const Offset(startX, baselineY),
        p2: const Offset(endX, baselineY),
        color: const Color(0xFF94A3B8),
        strokeWidth: 1.8,
      ));
      guide.add(buildStraightLineContent(
        p1: const Offset(startX, baselineY - amplitude),
        p2: const Offset(endX, baselineY - amplitude),
        color: const Color(0xFF38BDF8),
        strokeWidth: 1.2,
      ));
      guide.add(buildStraightLineContent(
        p1: const Offset(startX, baselineY + amplitude),
        p2: const Offset(endX, baselineY + amplitude),
        color: const Color(0xFF38BDF8),
        strokeWidth: 1.2,
      ));

      final double phase = i * (2 * math.pi / frameCount);
      final List<Offset> wavePoints = [];
      for (double x = startX; x <= endX; x += 6) {
        final double y = baselineY + amplitude * math.sin((2 * math.pi * (x - startX) / wavelength) - phase);
        wavePoints.add(Offset(x, y));
      }

      anim.add(buildSmoothLineContent(
        points: wavePoints,
        color: const Color(0xFF06B6D4),
        strokeWidth: 4.0,
      ));

      // Floating wave crest buoy
      final double buoyX = 180.0;
      final double buoyY = baselineY + amplitude * math.sin((2 * math.pi * (buoyX - startX) / wavelength) - phase);
      anim.add(buildCircleContent(
        center: Offset(buoyX, buoyY),
        radius: 9,
        color: const Color(0xFFF97316),
        strokeWidth: 3.0,
      ));

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Wave Motion', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 6. SLOW IN & SLOW OUT (16 frames)
  // =========================================================================
  static Map<String, dynamic> buildSlowInSlowOutProject() {
    const int frameCount = 16;
    const double trackY = 101.25;
    const double startX = 60.0;
    const double endX = 300.0;

    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildStraightLineContent(
        p1: const Offset(startX - 10, trackY),
        p2: const Offset(endX + 10, trackY),
        color: const Color(0xFF94A3B8),
        strokeWidth: 2.2,
      ));

      for (int k = 0; k < frameCount; k++) {
        final double tNorm = k / (frameCount - 1);
        final double eased = 0.5 - 0.5 * math.cos(math.pi * tNorm);
        final double tx = startX + (endX - startX) * eased;
        guide.add(buildStraightLineContent(
          p1: Offset(tx, trackY - 6),
          p2: Offset(tx, trackY + 6),
          color: const Color(0xFF38BDF8),
          strokeWidth: 1.5,
        ));
      }

      final double progress = i / (frameCount - 1);
      final double easedT = 0.5 - 0.5 * math.cos(math.pi * progress);
      final double objX = startX + (endX - startX) * easedT;

      anim.add(buildCircleContent(
        center: Offset(objX, trackY),
        radius: 15,
        color: const Color(0xFF10B981),
        strokeWidth: 4.0,
      ));
      anim.add(buildCircleContent(
        center: Offset(objX, trackY),
        radius: 5,
        color: const Color(0xFF10B981),
        strokeWidth: 2.0,
        style: PaintingStyle.fill,
      ));

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Slow In & Slow Out', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 7. ARCS: THROWN BALL (20 frames)
  // =========================================================================
  static Map<String, dynamic> buildArcsThrownBallProject() {
    const int frameCount = 20;
    const double floorY = 165.0;
    const double startX = 50.0;
    const double endX = 310.0;

    final List<Map<String, dynamic>> canvases = [];

    final List<Offset> trajPoints = [];
    for (int k = 0; k < 16; k++) {
      final double px = startX + (endX - startX) * 0.8 * (k / 15);
      final double py = floorY - 110.0 * math.sin(math.pi * (k / 15));
      trajPoints.add(Offset(px, py));
    }

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildStraightLineContent(
        p1: const Offset(30, floorY),
        p2: const Offset(330, floorY),
        color: const Color(0xFF94A3B8),
        strokeWidth: 2.5,
      ));
      guide.add(buildSmoothLineContent(
        points: trajPoints,
        color: const Color(0xFF38BDF8),
        strokeWidth: 1.8,
      ));

      double bx, by;
      if (i < 16) {
        bx = startX + (endX - startX) * 0.8 * (i / 15);
        by = floorY - 110.0 * math.sin(math.pi * (i / 15));
      } else {
        final double bProgress = (i - 16) / 3.0;
        bx = startX + (endX - startX) * (0.8 + 0.2 * bProgress);
        by = floorY - 24.0 * math.sin(math.pi * bProgress);
      }

      anim.add(buildCircleContent(
        center: Offset(bx, by),
        radius: 13,
        color: const Color(0xFFEC4899),
        strokeWidth: 3.5,
      ));

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Arcs: Thrown Ball', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 8. FLAME FLICKER (16 frames)
  // =========================================================================
  static Map<String, dynamic> buildFireFlickerProject() {
    const int frameCount = 16;

    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      // Candle / Log Base guide
      guide.add(buildRectangleContent(
        p1: const Offset(155, 160),
        p2: const Offset(205, 175),
        color: const Color(0xFF94A3B8),
        strokeWidth: 2.0,
      ));
      guide.add(buildStraightLineContent(
        p1: const Offset(180, 160),
        p2: const Offset(180, 145),
        color: const Color(0xFF64748B),
        strokeWidth: 2.5,
      ));

      final double flicker = math.sin(i * 2 * math.pi / frameCount);
      final double tipWobble = 14 * math.sin(i * 4 * math.pi / frameCount);
      final double heightOffset = 10 * math.cos(i * 2 * math.pi / frameCount);

      // Outer Red Flame
      final List<Offset> outerFlame = [
        const Offset(168, 145),
        Offset(150 + flicker * 4, 110),
        Offset(180 + tipWobble, 55 + heightOffset),
        Offset(210 - flicker * 4, 110),
        const Offset(192, 145),
      ];
      anim.add(buildSmoothLineContent(
        points: outerFlame,
        color: const Color(0xFFEF4444),
        strokeWidth: 3.8,
      ));

      // Inner Yellow Flame Core
      final List<Offset> innerFlame = [
        const Offset(174, 145),
        Offset(162 + flicker * 2, 120),
        Offset(180 + tipWobble * 0.6, 85 + heightOffset * 0.7),
        Offset(198 - flicker * 2, 120),
        const Offset(186, 145),
      ];
      anim.add(buildSmoothLineContent(
        points: innerFlame,
        color: const Color(0xFFFBBF24),
        strokeWidth: 3.0,
      ));

      // Rising Spark Particle
      final double sparkProgress = (i % 8) / 8.0;
      final double sparkY = (55 + heightOffset) - sparkProgress * 40;
      final double sparkX = 180 + tipWobble * 0.8 + 6 * math.sin(sparkProgress * 3 * math.pi);
      anim.add(buildCircleContent(
        center: Offset(sparkX, sparkY),
        radius: 3,
        color: const Color(0xFFF59E0B),
        strokeWidth: 2.0,
        style: PaintingStyle.fill,
      ));

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Flame Flicker', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 9. SQUASH & STRETCH (16 frames)
  // =========================================================================
  static Map<String, dynamic> buildSquashAndStretchProject() {
    const int frameCount = 16;
    const double floorY = 168.0;
    const double apexY = 40.0;
    const double cx = 180.0;

    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildStraightLineContent(
        p1: const Offset(50, floorY),
        p2: const Offset(310, floorY),
        color: const Color(0xFF94A3B8),
        strokeWidth: 2.5,
      ));
      guide.add(buildStraightLineContent(
        p1: const Offset(100, apexY),
        p2: const Offset(260, apexY),
        color: const Color(0xFF38BDF8),
        strokeWidth: 1.5,
      ));

      if (i == 8) {
        anim.add(buildCircleContent(
          center: const Offset(cx, floorY - 7),
          radius: 18,
          isEllipse: true,
          rx: 30,
          ry: 7,
          color: const Color(0xFF8B5CF6),
          strokeWidth: 4.0,
        ));
      } else if (i == 7 || i == 9) {
        final cy = (i == 7) ? floorY - 35 : floorY - 45;
        anim.add(buildCircleContent(
          center: Offset(cx, cy),
          radius: 18,
          isEllipse: true,
          rx: 10,
          ry: 26,
          color: const Color(0xFF8B5CF6),
          strokeWidth: 4.0,
        ));
      } else {
        final double t = (i < 8) ? i / 7.0 : (15 - i) / 6.0;
        final double cy = apexY + (floorY - 20 - apexY) * (t * t);
        anim.add(buildCircleContent(
          center: Offset(cx, cy),
          radius: 18,
          color: const Color(0xFF8B5CF6),
          strokeWidth: 4.0,
        ));
      }

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Squash & Stretch', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 10. ANTICIPATION (16 frames)
  // =========================================================================
  static Map<String, dynamic> buildAnticipationProject() {
    const int frameCount = 16;
    const double floorY = 165.0;
    const double cx = 180.0;

    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildStraightLineContent(
        p1: const Offset(40, floorY),
        p2: const Offset(320, floorY),
        color: const Color(0xFF94A3B8),
        strokeWidth: 2.2,
      ));

      // Guide upward anticipation arrow
      guide.add(buildStraightLineContent(
        p1: const Offset(cx + 45, 130),
        p2: const Offset(cx + 45, 60),
        color: const Color(0xFF38BDF8),
        strokeWidth: 1.5,
      ));

      double headY, bodyH, crouchX;
      Color stickColor = const Color(0xFF1E293B);

      if (i <= 3) {
        headY = 85;
        bodyH = 45;
        crouchX = 0;
      } else if (i <= 7) {
        final double t = (i - 3) / 4.0;
        headY = 85 + 40 * t;
        bodyH = 45 - 20 * t;
        crouchX = 8 * math.sin(t * math.pi);
        stickColor = const Color(0xFFEF4444);
      } else if (i <= 12) {
        final double t = (i - 7) / 5.0;
        headY = 125 - 90 * math.sin(t * math.pi);
        bodyH = 50;
        crouchX = 0;
        stickColor = const Color(0xFF10B981);
      } else {
        final double t = (i - 12) / 3.0;
        headY = 125 - 40 * (1 - t);
        bodyH = 45;
        crouchX = 0;
      }

      anim.add(buildCircleContent(
        center: Offset(cx + crouchX, headY),
        radius: 12,
        color: stickColor,
        strokeWidth: 3.5,
      ));
      anim.add(buildStraightLineContent(
        p1: Offset(cx + crouchX, headY + 12),
        p2: Offset(cx, headY + 12 + bodyH),
        color: stickColor,
        strokeWidth: 3.5,
      ));
      anim.add(buildStraightLineContent(
        p1: Offset(cx, headY + 12 + bodyH),
        p2: Offset(cx - 18, (headY + 12 + bodyH + 30).clamp(headY + 20, floorY)),
        color: stickColor,
        strokeWidth: 3.5,
      ));
      anim.add(buildStraightLineContent(
        p1: Offset(cx, headY + 12 + bodyH),
        p2: Offset(cx + 18, (headY + 12 + bodyH + 30).clamp(headY + 20, floorY)),
        color: stickColor,
        strokeWidth: 3.5,
      ));

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Anticipation', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 11. STAGING & FRAMING (16 frames)
  // =========================================================================
  static Map<String, dynamic> buildStagingProject() {
    const int frameCount = 16;
    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildStraightLineContent(
        p1: const Offset(120, 20),
        p2: const Offset(120, 182),
        color: const Color(0xFFCBD5E1),
        strokeWidth: 1.2,
      ));
      guide.add(buildStraightLineContent(
        p1: const Offset(240, 20),
        p2: const Offset(240, 182),
        color: const Color(0xFFCBD5E1),
        strokeWidth: 1.2,
      ));
      guide.add(buildStraightLineContent(
        p1: const Offset(20, 67),
        p2: const Offset(340, 67),
        color: const Color(0xFFCBD5E1),
        strokeWidth: 1.2,
      ));
      guide.add(buildStraightLineContent(
        p1: const Offset(20, 135),
        p2: const Offset(340, 135),
        color: const Color(0xFFCBD5E1),
        strokeWidth: 1.2,
      ));

      guide.add(buildStraightLineContent(
        p1: const Offset(40, 15),
        p2: const Offset(100, 180),
        color: const Color(0xFFFDE047),
        strokeWidth: 1.5,
      ));
      guide.add(buildStraightLineContent(
        p1: const Offset(40, 15),
        p2: const Offset(220, 180),
        color: const Color(0xFFFDE047),
        strokeWidth: 1.5,
      ));

      const Offset subjectPos = Offset(150, 115);
      final double pulse = 1.0 + 0.15 * math.sin(i * 2 * math.pi / frameCount);

      anim.add(buildCircleContent(
        center: subjectPos,
        radius: 28 * pulse,
        color: const Color(0xFFF59E0B),
        strokeWidth: 2.2,
      ));

      anim.add(buildCircleContent(
        center: const Offset(150, 95),
        radius: 12,
        color: const Color(0xFF1E1B39),
        strokeWidth: 3.5,
        style: PaintingStyle.fill,
      ));
      anim.add(buildRectangleContent(
        p1: const Offset(138, 107),
        p2: const Offset(162, 155),
        color: const Color(0xFF1E1B39),
        strokeWidth: 3.0,
        style: PaintingStyle.fill,
      ));

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Staging & Framing', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 12. STRAIGHT AHEAD FLOW (16 frames)
  // =========================================================================
  static Map<String, dynamic> buildStraightAheadFlowProject() {
    const int frameCount = 16;
    const double surfaceY = 150.0;
    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildStraightLineContent(
        p1: const Offset(40, surfaceY),
        p2: const Offset(320, surfaceY),
        color: const Color(0xFF94A3B8),
        strokeWidth: 2.0,
      ));

      if (i < 5) {
        final double dy = 30 + (surfaceY - 30) * (i / 4.0);
        anim.add(buildCircleContent(
          center: Offset(180, dy),
          radius: 9,
          isEllipse: true,
          rx: 7,
          ry: 13,
          color: const Color(0xFF0284C7),
          strokeWidth: 3.5,
        ));
      } else if (i < 10) {
        final double splashH = 35 * math.sin((i - 5) * math.pi / 5.0);
        final List<Offset> splashPoints = [
          const Offset(140, surfaceY),
          Offset(155, surfaceY - splashH),
          Offset(170, surfaceY - splashH * 0.4),
          Offset(180, surfaceY - splashH * 1.1),
          Offset(190, surfaceY - splashH * 0.4),
          Offset(205, surfaceY - splashH),
          const Offset(220, surfaceY),
        ];
        anim.add(buildSmoothLineContent(
          points: splashPoints,
          color: const Color(0xFF0284C7),
          strokeWidth: 3.5,
        ));
      } else {
        final double rippleR = 20 + 35 * ((i - 10) / 5.0);
        anim.add(buildCircleContent(
          center: const Offset(180, surfaceY),
          radius: rippleR,
          isEllipse: true,
          rx: rippleR,
          ry: rippleR * 0.3,
          color: const Color(0xFF38BDF8),
          strokeWidth: 2.5,
        ));

        final double beadY = surfaceY - 45 * (1 - (i - 10) / 5.0);
        anim.add(buildCircleContent(
          center: Offset(180, beadY),
          radius: 4,
          color: const Color(0xFF0284C7),
          strokeWidth: 2.5,
          style: PaintingStyle.fill,
        ));
      }

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Straight Ahead Flow', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 13. FOLLOW THROUGH TAIL (16 frames)
  // =========================================================================
  static Map<String, dynamic> buildFollowThroughTailProject() {
    const int frameCount = 16;
    const double baselineY = 100.0;
    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildStraightLineContent(
        p1: const Offset(70, baselineY),
        p2: const Offset(290, baselineY),
        color: const Color(0xFF94A3B8),
        strokeWidth: 1.5,
      ));

      final double t = i * 2 * math.pi / frameCount;
      final double bodyX = 180 + 55 * math.sin(t);
      final double bodyY = baselineY;

      anim.add(buildCircleContent(
        center: Offset(bodyX, bodyY),
        radius: 16,
        color: const Color(0xFFF97316),
        strokeWidth: 4.0,
      ));

      final List<Offset> tailPoints = [Offset(bodyX - 14, bodyY)];
      for (int joint = 1; joint <= 5; joint++) {
        final double lagPhase = t - joint * 0.45;
        final double jx = bodyX - 14 - joint * 18;
        final double jy = bodyY + 22 * math.sin(lagPhase);
        tailPoints.add(Offset(jx, jy));
      }

      anim.add(buildSmoothLineContent(
        points: tailPoints,
        color: const Color(0xFFF97316),
        strokeWidth: 3.5,
      ));

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Follow Through Tail', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 14. SECONDARY ACTION (16 frames)
  // =========================================================================
  static Map<String, dynamic> buildSecondaryActionProject() {
    const int frameCount = 16;
    const double cx = 180.0;
    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildStraightLineContent(
        p1: const Offset(cx, 40),
        p2: const Offset(cx, 165),
        color: const Color(0xFF94A3B8),
        strokeWidth: 1.5,
      ));

      final double t = i * 2 * math.pi / frameCount;
      final double bodyY = 100 + 40 * math.sin(t);

      anim.add(buildCircleContent(
        center: Offset(cx, bodyY),
        radius: 20,
        color: const Color(0xFF6366F1),
        strokeWidth: 4.0,
      ));
      anim.add(buildCircleContent(
        center: Offset(cx - 6, bodyY - 3),
        radius: 3,
        color: const Color(0xFF1E1B39),
        strokeWidth: 2.0,
        style: PaintingStyle.fill,
      ));
      anim.add(buildCircleContent(
        center: Offset(cx + 6, bodyY - 3),
        radius: 3,
        color: const Color(0xFF1E1B39),
        strokeWidth: 2.0,
        style: PaintingStyle.fill,
      ));

      final double featherLag = math.cos(t);
      final List<Offset> featherPoints = [
        Offset(cx, bodyY - 20),
        Offset(cx + 15 * featherLag, bodyY - 38),
        Offset(cx + 30 * featherLag, bodyY - 48),
      ];

      anim.add(buildSmoothLineContent(
        points: featherPoints,
        color: const Color(0xFFEF4444),
        strokeWidth: 3.5,
      ));

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Secondary Action', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 15. TIMING & WEIGHT (16 frames)
  // =========================================================================
  static Map<String, dynamic> buildTimingAndWeightProject() {
    const int frameCount = 16;
    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildStraightLineContent(
        p1: const Offset(180, 20),
        p2: const Offset(180, 180),
        color: const Color(0xFFCBD5E1),
        strokeWidth: 1.5,
      ));
      guide.add(buildStraightLineContent(
        p1: const Offset(30, 165),
        p2: const Offset(160, 165),
        color: const Color(0xFF94A3B8),
        strokeWidth: 2.0,
      ));
      guide.add(buildStraightLineContent(
        p1: const Offset(200, 165),
        p2: const Offset(330, 165),
        color: const Color(0xFF94A3B8),
        strokeWidth: 2.0,
      ));

      double anvilY = 35.0;
      if (i >= 3) {
        anvilY = 150.0;
      } else {
        anvilY = 35.0 + (150.0 - 35.0) * (i / 3.0);
      }
      anim.add(buildRectangleContent(
        p1: Offset(75, anvilY - 14),
        p2: Offset(115, anvilY + 14),
        color: const Color(0xFF334155),
        strokeWidth: 3.5,
        style: PaintingStyle.fill,
      ));

      final double balloonProgress = i / (frameCount - 1);
      final double balloonY = 35 + (150 - 35) * balloonProgress;
      final double balloonX = 265 + 24 * math.sin(balloonProgress * 3 * math.pi);
      anim.add(buildCircleContent(
        center: Offset(balloonX, balloonY),
        radius: 14,
        color: const Color(0xFFF43F5E),
        strokeWidth: 3.5,
      ));

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Timing & Weight', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 16. EXAGGERATION (16 frames)
  // =========================================================================
  static Map<String, dynamic> buildExaggerationProject() {
    const int frameCount = 16;
    const Offset center = Offset(180, 105);
    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildCircleContent(
        center: center,
        radius: 35,
        color: const Color(0xFFCBD5E1),
        strokeWidth: 1.5,
      ));

      if (i >= 5 && i <= 11) {
        final double popProgress = math.sin((i - 5) * math.pi / 6.0);

        anim.add(buildCircleContent(
          center: center,
          radius: 35 + 10 * popProgress,
          color: const Color(0xFFEF4444),
          strokeWidth: 4.0,
        ));

        final double eyeOffset = 30 * popProgress;
        anim.add(buildStraightLineContent(
          p1: Offset(center.dx - 12, center.dy - 10),
          p2: Offset(center.dx - 12 - eyeOffset * 0.5, center.dy - 10 - eyeOffset),
          color: const Color(0xFF1E1B39),
          strokeWidth: 2.5,
        ));
        anim.add(buildCircleContent(
          center: Offset(center.dx - 12 - eyeOffset * 0.5, center.dy - 10 - eyeOffset),
          radius: 12 + 6 * popProgress,
          color: const Color(0xFFEF4444),
          strokeWidth: 3.5,
        ));

        anim.add(buildStraightLineContent(
          p1: Offset(center.dx + 12, center.dy - 10),
          p2: Offset(center.dx + 12 + eyeOffset * 0.5, center.dy - 10 - eyeOffset),
          color: const Color(0xFF1E1B39),
          strokeWidth: 2.5,
        ));
        anim.add(buildCircleContent(
          center: Offset(center.dx + 12 + eyeOffset * 0.5, center.dy - 10 - eyeOffset),
          radius: 12 + 6 * popProgress,
          color: const Color(0xFFEF4444),
          strokeWidth: 3.5,
        ));

        anim.add(buildRectangleContent(
          p1: Offset(center.dx - 15, center.dy + 8),
          p2: Offset(center.dx + 15, center.dy + 25 + 30 * popProgress),
          color: const Color(0xFF1E1B39),
          strokeWidth: 3.5,
        ));
      } else {
        anim.add(buildCircleContent(
          center: center,
          radius: 35,
          color: const Color(0xFF10B981),
          strokeWidth: 4.0,
        ));
        anim.add(buildCircleContent(
          center: Offset(center.dx - 12, center.dy - 8),
          radius: 5,
          color: const Color(0xFF1E1B39),
          strokeWidth: 2.0,
          style: PaintingStyle.fill,
        ));
        anim.add(buildCircleContent(
          center: Offset(center.dx + 12, center.dy - 8),
          radius: 5,
          color: const Color(0xFF1E1B39),
          strokeWidth: 2.0,
          style: PaintingStyle.fill,
        ));
        anim.add(buildSmoothLineContent(
          points: [
            Offset(center.dx - 10, center.dy + 12),
            Offset(center.dx, center.dy + 18),
            Offset(center.dx + 10, center.dy + 12),
          ],
          color: const Color(0xFF1E1B39),
          strokeWidth: 3.0,
        ));
      }

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Exaggeration', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 17. SOLID DRAWING (16 frames)
  // =========================================================================
  static Map<String, dynamic> buildSolidDrawingProject() {
    const int frameCount = 16;
    const Offset center = Offset(180, 101.25);
    const double cubeSize = 36.0;

    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildStraightLineContent(
        p1: const Offset(20, 101.25),
        p2: const Offset(340, 101.25),
        color: const Color(0xFFCBD5E1),
        strokeWidth: 1.2,
      ));

      final double angle = i * 2 * math.pi / frameCount;
      final double cosA = math.cos(angle);
      final double sinA = math.sin(angle);

      final List<Offset> v = [];
      for (int dx in [-1, 1]) {
        for (int dy in [-1, 1]) {
          for (int dz in [-1, 1]) {
            final double x3d = dx * cubeSize;
            final double y3d = dy * cubeSize;
            final double z3d = dz * cubeSize;

            final double rx = x3d * cosA - z3d * sinA;
            final double rz = x3d * sinA + z3d * cosA + 150.0;
            final double pers = 150.0 / rz;

            v.add(Offset(center.dx + rx * pers, center.dy + y3d * pers));
          }
        }
      }

      final List<List<int>> edges = [
        [0, 1], [2, 3], [4, 5], [6, 7],
        [0, 2], [1, 3], [4, 6], [5, 7],
        [0, 4], [1, 5], [2, 6], [3, 7]
      ];

      for (final e in edges) {
        anim.add(buildStraightLineContent(
          p1: v[e[0]],
          p2: v[e[1]],
          color: const Color(0xFF4F46E5),
          strokeWidth: 3.0,
        ));
      }

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Solid Drawing', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 18. CHARACTER APPEAL (16 frames)
  // =========================================================================
  static Map<String, dynamic> buildCharacterAppealProject() {
    const int frameCount = 16;
    const Offset center = Offset(180, 105);
    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildStraightLineContent(
        p1: Offset(center.dx, 35),
        p2: Offset(center.dx, 175),
        color: const Color(0xFFCBD5E1),
        strokeWidth: 1.2,
      ));

      anim.add(buildCircleContent(
        center: center,
        radius: 42,
        color: const Color(0xFFEC4899),
        strokeWidth: 4.0,
      ));

      anim.add(buildSmoothLineContent(
        points: [
          Offset(center.dx - 35, center.dy - 20),
          Offset(center.dx - 45, center.dy - 55),
          Offset(center.dx - 15, center.dy - 38),
        ],
        color: const Color(0xFFEC4899),
        strokeWidth: 3.5,
      ));
      anim.add(buildSmoothLineContent(
        points: [
          Offset(center.dx + 35, center.dy - 20),
          Offset(center.dx + 45, center.dy - 55),
          Offset(center.dx + 15, center.dy - 38),
        ],
        color: const Color(0xFFEC4899),
        strokeWidth: 3.5,
      ));

      final bool isWinking = (i >= 6 && i <= 10);
      anim.add(buildCircleContent(
        center: Offset(center.dx - 16, center.dy - 6),
        radius: 8,
        color: const Color(0xFF1E1B39),
        strokeWidth: 2.5,
        style: PaintingStyle.fill,
      ));
      anim.add(buildCircleContent(
        center: Offset(center.dx - 18, center.dy - 9),
        radius: 2.5,
        color: Colors.white,
        strokeWidth: 1.5,
        style: PaintingStyle.fill,
      ));

      if (isWinking) {
        anim.add(buildSmoothLineContent(
          points: [
            Offset(center.dx + 8, center.dy - 4),
            Offset(center.dx + 16, center.dy - 8),
            Offset(center.dx + 24, center.dy - 4),
          ],
          color: const Color(0xFF1E1B39),
          strokeWidth: 3.5,
        ));
      } else {
        anim.add(buildCircleContent(
          center: Offset(center.dx + 16, center.dy - 6),
          radius: 8,
          color: const Color(0xFF1E1B39),
          strokeWidth: 2.5,
          style: PaintingStyle.fill,
        ));
      }

      anim.add(buildCircleContent(
        center: Offset(center.dx - 26, center.dy + 12),
        radius: 6,
        color: const Color(0xFFFDA4AF),
        strokeWidth: 2.0,
        style: PaintingStyle.fill,
      ));
      anim.add(buildCircleContent(
        center: Offset(center.dx + 26, center.dy + 12),
        radius: 6,
        color: const Color(0xFFFDA4AF),
        strokeWidth: 2.0,
        style: PaintingStyle.fill,
      ));

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Character Appeal', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 19. KEYS & INBETWEENS (16 frames)
  // =========================================================================
  static Map<String, dynamic> buildKeysAndInbetweensProject() {
    const int frameCount = 16;
    const double floorY = 160.0;
    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildStraightLineContent(
        p1: const Offset(40, 30),
        p2: const Offset(320, 30),
        color: const Color(0xFF94A3B8),
        strokeWidth: 1.8,
      ));
      guide.add(buildCircleContent(
        center: const Offset(60, 30),
        radius: 6,
        color: const Color(0xFFF59E0B),
        strokeWidth: 2.5,
        style: PaintingStyle.fill,
      ));
      guide.add(buildCircleContent(
        center: const Offset(300, 30),
        radius: 6,
        color: const Color(0xFFF59E0B),
        strokeWidth: 2.5,
        style: PaintingStyle.fill,
      ));

      guide.add(buildStraightLineContent(
        p1: const Offset(40, floorY),
        p2: const Offset(320, floorY),
        color: const Color(0xFF94A3B8),
        strokeWidth: 2.0,
      ));

      final double progress = i / (frameCount - 1);
      final double cx = 60 + (300 - 60) * progress;
      final double cy = floorY - 20 - 70 * math.sin(progress * math.pi);

      Color frameColor = const Color(0xFF06B6D4);
      if (i == 0 || i == frameCount - 1) {
        frameColor = const Color(0xFFF59E0B);
      } else if (i == 8) {
        frameColor = const Color(0xFF8B5CF6);
      }

      anim.add(buildCircleContent(
        center: Offset(cx, cy),
        radius: 16,
        color: frameColor,
        strokeWidth: 4.0,
      ));

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Keys & Inbetweens', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 20. THE KINETIC WHIP (16 frames)
  // =========================================================================
  static Map<String, dynamic> buildArmWhipProject() {
    const int frameCount = 16;
    const Offset shoulder = Offset(80, 110);
    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildCircleContent(
        center: shoulder,
        radius: 6,
        color: const Color(0xFF64748B),
        strokeWidth: 2.0,
        style: PaintingStyle.fill,
      ));

      final double t = i * 2 * math.pi / frameCount;
      final double elbowAngle = 0.4 * math.sin(t);
      final double wristAngle = 0.9 * math.sin(t - 0.6);
      final double tipAngle = 1.6 * math.sin(t - 1.2);

      final Offset elbow = Offset(
        shoulder.dx + 55 * math.cos(elbowAngle),
        shoulder.dy + 55 * math.sin(elbowAngle),
      );
      final Offset wrist = Offset(
        elbow.dx + 50 * math.cos(wristAngle),
        elbow.dy + 50 * math.sin(wristAngle),
      );
      final Offset tip = Offset(
        wrist.dx + 65 * math.cos(tipAngle),
        wrist.dy + 65 * math.sin(tipAngle),
      );

      anim.add(buildStraightLineContent(
        p1: shoulder,
        p2: elbow,
        color: const Color(0xFF1E293B),
        strokeWidth: 4.0,
      ));
      anim.add(buildStraightLineContent(
        p1: elbow,
        p2: wrist,
        color: const Color(0xFF0284C7),
        strokeWidth: 3.5,
      ));
      anim.add(buildSmoothLineContent(
        points: [wrist, tip],
        color: const Color(0xFFEF4444),
        strokeWidth: 3.5,
      ));

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'The Kinetic Whip', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 21. PUSH: HEAVY VS LIGHT (24 frames)
  // =========================================================================
  static Map<String, dynamic> buildPushHeavyVsLightProject() {
    const int frameCount = 24;
    const double floorY = 160.0;
    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildStraightLineContent(
        p1: const Offset(30, floorY),
        p2: const Offset(330, floorY),
        color: const Color(0xFF94A3B8),
        strokeWidth: 2.2,
      ));

      final double pushProgress = (i / (frameCount - 1));
      final double crateX = 190 + 35 * pushProgress;

      anim.add(buildRectangleContent(
        p1: Offset(crateX, floorY - 70),
        p2: Offset(crateX + 70, floorY),
        color: const Color(0xFF78350F),
        strokeWidth: 3.5,
      ));

      final double manX = crateX - 25;
      final double strainWobble = 2 * math.sin(i * 3 * math.pi);

      anim.add(buildCircleContent(
        center: Offset(manX - 25 + strainWobble, floorY - 50),
        radius: 11,
        color: const Color(0xFFEF4444),
        strokeWidth: 3.5,
      ));
      anim.add(buildStraightLineContent(
        p1: Offset(manX - 25 + strainWobble, floorY - 40),
        p2: Offset(manX - 55, floorY - 15),
        color: const Color(0xFF1E1B39),
        strokeWidth: 3.5,
      ));
      anim.add(buildStraightLineContent(
        p1: Offset(manX - 22, floorY - 38),
        p2: Offset(crateX, floorY - 45),
        color: const Color(0xFF1E1B39),
        strokeWidth: 3.5,
      ));
      anim.add(buildStraightLineContent(
        p1: Offset(manX - 55, floorY - 15),
        p2: Offset(manX - 80, floorY),
        color: const Color(0xFF1E1B39),
        strokeWidth: 3.5,
      ));

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Push: Heavy vs Light', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 22. DAMPED DECAY PENDULUM (24 frames)
  // =========================================================================
  static Map<String, dynamic> buildDampedDecayProject() {
    const int frameCount = 24;
    const Offset pivot = Offset(180, 25);
    const double length = 115.0;
    const double initialAngle = 0.75;

    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildCircleContent(
        center: pivot,
        radius: 4,
        color: const Color(0xFF64748B),
        strokeWidth: 2,
        style: PaintingStyle.fill,
      ));

      final double decay = math.exp(-i / 10.0);
      final double currentAngle = initialAngle * decay * math.sin(i * 3 * math.pi / 8.0);

      final Offset bobCenter = Offset(
        pivot.dx + length * math.sin(currentAngle),
        pivot.dy + length * math.cos(currentAngle),
      );

      anim.add(buildStraightLineContent(
        p1: pivot,
        p2: bobCenter,
        color: const Color(0xFF1E293B),
        strokeWidth: 3.0,
      ));
      anim.add(buildCircleContent(
        center: bobCenter,
        radius: 14,
        color: const Color(0xFF6366F1),
        strokeWidth: 4.0,
      ));

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Damped Decay', fps: 12, canvases: canvases);
  }


  // =========================================================================
  // 23. EYE BLINK & EXPRESSION (12 frames)
  // =========================================================================
  static Map<String, dynamic> buildEyeBlinkProject() {
    const int frameCount = 12;
    const Offset eyeCenter = Offset(180, 100);
    const double eyeRx = 42.0;
    const double eyeRy = 26.0;

    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildCircleContent(
        center: eyeCenter,
        radius: eyeRx,
        isEllipse: true,
        rx: eyeRx,
        ry: eyeRy,
        color: const Color(0xFFCBD5E1),
        strokeWidth: 1.5,
      ));
      guide.add(buildStraightLineContent(
        p1: const Offset(130, 62),
        p2: const Offset(230, 62),
        color: const Color(0xFF94A3B8),
        strokeWidth: 1.5,
      ));

      double browY = 62.0;
      if (i >= 4 && i <= 6) browY += 4.0;
      anim.add(buildSmoothLineContent(
        points: [
          Offset(136, browY + 3),
          Offset(180, browY - 3),
          Offset(224, browY + 2),
        ],
        color: const Color(0xFF334155),
        strokeWidth: 4.5,
      ));

      if (i == 5) {
        anim.add(buildSmoothLineContent(
          points: [
            Offset(eyeCenter.dx - eyeRx, eyeCenter.dy + 4),
            Offset(eyeCenter.dx, eyeCenter.dy + 7),
            Offset(eyeCenter.dx + eyeRx, eyeCenter.dy + 4),
          ],
          color: const Color(0xFF0F172A),
          strokeWidth: 4.0,
        ));
        anim.add(buildStraightLineContent(
          p1: Offset(eyeCenter.dx - 15, eyeCenter.dy + 6),
          p2: Offset(eyeCenter.dx - 22, eyeCenter.dy + 15),
          color: const Color(0xFF0F172A),
          strokeWidth: 2.5,
        ));
        anim.add(buildStraightLineContent(
          p1: Offset(eyeCenter.dx + 15, eyeCenter.dy + 6),
          p2: Offset(eyeCenter.dx + 22, eyeCenter.dy + 15),
          color: const Color(0xFF0F172A),
          strokeWidth: 2.5,
        ));
      } else if (i == 4 || i == 6) {
        final double midY = i == 4 ? eyeCenter.dy + 3 : eyeCenter.dy - 3;
        anim.add(buildSmoothLineContent(
          points: [
            Offset(eyeCenter.dx - eyeRx, eyeCenter.dy),
            Offset(eyeCenter.dx, eyeCenter.dy + eyeRy),
            Offset(eyeCenter.dx + eyeRx, eyeCenter.dy),
          ],
          color: const Color(0xFF0F172A),
          strokeWidth: 3.5,
        ));
        anim.add(buildSmoothLineContent(
          points: [
            Offset(eyeCenter.dx - eyeRx, eyeCenter.dy),
            Offset(eyeCenter.dx, midY),
            Offset(eyeCenter.dx + eyeRx, eyeCenter.dy),
          ],
          color: const Color(0xFF0F172A),
          strokeWidth: 4.0,
        ));
        anim.add(buildCircleContent(
          center: Offset(eyeCenter.dx, eyeCenter.dy + 4),
          radius: 12.0,
          color: const Color(0xFF3B82F6),
          strokeWidth: 3.5,
        ));
      } else {
        anim.add(buildSmoothLineContent(
          points: [
            Offset(eyeCenter.dx - eyeRx, eyeCenter.dy),
            Offset(eyeCenter.dx, eyeCenter.dy - eyeRy),
            Offset(eyeCenter.dx + eyeRx, eyeCenter.dy),
          ],
          color: const Color(0xFF0F172A),
          strokeWidth: 4.0,
        ));
        anim.add(buildSmoothLineContent(
          points: [
            Offset(eyeCenter.dx - eyeRx, eyeCenter.dy),
            Offset(eyeCenter.dx, eyeCenter.dy + eyeRy),
            Offset(eyeCenter.dx + eyeRx, eyeCenter.dy),
          ],
          color: const Color(0xFF0F172A),
          strokeWidth: 3.0,
        ));
        anim.add(buildCircleContent(
          center: eyeCenter,
          radius: 15.0,
          color: const Color(0xFF2563EB),
          strokeWidth: 3.5,
        ));
        anim.add(buildCircleContent(
          center: eyeCenter,
          radius: 6.0,
          color: const Color(0xFF0F172A),
          strokeWidth: 2.0,
          style: PaintingStyle.fill,
        ));
        anim.add(buildCircleContent(
          center: Offset(eyeCenter.dx - 4, eyeCenter.dy - 4),
          radius: 3.0,
          color: const Color(0xFFFFFFFF),
          strokeWidth: 2.0,
          style: PaintingStyle.fill,
        ));
      }

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Eye Blink & Expression', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 24. MOUTH SHAPES & LIP SYNC (16 frames)
  // =========================================================================
  static Map<String, dynamic> buildMouthShapesProject() {
    const int frameCount = 16;
    const Offset headCenter = Offset(180, 95);
    const Offset mouthCenter = Offset(180, 130);

    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildCircleContent(
        center: headCenter,
        radius: 65,
        color: const Color(0xFFE2E8F0),
        strokeWidth: 1.5,
      ));
      guide.add(buildStraightLineContent(
        p1: const Offset(140, 130),
        p2: const Offset(220, 130),
        color: const Color(0xFF94A3B8),
        strokeWidth: 1.5,
      ));

      // Eyes on character
      anim.add(buildCircleContent(
        center: const Offset(160, 85),
        radius: 6,
        color: const Color(0xFF1E293B),
        strokeWidth: 2,
        style: PaintingStyle.fill,
      ));
      anim.add(buildCircleContent(
        center: const Offset(200, 85),
        radius: 6,
        color: const Color(0xFF1E293B),
        strokeWidth: 2,
        style: PaintingStyle.fill,
      ));
      anim.add(buildCircleContent(
        center: headCenter,
        radius: 62,
        color: const Color(0xFF334155),
        strokeWidth: 3.5,
      ));

      // 5 Phoneme Mouth stages: 0..2 Rest, 3..5 "A" vowel, 6..8 "O" round, 9..11 "M" closed, 12..15 "E" & Smile
      if (i >= 3 && i <= 5) {
        // "A" open vowel
        anim.add(buildCircleContent(
          center: mouthCenter,
          radius: 18,
          isEllipse: true,
          rx: 16,
          ry: 18,
          color: const Color(0xFFEF4444),
          strokeWidth: 4.0,
        ));
        anim.add(buildSmoothLineContent(
          points: [
            Offset(mouthCenter.dx - 10, mouthCenter.dy + 8),
            Offset(mouthCenter.dx, mouthCenter.dy + 12),
            Offset(mouthCenter.dx + 10, mouthCenter.dy + 8),
          ],
          color: const Color(0xFFF87171),
          strokeWidth: 3.0,
        ));
      } else if (i >= 6 && i <= 8) {
        // "O" round circle
        anim.add(buildCircleContent(
          center: mouthCenter,
          radius: 13,
          color: const Color(0xFFEF4444),
          strokeWidth: 4.0,
        ));
      } else if (i >= 9 && i <= 11) {
        // "M" closed flat lips
        anim.add(buildSmoothLineContent(
          points: [
            Offset(mouthCenter.dx - 22, mouthCenter.dy),
            Offset(mouthCenter.dx, mouthCenter.dy + 2),
            Offset(mouthCenter.dx + 22, mouthCenter.dy),
          ],
          color: const Color(0xFFEF4444),
          strokeWidth: 4.0,
        ));
      } else if (i >= 12 && i <= 15) {
        // "E" / Wide Smile
        anim.add(buildSmoothLineContent(
          points: [
            Offset(mouthCenter.dx - 25, mouthCenter.dy - 4),
            Offset(mouthCenter.dx, mouthCenter.dy + 14),
            Offset(mouthCenter.dx + 25, mouthCenter.dy - 4),
          ],
          color: const Color(0xFFEF4444),
          strokeWidth: 4.0,
        ));
        anim.add(buildStraightLineContent(
          p1: Offset(mouthCenter.dx - 24, mouthCenter.dy - 3),
          p2: Offset(mouthCenter.dx + 24, mouthCenter.dy - 3),
          color: const Color(0xFFEF4444),
          strokeWidth: 3.0,
        ));
      } else {
        // Neutral Rest
        anim.add(buildSmoothLineContent(
          points: [
            Offset(mouthCenter.dx - 16, mouthCenter.dy),
            Offset(mouthCenter.dx, mouthCenter.dy + 2),
            Offset(mouthCenter.dx + 16, mouthCenter.dy),
          ],
          color: const Color(0xFFEF4444),
          strokeWidth: 3.5,
        ));
      }

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Mouth Shapes & Lip Sync', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 25. HAND WAVE & GESTURE (16 frames)
  // =========================================================================
  static Map<String, dynamic> buildHandWaveProject() {
    const int frameCount = 16;
    const Offset wrist = Offset(180, 160);
    const double palmLength = 45.0;

    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      final double waveAngle = 0.38 * math.sin(2 * math.pi * i / frameCount);

      guide.add(buildCircleContent(
        center: wrist,
        radius: 6,
        color: const Color(0xFF94A3B8),
        strokeWidth: 1.5,
      ));
      guide.add(buildStraightLineContent(
        p1: const Offset(180, 160),
        p2: const Offset(180, 195),
        color: const Color(0xFFCBD5E1),
        strokeWidth: 3.0,
      ));

      // Palm center & rotation
      final double palmX = wrist.dx + palmLength * math.sin(waveAngle);
      final double palmY = wrist.dy - palmLength * math.cos(waveAngle);
      final Offset palmCenter = Offset(palmX, palmY);

      // Arm
      anim.add(buildStraightLineContent(
        p1: const Offset(180, 195),
        p2: wrist,
        color: const Color(0xFF1E293B),
        strokeWidth: 4.5,
      ));

      // Palm
      anim.add(buildStraightLineContent(
        p1: wrist,
        p2: palmCenter,
        color: const Color(0xFFF97316),
        strokeWidth: 6.0,
      ));

      // 4 Fingers with follow-through delay
      for (int f = -2; f <= 2; f++) {
        if (f == 0) continue;
        final double fSpread = f * 0.12;
        final double fingerDelay = waveAngle + fSpread + 0.15 * math.sin(2 * math.pi * i / frameCount - 0.3);
        final double fLen = 32.0 - (f.abs() * 3.0);
        final Offset fTip = Offset(
          palmCenter.dx + fLen * math.sin(fingerDelay),
          palmCenter.dy - fLen * math.cos(fingerDelay),
        );
        anim.add(buildStraightLineContent(
          p1: palmCenter,
          p2: fTip,
          color: const Color(0xFFF97316),
          strokeWidth: 3.5,
        ));
      }

      // Thumb
      final double thumbAngle = waveAngle - 0.55;
      final Offset thumbTip = Offset(
        wrist.dx + 22 * math.sin(thumbAngle),
        wrist.dy - 22 * math.cos(thumbAngle),
      );
      anim.add(buildStraightLineContent(
        p1: wrist,
        p2: thumbTip,
        color: const Color(0xFFF97316),
        strokeWidth: 3.5,
      ));

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Hand Wave & Gesture', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 26. HAIR IN THE WIND (16 frames)
  // =========================================================================
  static Map<String, dynamic> buildHairInWindProject() {
    const int frameCount = 16;
    const Offset headCenter = Offset(110, 100);

    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      // Wind guide vectors
      guide.add(buildStraightLineContent(
        p1: const Offset(40, 50),
        p2: const Offset(320, 50),
        color: const Color(0xFFBAE6FD),
        strokeWidth: 1.5,
      ));
      guide.add(buildStraightLineContent(
        p1: const Offset(40, 150),
        p2: const Offset(320, 150),
        color: const Color(0xFFBAE6FD),
        strokeWidth: 1.5,
      ));

      // Head silhouette
      anim.add(buildCircleContent(
        center: headCenter,
        radius: 34,
        color: const Color(0xFF334155),
        strokeWidth: 3.5,
      ));
      // Face profile nose & chin
      anim.add(buildSmoothLineContent(
        points: [
          Offset(headCenter.dx + 18, headCenter.dy - 12),
          Offset(headCenter.dx + 38, headCenter.dy),
          Offset(headCenter.dx + 22, headCenter.dy + 14),
          Offset(headCenter.dx + 28, headCenter.dy + 24),
          Offset(headCenter.dx + 10, headCenter.dy + 34),
        ],
        color: const Color(0xFF334155),
        strokeWidth: 3.5,
      ));

      // 3 flowing hair strands with overlapping S-wave delay
      final List<double> baseY = [75.0, 98.0, 120.0];
      final List<Color> hairColors = [
        const Color(0xFF8B5CF6),
        const Color(0xFFA855F7),
        const Color(0xFF7C3AED),
      ];

      for (int s = 0; s < 3; s++) {
        final List<Offset> strandPoints = [];
        final double phase = (2 * math.pi * i / frameCount) - (s * 0.6);
        for (double x = 110; x <= 310; x += 18) {
          final double dist = (x - 110) / 200.0;
          final double wave = math.sin(phase - (dist * 2.8 * math.pi)) * (16.0 + dist * 18.0);
          strandPoints.add(Offset(x, baseY[s] + wave));
        }
        anim.add(buildSmoothLineContent(
          points: strandPoints,
          color: hairColors[s],
          strokeWidth: 4.0 - (s * 0.5),
        ));
      }

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Hair in the Wind', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 27. CLASSIC WALK CYCLE (16 frames)
  // =========================================================================
  static Map<String, dynamic> buildWalkCycleProject() {
    const int frameCount = 16;
    const double floorY = 165.0;
    const double bodyX = 180.0;

    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildStraightLineContent(
        p1: const Offset(30, floorY),
        p2: const Offset(330, floorY),
        color: const Color(0xFF94A3B8),
        strokeWidth: 2.5,
      ));

      // Torso bob (2 cycles per 16 frames)
      final double bob = math.sin(4 * math.pi * i / frameCount) * 5.0;
      final double hipY = 108.0 + bob;
      final Offset hip = Offset(bodyX, hipY);
      final Offset head = Offset(bodyX + 2, hipY - 46);

      // Head
      anim.add(buildCircleContent(
        center: head,
        radius: 15,
        color: const Color(0xFF1E293B),
        strokeWidth: 3.5,
      ));
      // Spine / Torso
      anim.add(buildStraightLineContent(
        p1: head,
        p2: hip,
        color: const Color(0xFF1E293B),
        strokeWidth: 4.5,
      ));

      // Leg 1 (Front - Primary Orange) & Leg 2 (Back - Slate)
      final double stepPhase = 2 * math.pi * i / frameCount;

      for (int leg = 0; leg < 2; leg++) {
        final double p = stepPhase + (leg * math.pi);
        final double footX = bodyX + 36 * math.sin(p);
        final double lift = math.cos(p) > 0 ? (math.cos(p) * 22.0) : 0.0;
        final double footY = floorY - lift;
        final Offset foot = Offset(footX, footY);

        final Offset knee = Offset(
          (hip.dx + foot.dx) / 2 + 10,
          (hip.dy + foot.dy) / 2 - 4,
        );

        final Color legColor = leg == 0 ? const Color(0xFFEA580C) : const Color(0xFF64748B);

        anim.add(buildSmoothLineContent(
          points: [hip, knee, foot],
          color: legColor,
          strokeWidth: leg == 0 ? 4.5 : 3.5,
        ));
        // Foot base
        anim.add(buildStraightLineContent(
          p1: foot,
          p2: Offset(foot.dx + 12, foot.dy),
          color: legColor,
          strokeWidth: 4.0,
        ));
      }

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Classic Walk Cycle', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 28. DYNAMIC RUN CYCLE (12 frames)
  // =========================================================================
  static Map<String, dynamic> buildRunCycleProject() {
    const int frameCount = 12;
    const double floorY = 165.0;
    const double bodyX = 175.0;

    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildStraightLineContent(
        p1: const Offset(30, floorY),
        p2: const Offset(330, floorY),
        color: const Color(0xFF94A3B8),
        strokeWidth: 2.0,
      ));

      // Vigorous vertical oscillation & flight phases
      final double bob = math.sin(4 * math.pi * i / frameCount) * 12.0;
      final double hipY = 100.0 + bob;
      final Offset hip = Offset(bodyX, hipY);
      // Forward body lean angle (25 degrees forward)
      final Offset head = Offset(bodyX + 22, hipY - 42);

      // Speed trailing motion guides
      guide.add(buildStraightLineContent(
        p1: Offset(head.dx - 40, head.dy),
        p2: Offset(head.dx - 15, head.dy),
        color: const Color(0xFFFDBA74),
        strokeWidth: 2.0,
      ));

      anim.add(buildCircleContent(
        center: head,
        radius: 14,
        color: const Color(0xFF0F172A),
        strokeWidth: 3.5,
      ));
      anim.add(buildStraightLineContent(
        p1: head,
        p2: hip,
        color: const Color(0xFF0F172A),
        strokeWidth: 4.5,
      ));

      final double runPhase = 2 * math.pi * i / frameCount;

      for (int leg = 0; leg < 2; leg++) {
        final double p = runPhase + (leg * math.pi);
        final double footX = bodyX + 54 * math.sin(p);
        final double lift = (math.cos(p) + 0.3).clamp(0.0, 1.3) * 36.0;
        final double footY = floorY - lift;
        final Offset foot = Offset(footX, footY);

        final Offset knee = Offset(
          (hip.dx + foot.dx) / 2 + 18,
          (hip.dy + foot.dy) / 2 - 12,
        );

        final Color legColor = leg == 0 ? const Color(0xFFDC2626) : const Color(0xFF475569);

        anim.add(buildSmoothLineContent(
          points: [hip, knee, foot],
          color: legColor,
          strokeWidth: leg == 0 ? 5.0 : 3.8,
        ));
      }

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Dynamic Run Cycle', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 29. JUMP & IMPACT LANDING (18 frames)
  // =========================================================================
  static Map<String, dynamic> buildCharacterJumpProject() {
    const int frameCount = 18;
    const double floorY = 165.0;
    const double bodyX = 180.0;

    final List<Map<String, dynamic>> canvases = [];

    // Jump height stages:
    // 0..2: Standing idle (120)
    // 3..5: Deep crouch anticipation (145)
    // 6..7: Launch stretch (90)
    // 8..11: Apex hang float (45)
    // 12..14: Descent stretch (95 -> 135)
    // 15..16: Impact squash (150)
    // 17: Settle recovery (120)
    final List<double> heights = [
      120.0, 120.0, 120.0,
      138.0, 145.0, 142.0,
      95.0, 65.0,
      45.0, 42.0, 45.0, 55.0,
      85.0, 120.0, 140.0,
      152.0, 145.0,
      120.0,
    ];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildStraightLineContent(
        p1: const Offset(40, floorY),
        p2: const Offset(320, floorY),
        color: const Color(0xFF94A3B8),
        strokeWidth: 2.5,
      ));

      // Parabolic jump trajectory curve guide
      final List<Offset> arc = [];
      for (double t = 0; t <= 1.0; t += 0.05) {
        final double ax = 100 + t * 160;
        final double ay = floorY - 4 * (165 - 42) * t * (1 - t);
        arc.add(Offset(ax, ay));
      }
      guide.add(buildSmoothLineContent(
        points: arc,
        color: const Color(0xFF38BDF8),
        strokeWidth: 1.5,
      ));

      final double currentY = heights[i];
      final bool isSquash = i >= 3 && i <= 5 || i >= 15 && i <= 16;
      final bool isStretch = (i >= 6 && i <= 7) || (i >= 12 && i <= 14);

      if (isSquash) {
        // Squashed character mass
        anim.add(buildCircleContent(
          center: Offset(bodyX, currentY),
          radius: 20,
          isEllipse: true,
          rx: 28,
          ry: 14,
          color: const Color(0xFF10B981),
          strokeWidth: 4.5,
        ));
        // Ground impact dust lines
        if (i >= 15) {
          anim.add(buildStraightLineContent(
            p1: Offset(bodyX - 35, floorY - 2),
            p2: Offset(bodyX - 48, floorY - 6),
            color: const Color(0xFF34D399),
            strokeWidth: 2.5,
          ));
          anim.add(buildStraightLineContent(
            p1: Offset(bodyX + 35, floorY - 2),
            p2: Offset(bodyX + 48, floorY - 6),
            color: const Color(0xFF34D399),
            strokeWidth: 2.5,
          ));
        }
      } else if (isStretch) {
        // Stretched elongated body
        anim.add(buildCircleContent(
          center: Offset(bodyX, currentY),
          radius: 20,
          isEllipse: true,
          rx: 13,
          ry: 30,
          color: const Color(0xFF10B981),
          strokeWidth: 4.5,
        ));
      } else {
        // Normal sphere character at apex or rest
        anim.add(buildCircleContent(
          center: Offset(bodyX, currentY),
          radius: 20,
          color: const Color(0xFF10B981),
          strokeWidth: 4.5,
        ));
      }

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Jump & Impact Landing', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 30. SNEAK & TIP-TOE (16 frames)
  // =========================================================================
  static Map<String, dynamic> buildSneakWalkProject() {
    const int frameCount = 16;
    const double floorY = 165.0;
    const double bodyX = 180.0;

    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildStraightLineContent(
        p1: const Offset(30, floorY),
        p2: const Offset(330, floorY),
        color: const Color(0xFF94A3B8),
        strokeWidth: 2.5,
      ));

      // Low crouching stealth body posture
      const double hipY = 120.0;
      const Offset hip = Offset(bodyX - 10, hipY);
      const Offset head = Offset(bodyX + 16, hipY - 32);

      anim.add(buildCircleContent(
        center: head,
        radius: 14,
        color: const Color(0xFF1E1B4B),
        strokeWidth: 3.5,
      ));
      anim.add(buildSmoothLineContent(
        points: [head, const Offset(bodyX, hipY - 14), hip],
        color: const Color(0xFF1E1B4B),
        strokeWidth: 4.5,
      ));

      // High knee exaggeration stepping
      final double stepPhase = 2 * math.pi * i / frameCount;
      final double highLift = (math.sin(stepPhase) > 0) ? (math.sin(stepPhase) * 38.0) : 0.0;
      final double footX = bodyX + 32 * math.cos(stepPhase);
      final double footY = floorY - highLift;

      final Offset knee = Offset(bodyX + 18, (hip.dy + footY) / 2 - 14);

      anim.add(buildSmoothLineContent(
        points: [hip, knee, Offset(footX, footY)],
        color: const Color(0xFF6366F1),
        strokeWidth: 4.5,
      ));
      // Delicate tip-toe touch
      anim.add(buildCircleContent(
        center: Offset(footX + 4, footY),
        radius: 3.5,
        color: const Color(0xFF4338CA),
        strokeWidth: 2,
        style: PaintingStyle.fill,
      ));

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Sneak & Tip-Toe', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 31. BALL WITH LEGS (16 frames)
  // =========================================================================
  static Map<String, dynamic> buildBallWithLegsProject() {
    const int frameCount = 16;
    const double floorY = 165.0;
    const double centerX = 180.0;

    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildStraightLineContent(
        p1: const Offset(30, floorY),
        p2: const Offset(330, floorY),
        color: const Color(0xFF94A3B8),
        strokeWidth: 2.0,
      ));

      // Bouncing ball mass with step bounce
      final double bounce = math.sin(4 * math.pi * i / frameCount) * 8.0;
      final Offset ballCenter = Offset(centerX, 105.0 + bounce);

      // Body ball
      anim.add(buildCircleContent(
        center: ballCenter,
        radius: 26,
        color: const Color(0xFFEC4899),
        strokeWidth: 4.0,
      ));
      // Cute eyes
      anim.add(buildCircleContent(
        center: Offset(ballCenter.dx + 8, ballCenter.dy - 6),
        radius: 4,
        color: const Color(0xFF831843),
        strokeWidth: 2,
        style: PaintingStyle.fill,
      ));

      // 2 cartoon legs
      final double phase = 2 * math.pi * i / frameCount;
      for (int l = 0; l < 2; l++) {
        final double p = phase + (l * math.pi);
        final double footX = centerX + (l == 0 ? -12 : 12) + 24 * math.sin(p);
        final double footLift = math.cos(p) > 0 ? (math.cos(p) * 20.0) : 0.0;
        final Offset hipJoint = Offset(centerX + (l == 0 ? -12 : 12), ballCenter.dy + 24);
        final Offset foot = Offset(footX, floorY - footLift);

        anim.add(buildSmoothLineContent(
          points: [hipJoint, Offset((hipJoint.dx + foot.dx) / 2 + 6, (hipJoint.dy + foot.dy) / 2), foot],
          color: const Color(0xFFBE185D),
          strokeWidth: 4.0,
        ));
        // Foot oval shoe
        anim.add(buildCircleContent(
          center: Offset(foot.dx + 4, foot.dy),
          radius: 6,
          isEllipse: true,
          rx: 8,
          ry: 4,
          color: const Color(0xFF9D174D),
          strokeWidth: 2.5,
          style: PaintingStyle.fill,
        ));
      }

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Ball with Legs', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 32. 3/4 HEAD TURN (16 frames)
  // =========================================================================
  static Map<String, dynamic> buildHeadTurn3DProject() {
    const int frameCount = 16;
    const Offset center = Offset(180, 100);
    const double rx = 48.0;
    const double ry = 58.0;

    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      // 3D rotation angle theta from -55 deg to +55 deg
      final double theta = math.sin(2 * math.pi * i / frameCount) * 0.95;

      guide.add(buildCircleContent(
        center: center,
        radius: rx,
        isEllipse: true,
        rx: rx,
        ry: ry,
        color: const Color(0xFFE2E8F0),
        strokeWidth: 1.5,
      ));

      // Head silhouette oval
      anim.add(buildCircleContent(
        center: center,
        radius: rx,
        isEllipse: true,
        rx: rx,
        ry: ry,
        color: const Color(0xFF0F172A),
        strokeWidth: 4.0,
      ));

      // 3D Curving Center Facial Guide Line
      final double curveX = center.dx + rx * math.sin(theta);
      final List<Offset> centerLine = [];
      for (double y = center.dy - ry; y <= center.dy + ry; y += 10) {
        final double normY = (y - center.dy) / ry;
        final double widthAtY = math.sqrt((1 - normY * normY).clamp(0.0, 1.0));
        centerLine.add(Offset(center.dx + (rx * math.sin(theta) * widthAtY), y));
      }
      anim.add(buildSmoothLineContent(
        points: centerLine,
        color: const Color(0xFF0284C7),
        strokeWidth: 2.0,
      ));

      // Nose & Eyes shifting with 3D projection
      final double eyeY = center.dy - 6;
      final double eyeSpacing = 22.0 * math.cos(theta);
      final Offset leftEye = Offset(curveX - eyeSpacing, eyeY);
      final Offset rightEye = Offset(curveX + eyeSpacing, eyeY);

      if ((leftEye.dx - center.dx).abs() < rx - 4) {
        anim.add(buildCircleContent(
          center: leftEye,
          radius: 5,
          color: const Color(0xFF0F172A),
          strokeWidth: 2,
          style: PaintingStyle.fill,
        ));
      }
      if ((rightEye.dx - center.dx).abs() < rx - 4) {
        anim.add(buildCircleContent(
          center: rightEye,
          radius: 5,
          color: const Color(0xFF0F172A),
          strokeWidth: 2,
          style: PaintingStyle.fill,
        ));
      }

      // Nose
      final Offset noseTip = Offset(curveX + 12 * math.sin(theta), center.dy + 12);
      anim.add(buildSmoothLineContent(
        points: [Offset(curveX, center.dy + 2), noseTip, Offset(curveX, center.dy + 16)],
        color: const Color(0xFF0F172A),
        strokeWidth: 3.0,
      ));

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: '3/4 Head Turn', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 33. WATER DROP & SPLASH (16 frames)
  // =========================================================================
  static Map<String, dynamic> buildWaterSplashProject() {
    const int frameCount = 16;
    const double surfaceY = 145.0;
    const double splashX = 180.0;

    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildStraightLineContent(
        p1: const Offset(30, surfaceY),
        p2: const Offset(330, surfaceY),
        color: const Color(0xFF7DD3FC),
        strokeWidth: 2.0,
      ));

      if (i <= 3) {
        // Falling droplet
        final double dropY = 25.0 + (i * 38.0);
        anim.add(buildCircleContent(
          center: Offset(splashX, dropY),
          radius: 12,
          isEllipse: true,
          rx: 8,
          ry: 16,
          color: const Color(0xFF0284C7),
          strokeWidth: 3.5,
        ));
      } else if (i >= 4 && i <= 8) {
        // Crown splash explosion
        final double splashRadius = (i - 3) * 14.0;
        final double spikeHeight = (i - 3) * 12.0;

        anim.add(buildSmoothLineContent(
          points: [
            Offset(splashX - splashRadius, surfaceY),
            Offset(splashX - splashRadius + 6, surfaceY - spikeHeight),
            Offset(splashX, surfaceY - (spikeHeight * 0.5)),
            Offset(splashX + splashRadius - 6, surfaceY - spikeHeight),
            Offset(splashX + splashRadius, surfaceY),
          ],
          color: const Color(0xFF0284C7),
          strokeWidth: 4.0,
        ));
        // Center rising droplet bead
        if (i >= 6) {
          anim.add(buildCircleContent(
            center: Offset(splashX, surfaceY - spikeHeight - 8),
            radius: 5,
            color: const Color(0xFF0284C7),
            strokeWidth: 2,
            style: PaintingStyle.fill,
          ));
        }
      } else {
        // Expanding circular ripple rings
        final double r1 = (i - 8) * 18.0;
        final double r2 = (i - 8) * 11.0;
        anim.add(buildCircleContent(
          center: const Offset(splashX, surfaceY),
          radius: r1,
          isEllipse: true,
          rx: r1,
          ry: r1 * 0.3,
          color: const Color(0xFF38BDF8),
          strokeWidth: 3.0,
        ));
        if (r2 > 4) {
          anim.add(buildCircleContent(
            center: const Offset(splashX, surfaceY),
            radius: r2,
            isEllipse: true,
            rx: r2,
            ry: r2 * 0.3,
            color: const Color(0xFF7DD3FC),
            strokeWidth: 2.0,
          ));
        }
      }

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Water Drop & Splash', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 34. EXPLOSION & SMOKE PUFF (16 frames)
  // =========================================================================
  static Map<String, dynamic> buildExplosionPuffProject() {
    const int frameCount = 16;
    const Offset center = Offset(180, 105);

    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildCircleContent(
        center: center,
        radius: 65,
        color: const Color(0xFFFEF08A),
        strokeWidth: 1.5,
      ));

      if (i <= 2) {
        // Bright initial blast spike
        final double r = 12.0 + i * 16.0;
        anim.add(buildCircleContent(
          center: center,
          radius: r,
          color: const Color(0xFFFACC15),
          strokeWidth: 4.5,
        ));
      } else if (i <= 8) {
        // Billowing smoke cloud lobes
        final int lobes = 7;
        final double growth = (i - 2) * 8.5;
        for (int l = 0; l < lobes; l++) {
          final double angle = (2 * math.pi * l / lobes);
          final Offset lobeCenter = Offset(
            center.dx + (growth * 0.8) * math.cos(angle),
            center.dy + (growth * 0.8) * math.sin(angle),
          );
          anim.add(buildCircleContent(
            center: lobeCenter,
            radius: 12.0 + (i * 2.5),
            color: const Color(0xFFF97316),
            strokeWidth: 3.5,
          ));
        }
      } else {
        // Dissipating floating smoke particles
        final int particles = 8;
        final double drift = (i - 8) * 12.0;
        for (int p = 0; p < particles; p++) {
          final double angle = (2 * math.pi * p / particles);
          final Offset pCenter = Offset(
            center.dx + (45 + drift) * math.cos(angle),
            center.dy - drift * 0.5 + (35 + drift) * math.sin(angle),
          );
          anim.add(buildCircleContent(
            center: pCenter,
            radius: (14.0 - (i - 8) * 1.5).clamp(2.0, 14.0),
            color: const Color(0xFF94A3B8),
            strokeWidth: 2.5,
          ));
        }
      }

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Explosion & Smoke Puff', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 35. LIGHTNING BOLT & ZAP (12 frames)
  // =========================================================================
  static Map<String, dynamic> buildLightningStrikeProject() {
    const int frameCount = 12;

    final List<Map<String, dynamic>> canvases = [];

    final List<Offset> mainBolt = [
      const Offset(180, 20),
      const Offset(165, 55),
      const Offset(195, 85),
      const Offset(170, 125),
      const Offset(190, 150),
      const Offset(180, 185),
    ];

    final List<Offset> branchBolt = [
      const Offset(165, 55),
      const Offset(135, 80),
      const Offset(145, 110),
    ];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildStraightLineContent(
        p1: const Offset(40, 185),
        p2: const Offset(320, 185),
        color: const Color(0xFF64748B),
        strokeWidth: 2.0,
      ));

      if (i == 0 || i == 1) {
        // Step leader faint trace
        anim.add(buildSmoothLineContent(
          points: mainBolt.sublist(0, 3 + i),
          color: const Color(0xFF93C5FD),
          strokeWidth: 2.5,
        ));
      } else if (i >= 2 && i <= 5) {
        // Blinding main flash & thick bolt
        anim.add(buildSmoothLineContent(
          points: mainBolt,
          color: const Color(0xFF3B82F6),
          strokeWidth: 6.0,
        ));
        anim.add(buildSmoothLineContent(
          points: mainBolt,
          color: const Color(0xFFFFFFFF),
          strokeWidth: 2.5,
        ));
        anim.add(buildSmoothLineContent(
          points: branchBolt,
          color: const Color(0xFF60A5FA),
          strokeWidth: 3.5,
        ));
        // Ground impact flash
        anim.add(buildCircleContent(
          center: const Offset(180, 185),
          radius: 18,
          color: const Color(0xFF60A5FA),
          strokeWidth: 3.0,
        ));
      } else if (i >= 6 && i <= 8) {
        // Residual crackle
        anim.add(buildSmoothLineContent(
          points: mainBolt,
          color: const Color(0xFF818CF8),
          strokeWidth: 3.0,
        ));
      }

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Lightning Bolt & Zap', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 36. BALLOON FLOAT & POP (16 frames)
  // =========================================================================
  static Map<String, dynamic> buildBalloonPopProject() {
    const int frameCount = 16;
    const Offset balloonCenter = Offset(195, 90);

    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildCircleContent(
        center: balloonCenter,
        radius: 36,
        color: const Color(0xFFFECDD3),
        strokeWidth: 1.5,
      ));

      if (i <= 6) {
        // Floating balloon and needle approaching
        final double sway = math.sin(2 * math.pi * i / 7) * 4.0;
        final Offset bPos = Offset(balloonCenter.dx + sway, balloonCenter.dy);
        final double needleX = 40.0 + (i * 18.0);

        // Needle
        anim.add(buildStraightLineContent(
          p1: Offset(needleX, 90),
          p2: Offset(needleX + 26, 90),
          color: const Color(0xFF475569),
          strokeWidth: 3.0,
        ));
        // Balloon
        anim.add(buildCircleContent(
          center: bPos,
          radius: 34,
          isEllipse: true,
          rx: 28,
          ry: 36,
          color: const Color(0xFFF43F5E),
          strokeWidth: 4.0,
        ));
        // String
        anim.add(buildSmoothLineContent(
          points: [
            Offset(bPos.dx, bPos.dy + 36),
            Offset(bPos.dx - 8, bPos.dy + 60),
            Offset(bPos.dx + 4, bPos.dy + 85),
          ],
          color: const Color(0xFF94A3B8),
          strokeWidth: 2.0,
        ));
      } else if (i >= 7 && i <= 10) {
        // POP! Elastic rupture flying fragments
        final double burst = (i - 6) * 14.0;
        final int frags = 6;
        for (int f = 0; f < frags; f++) {
          final double angle = 2 * math.pi * f / frags;
          final Offset fragPos = Offset(
            balloonCenter.dx + burst * math.cos(angle),
            balloonCenter.dy + burst * math.sin(angle),
          );
          anim.add(buildSmoothLineContent(
            points: [
              fragPos,
              Offset(fragPos.dx + 8 * math.cos(angle + 1), fragPos.dy + 8 * math.sin(angle + 1)),
            ],
            color: const Color(0xFFF43F5E),
            strokeWidth: 4.0,
          ));
        }
      }

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Balloon Float & Pop', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 37. FLUTTERING AUTUMN LEAF (20 frames)
  // =========================================================================
  static Map<String, dynamic> buildFallingLeafProject() {
    const int frameCount = 20;

    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      // S-curve drift trajectory
      final double progress = i / (frameCount - 1);
      final double leafY = 30.0 + (progress * 135.0);
      final double leafX = 180.0 + 75.0 * math.sin(2 * math.pi * i / 10.0);
      final double tilt = math.cos(2 * math.pi * i / 10.0) * 0.85;

      // Trajectory path guide
      final List<Offset> pathGuide = [];
      for (int t = 0; t < frameCount; t++) {
        final double py = 30.0 + (t / (frameCount - 1) * 135.0);
        final double px = 180.0 + 75.0 * math.sin(2 * math.pi * t / 10.0);
        pathGuide.add(Offset(px, py));
      }
      guide.add(buildSmoothLineContent(
        points: pathGuide,
        color: const Color(0xFFFED7AA),
        strokeWidth: 1.5,
      ));

      // Leaf body rotating & tilting
      final Offset leafCenter = Offset(leafX, leafY);
      final double lx1 = leafCenter.dx + 22 * math.sin(tilt);
      final double ly1 = leafCenter.dy - 22 * math.cos(tilt);
      final double lx2 = leafCenter.dx - 22 * math.sin(tilt);
      final double ly2 = leafCenter.dy + 22 * math.cos(tilt);

      anim.add(buildStraightLineContent(
        p1: Offset(lx1, ly1),
        p2: Offset(lx2, ly2),
        color: const Color(0xFFD97706),
        strokeWidth: 3.5,
      ));
      anim.add(buildCircleContent(
        center: leafCenter,
        radius: 14,
        isEllipse: true,
        rx: 16 * (tilt.abs() + 0.3),
        ry: 8,
        color: const Color(0xFFF59E0B),
        strokeWidth: 3.5,
      ));

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Fluttering Autumn Leaf', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 38. MAGIC STARBURST & TWINKLE (12 frames)
  // =========================================================================
  static Map<String, dynamic> buildMagicSparkleProject() {
    const int frameCount = 12;
    const Offset center = Offset(180, 100);

    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildCircleContent(
        center: center,
        radius: 45,
        color: const Color(0xFFDDD6FE),
        strokeWidth: 1.5,
      ));

      // Expanding 4-point diamond star
      final double scale = math.sin(math.pi * i / (frameCount - 1));
      final double rayLen = 12.0 + scale * 48.0;

      // Vertical & Horizontal rays
      anim.add(buildStraightLineContent(
        p1: Offset(center.dx, center.dy - rayLen),
        p2: Offset(center.dx, center.dy + rayLen),
        color: const Color(0xFF8B5CF6),
        strokeWidth: 4.0,
      ));
      anim.add(buildStraightLineContent(
        p1: Offset(center.dx - rayLen, center.dy),
        p2: Offset(center.dx + rayLen, center.dy),
        color: const Color(0xFF8B5CF6),
        strokeWidth: 4.0,
      ));

      // 4 diagonal secondary sparkles
      final double diag = rayLen * 0.5;
      anim.add(buildStraightLineContent(
        p1: Offset(center.dx - diag, center.dy - diag),
        p2: Offset(center.dx + diag, center.dy + diag),
        color: const Color(0xFFA78BFA),
        strokeWidth: 2.5,
      ));
      anim.add(buildStraightLineContent(
        p1: Offset(center.dx - diag, center.dy + diag),
        p2: Offset(center.dx + diag, center.dy - diag),
        color: const Color(0xFFA78BFA),
        strokeWidth: 2.5,
      ));

      // Central core glow
      anim.add(buildCircleContent(
        center: center,
        radius: 6.0 + scale * 6.0,
        color: const Color(0xFFC4B5FD),
        strokeWidth: 2,
        style: PaintingStyle.fill,
      ));

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Magic Starburst & Twinkle', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 39. LIQUID FLOURISH SPLASH (16 frames)
  // =========================================================================
  static Map<String, dynamic> buildLiquidFlourishProject() {
    const int frameCount = 16;
    const Offset center = Offset(180, 100);

    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      guide.add(buildCircleContent(
        center: center,
        radius: 55,
        color: const Color(0xFFCCFBF1),
        strokeWidth: 1.5,
      ));

      // Dynamic spiral fluid flourish
      final double progress = i / (frameCount - 1);
      final List<Offset> splashCurve = [];
      for (double a = 0; a <= progress * 2.2 * math.pi; a += 0.2) {
        final double r = 18.0 + a * 16.0;
        splashCurve.add(Offset(
          center.dx + r * math.cos(a),
          center.dy + r * math.sin(a),
        ));
      }

      if (splashCurve.length >= 2) {
        anim.add(buildSmoothLineContent(
          points: splashCurve,
          color: const Color(0xFF0D9488),
          strokeWidth: 4.5,
        ));
      }

      // Trailing droplet beads
      if (splashCurve.isNotEmpty) {
        anim.add(buildCircleContent(
          center: splashCurve.last,
          radius: 6,
          color: const Color(0xFF14B8A6),
          strokeWidth: 2,
          style: PaintingStyle.fill,
        ));
      }

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Liquid Flourish Splash', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 40. SWORD SLASH & TRAIL (14 frames)
  // =========================================================================
  static Map<String, dynamic> buildSwordSlashProject() {
    const int frameCount = 14;

    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      // Crescent slash arc guide
      final List<Offset> arcGuide = [];
      for (double a = -0.8; a <= 1.8; a += 0.1) {
        arcGuide.add(Offset(180 + 110 * math.cos(a), 110 + 75 * math.sin(a)));
      }
      guide.add(buildSmoothLineContent(
        points: arcGuide,
        color: const Color(0xFFFDE68A),
        strokeWidth: 1.5,
      ));

      if (i <= 3) {
        // Windup ready stance
        anim.add(buildStraightLineContent(
          p1: const Offset(90, 140),
          p2: const Offset(130, 60),
          color: const Color(0xFF3B82F6),
          strokeWidth: 4.5,
        ));
      } else if (i >= 4 && i <= 8) {
        // Lightning fast crescent speed-arc slash
        final List<Offset> slashBlade = [];
        for (double a = -0.4; a <= 1.6; a += 0.15) {
          slashBlade.add(Offset(180 + 115 * math.cos(a), 105 + 75 * math.sin(a)));
        }
        anim.add(buildSmoothLineContent(
          points: slashBlade,
          color: const Color(0xFFF59E0B),
          strokeWidth: 6.0,
        ));
        anim.add(buildSmoothLineContent(
          points: slashBlade,
          color: const Color(0xFFFFFFFF),
          strokeWidth: 2.5,
        ));
      } else {
        // Follow through sword resting
        anim.add(buildStraightLineContent(
          p1: const Offset(230, 80),
          p2: const Offset(280, 160),
          color: const Color(0xFF3B82F6),
          strokeWidth: 4.5,
        ));
      }

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Sword Slash & Trail', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 41. BIRD FLIGHT & WING FLAP (16 frames)
  // =========================================================================
  static Map<String, dynamic> buildBirdFlightProject() {
    const int frameCount = 16;
    const double bodyX = 180.0;

    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      final double flightBob = math.sin(2 * math.pi * i / frameCount) * 10.0;
      final Offset birdCenter = Offset(bodyX, 100.0 + flightBob);

      guide.add(buildCircleContent(
        center: birdCenter,
        radius: 40,
        color: const Color(0xFFE2E8F0),
        strokeWidth: 1.5,
      ));

      // Bird body
      anim.add(buildCircleContent(
        center: birdCenter,
        radius: 16,
        isEllipse: true,
        rx: 24,
        ry: 12,
        color: const Color(0xFF0F172A),
        strokeWidth: 4.0,
      ));
      // Beak
      anim.add(buildStraightLineContent(
        p1: Offset(birdCenter.dx + 22, birdCenter.dy - 2),
        p2: Offset(birdCenter.dx + 34, birdCenter.dy + 2),
        color: const Color(0xFFF97316),
        strokeWidth: 3.5,
      ));

      // Articulated wings (Upstroke F0..7, Downstroke F8..15)
      final double wingAngle = math.sin(2 * math.pi * i / frameCount) * 0.9;
      final double tipY = birdCenter.dy - 38 * math.sin(wingAngle + math.pi / 2);

      // Left & Right Wings
      anim.add(buildSmoothLineContent(
        points: [
          Offset(birdCenter.dx - 6, birdCenter.dy),
          Offset(birdCenter.dx - 18, birdCenter.dy + (tipY - birdCenter.dy) * 0.6),
          Offset(birdCenter.dx - 45, tipY),
        ],
        color: const Color(0xFF2563EB),
        strokeWidth: 4.5,
      ));
      anim.add(buildSmoothLineContent(
        points: [
          Offset(birdCenter.dx + 6, birdCenter.dy),
          Offset(birdCenter.dx + 18, birdCenter.dy + (tipY - birdCenter.dy) * 0.6),
          Offset(birdCenter.dx + 45, tipY),
        ],
        color: const Color(0xFF3B82F6),
        strokeWidth: 4.5,
      ));

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: 'Bird Flight & Wing Flap', fps: 12, canvases: canvases);
  }

  // =========================================================================
  // 42. 3D DEPTH PARALLAX (16 frames)
  // =========================================================================
  static Map<String, dynamic> buildCameraParallaxProject() {
    const int frameCount = 16;

    final List<Map<String, dynamic>> canvases = [];

    for (int i = 0; i < frameCount; i++) {
      final List<Map<String, dynamic>> guide = [];
      final List<Map<String, dynamic>> anim = [];

      // Camera viewframe border guide
      guide.add(buildRectangleContent(
        p1: const Offset(20, 20),
        p2: const Offset(340, 180),
        color: const Color(0xFF94A3B8),
        strokeWidth: 2.0,
      ));

      // 1. Distant Mountain Range (Slow: dx = i * 2.5)
      final double bgShift = (i * 2.5) % 80.0;
      anim.add(buildSmoothLineContent(
        points: [
          Offset(20, 120),
          Offset(90 - bgShift, 70),
          Offset(180 - bgShift, 110),
          Offset(270 - bgShift, 60),
          Offset(340, 120),
        ],
        color: const Color(0xFF93C5FD),
        strokeWidth: 3.0,
      ));

      // 2. Midground Rolling Hills (Medium: dx = i * 6.0)
      final double mgShift = (i * 6.0) % 120.0;
      anim.add(buildSmoothLineContent(
        points: [
          Offset(20, 145),
          Offset(110 - mgShift, 120),
          Offset(220 - mgShift, 140),
          Offset(340, 135),
        ],
        color: const Color(0xFF34D399),
        strokeWidth: 4.0,
      ));

      // 3. Foreground Fence Post (Fast: dx = i * 14.0)
      final double fgX = (340 - (i * 18.0)) % 320 + 20;
      anim.add(buildStraightLineContent(
        p1: Offset(fgX, 120),
        p2: Offset(fgX, 180),
        color: const Color(0xFF78350F),
        strokeWidth: 6.0,
      ));

      canvases.add(_wrapCanvas(guideHistory: guide, animHistory: anim));
    }

    return _wrapProjectState(title: '3D Depth Parallax', fps: 12, canvases: canvases);
  }


  // =========================================================================
  // Master project state router for all tutorial definitions (42 Lessons)
  // =========================================================================
  static Map<String, dynamic> buildProjectForTutorial(String tutorialId, String title, int frameCount) {
    switch (tutorialId) {
      // 1. Animation Basics
      case 'bouncing_ball':
        return buildBouncingBallProject();
      case 'pendulum_swing':
        return buildPendulumSwingProject();
      case 'shape_morphing':
        return buildShapeMorphingProject();
      case 'spinning_star':
        return buildSpinningStarProject();
      case 'wave_motion':
        return buildWaveMotionProject();
      case 'slow_in_slow_out':
        return buildSlowInSlowOutProject();
      case 'arcs_thrown_ball':
        return buildArcsThrownBallProject();
      case 'fire_flicker':
        return buildFireFlickerProject();
      case 'eye_blink':
        return buildEyeBlinkProject();
      case 'mouth_shapes':
        return buildMouthShapesProject();
      case 'hand_wave':
        return buildHandWaveProject();
      case 'hair_in_wind':
        return buildHairInWindProject();

      // 2. The 12 Principles
      case 'squash_and_stretch':
        return buildSquashAndStretchProject();
      case 'anticipation':
        return buildAnticipationProject();
      case 'staging':
        return buildStagingProject();
      case 'straight_ahead_pose_to_pose':
        return buildStraightAheadFlowProject();
      case 'follow_through_tail':
        return buildFollowThroughTailProject();
      case 'secondary_action':
        return buildSecondaryActionProject();
      case 'timing_is_weight':
        return buildTimingAndWeightProject();
      case 'exaggeration':
        return buildExaggerationProject();
      case 'solid_drawing':
        return buildSolidDrawingProject();
      case 'appeal':
        return buildCharacterAppealProject();

      // 3. Character & Locomotion
      case 'walk_cycle':
        return buildWalkCycleProject();
      case 'run_cycle':
        return buildRunCycleProject();
      case 'character_jump':
        return buildCharacterJumpProject();
      case 'sneak_walk':
        return buildSneakWalkProject();
      case 'ball_with_legs':
        return buildBallWithLegsProject();
      case 'head_turn_3d':
        return buildHeadTurn3DProject();

      // 4. VFX & Elements
      case 'water_splash':
        return buildWaterSplashProject();
      case 'explosion_puff':
        return buildExplosionPuffProject();
      case 'lightning_strike':
        return buildLightningStrikeProject();
      case 'balloon_pop':
        return buildBalloonPopProject();
      case 'falling_leaf':
        return buildFallingLeafProject();
      case 'magic_sparkle':
        return buildMagicSparkleProject();
      case 'liquid_flourish':
        return buildLiquidFlourishProject();

      // 5. Master Practice
      case 'keys_and_inbetweens':
        return buildKeysAndInbetweensProject();
      case 'arm_whip':
        return buildArmWhipProject();
      case 'push_heavy_vs_light':
        return buildPushHeavyVsLightProject();
      case 'pendulum_losing_energy':
        return buildDampedDecayProject();
      case 'sword_slash':
        return buildSwordSlashProject();
      case 'bird_flight':
        return buildBirdFlightProject();
      case 'camera_parallax':
        return buildCameraParallaxProject();

      default:
        return buildBouncingBallProject();
    }
  }
}

/// CustomPainter that renders any vector canvas frame accurately
class TutorialVectorPainter extends CustomPainter {
  final Map<String, dynamic>? canvasData;
  final bool showGrid;

  const TutorialVectorPainter({this.canvasData, this.showGrid = true});

  @override
  void paint(Canvas canvas, Size size) {
    // Pure solid clean canvas background without grid presets
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, bgPaint);

    if (canvasData == null) return;

    final double scaleX = size.width / TutorialProjectBuilder.canvasW;
    final double scaleY = size.height / TutorialProjectBuilder.canvasH;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    final layers = canvasData!['layers'] as List<dynamic>? ?? [];
    for (final layer in layers) {
      final lMap = layer as Map<String, dynamic>;
      if (lMap['isVisible'] == false) continue;
      final double opacity = (lMap['opacity'] as num?)?.toDouble() ?? 1.0;
      final history = lMap['history'] as List<dynamic>? ?? [];

      for (final item in history) {
        final hMap = item as Map<String, dynamic>;
        final type = hMap['type'] as String?;
        final paintMap = hMap['paint'] as Map<String, dynamic>?;
        if (paintMap == null) continue;

        final Color baseColor = Color(paintMap['color'] as int? ?? Colors.black.toARGB32());
        final Color paintColor = baseColor.withValues(alpha: (baseColor.a * opacity).clamp(0.0, 1.0));
        final double strokeW = (paintMap['strokeWidth'] as num?)?.toDouble() ?? 3.5;
        final style = PaintingStyle.values[paintMap['style'] as int? ?? PaintingStyle.stroke.index];

        final paint = Paint()
          ..color = paintColor
          ..strokeWidth = strokeW
          ..style = style
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

        if (type == 'StraightLine') {
          final p1 = hMap['startPoint'] as Map<String, dynamic>;
          final p2 = hMap['endPoint'] as Map<String, dynamic>;
          canvas.drawLine(
            Offset((p1['dx'] as num).toDouble(), (p1['dy'] as num).toDouble()),
            Offset((p2['dx'] as num).toDouble(), (p2['dy'] as num).toDouble()),
            paint,
          );
        } else if (type == 'Circle') {
          final isEllipse = hMap['isEllipse'] as bool? ?? false;
          final centerMap = hMap['center'] as Map<String, dynamic>;
          final center = Offset((centerMap['dx'] as num).toDouble(), (centerMap['dy'] as num).toDouble());
          if (isEllipse) {
            final p1 = hMap['startPoint'] as Map<String, dynamic>;
            final p2 = hMap['endPoint'] as Map<String, dynamic>;
            final rect = Rect.fromPoints(
              Offset((p1['dx'] as num).toDouble(), (p1['dy'] as num).toDouble()),
              Offset((p2['dx'] as num).toDouble(), (p2['dy'] as num).toDouble()),
            );
            canvas.drawOval(rect, paint);
          } else {
            final double radius = (hMap['radius'] as num).toDouble();
            canvas.drawCircle(center, radius, paint);
          }
        } else if (type == 'SmoothLine') {
          final points = hMap['points'] as List<dynamic>? ?? [];
          if (points.length >= 2) {
            final path = Path();
            final p0 = points.first as Map<String, dynamic>;
            path.moveTo((p0['dx'] as num).toDouble(), (p0['dy'] as num).toDouble());
            for (int k = 1; k < points.length; k++) {
              final pk = points[k] as Map<String, dynamic>;
              path.lineTo((pk['dx'] as num).toDouble(), (pk['dy'] as num).toDouble());
            }
            canvas.drawPath(path, paint);
          }
        } else if (type == 'Rectangle') {
          final p1 = hMap['startPoint'] as Map<String, dynamic>;
          final p2 = hMap['endPoint'] as Map<String, dynamic>;
          final rect = Rect.fromPoints(
            Offset((p1['dx'] as num).toDouble(), (p1['dy'] as num).toDouble()),
            Offset((p2['dx'] as num).toDouble(), (p2['dy'] as num).toDouble()),
          );
          canvas.drawRect(rect, paint);
        }
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TutorialVectorPainter oldDelegate) {
    return oldDelegate.canvasData != canvasData || oldDelegate.showGrid != showGrid;
  }
}

/// Self-contained, isolated widget that loops through animation frames smoothly
/// without triggering parent widget rebuilds or interrupting scroll physics.
class TutorialLivePreview extends StatefulWidget {
  final List<dynamic>? canvases;
  final Widget? placeholder;
  final Duration frameInterval;

  const TutorialLivePreview({
    super.key,
    required this.canvases,
    this.placeholder,
    this.frameInterval = const Duration(milliseconds: 140),
  });

  @override
  State<TutorialLivePreview> createState() => _TutorialLivePreviewState();
}

class _TutorialLivePreviewState extends State<TutorialLivePreview> {
  int _currentFrame = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    final count = widget.canvases?.length ?? 0;
    if (count > 1) {
      _timer = Timer.periodic(widget.frameInterval, (_) {
        if (mounted) {
          setState(() {
            _currentFrame = (_currentFrame + 1) % count;
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant TutorialLivePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.canvases != widget.canvases) {
      _currentFrame = 0;
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canvases = widget.canvases;
    if (canvases == null || canvases.isEmpty) {
      return widget.placeholder ?? const SizedBox.shrink();
    }
    final currentCanvas = canvases[_currentFrame % canvases.length] as Map<String, dynamic>?;

    return RepaintBoundary(
      child: CustomPaint(
        painter: TutorialVectorPainter(
          canvasData: currentCanvas,
          showGrid: false,
        ),
      ),
    );
  }
}

