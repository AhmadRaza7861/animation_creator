import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Bounded LRU cache for baked GPU `ui.Image` brush stamps.
/// Disposes evicted textures automatically to keep VRAM bounded.
class BoundedImageCache<K> {
  BoundedImageCache({this.maxEntries = 32});

  final int maxEntries;
  final LinkedHashMap<K, ui.Image> _entries = LinkedHashMap<K, ui.Image>();

  /// Returns a cached image for [key] and promotes it as most recently used.
  ui.Image? get(K key) {
    final ui.Image? existing = _entries.remove(key);
    if (existing != null) {
      _entries[key] = existing;
    }
    return existing;
  }

  /// Stores [image] under [key], evicting and disposing least-recently-used entries.
  void put(K key, ui.Image image) {
    final ui.Image? previous = _entries.remove(key);
    if (previous != null && previous != image) {
      try {
        previous.dispose();
      } catch (_) {}
    }
    _entries[key] = image;
    _evictOverflow();
  }

  void _evictOverflow() {
    while (_entries.length > maxEntries) {
      final K oldestKey = _entries.keys.first;
      final ui.Image? evicted = _entries.remove(oldestKey);
      try {
        evicted?.dispose();
      } catch (_) {}
    }
  }

  /// Returns a cached image for [key], or creates and caches it with [baker].
  /// Returns `null` if baking fails in an environment without raster backing.
  ui.Image? getOrBake(K key, ui.Image? Function() baker) {
    final ui.Image? existing = get(key);
    if (existing != null) {
      return existing;
    }

    final ui.Image? created = baker();
    if (created == null) {
      return null;
    }

    _entries[key] = created;
    _evictOverflow();
    return created;
  }

  /// Disposes and clears all cached stamp images.
  void clear() {
    for (final ui.Image img in _entries.values) {
      try {
        img.dispose();
      } catch (_) {}
    }
    _entries.clear();
  }
}

/// Shared caches for procedural soft-circle and 3D-shaded sphere stamp images.
class ProceduralStampCaches {
  ProceduralStampCaches._();

  static const double softTileSize = 144.0;
  static const double softDrawRadius = 48.0;

  static const double sphereTileSize = 96.0;

  static final BoundedImageCache<int> softCircleCache =
      BoundedImageCache<int>(maxEntries: 20);
  static final BoundedImageCache<int> shadedSphereCache =
      BoundedImageCache<int>(maxEntries: 24);

  /// Bakes or returns a white-alpha feathered circle stamp for [softness].
  static ui.Image? getSoftCircleStamp(double softness) {
    final int q = (softness.clamp(0.05, 1.0) * 20).round();
    return softCircleCache.getOrBake(q, () {
      try {
        final double s = softTileSize;
        final double c = s / 2;
        final double r = softDrawRadius;
        final double effectiveSoftness = (q / 20.0).clamp(0.05, 1.0);
        final double innerStop = (1.0 - effectiveSoftness).clamp(0.0, 0.9);
        final ui.PictureRecorder rec = ui.PictureRecorder();
        final Canvas canvas = Canvas(rec, Rect.fromLTWH(0, 0, s, s));
        final Paint p = Paint()
          ..isAntiAlias = true
          ..shader = ui.Gradient.radial(
            Offset(c, c),
            r,
            <Color>[Colors.white, Colors.white, const Color(0x00FFFFFF)],
            <double>[0.0, innerStop, 1.0],
          );
        canvas.drawCircle(Offset(c, c), r, p);
        final ui.Picture pic = rec.endRecording();
        final ui.Image img = pic.toImageSync(s.toInt(), s.toInt());
        pic.dispose();
        return img;
      } catch (_) {
        return null;
      }
    });
  }

