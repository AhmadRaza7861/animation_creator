import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import '../package_code/src/drawing_controller.dart';
import '../package_code/paint_contents.dart';

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
    // PageView index is 0-based, FPS is 1-based, so index = fps - 1
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Preview Animation',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
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
                                    bottom: BorderSide(color: Colors.black87, width: 2),
                                  ),
                                )
                              : null,
                          child: Text(
                            '$value fps',
                            style: TextStyle(
                              fontSize: isSelected ? 18 : 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.black87 : Colors.black38,
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
              color: widget.globalBackground.color,
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
    canvas.saveLayer(Offset.zero & size, Paint());
    for (int i = controller.layers.length - 1; i >= 0; i--) {
      final layer = controller.layers[i];
      if (!layer.isVisible) continue;

      canvas.saveLayer(
        Offset.zero & size,
        Paint()
          ..blendMode = layer.blendMode
          ..color = Colors.white.withOpacity(layer.opacity),
      );

      for (int j = 0; j < layer.currentIndex; j++) {
        layer.history[j].draw(canvas, size, true);
      }

      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FramePainter oldDelegate) => true;
}

class PreviewPatternPainter extends CustomPainter {
  final String pattern;
  const PreviewPatternPainter(this.pattern);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..strokeWidth = 1.0;

    if (pattern == 'grid') {
      const double spacing = 20.0;
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    } else if (pattern == 'dots') {
      const double spacing = 20.0;
      final dotPaint = Paint()..color = Colors.black.withOpacity(0.15);
      for (double x = spacing / 2; x < size.width; x += spacing) {
        for (double y = spacing / 2; y < size.height; y += spacing) {
          canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
        }
      }
    } else if (pattern == 'lines') {
      const double spacing = 24.0;
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
      final marginPaint = Paint()
        ..color = Colors.redAccent.withOpacity(0.2)
        ..strokeWidth = 1.5;
      canvas.drawLine(const Offset(40, 0), Offset(40, size.height), marginPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PreviewPatternPainter oldDelegate) => oldDelegate.pattern != pattern;
}
