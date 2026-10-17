import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../package_code/src/drawing_controller.dart';
import '../../../../package_code/src/paint_contents/image.dart';
import '../../../../package_code/src/paint_contents/fill.dart';
import '../../../../package_code/src/paint_contents/paint_content.dart';
import '../../../../package_code/src/paint_contents/shape_sticker.dart';
import '../../../../package_code/src/paint_contents/group.dart';
import '../../../../package_code/src/paint_contents/clipped.dart';
import '../controllers/editor_controller.dart';
import '../../../projects/presentation/widgets/preview_pattern_painter.dart';
import '../../../../core/widgets/safe_thumbnail_widget.dart';

class AnimationPreviewScreen extends StatefulWidget {
  final List<DrawingController> canvases;
  final double? aspectRatio;
  final CanvasBackground globalBackground;
  final int initialFps;

  const AnimationPreviewScreen({
    super.key,
    required this.canvases,
    required this.aspectRatio,
    required this.globalBackground,
    required this.initialFps,
  });

  @override
  State<AnimationPreviewScreen> createState() => _AnimationPreviewScreenState();
}

class _AnimationPreviewScreenState extends State<AnimationPreviewScreen> {
  late int _fps;
  late PageController _fpsPageController;
  Timer? _playbackTimer;
  int _currentFrameIndex = 0;

  final Set<int> _loadingIndices = {};
  final Set<int> _activeLoadedIndices = {};

  @override
  void initState() {
    super.initState();
    _fps = widget.initialFps;
    _fpsPageController = PageController(
      initialPage: _fps - 1,
      viewportFraction: 0.3,
    );
    _prewarmAndStart();
  }