  static Color _lighten(Color c, double amount) {
    final HSLColor hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  static Color _darken(Color c, double amount) {
    final HSLColor hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  /// Bakes or returns a 3D specular-shaded sphere stamp for [baseColor].
  static ui.Image? getShadedSphereStamp(Color baseColor) {
    final int key = baseColor.toARGB32();
    return shadedSphereCache.getOrBake(key, () {
      try {
        final double s = sphereTileSize;
        final double c = s / 2;
        final double r = c - 1.0;
        final Offset center = Offset(c, c);
        final ui.PictureRecorder rec = ui.PictureRecorder();
        final Canvas canvas = Canvas(rec, Rect.fromLTWH(0, 0, s, s));
        final Paint p = Paint()
          ..isAntiAlias = true
          ..shader = ui.Gradient.radial(
            center + Offset(-r * 0.35, -r * 0.35),
            r * 1.6,
            <Color>[_lighten(baseColor, 0.34), baseColor, _darken(baseColor, 0.26)],
            <double>[0.0, 0.55, 1.0],
          );
        canvas.drawCircle(center, r, p);
        final ui.Picture pic = rec.endRecording();
        final ui.Image img = pic.toImageSync(s.toInt(), s.toInt());
        pic.dispose();
        return img;
      } catch (_) {
        return null;
      }
    });
  }

  static void clearAll() {
    softCircleCache.clear();
    shadedSphereCache.clear();
  }
}

/// Fast batched sprite stamping using `Canvas.drawAtlas` (single GPU draw call)
/// when non-mirrored, with clean `drawImageRect` fallback for axis mirror flips.
class AtlasStampDrawer {
  AtlasStampDrawer._();

  static final Paint _atlasPaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.low;

  static final Paint _mirroredPaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.low;

  /// Stamps [stamp] at each `(xs[i], ys[i])` rotated by `angles[i]`.
  ///
  /// When [tint] is provided, modulates a white-alpha stamp image by [tint].
  /// When [tint] is null, draws pre-colored stamp pixels directly (`srcOver`).
  static void drawBatch({
    required Canvas canvas,
    required ui.Image stamp,
    required double srcSize,
    required double targetRadius,
    required double stampRefRadius,
    required List<double> xs,
    required List<double> ys,
    required List<double> angles,
    int start = 0,
    int? end,
    Color? tint,
    bool flipX = false,
    bool flipY = false,
  }) {
    final int count = (end ?? xs.length) - start;
    if (count <= 0 || targetRadius <= 0 || stampRefRadius <= 0) {
      return;
    }

    final double scale = targetRadius / stampRefRadius;
    final double anchor = srcSize / 2;
    final Rect srcRect = Rect.fromLTWH(0, 0, srcSize, srcSize);

    // Axis reflection requires negative X or Y scale, which RSTransform does not
    // represent natively. Both flipped simultaneously is simply a +pi rotation.
    if (flipX ^ flipY) {
      final Paint p = _mirroredPaint
        ..colorFilter = tint != null
            ? ColorFilter.mode(tint, BlendMode.modulate)
            : null;
      final Rect dst = Rect.fromLTWH(
        -anchor * scale,
        -anchor * scale,
        srcSize * scale,
        srcSize * scale,
      );
      final double sx = flipX ? -1.0 : 1.0;
      final double sy = flipY ? -1.0 : 1.0;
      for (int i = start; i < start + count; i++) {
        canvas.save();
        canvas.translate(xs[i], ys[i]);
        final double a = angles[i];
        if (a != 0.0) canvas.rotate(a);
        canvas.scale(sx, sy);
        canvas.drawImageRect(stamp, srcRect, dst, p);
        canvas.restore();
      }
      return;
    }

    final double angleOffset = (flipX && flipY) ? pi : 0.0;
    final List<RSTransform> transforms = List<RSTransform>.generate(
      count,
      (int idx) {
        final int i = start + idx;
        return RSTransform.fromComponents(
          rotation: angles[i] + angleOffset,
          scale: scale,
          anchorX: anchor,
          anchorY: anchor,
          translateX: xs[i],
          translateY: ys[i],
        );
      },
      growable: false,
    );
    final List<Rect> rects = List<Rect>.filled(count, srcRect, growable: false);

    if (tint != null) {
      final List<Color> colors = List<Color>.filled(count, tint, growable: false);
      canvas.drawAtlas(
        stamp,
        transforms,
        rects,
        colors,
        BlendMode.modulate,
        null,
        _atlasPaint,
      );
    } else {
      canvas.drawAtlas(
        stamp,
        transforms,
        rects,
        null,
        null,
        null,
        _atlasPaint,
      );
    }
  }
}

/// Chunked `ui.Picture` cache for procedural vector brushes so committed
/// sections of a stroke never re-run Dart path/jitter/loop logic across frames.
class ChunkedStrokeCache {
  static const int chunkSize = 16;

  final List<ui.Picture> _chunks = <ui.Picture>[];
  int _bakedEndIndex = 0;
  int _styleSignature = 0;

  // Compact packed tangent samples for frozen segments `[0 .. _committedSegEnd]`.
  final List<double> xs = <double>[];
  final List<double> ys = <double>[];
  final List<double> angles = <double>[];
  final List<double> distances = <double>[];

  // Cached tail samples (from `mid(n-2, n-1)` to `points.last`) matching `_cachedPtLen`.
  final List<double> tailXs = <double>[];
  final List<double> tailYs = <double>[];
  final List<double> tailAngles = <double>[];
  final List<double> tailDistances = <double>[];

  int _cachedPtLen = 0;
  Offset? _cachedFirst;
  Offset? _cachedFrozenLast;
  Offset? _cachedSecond;
  Offset? _cachedLast;
  double _cachedStep = 0;
  int _committedSeg = 1; // Next segment index in `1 .. n-2` to freeze.
  double _nextOffsetInSeg = 0;
  double _cumFrozenLength = 0;
  double _lastTailLength = 0;

  double get totalLength => _cumFrozenLength + _lastTailLength;

  int get frozenCount => xs.length;
  int get tailCount => tailXs.length;
  int get bakedEndIndex => _bakedEndIndex;
  List<ui.Picture> get chunks => _chunks;

  /// Ensures all tangent samples along `points` at `step` are computed
  /// incrementally. Only newly added Bezier segments are measured via Skia/Impeller.
  void ensureSamples(List<Offset> points, double step) {
    final int n = points.length;
    if (n < 2) {
      resetAll();
      return;
    }

    // Detect non-append mutations (e.g. Clear, Scale, Undo, AutoBetween) or step change.
    final bool canExtend =
        _cachedStep == step &&
        _cachedPtLen >= 2 &&
        n >= _cachedPtLen &&
        _cachedFirst == points.first &&
        _cachedSecond == points[1] &&
        (_cachedPtLen < 3 || _cachedFrozenLast == points[_cachedPtLen - 2]);

    if (!canExtend) {
      resetAll();
      _cachedStep = step;
      _cachedFirst = points.first;
      _cachedSecond = points[1];
    }

    final bool tailUnchanged =
        canExtend && n == _cachedPtLen && _cachedLast == points.last;
    if (tailUnchanged) {
      return;
    }

    if (n == 2) {
      _sampleTailLine(points[0], points[1], step);
      _cachedPtLen = 2;
      _cachedFirst = points[0];
      _cachedSecond = points[1];
      _cachedLast = points[1];
      _cachedFrozenLast = points[0];
      return;
    }

    // Freeze any newly finalized segments `k` from `_committedSeg .. n - 2`.
    // In buildSmoothPath(), segment `k` runs from `start` through `ctrl = points[k]`
    // to `mid(points[k], points[k+1])`, which is immutable for all future points.
    final int maxFrozenSeg = n - 2;
    while (_committedSeg <= maxFrozenSeg) {
      final int k = _committedSeg;
      final Offset segStart = k == 1
          ? points[0]
          : Offset(
              (points[k - 1].dx + points[k].dx) * 0.5,
              (points[k - 1].dy + points[k].dy) * 0.5,
            );
      final Offset ctrl = points[k];
      final Offset segEnd = Offset(
        (ctrl.dx + points[k + 1].dx) * 0.5,
        (ctrl.dy + points[k + 1].dy) * 0.5,
      );

      final Path segPath = Path()
        ..moveTo(segStart.dx, segStart.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, segEnd.dx, segEnd.dy);

      for (final ui.PathMetric metric in segPath.computeMetrics()) {
        final double len = metric.length;
        if (len <= 0) continue;
        double d = _nextOffsetInSeg;
        while (d <= len + 1e-6) {
          final double clampedD = d > len ? len : d;
          final ui.Tangent? t = metric.getTangentForOffset(clampedD);
          if (t != null) {
            xs.add(t.position.dx);
            ys.add(t.position.dy);
            angles.add(t.angle);
            distances.add(_cumFrozenLength + clampedD);
          }
          d += step;
        }
        _nextOffsetInSeg = (d - len).clamp(0.0, double.infinity);
        _cumFrozenLength += len;
      }
      _committedSeg++;
    }

    // Sample the tiny ephemeral tail: `mid(n-2, n-1) -> ctrl(n-2) -> points[n-1]`.
    final Offset tailCtrl = points[n - 2];
    final Offset tailLast = points[n - 1];
    final Offset tailStart = Offset(
      (tailCtrl.dx + tailLast.dx) * 0.5,
      (tailCtrl.dy + tailLast.dy) * 0.5,
    );
    _sampleTailQuadratic(tailStart, tailCtrl, tailLast, step);

    _cachedPtLen = n;
    _cachedFirst = points.first;
    _cachedFrozenLast = points[n - 2];
    _cachedLast = tailLast;
  }

  void _sampleTailLine(Offset a, Offset b, double step) {
    tailXs.clear();
    tailYs.clear();
    tailAngles.clear();
    tailDistances.clear();
    final Path seg = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy);
    double len = 0;
    for (final ui.PathMetric metric in seg.computeMetrics()) {
      len = metric.length;
      double d = 0.0;
      while (d <= len + 1e-6) {
        final double clampedD = d > len ? len : d;
        final ui.Tangent? t = metric.getTangentForOffset(clampedD);
        if (t != null) {
          tailXs.add(t.position.dx);
          tailYs.add(t.position.dy);
          tailAngles.add(t.angle);
          tailDistances.add(clampedD);
        }
        d += step;
      }
    }
    _lastTailLength = len;
  }

  void _sampleTailQuadratic(Offset start, Offset ctrl, Offset end, double step) {
    tailXs.clear();
    tailYs.clear();
    tailAngles.clear();
    tailDistances.clear();
    final Path seg = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
    double len = 0;
    for (final ui.PathMetric metric in seg.computeMetrics()) {
      len = metric.length;
      if (len <= 0) continue;
      double d = _nextOffsetInSeg;
      while (d <= len + 1e-6) {
        final double clampedD = d > len ? len : d;
        final ui.Tangent? t = metric.getTangentForOffset(clampedD);
        if (t != null) {
          tailXs.add(t.position.dx);
          tailYs.add(t.position.dy);
          tailAngles.add(t.angle);
          tailDistances.add(_cumFrozenLength + clampedD);
        }
        d += step;
      }
    }
    _lastTailLength = len;
  }

  /// Renders baked chunks + remaining unbaked samples using [paintRange].
  /// Any frozen block of [chunkSize] samples is recorded ONCE into a `ui.Picture`.
  void drawWithChunks(
    Canvas canvas,
    Size size,
    int styleSignature,
    void Function(Canvas target, int startIdx, int endIdx, bool isTail) paintRange,
  ) {
    if (_styleSignature != styleSignature) {
      disposePictures();
      _styleSignature = styleSignature;
    }

    // Bake completed blocks of `chunkSize` frozen samples cleanly.
    final int fCount = xs.length;
    while (fCount - _bakedEndIndex >= chunkSize) {
      final int start = _bakedEndIndex;
      final int end = start + chunkSize;
      final ui.PictureRecorder rec = ui.PictureRecorder();
      final Canvas recCanvas = Canvas(
        rec,
        size.isEmpty ? null : Offset.zero & size,
      );
      paintRange(recCanvas, start, end, false);
      _chunks.add(rec.endRecording());
      _bakedEndIndex = end;
    }

    for (final ui.Picture chunk in _chunks) {
      canvas.drawPicture(chunk);
    }

    if (_bakedEndIndex < fCount) {
      paintRange(canvas, _bakedEndIndex, fCount, false);
    }
    if (tailXs.isNotEmpty) {
      paintRange(canvas, 0, tailXs.length, true);
    }
  }

  /// Helper to read X/Y/Angle/Dist/GlobalIndex seamlessly across frozen or tail slice.
  @pragma('vm:prefer-inline')
  double getX(int i, bool isTail) => isTail ? tailXs[i] : xs[i];
  @pragma('vm:prefer-inline')
  double getY(int i, bool isTail) => isTail ? tailYs[i] : ys[i];
  @pragma('vm:prefer-inline')
  double getAngle(int i, bool isTail) => isTail ? tailAngles[i] : angles[i];
  @pragma('vm:prefer-inline')
  double getDist(int i, bool isTail) => isTail ? tailDistances[i] : distances[i];
  @pragma('vm:prefer-inline')
  int globalIndex(int i, bool isTail) => isTail ? xs.length + i : i;

  void disposePictures() {
    for (final ui.Picture p in _chunks) {
      try {
        p.dispose();
      } catch (_) {}
    }
    _chunks.clear();
    _bakedEndIndex = 0;
  }

  void resetAll() {
    disposePictures();
    xs.clear();
    ys.clear();
    angles.clear();
    distances.clear();
    tailXs.clear();
    tailYs.clear();
    tailAngles.clear();
    tailDistances.clear();
    _cachedPtLen = 0;
    _cachedFirst = null;
    _cachedFrozenLast = null;
    _cachedLast = null;
    _cachedStep = 0;
    _committedSeg = 1;
    _nextOffsetInSeg = 0;
    _cumFrozenLength = 0;
    _lastTailLength = 0;
    _styleSignature = 0;
  }
}

/// Generates a uniform packed sample float array only for debug/fallback verification.
Float32List emptyFloat32List() => Float32List(0);

/// Incremental async `ui.Image` + `ui.Picture` backing for preview scratchpads
/// so completed strokes flatten into a single GPU quad even under Impeller.
class AsyncScratchpadBacking {
  AsyncScratchpadBacking({required this.onImageBaked});

