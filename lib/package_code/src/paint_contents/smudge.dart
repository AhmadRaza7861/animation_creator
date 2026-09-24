import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';
import 'paint_content.dart';

/// Touch point record for smudge gesture serialization
class SmudgePoint {
  const SmudgePoint(this.point, this.delta, [this.pressure = 1.0]);

  final Offset point;
  final Offset delta;
  final double pressure;

  Map<String, dynamic> toJson() => {
        'point': point.toJson(),
        'delta': delta.toJson(),
        'pressure': pressure,
      };

  factory SmudgePoint.fromJson(Map<String, dynamic> json) => SmudgePoint(
        jsonToOffset(json['point']),
        jsonToOffset(json['delta']),
        (json['pressure'] as num?)?.toDouble() ?? 1.0,
      );
}

/// Ultra-Fast Professional Digital Painting Smudge Engine
///
/// Performance Optimizations:
/// - Inlined fast subpixel bilinear sampling with zero function-call overhead.
/// - Inlined premultiplied alpha color blending.
/// - Early-exit optimizations for transparent / uniform pixel patches.
/// - Optimal step pacing (20-25% brush radius) for 60-120 FPS continuous smear.
/// - Throttled GPU texture uploads with coalesced frame decoding.
/// - Reusable typed working buffers to eliminate GC allocations in touch loop.
class SmudgeContent extends PaintContent {
  SmudgeContent({this.strength = 0.75});

  SmudgeContent.data({
    required this.points,
    required this.strength,
    required Paint paint,
    this.image,
    this.canvasSize,
    this.onRepaint,
    Uint8List? rgbaData,
    int? rgbaWidth,
    int? rgbaHeight,
  }) : super.paint(paint) {
    if (rgbaData != null && rgbaWidth != null && rgbaHeight != null) {
      setRgbaData(rgbaData, rgbaWidth, rgbaHeight);
    }
  }