  void _prewarmAndStart() async {
    if (widget.canvases.isEmpty) return;
    // Pre-warm the first 10 frames before playback starts
    final int prewarmCount = math.min(widget.canvases.length, 10);
    for (int i = 0; i < prewarmCount; i++) {
      await _prepareCanvasImages(widget.canvases[i]);
      _activeLoadedIndices.add(i);
    }
    if (mounted) {
      setState(() {});
      _requestFramePreload(0);
      _startPlayback();
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _fpsPageController.dispose();
    _loadingIndices.clear();
    // Only evict frames that were temporarily loaded during preview (frames > 2)
    if (widget.canvases.length > 25) {
      for (final idx in _activeLoadedIndices) {
        if (idx > 2 && idx < widget.canvases.length) {
          _evictCanvasImages(widget.canvases[idx]);
        }
      }
    }
    _activeLoadedIndices.clear();
    super.dispose();
  }

  bool _isCanvasReady(DrawingController canvas) {
    for (final layer in canvas.layers) {
      final int count = layer.currentIndex > 0 ? layer.currentIndex : layer.history.length;
      for (int j = 0; j < count; j++) {
        if (!_isContentReady(layer.history[j])) {
          return false;
        }
      }
    }
    return true;
  }

  bool _isContentReady(PaintContent content) {
    if (content is ImageContent) {
      if (content.imageUrl != null && content.imageUrl!.isNotEmpty && content.image == null) {
        return false;
      }
    } else if (content is FillContent) {
      if (content.cachedBase64Image != null && content.cachedBase64Image!.isNotEmpty && content.image == null) {
        return false;
      }
    } else if (content is GroupContent) {
      for (final child in content.children) {
        if (!_isContentReady(child)) return false;
      }
    } else if (content is ClippedHistoryContent) {
      for (final item in content.history) {
        if (!_isContentReady(item)) return false;
      }
    } else if (content is ShapeStickerContent) {
      return _isContentReady(content.child);
    } else if (content is OffsetContent) {
      return _isContentReady(content.child);
    } else if (content is ClippedContent) {
      return _isContentReady(content.child);
    }
    return true;
  }

  Future<void> _prepareCanvasImages(DrawingController canvas) async {
    for (final layer in canvas.layers) {
      final int count = layer.currentIndex > 0 ? layer.currentIndex : layer.history.length;
      for (int j = 0; j < count; j++) {
        await _prepareContentImages(layer.history[j]);
      }
    }
  }

  Future<void> _prepareContentImages(PaintContent content) async {
    if (content is ImageContent) {
      if (content.image == null && content.imageUrl != null && content.imageUrl!.isNotEmpty) {
        try {
          if (content.imageUrl!.startsWith('assets/')) {
            final ByteData data = await rootBundle.load(content.imageUrl!);
            final Uint8List bytes = data.buffer.asUint8List();
            final ui.Codec codec = await ui.instantiateImageCodec(bytes, targetWidth: 384);
            final ui.FrameInfo fi = await codec.getNextFrame();
            content.image = fi.image;
          } else {
            final File file = File(content.imageUrl!);
            if (await file.exists()) {
              final Uint8List bytes = await file.readAsBytes();
              final ui.Codec codec = await ui.instantiateImageCodec(bytes, targetWidth: 384);
              final ui.FrameInfo fi = await codec.getNextFrame();
              content.image = fi.image;
            }
          }
        } catch (e) {
          debugPrint('Error preparing preview image: $e');
        }
      }
    } else if (content is FillContent) {
      if (content.image == null && content.cachedBase64Image != null && content.cachedBase64Image!.isNotEmpty) {
        try {
          final Uint8List bytes = base64Decode(content.cachedBase64Image!);
          final ui.Codec codec = await ui.instantiateImageCodec(bytes, targetWidth: 384);
          final ui.FrameInfo fi = await codec.getNextFrame();
          content.image = fi.image;
        } catch (e) {
          debugPrint('Error preparing preview fill image: $e');
        }
      }
    } else if (content is ShapeStickerContent) {
      await _prepareContentImages(content.child);
    } else if (content is OffsetContent) {
      await _prepareContentImages(content.child);
    } else if (content is ClippedContent) {
      await _prepareContentImages(content.child);
    } else if (content is GroupContent) {
      for (final child in content.children) {
        await _prepareContentImages(child);
      }
    } else if (content is ClippedHistoryContent) {
      for (final child in content.history) {
        await _prepareContentImages(child);
      }
    }
  }

  void _evictCanvasImages(DrawingController canvas) {
    for (final layer in canvas.layers) {
      for (final content in layer.history) {
        _evictContentImages(content);
      }
    }
  }

  void _evictContentImages(PaintContent content) {
    if (content is ImageContent && content.imageUrl != null && content.image != null) {
      final imgToDispose = content.image;
      content.image = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          imgToDispose?.dispose();
        } catch (_) {}
      });
    } else if (content is ShapeStickerContent) {
      _evictContentImages(content.child);
    } else if (content is OffsetContent) {
      _evictContentImages(content.child);
    } else if (content is ClippedContent) {
      _evictContentImages(content.child);
    } else if (content is GroupContent) {
      for (final child in content.children) {
        _evictContentImages(child);
      }
    } else if (content is ClippedHistoryContent) {
      for (final child in content.history) {
        _evictContentImages(child);
      }
    }
  }

  void _requestFramePreload(int centerIndex) {
    if (!mounted || widget.canvases.isEmpty) return;

    // 1. Sliding window eviction: evict frames trailing behind centerIndex by > 6 frames
    if (widget.canvases.length > 25) {
      final List<int> toEvict = [];
      for (final idx in _activeLoadedIndices) {
        if (idx <= 2) continue; // Keep initial editor frames in memory
        final int dist = (idx - centerIndex + widget.canvases.length) % widget.canvases.length;
        if (dist > 22 && dist < widget.canvases.length - 6) {
          toEvict.add(idx);
        }
      }
      for (final idx in toEvict) {
        _activeLoadedIndices.remove(idx);
        _evictCanvasImages(widget.canvases[idx]);
      }
    }

    // 2. Preload upcoming 20 frames with up to 4 parallel decodes:
    for (int step = 0; step <= 20; step++) {
      final int idx = (centerIndex + step) % widget.canvases.length;
      if (_isCanvasReady(widget.canvases[idx])) {
        _activeLoadedIndices.add(idx);
        continue;
      }
      if (_loadingIndices.contains(idx)) continue;
      if (_loadingIndices.length >= 4) break; // Maximum 4 parallel decodes

      _loadingIndices.add(idx);
      _prepareCanvasImages(widget.canvases[idx]).then((_) {
        _loadingIndices.remove(idx);
        _activeLoadedIndices.add(idx);
        if (mounted) {
          if (_currentFrameIndex == idx) {
            setState(() {});
          }
          // Continue feeding the preloading pipeline
          _requestFramePreload(_currentFrameIndex);
        }
      }).catchError((_) {
        _loadingIndices.remove(idx);
      });
    }
  }

  void _startPlayback() {
    _playbackTimer?.cancel();
    if (widget.canvases.isEmpty) return;

    final int intervalMs = (1000 / _fps).round();
    _playbackTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (!mounted) return;

      final nextIndex = (_currentFrameIndex + 1) % widget.canvases.length;
      _requestFramePreload(nextIndex);

      // Only advance if the next frame is ready. If decoding is in progress, hold the current frame
      // for 1 tick so the user never sees a blank white screen.
      if (_isCanvasReady(widget.canvases[nextIndex])) {
        setState(() {
          _currentFrameIndex = nextIndex;
        });
      }
    });
  }

  void _stopAndGoBack() {
    Navigator.pop(context, _fps);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        leading: AppBackButton(
          onPressed: _stopAndGoBack,
        ),
        title: Text(
          context.tr('previewAnimation'),
          style: const TextStyle(
            color: ColorConstants.darkText,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: ColorConstants.background,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Custom Horizontal FPS Picker
            Center(
              child: Container(
                width: 260,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: PageView.builder(
                  controller: _fpsPageController,
                  onPageChanged: (index) {
                    setState(() {
                      _fps = index + 1;
                    });
                    _startPlayback();
                  },
                  itemCount: 30, // 1 to 30 FPS
                  itemBuilder: (context, index) {
                    final value = index + 1;
                    final isSelected = value == _fps;

                    return GestureDetector(
                      onTap: () {
                        _fpsPageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          decoration: isSelected
                              ? const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: ColorConstants.darkText, width: 2),
                                  ),
                                )
                              : null,
                          child: Text(
                            '$value fps',
                            style: TextStyle(
                              fontSize: isSelected ? 18 : 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? ColorConstants.darkText : Colors.black38,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Animation Canvas view
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: widget.aspectRatio != null
                      ? AspectRatio(
                          aspectRatio: widget.aspectRatio!,
                          child: _buildPlayerCanvas(),
                        )
                      : _buildPlayerCanvas(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status message
            GestureDetector(
              onTap: _stopAndGoBack,
              child: Text(
                context.tr('tapOnScreenToStop'),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCanvas() {
    if (widget.canvases.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        child: Center(
          child: Text(context.tr('noFramesToAnimate')),
        ),
      );
    }

    final activeController = widget.canvases[_currentFrameIndex];

    return GestureDetector(
      onTap: _stopAndGoBack,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Shared Global Background
            Container(
              color: PatternBackgroundHelper.getBaseColor(widget.globalBackground.pattern, widget.globalBackground.color),
            ),
            if (widget.globalBackground.image != null)
              Positioned.fill(
                child: Opacity(
                  opacity: widget.globalBackground.imageOpacity,
                  child: SafeThumbnailWidget(
                    image: widget.globalBackground.image!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            if (widget.globalBackground.pattern != null && widget.globalBackground.pattern != 'none')
              Positioned.fill(
                child: CustomPaint(
                  painter: PreviewPatternPainter(widget.globalBackground.pattern!),
                ),
              ),

            // Canvas Vector & Image Paint Content
            Positioned.fill(
              child: CustomPaint(
                painter: FramePainter(activeController),
              ),
            ),

            // Frame Indicator Badge
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  context.tr('frameIndexLabel', {
                    'current': '${_currentFrameIndex + 1}',
                    'total': '${widget.canvases.length}',
                  }),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FramePainter extends CustomPainter {
  final DrawingController controller;
  const FramePainter(this.controller);

  @override
  void paint(Canvas canvas, Size size) {
    final Size originalSize = (controller.drawConfig.value.size != null && !controller.drawConfig.value.size!.isEmpty)
        ? controller.drawConfig.value.size!
        : size;

    if (originalSize.isEmpty) return;

    final double scaleX = size.width / originalSize.width;
    final double scaleY = size.height / originalSize.height;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    canvas.saveLayer(Offset.zero & originalSize, Paint());
    for (int i = controller.layers.length - 1; i >= 0; i--) {
      final layer = controller.layers[i];
      if (!layer.isVisible || layer.isGuide || layer.name == 'Stencil Guide') continue;

      canvas.saveLayer(
        Offset.zero & originalSize,
        Paint()
          ..blendMode = layer.blendMode
          ..color = Colors.white.withValues(alpha: layer.opacity.clamp(0.0, 1.0)),
      );

      final int count = layer.currentIndex > 0 ? layer.currentIndex : layer.history.length;
      for (int j = 0; j < count; j++) {
        layer.history[j].draw(canvas, originalSize, true);
      }

      canvas.restore();
    }
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FramePainter oldDelegate) => true;
}
