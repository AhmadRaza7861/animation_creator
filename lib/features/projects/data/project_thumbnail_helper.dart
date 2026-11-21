import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../package_code/paint_contents.dart';
import '../../../package_code/src/paint_contents/layer_data.dart';
import '../../../package_code/src/paint_contents/paint_content_decoder.dart';
import '../../../package_code/src/ruler/mirror_content.dart';
import '../../../package_code/src/ruler/radial_content.dart';
import '../presentation/widgets/preview_pattern_painter.dart';

/// Shared helper for rendering compact PNG project thumbnails from either live
/// editor layers or serialized `data.json` project state.
class ProjectThumbnailHelper {
  ProjectThumbnailHelper._();

  static const double _maxThumbDimension = 512.0;

  /// Renders a PNG thumbnail directly from decoded [layers] and background.
  static Future<Uint8List?> renderSnapshot({
    required Size canvasSize,
    required Color backgroundColor,
    String? backgroundPattern,
    ui.Image? backgroundImage,
    double backgroundImageOpacity = 1.0,
    required List<LayerData> layers,
    bool includeGuideLayers = false,
    void Function(Canvas canvas, Size canvasSize)? overlayPainter,
  }) async {
    if (canvasSize.width <= 0 || canvasSize.height <= 0) return null;

    final double longest = canvasSize.longestSide > 0
        ? canvasSize.longestSide
        : _maxThumbDimension;
    final double scale = _maxThumbDimension / longest;
    final Size renderSize = Size(
      (canvasSize.width * scale).roundToDouble().clamp(1.0, 2048.0),
      (canvasSize.height * scale).roundToDouble().clamp(1.0, 2048.0),
    );

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, Offset.zero & renderSize);
    canvas.scale(scale);

    // 1. Solid opaque background
    canvas.drawRect(Offset.zero & canvasSize, Paint()..color = backgroundColor);

    if (backgroundImage != null) {
      paintImage(
        canvas: canvas,
        rect: Offset.zero & canvasSize,
        image: backgroundImage,
        fit: BoxFit.cover,
        opacity: backgroundImageOpacity.clamp(0.0, 1.0),
      );
    }

    if (backgroundPattern != null && backgroundPattern != 'none') {
      final painter = PreviewPatternPainter(backgroundPattern);
      painter.paint(canvas, canvasSize);
    }

    // 2. Canvas layers (bottom-to-top)
    canvas.saveLayer(Offset.zero & canvasSize, Paint());
    for (int i = layers.length - 1; i >= 0; i--) {
      final layer = layers[i];
      final bool isGuide =
          layer.isGuide || layer.name == 'Stencil Guide' || layer.name.contains('Guide');
      if (!layer.isVisible || (!includeGuideLayers && isGuide)) {
        continue;
      }

      canvas.saveLayer(
        Offset.zero & canvasSize,
        Paint()
          ..blendMode = layer.blendMode
          ..color = Colors.white.withValues(alpha: layer.opacity.clamp(0.0, 1.0)),
      );
      layer.drawHistory(canvas, canvasSize, false);
      canvas.restore();
    }

    overlayPainter?.call(canvas, canvasSize);
    canvas.restore();

