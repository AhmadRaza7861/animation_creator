import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../package_code/src/drawing_controller.dart';
import '../controllers/editor_controller.dart'; // contains CanvasBackground definition

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorConstants.darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Preview Animation',
          style: TextStyle(
            color: ColorConstants.darkText,
            fontWeight: FontWeight.bold,
            fontSize: 20,
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
              color: widget.globalBackground.pattern == 'blueprint'
                  ? const Color(0xFF1E3D59)
                  : (widget.globalBackground.pattern == 'graph' ? const Color(0xFFF1F8F6) : widget.globalBackground.color),
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
      if (!layer.isVisible) continue;

      canvas.saveLayer(
        Offset.zero & originalSize,
        Paint()
          ..blendMode = layer.blendMode
          ..color = Colors.white.withOpacity(layer.opacity),
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
    } else if (pattern == 'checkboard') {
      const double spacing = 30.0;
      final cellPaint = Paint()..color = Colors.black.withOpacity(0.04);
      for (double x = 0; x < size.width; x += spacing) {
        for (double y = 0; y < size.height; y += spacing) {
          if (((x / spacing).floor() + (y / spacing).floor()) % 2 == 0) {
            canvas.drawRect(Rect.fromLTWH(x, y, spacing, spacing), cellPaint);
          }
        }
      }
    } else if (pattern == 'isometric') {
      const double spacing = 24.0;
      final double h = spacing * 0.866025;
      for (double x = 0; x < size.width + spacing; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      final double slope = 0.57735;
      for (double y = -size.width * slope; y < size.height; y += h * 2) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y + size.width * slope), paint);
        canvas.drawLine(Offset(0, y + size.width * slope), Offset(size.width, y), paint);
      }
    } else if (pattern == 'blueprint') {
      final bpPaint = Paint()
        ..color = Colors.white.withOpacity(0.12)
        ..strokeWidth = 1.0;
      const double spacing = 25.0;
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), bpPaint);
      }
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), bpPaint);
      }
    } else if (pattern == 'graph') {
      final minorPaint = Paint()
        ..color = const Color(0xFF81B214).withOpacity(0.1)
        ..strokeWidth = 0.5;
      final majorPaint = Paint()
        ..color = const Color(0xFF81B214).withOpacity(0.25)
        ..strokeWidth = 1.0;
      const double minorSpacing = 10.0;
      const double majorSpacing = 50.0;
      for (double x = 0; x < size.width; x += minorSpacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), (x % majorSpacing == 0) ? majorPaint : minorPaint);
      }
      for (double y = 0; y < size.height; y += minorSpacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), (y % majorSpacing == 0) ? majorPaint : minorPaint);
      }
    } else if (pattern == 'polar') {
      final center = Offset(size.width / 2, size.height / 2);
      final maxRadius = sqrt(size.width * size.width + size.height * size.height) / 2;
      for (double r = 40.0; r < maxRadius; r += 40.0) {
        canvas.drawCircle(center, r, paint);
      }
      for (int angle = 0; angle < 360; angle += 30) {
        final rad = angle * pi / 180;
        final end = center + Offset(cos(rad) * maxRadius, sin(rad) * maxRadius);
        canvas.drawLine(center, end, paint);
      }
    } else if (pattern == 'brick') {
      const double brickW = 40.0;
      const double brickH = 20.0;
      int rowIndex = 0;
      for (double y = 0; y < size.height + brickH; y += brickH) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        final double offset = (rowIndex % 2 == 0) ? 0 : brickW / 2;
        for (double x = -offset; x < size.width + brickW; x += brickW) {
          canvas.drawLine(Offset(x, y), Offset(x, y + brickH), paint);
        }
        rowIndex++;
      }
    } else if (pattern == 'music') {
      const double lineSpacing = 8.0;
      const double groupSpacing = 40.0;
      double y = 30.0;
      while (y < size.height - 40.0) {
        for (int i = 0; i < 5; i++) {
          final double py = y + i * lineSpacing;
          canvas.drawLine(Offset(0, py), Offset(size.width, py), paint);
        }
        y += 4 * lineSpacing + groupSpacing;
      }
    } else if (pattern == 'hex') {
      const double r = 16.0;
      final double h = r * sin(pi / 3);
      final path = Path();
      for (double x = 0; x < size.width + r * 2; x += r * 3) {
        int col = 0;
        for (double y = 0; y < size.height + r * 2; y += h) {
          final double ox = (col % 2 == 0) ? 0 : r * 1.5;
          path.moveTo(ox + x, y);
          path.lineTo(ox + x + r / 2, y + h);
          path.lineTo(ox + x + r * 1.5, y + h);
          path.lineTo(ox + x + r * 2, y);
          col++;
        }
      }
      canvas.drawPath(path, paint..style = PaintingStyle.stroke);
    } else if (pattern == 'cross') {
      const double spacing = 25.0;
      const double crossSize = 3.0;
      for (double x = spacing; x < size.width; x += spacing) {
        for (double y = spacing; y < size.height; y += spacing) {
          canvas.drawLine(Offset(x - crossSize, y), Offset(x + crossSize, y), paint);
          canvas.drawLine(Offset(x, y - crossSize), Offset(x, y + crossSize), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant PreviewPatternPainter oldDelegate) => oldDelegate.pattern != pattern;
}