  final VoidCallback onImageBaked;

  ui.Image? _bakedImage;
  ui.Picture? _fallbackPicture;
  int _bakedCount = 0;
  Size? _bakedSize;
  int _fallbackCount = 0;
  Size? _fallbackSize;
  int _epoch = 0;
  bool _baking = false;
  bool _disposed = false;

  static final Paint _blitPaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.low;

  void drawCommitted(
    Canvas canvas,
    Size size,
    int strokeCount,
    void Function(Canvas target, Size canvasSize, int index) drawStroke,
  ) {
    if (strokeCount <= 0 || size.isEmpty) return;

    if (_bakedImage != null && _bakedSize == size && _bakedCount <= strokeCount) {
      final ui.Image img = _bakedImage!;
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        Offset.zero & size,
        _blitPaint,
      );
      for (int i = _bakedCount; i < strokeCount; i++) {
        drawStroke(canvas, size, i);
      }
      if (_bakedCount < strokeCount && !_baking) {
        _scheduleBake(size, strokeCount, drawStroke);
      }
      return;
    }

    final ui.Picture? pic = _getFallbackPicture(size, strokeCount, drawStroke);
    if (pic != null) {
      canvas.drawPicture(pic);
    } else {
      for (int i = 0; i < strokeCount; i++) {
        drawStroke(canvas, size, i);
      }
    }
    if (!_baking) {
      _scheduleBake(size, strokeCount, drawStroke);
    }
  }

