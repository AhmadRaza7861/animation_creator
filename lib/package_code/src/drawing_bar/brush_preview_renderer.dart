import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../paint_contents.dart';
import '../paint_contents/brush_cache.dart';
import 'brush_presets.dart';

/// Ultra high-performance, 100% authentic, crash-proof brush preview renderer.
///
/// Renders first frame immediately via a bounded [ui.Picture] and asynchronously
/// bakes each visible preview into a bounded GPU [ui.Image] so Impeller draws
/// a single textured quad during live scratchpad doodling and scrolling.
class BrushPreviewRenderer {
  const BrushPreviewRenderer._();

  static const int _maxEntries = 64;
  static final Map<String, ui.Picture> _pictureCache = <String, ui.Picture>{};
  static final BoundedImageCache<String> _imageCache = BoundedImageCache<String>(maxEntries: _maxEntries);
  static final Set<String> _pendingBakes = <String>{};
  static final ValueNotifier<int> repaintNotifier = ValueNotifier<int>(0);
  static int _cacheEpoch = 0;
  static bool _notifyScheduled = false;

  static final Paint _imagePaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.low;

  static void paintPreview(
    Canvas canvas,
    Size size,
    BrushPreset preset,
    Color color,
  ) {
    if (size.width <= 0 || size.height <= 0) return;

    final Color effectiveColor = color.computeLuminance() > 0.88
        ? const Color(0xFF2563EB)
        : color;

    final String cacheKey =
        '${preset.id}_${size.width.toInt()}x${size.height.toInt()}_${effectiveColor.toARGB32()}';

    final ui.Image? cachedImage = _imageCache.get(cacheKey);
    if (cachedImage != null) {
      canvas.drawImageRect(
        cachedImage,
        Rect.fromLTWH(0, 0, cachedImage.width.toDouble(), cachedImage.height.toDouble()),
        Offset.zero & size,
        _imagePaint,
      );
      return;
    }

    ui.Picture? picture = _pictureCache.remove(cacheKey);
    if (picture == null) {
      picture = _recordPreviewPicture(size, preset, effectiveColor);
      if (_pictureCache.length >= _maxEntries) {
        final String oldestKey = _pictureCache.keys.first;
        final ui.Picture? evicted = _pictureCache.remove(oldestKey);
        try {
          evicted?.dispose();
        } catch (_) {}
      }
    }
    _pictureCache[cacheKey] = picture;
    canvas.drawPicture(picture);
    _scheduleBitmapBake(cacheKey, picture, size);
  }