    final ui.Picture picture = recorder.endRecording();
    ui.Image? img;
    try {
      img = await picture.toImage(
        renderSize.width.toInt(),
        renderSize.height.toInt(),
      );
      final ByteData? byteData = await img.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error encoding project thumbnail: $e');
      return null;
    } finally {
      try {
        picture.dispose();
      } catch (_) {}
      try {
        img?.dispose();
      } catch (_) {}
    }
  }

  /// Checks quickly whether a serialized project state contains any visual
  /// content worth rendering as a thumbnail.
  static bool stateHasVisualContent(Map<String, dynamic> state) {
    final Map<String, dynamic>? bg =
        state['globalBackground'] as Map<String, dynamic>?;
    if (_bgHasVisualContent(bg)) return true;

    final List<dynamic>? templateAssets =
        state['templateFrameAssets'] as List<dynamic>?;
    if (templateAssets != null && templateAssets.isNotEmpty) return true;

    final List<dynamic>? canvases = state['canvases'] as List<dynamic>?;
    if (canvases == null || canvases.isEmpty) return false;

    final int limit = math.min(canvases.length, 50);
    for (int i = 0; i < limit; i++) {
      final dynamic c = canvases[i];
      if (c is! Map<String, dynamic>) continue;
      if (_canvasMapHasDrawableLayer(c, includeGuide: false) ||
          _canvasMapHasDrawableLayer(c, includeGuide: true)) {
        return true;
      }
    }
    return false;
  }

  /// Renders a PNG thumbnail from a serialized `data.json` state map.
  ///
  /// Returns `null` when the project is genuinely blank so blank projects
  /// continue showing the Blank Canvas placeholder.
  static Future<Uint8List?> renderFromState(Map<String, dynamic> state) async {
    final Map<String, dynamic>? bg =
        state['globalBackground'] as Map<String, dynamic>?;
    final List<dynamic>? canvases = state['canvases'] as List<dynamic>?;
    if (canvases == null || canvases.isEmpty) return null;

    final int limit = math.min(canvases.length, 50);
    int? chosenIndex;
    bool useGuideFallback = false;

    for (int i = 0; i < limit; i++) {
      final dynamic c = canvases[i];
      if (c is Map<String, dynamic> &&
          _canvasMapHasDrawableLayer(c, includeGuide: false)) {
        chosenIndex = i;
        break;
      }
    }

    if (chosenIndex == null) {
      for (int i = 0; i < limit; i++) {
        final dynamic c = canvases[i];
        if (c is Map<String, dynamic> &&
            _canvasMapHasDrawableLayer(c, includeGuide: true)) {
          chosenIndex = i;
          useGuideFallback = true;
          break;
        }
      }
    }

    final bool hasBgVisual = _bgHasVisualContent(bg);
    if (chosenIndex == null && !hasBgVisual) {
      return null;
    }

    final Map<String, dynamic> cMap =
        (canvases[chosenIndex ?? 0] as Map<String, dynamic>?) ??
            const <String, dynamic>{};

    final double ratio =
        (state['aspectRatio'] as num?)?.toDouble() ?? 1.0;
    Size canvasSize = _parseCanvasSize(cMap, ratio);

    final Color rawBgColor = Color(
      (bg?['color'] as int?) ?? Colors.white.toARGB32(),
    );
    final String? bgPattern = bg?['pattern'] as String?;
    final Color bgColor = PatternBackgroundHelper.getBaseColor(
      bgPattern,
      rawBgColor,
    );
    final double bgImageOpacity =
        (bg?['imageOpacity'] as num?)?.toDouble() ?? 1.0;
    final String? bgImagePath = bg?['imagePath'] as String?;

    final List<ui.Image> allocatedImages = <ui.Image>[];
    ui.Image? bgImage;
    try {
      if (bgImagePath != null && bgImagePath.isNotEmpty) {
        bgImage = await _loadLocalOrAssetImage(bgImagePath);
        if (bgImage != null) {
          allocatedImages.add(bgImage);
        }
      }

      final List<LayerData> layers = await _decodeLayers(
        cMap['layers'] as List<dynamic>? ?? const [],
        allocatedImages,
      );

      return await renderSnapshot(
        canvasSize: canvasSize,
        backgroundColor: bgColor,
        backgroundPattern: bgPattern,
        backgroundImage: bgImage,
        backgroundImageOpacity: bgImageOpacity,
        layers: layers,
        includeGuideLayers: useGuideFallback,
      );
    } catch (e) {
      debugPrint('Failed rendering thumbnail from project state: $e');
      return null;
    } finally {
      for (final img in allocatedImages) {
        try {
          img.dispose();
        } catch (_) {}
      }
    }
  }

  static bool _bgHasVisualContent(Map<String, dynamic>? bg) {
    if (bg == null) return false;
    final String? imagePath = bg['imagePath'] as String?;
    if (imagePath != null && imagePath.isNotEmpty) return true;
    final String? pattern = bg['pattern'] as String?;
    if (pattern != null && pattern != 'none') return true;
    final int? colorVal = bg['color'] as int?;
    if (colorVal != null && colorVal != Colors.white.toARGB32()) return true;
    return false;
  }

  static bool _canvasMapHasDrawableLayer(
    Map<String, dynamic> cMap, {
    required bool includeGuide,
  }) {
    final List<dynamic>? layers = cMap['layers'] as List<dynamic>?;
    if (layers == null || layers.isEmpty) return false;

    for (final dynamic l in layers) {
      if (l is! Map<String, dynamic>) continue;
      final bool isVisible = l['isVisible'] as bool? ?? true;
      if (!isVisible) continue;

      final String name = l['name'] as String? ?? '';
      final bool isGuide =
          (l['isGuide'] as bool?) ??
          (name == 'Stencil Guide' || name.contains('Guide'));
      if (isGuide != includeGuide) continue;

      final List<dynamic>? history = l['history'] as List<dynamic>?;
      if (history == null || history.isEmpty) continue;

      final int effectiveCount =
          ((l['currentIndex'] as int?) ?? history.length).clamp(0, history.length);
      if (effectiveCount <= 0) continue;

      final Set<String> deletedIds = <String>{};
      for (int i = 0; i < effectiveCount; i++) {
        final dynamic item = history[i];
        if (item is Map<String, dynamic> && item['type'] == 'DeleteContent') {
          final String? targetId = item['targetId'] as String?;
          if (targetId != null) deletedIds.add(targetId);
        }
      }

      for (int i = 0; i < effectiveCount; i++) {
        final dynamic item = history[i];
        if (item is! Map<String, dynamic>) continue;
        final String? type = item['type'] as String?;
        final String? id = item['id'] as String?;
        if (type == 'EmptyContent' || type == 'DeleteContent') continue;
        if (id != null && deletedIds.contains(id)) continue;
        return true;
      }
    }
    return false;
  }

  static Size _parseCanvasSize(Map<String, dynamic> cMap, double ratio) {
    final Map<String, dynamic>? sizeMap = cMap['size'] as Map<String, dynamic>?;
    if (sizeMap != null) {
      final double w = (sizeMap['width'] as num?)?.toDouble() ?? 0.0;
      final double h = (sizeMap['height'] as num?)?.toDouble() ?? 0.0;
      if (w > 0 && h > 0) return Size(w, h);
    }
    final double safeRatio = ratio > 0 ? ratio : 1.0;
    return safeRatio >= 1.0
        ? Size(1000.0, 1000.0 / safeRatio)
        : Size(1000.0 * safeRatio, 1000.0);
  }

  static Future<List<LayerData>> _decodeLayers(
    List<dynamic> layersData,
    List<ui.Image> allocatedImages,
  ) async {
    final List<LayerData> layers = <LayerData>[];
    for (int lIdx = 0; lIdx < layersData.length; lIdx++) {
      final dynamic lRaw = layersData[lIdx];
      if (lRaw is! Map<String, dynamic>) continue;

      final List<dynamic> historyData =
          lRaw['history'] as List<dynamic>? ?? const [];
      int latestRasterIndex = -1;
      for (int i = historyData.length - 1; i >= 0; i--) {
        final dynamic h = historyData[i];
        if (h is Map<String, dynamic>) {
          final String? type = h['type'] as String?;
          if (type == 'SmudgeContent' || type == 'BlurContent') {
            latestRasterIndex = i;
            break;
          }
        }
      }

      final List<PaintContent> history = <PaintContent>[];
      for (int i = 0; i < historyData.length; i++) {
        final dynamic hRaw = historyData[i];
        if (hRaw is! Map<String, dynamic>) continue;
        final String? type = hRaw['type'] as String?;
        if (type == null) continue;
        final PaintContent? content = decodePaintContent(type, hRaw);
        if (content != null) {
          final bool needImage =
              (i == latestRasterIndex) ||
              (content is! SmudgeContent && content is! BlurContent);
          if (needImage) {
            await _rehydrateContentForThumbnail(content, hRaw, allocatedImages);
          }
          history.add(content);
        }
      }

      final String name = lRaw['name'] as String? ?? 'Layer';
      final int validIdx =
          ((lRaw['currentIndex'] as int?) ?? history.length).clamp(0, history.length);
      final int blendIdx =
          ((lRaw['blendMode'] as int?) ?? BlendMode.srcOver.index)
              .clamp(0, BlendMode.values.length - 1);

      layers.add(
        LayerData(
          id: lRaw['id'] as String? ?? 'thumb_layer_$lIdx',
          name: name,
          isVisible: lRaw['isVisible'] as bool? ?? true,
          isLocked: lRaw['isLocked'] as bool? ?? false,
          isGuide:
              (lRaw['isGuide'] as bool?) ??
              (name == 'Stencil Guide' || name.contains('Guide')),
          opacity: (lRaw['opacity'] as num?)?.toDouble() ?? 1.0,
          blendMode: BlendMode.values[blendIdx],
          history: history,
          currentIndex: validIdx,
          sessionStartIndex: validIdx,
        ),
      );
    }
    return layers;
  }

  static Future<void> _rehydrateContentForThumbnail(
    PaintContent content,
    Map<String, dynamic> data,
    List<ui.Image> allocatedImages,
  ) async {
    if (content is BlurContent ||
        content is SmudgeContent ||
        content is FillContent) {
      final String? base64Data = data['imageDataBase64'] as String?;
      if (base64Data != null && base64Data.isNotEmpty) {
        try {
          final Uint8List bytes = base64Decode(base64Data);
          final ui.Image? decoded = await _decodeBytesImage(bytes);
          if (decoded != null) {
            allocatedImages.add(decoded);
            if (content is BlurContent) {
              content.image = decoded;
              content.cachedBase64Image = base64Data;
            } else if (content is SmudgeContent) {
              content.image = decoded;
              content.cachedBase64Image = base64Data;
            } else if (content is FillContent) {
              content.image = decoded;
            }
          }
        } catch (_) {}
      }
    } else if (content is ImageContent && content.image == null) {
      final String? imageUrl = data['imageUrl'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
        final ui.Image? loaded = await _loadLocalOrAssetImage(imageUrl);
        if (loaded != null) {
          allocatedImages.add(loaded);
          content.image = loaded;
        }
      }
    } else if (content is GroupContent) {
      final List<dynamic> childrenData = data['children'] as List<dynamic>? ?? [];
      for (int i = 0; i < content.children.length && i < childrenData.length; i++) {
        if (childrenData[i] is Map<String, dynamic>) {
          await _rehydrateContentForThumbnail(
            content.children[i],
            childrenData[i] as Map<String, dynamic>,
            allocatedImages,
          );
        }
      }
    } else if (content is ClippedHistoryContent) {
      final List<dynamic> historyData = data['history'] as List<dynamic>? ?? [];
      for (int i = 0; i < content.history.length && i < historyData.length; i++) {
        if (historyData[i] is Map<String, dynamic>) {
          await _rehydrateContentForThumbnail(
            content.history[i],
            historyData[i] as Map<String, dynamic>,
            allocatedImages,
          );
        }
      }
    } else if (content is ShapeStickerContent) {
      final Map<String, dynamic>? childData =
          data['child'] as Map<String, dynamic>?;
      if (childData != null) {
        await _rehydrateContentForThumbnail(content.child, childData, allocatedImages);
      }
    } else if (content is OffsetContent) {
      final Map<String, dynamic>? childData =
          data['child'] as Map<String, dynamic>?;
      if (childData != null) {
        await _rehydrateContentForThumbnail(content.child, childData, allocatedImages);
      }
    } else if (content is ClippedContent) {
      final Map<String, dynamic>? childData =
          data['child'] as Map<String, dynamic>?;
      if (childData != null) {
        await _rehydrateContentForThumbnail(content.child, childData, allocatedImages);
      }
    } else if (content is MirrorContent) {
      final Map<String, dynamic>? childData =
          data['child'] as Map<String, dynamic>?;
      if (childData != null) {
        await _rehydrateContentForThumbnail(content.child, childData, allocatedImages);
      }
    } else if (content is QuadMirrorContent) {
      final Map<String, dynamic>? childData =
          data['child'] as Map<String, dynamic>?;
      if (childData != null) {
        await _rehydrateContentForThumbnail(content.child, childData, allocatedImages);
      }
    } else if (content is RadialContent) {
      final Map<String, dynamic>? childData =
          data['child'] as Map<String, dynamic>?;
      if (childData != null) {
        await _rehydrateContentForThumbnail(content.child, childData, allocatedImages);
      }
    }
  }

  static Future<ui.Image?> _loadLocalOrAssetImage(String path) async {
    try {
      Uint8List bytes;
      if (path.startsWith('assets/')) {
        final ByteData data = await rootBundle.load(path);
        bytes = data.buffer.asUint8List();
      } else {
        final File file = File(path);
        if (!await file.exists()) return null;
        bytes = await file.readAsBytes();
      }
      return await _decodeBytesImage(bytes);
    } catch (_) {
      return null;
    }
  }

  static Future<ui.Image?> _decodeBytesImage(Uint8List bytes) async {
    ui.Codec? codec;
    try {
      codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo info = await codec.getNextFrame();
      return info.image;
    } catch (_) {
      return null;
    } finally {
      try {
        codec?.dispose();
      } catch (_) {}
    }
  }
}

