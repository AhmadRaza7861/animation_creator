import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';
import 'paint_content.dart';

class SmudgePoint {
  const SmudgePoint(this.point, this.delta);

  final Offset point;
  final Offset delta;

  Map<String, dynamic> toJson() => {
        'point': point.toJson(),
        'delta': delta.toJson(),
      };

  factory SmudgePoint.fromJson(Map<String, dynamic> json) => SmudgePoint(
        jsonToOffset(json['point']),
        jsonToOffset(json['delta']),
      );
}

/// 像素涂抹/位移引擎 (Local Wet-Paint Dispersion & Spread Engine)
/// 
/// Diffuses and spreads existing artwork pixels directly from the stroke contact point
/// in the swipe direction, creating a clean soft-feathered gap and a natural smoky dispersion plume.
class SmudgeContent extends PaintContent {
  SmudgeContent({this.strength = 0.5});

  SmudgeContent.data({
    required this.points,
    required this.strength,
    required Paint paint,
    this.image,
    this.rgbaData,
    this.rgbaWidth,
    this.rgbaHeight,
    this.onRepaint,
  }) : super.paint(paint);

  factory SmudgeContent.fromJson(Map<String, dynamic> data) {
    final content = SmudgeContent.data(
      points: (data['points'] as List<dynamic>?)
              ?.map((e) => SmudgePoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      strength: (data['strength'] ?? 0.5) as double,
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
      image: null,
    );
    if (data['imageDataBase64'] != null) {
      content.cachedBase64Image = data['imageDataBase64'] as String;
    }
    return content;
  }

  List<SmudgePoint> points = [];
  double strength;
  VoidCallback? onRepaint;

  ui.Image? image;
  Uint8List? rgbaData;
  int? rgbaWidth;
  int? rgbaHeight;
  String? cachedBase64Image;

  Offset? _lastPoint;

  @override
  String get contentType => 'SmudgeContent';

  void setImageData(ui.Image imageData) {
    image = imageData;
    rgbaWidth = imageData.width;
    rgbaHeight = imageData.height;
    imageData.toByteData(format: ui.ImageByteFormat.rawRgba).then((ByteData? data) {
      if (data != null) {
        setRgbaData(data.buffer.asUint8List(), imageData.width, imageData.height);
      }
    });
  }

  void setRgbaData(Uint8List data, int width, int height) {
    rgbaData = data;
    rgbaWidth = width;
    rgbaHeight = height;
    onRepaint?.call();
  }

  @override
  void startDraw(Offset startPoint) {
    points.clear();
    _lastPoint = startPoint;
    points.add(SmudgePoint(startPoint, Offset.zero));
  }

  @override
  void drawing(Offset nowPoint) {
    if (_lastPoint == null) {
      _lastPoint = nowPoint;
      return;
    }

    final Offset delta = nowPoint - _lastPoint!;
    if (delta.distance > 0.5) {
      points.add(SmudgePoint(nowPoint, delta));
      _lastPoint = nowPoint;
      onRepaint?.call();
    }
  }

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (points.length < 2) return;

    final double strokeWidth = paint.strokeWidth;

    // 1. Smooth Catmull-Rom spline interpolation for fluid gesture curves
    final List<Offset> stamps = <Offset>[];
    final double stepSize = (strokeWidth * 0.12).clamp(1.2, 3.5);

    final List<Offset> pts = points.map((e) => e.point).toList();
    if (pts.length == 2) {
      final double dist = (pts[1] - pts[0]).distance;
      final int steps = (dist / stepSize).ceil().clamp(1, 100);
      for (int s = 0; s <= steps; s++) {
        stamps.add(Offset.lerp(pts[0], pts[1], s / steps)!);
      }
    } else {
      stamps.add(pts[0]);
      for (int i = 0; i < pts.length - 1; i++) {
        final Offset p0 = i > 0 ? pts[i - 1] : pts[i];
        final Offset p1 = pts[i];
        final Offset p2 = pts[i + 1];
        final Offset p3 = i + 2 < pts.length ? pts[i + 2] : p2;

        final double dist = (p2 - p1).distance;
        final int numSteps = (dist / stepSize).ceil().clamp(1, 60);

        for (int s = 1; s <= numSteps; s++) {
          final double t = s / numSteps;
          final double t2 = t * t;
          final double t3 = t2 * t;

          final double x = 0.5 *
              ((2 * p1.dx) +
                  (-p0.dx + p2.dx) * t +
                  (2 * p0.dx - 5 * p1.dx + 4 * p2.dx - p3.dx) * t2 +
                  (-p0.dx + 3 * p1.dx - 3 * p2.dx + p3.dx) * t3);
          final double y = 0.5 *
              ((2 * p1.dy) +
                  (-p0.dy + p2.dy) * t +
                  (2 * p0.dy - 5 * p1.dy + 4 * p2.dy - p3.dy) * t2 +
                  (-p0.dy + 3 * p1.dy - 3 * p2.dy + p3.dy) * t3);

          stamps.add(Offset(x, y));
        }
      }
    }

    if (stamps.length < 2) return;

    // Helper: Sample underlying pixel color from snapshot within brush radius
    Color? sampleBrush(double px, double py) {
      if (rgbaData == null || rgbaWidth == null || rgbaHeight == null) return null;
      if (size.width <= 0 || size.height <= 0) return null;

      final double scaleX = rgbaWidth! / size.width;
      final double scaleY = rgbaHeight! / size.height;

      Color? check(double x, double y) {
        final int ix = (x * scaleX).round().clamp(0, rgbaWidth! - 1);
        final int iy = (y * scaleY).round().clamp(0, rgbaHeight! - 1);
        final int idx = (iy * rgbaWidth! + ix) * 4;
        if (idx < 0 || idx + 3 >= rgbaData!.length) return null;
        final int a = rgbaData![idx + 3];
        if (a <= 8) return null;
        return Color.fromARGB(a, rgbaData![idx], rgbaData![idx + 1], rgbaData![idx + 2]);
      }

      final Color? center = check(px, py);
      if (center != null) return center;

      final double r = (strokeWidth * 0.35).clamp(2.0, 14.0);
      return check(px + r, py) ??
          check(px - r, py) ??
          check(px, py + r) ??
          check(px, py - r);
    }

    // 2. Identify localized stroke contact points and render localized dispersion plumes
    List<Offset> currentContactPoints = <Offset>[];
    Color? contactColor;
    Offset? lastDirection;

    void flushContactCluster(Offset? exitPoint) {
      if (currentContactPoints.isEmpty || contactColor == null) {
        currentContactPoints.clear();
        contactColor = null;
        return;
      }

      final Offset pEntry = currentContactPoints.first;
      final Offset pExit = currentContactPoints.last;

      // Determine swipe direction vector
      Offset dir;
      if (exitPoint != null && (exitPoint - pEntry).distance > 1.0) {
        dir = exitPoint - pEntry;
      } else if (currentContactPoints.length >= 2 &&
          (pExit - pEntry).distance > 1.0) {
        dir = pExit - pEntry;
      } else if (lastDirection != null && lastDirection!.distance > 0.1) {
        dir = lastDirection!;
      } else {
        dir = const Offset(1.0, 0.0);
      }

      final double dirLen = dir.distance;
      final Offset u = dirLen > 0.001 ? dir / dirLen : const Offset(1.0, 0.0);
      final Offset n = Offset(-u.dy, u.dx); // Normal perpendicular vector

      // Dynamic plume spread distance beyond stroke exit
      final double swipeDist = exitPoint != null ? (exitPoint - pExit).distance : 0.0;
      final double spreadDistance = (swipeDist > 10.0
              ? (swipeDist * 1.15).clamp(28.0, 120.0)
              : (strokeWidth * (1.9 + strength * 1.5)).clamp(28.0, 95.0));

      final Offset pEnd = pExit + u * spreadDistance;
      final double totalLength = (pEnd - pEntry).distance;
      final double exitDist = (pExit - pEntry).distance;
      final double tExit = totalLength > 0.001 ? (exitDist / totalLength).clamp(0.12, 0.38) : 0.25;

      // A. Soft angled cut across the stroke along the swipe path
      final Path contactPath = Path();
      contactPath.moveTo(pEntry.dx, pEntry.dy);
      for (int i = 1; i < currentContactPoints.length; i++) {
        contactPath.lineTo(currentContactPoints[i].dx, currentContactPoints[i].dy);
      }
      if (currentContactPoints.length == 1) {
        contactPath.addOval(Rect.fromCircle(center: pEntry, radius: strokeWidth * 0.45));
      }

      final Paint localErasePaint = Paint()
        ..blendMode = BlendMode.dstOut
        ..color = Colors.black.withValues(alpha: 0.96)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 1.15
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, (strokeWidth * 0.18).clamp(1.5, 4.5));
      canvas.drawPath(contactPath, localErasePaint);

      // B. Draw continuous, seamless wet-paint drag from pEntry through pExit into trailing brush plume
      final double baseWidth = (strokeWidth * 1.05).clamp(3.5, 55.0);
      final double tipWidth = (strokeWidth * 1.25).clamp(4.5, 65.0);
      final double plumeBlur = (strokeWidth * 0.25).clamp(2.5, 8.0);

      final Path fanPath = Path()
        ..moveTo(pEntry.dx - n.dx * (baseWidth * 0.5), pEntry.dy - n.dy * (baseWidth * 0.5))
        ..lineTo(pEnd.dx - n.dx * (tipWidth * 0.5), pEnd.dy - n.dy * (tipWidth * 0.5))
        ..quadraticBezierTo(
          pEnd.dx + u.dx * (tipWidth * 0.35),
          pEnd.dy + u.dy * (tipWidth * 0.35),
          pEnd.dx + n.dx * (tipWidth * 0.5),
          pEnd.dy + n.dy * (tipWidth * 0.5),
        )
        ..lineTo(pEntry.dx + n.dx * (baseWidth * 0.5), pEntry.dy + n.dy * (baseWidth * 0.5))
        ..close();

      final Paint fanPaint = Paint()
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, plumeBlur)
        ..shader = ui.Gradient.linear(
          pEntry,
          pEnd,
          <Color>[
            contactColor!.withValues(alpha: 0.0), // 100% clean at entry (zero halo on background)
            contactColor!.withValues(alpha: 0.18), // Soft grey gradient inside stroke gap
            contactColor!.withValues(alpha: (0.82 + strength * 0.14).clamp(0.70, 0.95)), // Deep rich wet paint at exit
            contactColor!.withValues(alpha: (0.45 + strength * 0.10).clamp(0.28, 0.55)), // Streamlined plume body
            contactColor!.withValues(alpha: (0.12 + strength * 0.06).clamp(0.04, 0.18)), // Soft tip taper
            contactColor!.withValues(alpha: 0.0), // Faded tip
          ],
          <double>[
            0.0,
            tExit * 0.5,
            tExit,
            tExit + (1.0 - tExit) * 0.38,
            tExit + (1.0 - tExit) * 0.78,
            1.0,
          ],
        );