  static ui.Picture _recordPreviewPicture(
    Size size,
    BrushPreset preset,
    Color effectiveColor,
  ) {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas recCanvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.width, size.height));

    final double padX = size.width > 220 ? 18.0 : size.width * 0.08;
    final double usableW = size.width - padX * 2;
    final double midY = size.height * 0.5;
    final double amp = size.height * 0.23;
    final int segments = size.width > 220 ? 32 : 22;

    final List<Offset> points = <Offset>[];
    for (int i = 0; i <= segments; i++) {
      final double t = i / segments;
      final double x = padX + usableW * t;
      final double y = midY - sin(t * pi * 2) * amp;
      points.add(Offset(x, y));
    }

    final double width = _resolvePreviewWidth(preset.id, size);

    try {
      final PaintContent content = preset.create()
        ..paint = (Paint()
          ..color = effectiveColor
          ..strokeWidth = width
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true);

      content.startDraw(points.first);
      for (int i = 1; i < points.length; i++) {
        content.drawing(points[i]);
      }
      content.draw(recCanvas, size, false);
      content.clearRenderCache();
    } catch (_) {
      final fallbackPaint = Paint()
        ..color = effectiveColor
        ..strokeWidth = 4.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;
      final Path path = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      recCanvas.drawPath(path, fallbackPaint);
    }

    return recorder.endRecording();
  }

  static void _scheduleBitmapBake(String cacheKey, ui.Picture sourcePic, Size size) {
    if (_pendingBakes.contains(cacheKey)) return;
    _pendingBakes.add(cacheKey);

    final int epoch = _cacheEpoch;
    final double dpr = ui.PlatformDispatcher.instance.views.isNotEmpty
        ? ui.PlatformDispatcher.instance.views.first.devicePixelRatio.clamp(1.0, 2.0)
        : 1.5;
    final int targetW = (size.width * dpr).round().clamp(1, 640);
    final int targetH = (size.height * dpr).round().clamp(1, 200);

    final ui.PictureRecorder scaledRec = ui.PictureRecorder();
    final Canvas scaledCanvas = Canvas(
      scaledRec,
      Rect.fromLTWH(0, 0, targetW.toDouble(), targetH.toDouble()),
    );
    scaledCanvas.scale(targetW / size.width, targetH / size.height);
    scaledCanvas.drawPicture(sourcePic);
    final ui.Picture scaledPic = scaledRec.endRecording();

    scaledPic.toImage(targetW, targetH).then((ui.Image img) {
      try {
        scaledPic.dispose();
      } catch (_) {}
      _pendingBakes.remove(cacheKey);
      if (epoch != _cacheEpoch) {
        try {
          img.dispose();
        } catch (_) {}
        return;
      }
      _imageCache.put(cacheKey, img);
      if (!_notifyScheduled) {
        _notifyScheduled = true;
        scheduleMicrotask(() {
          _notifyScheduled = false;
          if (epoch == _cacheEpoch) {
            repaintNotifier.value++;
          }
        });
      }
    }).catchError((_) {
      _pendingBakes.remove(cacheKey);
      try {
        scaledPic.dispose();
      } catch (_) {}
    });
  }

  static double _resolvePreviewWidth(String presetId, Size size) {
    final String id = presetId.toLowerCase();
    double width = 8.0;

    if (id.contains('pencilh')) {
      width = 14.0;
    } else if (id.contains('pencil6b') || id.contains('crayon')) {
      width = 18.0;
    } else if (id.contains('pencil') ||
        id.contains('sketch') ||
        id.contains('grain') ||
        id.contains('crayongrain')) {
      width = 16.0;
    } else if (id.contains('calligraphy') ||
        id.contains('fountain') ||
        id.contains('dip') ||
        id.contains('rollerball') ||
        id.contains('gel') ||
        id.contains('marker') ||
        id.contains('brushpen') ||
        id.contains('sumi') ||
        id.contains('reed')) {
      width = 12.0;
    } else if (id.contains('stamp') ||
        id.contains('heart') ||
        id.contains('star') ||
        id.contains('butterfly') ||
        id.contains('paw') ||
        id.contains('fish') ||
        id.contains('crosshair') ||
        id.contains('gem') ||
        id.contains('crown') ||
        id.contains('lightning') ||
        id.contains('flower') ||
        id.contains('leaf') ||
        id.contains('leaves') ||
        id.contains('blossom') ||
        id.contains('tree') ||
        id.contains('cloud') ||
        id.contains('sun') ||
        id.contains('moon') ||
        id.contains('sparkle') ||
        id.contains('confetti') ||
        id.contains('ghost') ||
        id.contains('rocket') ||
        id.contains('atom') ||
        id.contains('puzzle') ||
        id.contains('anchor') ||
        id.contains('hourglass') ||
        id.contains('lightbulb') ||
        id.contains('bell') ||
        id.contains('key') ||
        id.contains('bowtie') ||
        id.contains('crescent') ||
        id.contains('petals') ||
        id.contains('pinetree') ||
        id.contains('feather') ||
        id.contains('diamond') ||
        id.contains('triangle') ||
        id.contains('hexagon') ||
        id.contains('octagon') ||
        id.contains('shield') ||
        id.contains('spiral') ||
        id.contains('teardrop') ||
        id.contains('ring')) {
      width = 20.0;
    } else if (id.contains('marble') ||
        id.contains('honeycomb') ||
        id.contains('lace') ||
        id.contains('weave') ||
        id.contains('mesh') ||
        id.contains('cobweb') ||
        id.contains('cells') ||
        id.contains('fur') ||
        id.contains('hair') ||
        id.contains('grunge') ||
        id.contains('static') ||
        id.contains('sprinkles') ||
        id.contains('halftone') ||
        id.contains('mosaic') ||
        id.contains('orange') ||
        id.contains('sand') ||
        id.contains('charcoal') ||
        id.contains('chalk') ||
        id.contains('sponge') ||
        id.contains('watercolor') ||
        id.contains('oil') ||
        id.contains('acrylic') ||
        id.contains('gouache')) {
      width = 17.0;
    } else if (id.contains('neon') ||
        id.contains('glow') ||
        id.contains('rainbow') ||
        id.contains('ribbon') ||
        id.contains('chain') ||
        id.contains('audio') ||
        id.contains('stitch') ||
        id.contains('candy') ||
        id.contains('saw') ||
        id.contains('gear') ||
        id.contains('heartbeat') ||
        id.contains('bubble') ||
        id.contains('electric') ||
        id.contains('constellation') ||
        id.contains('galaxy') ||
        id.contains('embers') ||
        id.contains('glitter') ||
        id.contains('starglow') ||
        id.contains('crackle') ||
        id.contains('circuit') ||
        id.contains('flame') ||
        id.contains('ripple') ||
        id.contains('snow') ||
        id.contains('rain') ||
        id.contains('grass') ||
        id.contains('dots') ||
        id.contains('squares') ||
        id.contains('dash') ||
        id.contains('pixel') ||
        id.contains('hatch') ||
        id.contains('gradient') ||
        id.contains('3d')) {
      width = 14.0;
    } else if (id.contains('spray') ||
        id.contains('splatter') ||
        id.contains('spatter') ||
        id.contains('smoke') ||
        id.contains('bokeh') ||
        id.contains('stipple') ||
        id.contains('highlighter')) {
      width = 18.0;
    } else {
      width = 10.0;
    }

    if (size.height < 50) {
      width *= 0.8;
    }

    return width;
  }

  /// Clears and safely disposes all cached preview pictures and bitmaps
  static void clearCache() {
    _cacheEpoch++;
    _pendingBakes.clear();
    _imageCache.clear();
    for (final pic in _pictureCache.values) {
      try {
        pic.dispose();
      } catch (_) {}
    }
    _pictureCache.clear();
  }
}