  ui.Picture? _getFallbackPicture(
    Size size,
    int strokeCount,
    void Function(Canvas target, Size canvasSize, int index) drawStroke,
  ) {
    if (_fallbackPicture != null &&
        _fallbackCount == strokeCount &&
        _fallbackSize == size) {
      return _fallbackPicture;
    }
    final ui.PictureRecorder rec = ui.PictureRecorder();
    final Canvas c = Canvas(rec, Offset.zero & size);
    if (_fallbackPicture != null &&
        _fallbackSize == size &&
        _fallbackCount > 0 &&
        _fallbackCount <= strokeCount) {
      c.drawPicture(_fallbackPicture!);
      for (int i = _fallbackCount; i < strokeCount; i++) {
        drawStroke(c, size, i);
      }
    } else {
      for (int i = 0; i < strokeCount; i++) {
        drawStroke(c, size, i);
      }
    }
    final ui.Picture nextPic = rec.endRecording();
    try {
      _fallbackPicture?.dispose();
    } catch (_) {}
    _fallbackPicture = nextPic;
    _fallbackCount = strokeCount;
    _fallbackSize = size;
    return _fallbackPicture;
  }

  void _scheduleBake(
    Size size,
    int targetCount,
    void Function(Canvas target, Size canvasSize, int index) drawStroke,
  ) {
    if (_disposed || _baking || targetCount <= 0 || size.isEmpty) return;
    _baking = true;

    final int epoch = _epoch;
    final double dpr = ui.PlatformDispatcher.instance.views.isNotEmpty
        ? ui.PlatformDispatcher.instance.views.first.devicePixelRatio.clamp(1.0, 2.0)
        : 1.5;
    final int targetW = (size.width * dpr).round().clamp(1, 1080);
    final int targetH = (size.height * dpr).round().clamp(1, 360);

    final ui.PictureRecorder rec = ui.PictureRecorder();
    final Canvas c = Canvas(
      rec,
      Rect.fromLTWH(0, 0, targetW.toDouble(), targetH.toDouble()),
    );
    c.scale(targetW / size.width, targetH / size.height);

    int startIndex = 0;
    if (_bakedImage != null && _bakedSize == size && _bakedCount > 0 && _bakedCount <= targetCount) {
      final ui.Image prev = _bakedImage!;
      c.drawImageRect(
        prev,
        Rect.fromLTWH(0, 0, prev.width.toDouble(), prev.height.toDouble()),
        Offset.zero & size,
        _blitPaint,
      );
      startIndex = _bakedCount;
    }
    for (int i = startIndex; i < targetCount; i++) {
      drawStroke(c, size, i);
    }

    final ui.Picture pic = rec.endRecording();
    pic.toImage(targetW, targetH).then((ui.Image img) {
      try {
        pic.dispose();
      } catch (_) {}
      _baking = false;
      if (_disposed || epoch != _epoch) {
        try {
          img.dispose();
        } catch (_) {}
        return;
      }
      final ui.Image? oldImg = _bakedImage;
      _bakedImage = img;
      _bakedCount = targetCount;
      _bakedSize = size;
      if (oldImg != null && oldImg != img) {
        try {
          oldImg.dispose();
        } catch (_) {}
      }
      onImageBaked();
    }).catchError((_) {
      _baking = false;
      try {
        pic.dispose();
      } catch (_) {}
    });
  }

