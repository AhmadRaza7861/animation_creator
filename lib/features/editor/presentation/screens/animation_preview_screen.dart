import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../package_code/src/drawing_controller.dart';
import '../controllers/editor_controller.dart'; // contains CanvasBackground definition
import '../../../projects/presentation/widgets/preview_pattern_painter.dart';

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

  @override
  void initState() {
    super.initState();
    _fps = widget.initialFps;
    _fpsPageController = PageController(
      initialPage: _fps - 1,
      viewportFraction: 0.3,
    );
    _startPlayback();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _fpsPageController.dispose();
    super.dispose();
  }

  void _startPlayback() {
    _playbackTimer?.cancel();
    if (widget.canvases.isEmpty) return;

    final int intervalMs = (1000 / _fps).round();
    _playbackTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (mounted) {
        setState(() {
          _currentFrameIndex = (_currentFrameIndex + 1) % widget.canvases.length;
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
        title: const Text(
          'Preview Animation',
          style: TextStyle(
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
                'Tap on screen to stop',
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
        child: const Center(
          child: Text('No frames to animate'),
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
                  child: RawImage(
                    image: widget.globalBackground.image,
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

            // Canvas Vector Paint Content
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
                  'Frame ${_currentFrameIndex + 1} / ${widget.canvases.length}',
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
    final Size? originalSize = controller.drawConfig.value.size;
    if (originalSize == null || originalSize.isEmpty) return;

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

      for (int j = 0; j < layer.currentIndex; j++) {
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