      canvas.drawPath(fanPath, fanPaint);

      // C. Central spine core for natural dense wet-paint flow directly from stroke exit
      final double spineLen = spreadDistance * 0.70;
      final Offset pSpineEnd = pExit + u * spineLen;
      final Path spinePath = Path()
        ..moveTo(pEntry.dx + u.dx * (exitDist * 0.4), pEntry.dy + u.dy * (exitDist * 0.4))
        ..lineTo(pSpineEnd.dx, pSpineEnd.dy);

      final Paint spinePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = baseWidth * 0.75
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, (strokeWidth * 0.16).clamp(1.5, 4.5))
        ..shader = ui.Gradient.linear(
          pEntry + u * (exitDist * 0.4),
          pSpineEnd,
          <Color>[
            contactColor!.withValues(alpha: 0.12),
            contactColor!.withValues(alpha: (0.65 + strength * 0.16).clamp(0.50, 0.85)),
            contactColor!.withValues(alpha: (0.18 + strength * 0.08).clamp(0.06, 0.24)),
            contactColor!.withValues(alpha: 0.0),
          ],
          <double>[0.0, 0.30, 0.75, 1.0],
        );

      canvas.drawPath(spinePath, spinePaint);

      currentContactPoints.clear();
      contactColor = null;
    }

    for (int k = 0; k < stamps.length; k++) {
      final Offset pt = stamps[k];
      if (k > 0) {
        lastDirection = pt - stamps[k - 1];
      }
      final Color? under = sampleBrush(pt.dx, pt.dy);

      if (under != null) {
        // Touching stroke paint
        contactColor = (contactColor == null) ? under : Color.lerp(contactColor, under, 0.35);
        currentContactPoints.add(pt);
      } else {
        // Exited stroke into empty canvas space -> flush local spread
        if (currentContactPoints.isNotEmpty) {
          flushContactCluster(pt);
        }
      }
    }

    // Flush any pending contact cluster at end of gesture
    flushContactCluster(stamps.last);
  }

  @override
  SmudgeContent copy() => SmudgeContent.data(
        points: List.from(points),
        strength: strength,
        paint: paint.copyWith(),
        image: image,
        rgbaData: rgbaData,
        rgbaWidth: rgbaWidth,
        rgbaHeight: rgbaHeight,
        onRepaint: onRepaint,
      )..cachedBase64Image = cachedBase64Image;

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'points': points.map((e) => e.toJson()).toList(),
      'strength': strength,
      'paint': paint.toJson(),
      'imageDataBase64': cachedBase64Image,
    };
  }

  @override
  Future<void> prepareExport() async {
    if (image != null && cachedBase64Image == null) {
      final ByteData? byteData = await image!.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        cachedBase64Image = base64Encode(pngBytes);
      }
    }
  }
}
