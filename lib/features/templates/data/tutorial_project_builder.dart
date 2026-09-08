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
  // Master project state router for all tutorial definitions
  // =========================================================================
  static Map<String, dynamic> buildProjectForTutorial(String tutorialId, String title, int frameCount) {
    switch (tutorialId) {
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
      case 'keys_and_inbetweens':
        return buildKeysAndInbetweensProject();
      case 'arm_whip':
        return buildArmWhipProject();
      case 'push_heavy_vs_light':
        return buildPushHeavyVsLightProject();
      case 'pendulum_losing_energy':
        return buildDampedDecayProject();
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