  factory SmudgeContent.fromJson(Map<String, dynamic> data) {
    final content = SmudgeContent.data(
      points: (data['points'] as List<dynamic>?)
              ?.map((e) => SmudgePoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      strength: (data['strength'] as num?)?.toDouble() ?? 0.75,
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
      image: null,
    );
    if (data['imageDataBase64'] != null) {
      content.cachedBase64Image = data['imageDataBase64'] as String;
    }
    return content;
  }

  /// Touch point record for smudge gesture serialization
  List<SmudgePoint> points = [];
  double strength;
  Size? canvasSize;
  VoidCallback? onRepaint;

  /// Committed raster image snapshot
  ui.Image? image;

  /// Live hardware-accelerated texture for real-time display
  ui.Image? liveImage;

  /// Working 32-bit RGBA pixel buffer (1:1 image coordinates)
  Uint32List? _pixels;
  int _width = 0;
  int _height = 0;

  int? get rgbaWidth => _width > 0 ? _width : null;
  int? get rgbaHeight => _height > 0 ? _height : null;
  Uint8List? get rgbaData => _pixels?.buffer.asUint8List();

  String? cachedBase64Image;

  final List<Offset> _pendingPoints = [];
  final List<double> _pendingPressures = [];
  int _processedIndex = 0;

  /// Moving wet-paint carrier reservoir buffer (allocated on demand during touch)
  Uint32List _reservoir = Uint32List(0);
  int _reservoirDim = 0;
  bool _reservoirInitialized = false;

  /// Reusable local patch buffer to prevent memory allocations in touch loop
  static Uint32List _patchBuffer = Uint32List(256 * 256);

  bool _isDecoding = false;
  bool _needsDecode = false;

  @override
  String get contentType => 'SmudgeContent';

  /// Initializes the working pixel buffer from an existing ui.Image
  void setImageData(ui.Image imageData, [Size? size]) {
    image = imageData;
    liveImage ??= imageData;
    _width = imageData.width;
    _height = imageData.height;
    if (size != null) {
      canvasSize = size;
    }

    imageData.toByteData(format: ui.ImageByteFormat.rawRgba).then((ByteData? data) {
      if (data != null) {
        if (_pixels == null) {
          final Uint32List u32 = data.buffer.asUint32List(data.offsetInBytes, data.lengthInBytes ~/ 4);
          _pixels = Uint32List.fromList(u32);
          _width = imageData.width;
          _height = imageData.height;
          _processPendingSegments();
          _scheduleLiveImageDecode();
        }
      }
    });
  }

  /// Sets raw 8-bit RGBA data into the 32-bit working pixel buffer
  void setRgbaData(Uint8List data, int width, int height, [Size? size]) {
    _width = width;
    _height = height;
    if (size != null) {
      canvasSize = size;
    }
    final ByteData bd = ByteData.sublistView(data);
    _pixels = Uint32List.fromList(bd.buffer.asUint32List(bd.offsetInBytes, data.lengthInBytes ~/ 4));
    _processPendingSegments();
    _scheduleLiveImageDecode();
  }

  /// Sets raw 32-bit RGBA data directly
  void setRgba32Data(Uint32List data, int width, int height, [Size? size]) {
    _width = width;
    _height = height;
    if (size != null) {
      canvasSize = size;
    }
    _pixels = Uint32List.fromList(data);
    _processPendingSegments();
    _scheduleLiveImageDecode();
  }

  @override
  void startDraw(Offset startPoint) {
    startDrawWithPressure(startPoint, 1.0);
  }

  void startDrawWithPressure(Offset startPoint, double pressure) {
    points.clear();
    _pendingPoints.clear();
    _pendingPressures.clear();
    _processedIndex = 0;
    _reservoirInitialized = false;

    final double p = pressure > 0 ? pressure : 1.0;
    points.add(SmudgePoint(startPoint, Offset.zero, p));
    _pendingPoints.add(startPoint);
    _pendingPressures.add(p);

    if (_pixels != null && _width > 0 && _height > 0) {
      _initReservoirAt(startPoint);
    }
  }

  @override
  void drawing(Offset nowPoint) {
    drawingWithPressure(nowPoint, 1.0);
  }

  void drawingWithPressure(Offset nowPoint, double pressure) {
    if (_pendingPoints.isEmpty) {
      startDrawWithPressure(nowPoint, pressure);
      return;
    }

    final Offset lastPt = _pendingPoints.last;
    final Offset delta = nowPoint - lastPt;
    if (delta.distance < 0.25) return;

    final double effectivePressure = pressure > 0 ? pressure : 1.0;
    points.add(SmudgePoint(nowPoint, delta, effectivePressure));
    _pendingPoints.add(nowPoint);
    _pendingPressures.add(effectivePressure);

    if (_pixels != null && _width > 0 && _height > 0) {
      _processPendingSegments();
      _scheduleLiveImageDecode();
    }
  }

  /// Releases unmanaged 32-bit pixel buffers, reservoir, and live textures once superseded in history
  void releaseWorkingBuffers() {
    _pixels = null;
    _reservoir = Uint32List(0);
    _reservoirDim = 0;
    _reservoirInitialized = false;
    liveImage = null;
  }

  /// Finalizes the smudge stroke and produces the final raster image
  void finalizeStroke() {
    _processPendingSegments();
    if (liveImage != null) {
      image = liveImage;
    }
    _scheduleLiveImageDecode(forceImmediate: true);
    _reservoir = Uint32List(0);
    _reservoirDim = 0;
    _reservoirInitialized = false;
  }

  double _getScaleX() => (_width > 0 && canvasSize != null && canvasSize!.width > 0)
      ? _width / canvasSize!.width
      : 1.0;

  double _getScaleY() => (_height > 0 && canvasSize != null && canvasSize!.height > 0)
      ? _height / canvasSize!.height
      : 1.0;

  /// Initializes the wet-paint carrier reservoir from pixels under the brush on touchdown
  void _initReservoirAt(Offset pt) {
    if (_pixels == null || _width <= 0 || _height <= 0) return;
    final double scaleX = _getScaleX();
    final double scaleY = _getScaleY();
    final double px = pt.dx * scaleX;
    final double py = pt.dy * scaleY;

    final double strokeWidth = paint.strokeWidth * scaleX;
    final double radius = math.max(2.0, strokeWidth * 0.5);
    final int dim = math.max(3, (2 * radius + 1).ceil());

    if (_reservoir.length < dim * dim) {
      _reservoir = Uint32List(dim * dim * 2);
    }
    _reservoirDim = dim;

    final Uint32List pixels = _pixels!;
    final int w = _width;
    final int h = _height;

    for (int v = 0; v < dim; v++) {
      final double sampleY = py + (v - radius);
      final int rowIdx = v * dim;
      for (int u = 0; u < dim; u++) {
        final double sampleX = px + (u - radius);
        _reservoir[rowIdx + u] = _sampleBilinearFast(pixels, w, h, sampleX, sampleY);
      }
    }
    _reservoirInitialized = true;
  }

  /// Processes any queued touch segments that haven't been applied yet
  void _processPendingSegments() {
    if (_pixels == null || _width <= 0 || _height <= 0) return;
    if (_pendingPoints.isEmpty) return;

    if (!_reservoirInitialized && _pendingPoints.isNotEmpty) {
      _initReservoirAt(_pendingPoints.first);
    }

    if (_pendingPoints.length <= 1) return;

    final double scaleX = _getScaleX();
    final double scaleY = _getScaleY();

    while (_processedIndex < _pendingPoints.length - 1) {
      final Offset p0 = _pendingPoints[_processedIndex];
      final Offset p1 = _pendingPoints[_processedIndex + 1];
      final double pr0 = _pendingPressures[_processedIndex];
      final double pr1 = _pendingPressures[_processedIndex + 1];

      final Offset px0 = Offset(p0.dx * scaleX, p0.dy * scaleY);
      final Offset px1 = Offset(p1.dx * scaleX, p1.dy * scaleY);

      _applySmudgeSegment(px0, px1, pr0, pr1, scaleX);
      _processedIndex++;
    }
  }

  /// Applies high-speed wet-paint fluid displacement and reservoir smear
  void _applySmudgeSegment(
    Offset p0,
    Offset p1,
    double pressure0,
    double pressure1,
    double scale,
  ) {
    final Uint32List pixels = _pixels!;
    final int w = _width;
    final int h = _height;

    final double baseStrokeWidth = paint.strokeWidth * scale;
    final double baseRadius = math.max(2.0, baseStrokeWidth * 0.5);

    final Offset dir = p1 - p0;
    final double dist = dir.distance;
    if (dist < 0.1) return;

    // Optimized step spacing: 20-22% of brush radius for smooth continuous blending with high performance
    final double stepSize = math.max(2.0, baseRadius * 0.22);
    final int numSteps = (dist / stepSize).ceil().clamp(1, 60);

    Offset prevPt = p0;
    double prevPr = pressure0;

    for (int s = 1; s <= numSteps; s++) {
      final double tTo = s / numSteps;
      final Offset currPt = Offset.lerp(p0, p1, tTo)!;
      final double currPr = ui.lerpDouble(pressure0, pressure1, tTo) ?? 1.0;

      final double avgPressure = (prevPr + currPr) * 0.5;
      final double radius = math.max(2.0, baseRadius * avgPressure);
      final double radiusSq = radius * radius;
      final double invRadiusSq = 1.0 / radiusSq;

      final Offset stepDelta = currPt - prevPt;
      final double stepDist = stepDelta.distance;

      final double cx = currPt.dx;
      final double cy = currPt.dy;

      final double effStrength = (strength * avgPressure).clamp(0.05, 1.0);

      // Clamped bounding box for current step
      final int minX = (cx - radius - 0.5).floor().clamp(0, w - 1);
      final int maxX = (cx + radius + 0.5).ceil().clamp(0, w - 1);
      final int minY = (cy - radius - 0.5).floor().clamp(0, h - 1);
      final int maxY = (cy + radius + 0.5).ceil().clamp(0, h - 1);

      final int patchW = maxX - minX + 1;
      final int patchH = maxY - minY + 1;
      final int patchSize = patchW * patchH;

      if (_patchBuffer.length < patchSize) {
        _patchBuffer = Uint32List(patchSize * 2);
      }

      final int resDim = _reservoirDim;
      final double resRadius = (resDim - 1) * 0.5;

      // 1. Compute Local Dual-Action Smear (Advection + Reservoir Mixing)
      for (int py = minY; py <= maxY; py++) {
        final double dy = py - cy;
        final double dySq = dy * dy;
        final int localRow = (py - minY) * patchW;
        final int canvasRow = py * w;

        for (int px = minX; px <= maxX; px++) {
          final double dx = px - cx;
          final double distSq = dx * dx + dySq;
          final int localIdx = localRow + (px - minX);

          if (distSq >= radiusSq) {
            _patchBuffer[localIdx] = pixels[canvasRow + px];
            continue;
          }

          // Smooth polynomial falloff mask: (1 - (r/R)^2)^2
          final double uSq = distSq * invRadiusSq;
          final double oneMinusUSq = 1.0 - uSq;
          final double falloff = oneMinusUSq * oneMinusUSq;

          final int currentDstColor = pixels[canvasRow + px];

          // A. Pixel Advection (Deformation / Dragging)
          final double advectFactor = (falloff * effStrength).clamp(0.0, 1.0);
          final double srcSampleX = px - stepDelta.dx * (advectFactor * 1.5 + 0.5);
          final double srcSampleY = py - stepDelta.dy * (advectFactor * 1.5 + 0.5);

          final int advectedColor = _sampleBilinearFast(pixels, w, h, srcSampleX, srcSampleY);

          // B. Wet Reservoir Sampling & Blending
          int finalColor = currentDstColor;

          if (resDim > 0 && _reservoirInitialized) {
            final double resU = (dx + resRadius).clamp(0.0, (resDim - 1).toDouble());
            final double resV = (dy + resRadius).clamp(0.0, (resDim - 1).toDouble());
            final int carriedColor = _sampleReservoirBilinearFast(_reservoir, resDim, resU, resV);

            // Blend advected paint with carried reservoir pigment
            final double reservoirWeight = ((1.0 - effStrength * 0.4) * 0.5).clamp(0.1, 0.7);
            final int blendedPaint = _blendColorsFast(advectedColor, carriedColor, reservoirWeight);

            // Deposit result onto canvas with smooth falloff
            final double depositWeight = (falloff * (0.6 + effStrength * 0.4)).clamp(0.0, 1.0);
            finalColor = _blendColorsFast(currentDstColor, blendedPaint, depositWeight);
          } else {
            // Pure advection when reservoir is not yet populated
            final double depositWeight = (falloff * effStrength).clamp(0.0, 1.0);
            finalColor = _blendColorsFast(currentDstColor, advectedColor, depositWeight);
          }

          _patchBuffer[localIdx] = finalColor;
        }
      }

      // 2. Commit Patch Buffer to Canvas Buffer
      for (int py = minY; py <= maxY; py++) {
        final int localRow = (py - minY) * patchW;
        final int canvasRow = py * w;
        for (int px = minX; px <= maxX; px++) {
          pixels[canvasRow + px] = _patchBuffer[localRow + (px - minX)];
        }
      }

      // 3. Dynamic Pickup into Wet Reservoir for continuous paint carry (updated on step intervals)
      if (resDim > 0 && _reservoirInitialized && stepDist > 0.05 && (s == numSteps || s % 2 == 0)) {
        for (int v = 0; v < resDim; v++) {
          final double dy = v - resRadius;
          final double dySq = dy * dy;
          final double sampleY = cy + dy;
          final int rowIdx = v * resDim;

          for (int u = 0; u < resDim; u++) {
            final double dx = u - resRadius;
            final double distSq = dx * dx + dySq;

            if (distSq < radiusSq) {
              final double sampleX = cx + dx;
              final double uSq = distSq * invRadiusSq;
              final double falloff = (1.0 - uSq) * (1.0 - uSq);

              final int canvasColor = _sampleBilinearFast(pixels, w, h, sampleX, sampleY);
              final int canvasA = (canvasColor >> 24) & 0xFF;

              if (canvasA > 5) {
                final int oldRes = _reservoir[rowIdx + u];
                final double pickupRate = ((1.0 - effStrength * 0.6) * 0.45).clamp(0.1, 0.8);
                final double mixWeight = (falloff * pickupRate).clamp(0.0, 1.0);
                _reservoir[rowIdx + u] = _blendColorsFast(oldRes, canvasColor, mixWeight);
              }
            }
          }
        }
      }

      prevPt = currPt;
      prevPr = currPr;
    }
  }

  /// Fast subpixel bilinear sampling with inlined premultiplied alpha weighting
  static int _sampleBilinearFast(Uint32List pixels, int width, int height, double x, double y) {
    if (x < 0.0) x = 0.0;
    if (y < 0.0) y = 0.0;
    if (x > width - 1.0) x = width - 1.0;
    if (y > height - 1.0) y = height - 1.0;

    final int x0 = x.toInt();
    final int y0 = y.toInt();
    final int x1 = (x0 + 1 < width) ? x0 + 1 : x0;
    final int y1 = (y0 + 1 < height) ? y0 + 1 : y0;

    final int c00 = pixels[y0 * width + x0];
    final int c10 = pixels[y0 * width + x1];
    final int c01 = pixels[y1 * width + x0];
    final int c11 = pixels[y1 * width + x1];

    // Fast path: completely transparent or uniform colors
    if (c00 == 0 && c10 == 0 && c01 == 0 && c11 == 0) return 0;
    if (c00 == c10 && c00 == c01 && c00 == c11) return c00;

    final double fx = x - x0;
    final double fy = y - y0;
    final double ifx = 1.0 - fx;
    final double ify = 1.0 - fy;

    final double w00 = ifx * ify;
    final double w10 = fx * ify;
    final double w01 = ifx * fy;
    final double w11 = fx * fy;

    final int a00 = (c00 >> 24) & 0xFF;
    final int a10 = (c10 >> 24) & 0xFF;
    final int a01 = (c01 >> 24) & 0xFF;
    final int a11 = (c11 >> 24) & 0xFF;

    final double a = a00 * w00 + a10 * w10 + a01 * w01 + a11 * w11;
    if (a <= 1.5) return 0;

    final double invA = 1.0 / a;
    final double r = ((c00 & 0xFF) * a00 * w00 +
            (c10 & 0xFF) * a10 * w10 +
            (c01 & 0xFF) * a01 * w01 +
            (c11 & 0xFF) * a11 * w11) *
        invA;
    final double g = (((c00 >> 8) & 0xFF) * a00 * w00 +
            ((c10 >> 8) & 0xFF) * a10 * w10 +
            ((c01 >> 8) & 0xFF) * a01 * w01 +
            ((c11 >> 8) & 0xFF) * a11 * w11) *
        invA;
    final double b = (((c00 >> 16) & 0xFF) * a00 * w00 +
            ((c10 >> 16) & 0xFF) * a10 * w10 +
            ((c01 >> 16) & 0xFF) * a01 * w01 +
            ((c11 >> 16) & 0xFF) * a11 * w11) *
        invA;

    final int rInt = r.round().clamp(0, 255);
    final int gInt = g.round().clamp(0, 255);
    final int bInt = b.round().clamp(0, 255);
    final int aInt = a.round().clamp(0, 255);

    return (aInt << 24) | (bInt << 16) | (gInt << 8) | rInt;
  }

  /// Fast subpixel bilinear sampling from wet-paint reservoir
  static int _sampleReservoirBilinearFast(Uint32List res, int dim, double x, double y) {
    if (x < 0.0) x = 0.0;
    if (y < 0.0) y = 0.0;
    if (x > dim - 1.0) x = dim - 1.0;
    if (y > dim - 1.0) y = dim - 1.0;

    final int x0 = x.toInt();
    final int y0 = y.toInt();
    final int x1 = (x0 + 1 < dim) ? x0 + 1 : x0;
    final int y1 = (y0 + 1 < dim) ? y0 + 1 : y0;

    final int c00 = res[y0 * dim + x0];
    final int c10 = res[y0 * dim + x1];
    final int c01 = res[y1 * dim + x0];
    final int c11 = res[y1 * dim + x1];

    if (c00 == 0 && c10 == 0 && c01 == 0 && c11 == 0) return 0;
    if (c00 == c10 && c00 == c01 && c00 == c11) return c00;

    final double fx = x - x0;
    final double fy = y - y0;
    final double ifx = 1.0 - fx;
    final double ify = 1.0 - fy;

    final double w00 = ifx * ify;
    final double w10 = fx * ify;
    final double w01 = ifx * fy;
    final double w11 = fx * fy;

    final int a00 = (c00 >> 24) & 0xFF;
    final int a10 = (c10 >> 24) & 0xFF;
    final int a01 = (c01 >> 24) & 0xFF;
    final int a11 = (c11 >> 24) & 0xFF;

    final double a = a00 * w00 + a10 * w10 + a01 * w01 + a11 * w11;
    if (a <= 1.5) return 0;

    final double invA = 1.0 / a;
    final double r = ((c00 & 0xFF) * a00 * w00 +
            (c10 & 0xFF) * a10 * w10 +
            (c01 & 0xFF) * a01 * w01 +
            (c11 & 0xFF) * a11 * w11) *
        invA;
    final double g = (((c00 >> 8) & 0xFF) * a00 * w00 +
            ((c10 >> 8) & 0xFF) * a10 * w10 +
            ((c01 >> 8) & 0xFF) * a01 * w01 +
            ((c11 >> 8) & 0xFF) * a11 * w11) *
        invA;
    final double b = (((c00 >> 16) & 0xFF) * a00 * w00 +
            ((c10 >> 16) & 0xFF) * a10 * w10 +
            ((c01 >> 16) & 0xFF) * a01 * w01 +
            ((c11 >> 16) & 0xFF) * a11 * w11) *
        invA;

    final int rInt = r.round().clamp(0, 255);
    final int gInt = g.round().clamp(0, 255);
    final int bInt = b.round().clamp(0, 255);
    final int aInt = a.round().clamp(0, 255);

    return (aInt << 24) | (bInt << 16) | (gInt << 8) | rInt;
  }

  /// Fast inlined premultiplied alpha color blending
  static int _blendColorsFast(int cDst, int cSrc, double weight) {
    if (weight <= 0.0) return cDst;
    if (weight >= 1.0) return cSrc;
    if (cDst == cSrc) return cDst;

    final int aD = (cDst >> 24) & 0xFF;
    final int aS = (cSrc >> 24) & 0xFF;

    if (aD == 0 && aS == 0) return 0;

    final double invW = 1.0 - weight;
    final double aOut = aD * invW + aS * weight;
    if (aOut < 2.0) return 0;

    final int rD = cDst & 0xFF;
    final int gD = (cDst >> 8) & 0xFF;
    final int bD = (cDst >> 16) & 0xFF;

    final int rS = cSrc & 0xFF;
    final int gS = (cSrc >> 8) & 0xFF;
    final int bS = (cSrc >> 16) & 0xFF;

    final double invA = 1.0 / aOut;
    final double rOut = (rD * aD * invW + rS * aS * weight) * invA;
    final double gOut = (gD * aD * invW + gS * aS * weight) * invA;
    final double bOut = (bD * aD * invW + bS * aS * weight) * invA;

    final int rInt = rOut.round().clamp(0, 255);
    final int gInt = gOut.round().clamp(0, 255);
    final int bInt = bOut.round().clamp(0, 255);
    final int aInt = aOut.round().clamp(0, 255);

    return (aInt << 24) | (bInt << 16) | (gInt << 8) | rInt;
  }

  /// Schedules an asynchronous decode to produce live ui.Image for real-time 60-120fps display
  void _scheduleLiveImageDecode({bool forceImmediate = false}) {
    if (_isDecoding && !forceImmediate) {
      _needsDecode = true;
      return;
    }

    if (_pixels == null || _width <= 0 || _height <= 0) return;

    _isDecoding = true;
    final Uint8List rawBytes = _pixels!.buffer.asUint8List();

    ui.decodeImageFromPixels(
      rawBytes,
      _width,
      _height,
      ui.PixelFormat.rgba8888,
      (ui.Image decoded) {
        liveImage = decoded;
        image = decoded;
        _isDecoding = false;
        onRepaint?.call();

        if (_needsDecode) {
          _needsDecode = false;
          _scheduleLiveImageDecode();
        }
      },
    );
  }

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    final ui.Image? targetImage = liveImage ?? image;
    if (targetImage != null) {
      canvas.drawImageRect(
        targetImage,
        Rect.fromLTWH(0, 0, targetImage.width.toDouble(), targetImage.height.toDouble()),
        Offset.zero & size,
        Paint()..filterQuality = ui.FilterQuality.high,
      );
    }
  }

  @override
  Path getPath() {
    final Path path = Path();
    if (points.isEmpty) {
      if (canvasSize != null && canvasSize!.width > 0 && canvasSize!.height > 0) {
        path.addRect(Offset.zero & canvasSize!);
      }
      return path;
    }
    path.moveTo(points.first.point.dx, points.first.point.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].point.dx, points[i].point.dy);
    }
    return path;
  }

  @override
  SmudgeContent copy() => SmudgeContent.data(
        points: List.from(points),
        strength: strength,
        paint: paint.copyWith(),
        image: image ?? liveImage,
        canvasSize: canvasSize,
        onRepaint: onRepaint,
      )
        ..liveImage = liveImage ?? image
        .._pixels = _pixels
        .._width = _width
        .._height = _height
        ..cachedBase64Image = cachedBase64Image;

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
    final ui.Image? targetImg = image ?? liveImage;
    if (targetImg != null && cachedBase64Image == null) {
      final ByteData? byteData = await targetImg.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        cachedBase64Image = base64Encode(pngBytes);
      }
    }
  }
}