  void invalidate() {
    _epoch++;
    _baking = false;
    try {
      _bakedImage?.dispose();
    } catch (_) {}
    _bakedImage = null;
    _bakedCount = 0;
    _bakedSize = null;
    try {
      _fallbackPicture?.dispose();
    } catch (_) {}
    _fallbackPicture = null;
    _fallbackCount = 0;
    _fallbackSize = null;
  }

  void dispose() {
    _disposed = true;
    invalidate();
  }
}

/// Bounded LRU picture + async GPU bitmap cache for small UI tile painters
/// (e.g. Brush Tip Studio tiles) to avoid re-running vector blurs per frame.
class AsyncTileBitmapCache {
  AsyncTileBitmapCache({this.maxEntries = 48});

  final int maxEntries;
  final Map<String, ui.Picture> _pictures = <String, ui.Picture>{};
  late final BoundedImageCache<String> _images =
      BoundedImageCache<String>(maxEntries: maxEntries);
  final Set<String> _pending = <String>{};
  final ValueNotifier<int> repaintNotifier = ValueNotifier<int>(0);
  int _epoch = 0;
  bool _notifyScheduled = false;

  static final Paint _blitPaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.low;

  void draw(
    Canvas canvas,
    Size size,
    String key,
    void Function(Canvas recCanvas, Size canvasSize) record,
  ) {
    if (size.isEmpty) return;
    final ui.Image? cachedImg = _images.get(key);
    if (cachedImg != null) {
      canvas.drawImageRect(
        cachedImg,
        Rect.fromLTWH(0, 0, cachedImg.width.toDouble(), cachedImg.height.toDouble()),
        Offset.zero & size,
        _blitPaint,
      );
      return;
    }

    ui.Picture? pic = _pictures.remove(key);
    if (pic == null) {
      final ui.PictureRecorder rec = ui.PictureRecorder();
      final Canvas c = Canvas(rec, Offset.zero & size);
      record(c, size);
      pic = rec.endRecording();
      if (_pictures.length >= maxEntries) {
        final String oldest = _pictures.keys.first;
        final ui.Picture? evicted = _pictures.remove(oldest);
        try {
          evicted?.dispose();
        } catch (_) {}
      }
    }
    _pictures[key] = pic;
    canvas.drawPicture(pic);

    if (_pending.add(key)) {
      final int epoch = _epoch;
      final double dpr = ui.PlatformDispatcher.instance.views.isNotEmpty
          ? ui.PlatformDispatcher.instance.views.first.devicePixelRatio.clamp(1.0, 2.0)
          : 1.5;
      final int targetW = (size.width * dpr).round().clamp(1, 256);
      final int targetH = (size.height * dpr).round().clamp(1, 256);
      final ui.PictureRecorder scaledRec = ui.PictureRecorder();
      final Canvas scaledCanvas = Canvas(
        scaledRec,
        Rect.fromLTWH(0, 0, targetW.toDouble(), targetH.toDouble()),
      );
      scaledCanvas.scale(targetW / size.width, targetH / size.height);
      scaledCanvas.drawPicture(pic);
      final ui.Picture scaledPic = scaledRec.endRecording();
      scaledPic.toImage(targetW, targetH).then((ui.Image img) {
        try {
          scaledPic.dispose();
        } catch (_) {}
        _pending.remove(key);
        if (epoch != _epoch) {
          try {
            img.dispose();
          } catch (_) {}
          return;
        }
        _images.put(key, img);
        if (!_notifyScheduled) {
          _notifyScheduled = true;
          scheduleMicrotask(() {
            _notifyScheduled = false;
            if (epoch == _epoch) {
              repaintNotifier.value++;
            }
          });
        }
      }).catchError((_) {
        _pending.remove(key);
        try {
          scaledPic.dispose();
        } catch (_) {}
      });
    }
  }

  void clear() {
    _epoch++;
    _pending.clear();
    _images.clear();
    for (final ui.Picture pic in _pictures.values) {
      try {
        pic.dispose();
      } catch (_) {}
    }
    _pictures.clear();
  }
}
