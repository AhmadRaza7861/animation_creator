import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/app_path_provider.dart';

class ImageCropScreen extends StatefulWidget {
  final File imageFile;
  final double? targetAspectRatio;
  final String? title;
  final bool lockAspectRatio;

  const ImageCropScreen({
    super.key,
    required this.imageFile,
    this.targetAspectRatio,
    this.title,
    this.lockAspectRatio = true,
  });

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  ui.Image? _image;
  bool _isLoading = true;
  String? _errorMessage;

  // Transformations
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  int _rotationQuarterTurns = 0; // 0, 1, 2, 3 (0, 90, 180, 270 degrees)
  bool _flipX = false;
  bool _flipY = false;
  bool _isCoverMode = true;

  // Gesture tracking
  Offset _startOffset = Offset.zero;
  double _startScale = 1.0;
  Offset _startFocalPoint = Offset.zero;

  // Target aspect ratio
  late double _aspectRatio;

  @override
  void initState() {
    super.initState();
    _aspectRatio = widget.targetAspectRatio ?? (16.0 / 9.0);
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      if (!await widget.imageFile.exists()) {
        throw Exception('Image file not found');
      }
      final Uint8List bytes = await widget.imageFile.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image loadedImage = frameInfo.image;

      if (!mounted) return;
      setState(() {
        _image = loadedImage;
        _isLoading = false;
        if (widget.targetAspectRatio == null && loadedImage.height > 0) {
          _aspectRatio = loadedImage.width / loadedImage.height;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load image: $e';
      });
    }
  }

  String _getAspectRatioLabel() {
    if ((_aspectRatio - 16.0 / 9.0).abs() < 0.05) return '16:9';
    if ((_aspectRatio - 9.0 / 16.0).abs() < 0.05) return '9:16';
    if ((_aspectRatio - 1.0).abs() < 0.05) return '1:1';
    if ((_aspectRatio - 4.0 / 3.0).abs() < 0.05) return '4:3';
    if ((_aspectRatio - 3.0 / 4.0).abs() < 0.05) return '3:4';
    if ((_aspectRatio - 3.0 / 2.0).abs() < 0.05) return '3:2';
    return '${_aspectRatio.toStringAsFixed(2)}:1';
  }

  Rect _calculateCropRect(Size availableSize) {
    const double margin = 24.0;
    final double availW = math.max(10.0, availableSize.width - (margin * 2));
    final double availH = math.max(10.0, availableSize.height - (margin * 2));

    double cropW;
    double cropH;

    if (availW / availH > _aspectRatio) {
      cropH = availH;
      cropW = cropH * _aspectRatio;
    } else {
      cropW = availW;
      cropH = cropW / _aspectRatio;
    }

    final Offset center = Offset(availableSize.width / 2, availableSize.height / 2);
    return Rect.fromCenter(center: center, width: cropW, height: cropH);
  }

  double _calculateBaseScale(Rect cropRect) {
    if (_image == null) return 1.0;
    final bool isRotated90or270 = _rotationQuarterTurns % 2 != 0;
    final double imgW = (isRotated90or270 ? _image!.height : _image!.width).toDouble();
    final double imgH = (isRotated90or270 ? _image!.width : _image!.height).toDouble();

    if (imgW <= 0 || imgH <= 0) return 1.0;

    if (_isCoverMode) {
      return math.max(cropRect.width / imgW, cropRect.height / imgH);
    } else {
      return math.min(cropRect.width / imgW, cropRect.height / imgH);
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    _startOffset = _offset;
    _startScale = _scale;
    _startFocalPoint = details.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _offset = _startOffset + (details.localFocalPoint - _startFocalPoint);
      _scale = (_startScale * details.scale).clamp(0.2, 10.0);
    });
  }

  void _toggleFlipHorizontal() {
    setState(() {
      _flipX = !_flipX;
    });
  }

  void _toggleFlipVertical() {
    setState(() {
      _flipY = !_flipY;
    });
  }

  void _rotateLeft() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns - 1) % 4;
      if (_rotationQuarterTurns < 0) _rotationQuarterTurns += 4;
    });
  }

  void _rotateRight() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
    });
  }

  void _toggleFitCover() {
    setState(() {
      _isCoverMode = !_isCoverMode;
      _scale = 1.0;
      _offset = Offset.zero;
    });
  }

  void _resetTransforms() {
    setState(() {
      _scale = 1.0;
      _offset = Offset.zero;
      _rotationQuarterTurns = 0;
      _flipX = false;
      _flipY = false;
      _isCoverMode = true;
    });
  }

  Future<void> _confirmCrop(Rect cropRect) async {
    if (_image == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: ColorConstants.primary),
                SizedBox(height: 16),
                Text(
                  StringConstants.processing_image,
                  style: TextStyle(fontWeight: FontWeight.w600, color: ColorConstants.darkText),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Calculate export resolution matching target aspect ratio (high-resolution output)
      const double targetWidth = 1920.0;
      final double targetHeight = targetWidth / _aspectRatio;

      final double outputScale = targetWidth / cropRect.width;
      final double baseScale = _calculateBaseScale(cropRect);

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, targetWidth, targetHeight),
      );

      // Map canvas from cropRect coordinate space to output coordinate space
      canvas.scale(outputScale);
      canvas.translate(-cropRect.left, -cropRect.top);

      // Apply the image's transforms exactly as displayed in the viewport
      canvas.save();
      canvas.translate(cropRect.center.dx + _offset.dx, cropRect.center.dy + _offset.dy);
      canvas.rotate(_rotationQuarterTurns * (math.pi / 2.0));
      canvas.scale(
        (_flipX ? -1.0 : 1.0) * baseScale * _scale,
        (_flipY ? -1.0 : 1.0) * baseScale * _scale,
      );

      final Paint paint = Paint()..filterQuality = FilterQuality.high;
      canvas.drawImage(
        _image!,
        Offset(-_image!.width / 2.0, -_image!.height / 2.0),
        paint,
      );
      canvas.restore();

      final ui.Picture picture = recorder.endRecording();
      final ui.Image croppedImg = await picture.toImage(targetWidth.round(), targetHeight.round());
      final ByteData? byteData = await croppedImg.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to encode cropped image to PNG');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final Directory tempDir = await AppPathProvider.getSafeTempDirectory();
      final String croppedPath =
          '${tempDir.path}/cropped_bg_${DateTime.now().millisecondsSinceEpoch}.png';
      final File croppedFile = File(croppedPath);
      await croppedFile.writeAsBytes(pngBytes);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      Navigator.pop(context, croppedPath); // Return cropped path
    } catch (e) {
      debugPrint('Error cropping image: $e');
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to crop image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Material(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.pop(context),
              child: const Center(
                child: Icon(
                  Icons.close_rounded,
                  color: ColorConstants.darkText,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title ?? StringConstants.image_import,
              style: const TextStyle(
                color: ColorConstants.darkText,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: ColorConstants.primaryLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ColorConstants.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                _getAspectRatioLabel(),
                style: const TextStyle(
                  color: ColorConstants.primaryDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (!_isLoading && _image != null)
            LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Material(
                    color: ColorConstants.primary,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        final Size screenSize = MediaQuery.of(context).size;
                        final double topBarHeight = MediaQuery.of(context).padding.top + kToolbarHeight;
                        const double bottomBarHeight = 100.0;
                        final Size availableSize = Size(
                          screenSize.width,
                          screenSize.height - topBarHeight - bottomBarHeight,
                        );
                        final Rect cropRect = _calculateCropRect(availableSize);
                        _confirmCrop(cropRect);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Center(
                          child: Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: ColorConstants.primary),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: ColorConstants.destructive),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      // Interactive Crop Canvas Area
                      Positioned.fill(
                        bottom: 90, // Leave room for floating bottom toolbar
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final Size availableSize = Size(constraints.maxWidth, constraints.maxHeight);
                            final Rect cropRect = _calculateCropRect(availableSize);
                            final double baseScale = _calculateBaseScale(cropRect);

                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onScaleStart: _onScaleStart,
                              onScaleUpdate: _onScaleUpdate,
                              onDoubleTap: _toggleFitCover,
                              child: CustomPaint(
                                size: availableSize,
                                painter: _CropViewportPainter(
                                  image: _image!,
                                  cropRect: cropRect,
                                  scale: _scale,
                                  baseScale: baseScale,
                                  offset: _offset,
                                  rotationQuarterTurns: _rotationQuarterTurns,
                                  flipX: _flipX,
                                  flipY: _flipY,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Floating Bottom Toolbar
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 16,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: ColorConstants.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildToolButton(
                                  icon: Icons.flip_rounded,
                                  tooltip: 'Flip Horizontal',
                                  isActive: _flipX,
                                  onTap: _toggleFlipHorizontal,
                                ),
                                const SizedBox(width: 4),
                                _buildToolButton(
                                  iconWidget: const RotatedBox(
                                    quarterTurns: 1,
                                    child: Icon(Icons.flip_rounded, size: 20),
                                  ),
                                  tooltip: 'Flip Vertical',
                                  isActive: _flipY,
                                  onTap: _toggleFlipVertical,
                                ),
                                const SizedBox(width: 4),
                                _buildToolButton(
                                  icon: Icons.rotate_left_rounded,
                                  tooltip: 'Rotate Left',
                                  onTap: _rotateLeft,
                                ),
                                const SizedBox(width: 4),
                                _buildToolButton(
                                  icon: Icons.rotate_right_rounded,
                                  tooltip: 'Rotate Right',
                                  onTap: _rotateRight,
                                ),
                                const SizedBox(width: 4),
                                _buildToolButton(
                                  icon: _isCoverMode
                                      ? Icons.open_in_full_rounded
                                      : Icons.close_fullscreen_rounded,
                                  tooltip: _isCoverMode ? 'Fit Entire Image' : 'Cover Canvas',
                                  isActive: !_isCoverMode,
                                  onTap: _toggleFitCover,
                                ),
                                const SizedBox(width: 4),
                                _buildToolButton(
                                  icon: Icons.restart_alt_rounded,
                                  tooltip: 'Reset Transforms',
                                  onTap: _resetTransforms,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildToolButton({
    IconData? icon,
    Widget? iconWidget,
    required String tooltip,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive ? ColorConstants.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: iconWidget ??
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? ColorConstants.primaryDark : ColorConstants.darkText,
                ),
          ),
        ),
      ),
    );
  }
}

class _CropViewportPainter extends CustomPainter {
  final ui.Image image;
  final Rect cropRect;
  final double scale;
  final double baseScale;
  final Offset offset;
  final int rotationQuarterTurns;
  final bool flipX;
  final bool flipY;

  _CropViewportPainter({
    required this.image,
    required this.cropRect,
    required this.scale,
    required this.baseScale,
    required this.offset,
    required this.rotationQuarterTurns,
    required this.flipX,
    required this.flipY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect canvasRect = Offset.zero & size;

    // 1. Draw Image with transformations
    canvas.save();
    canvas.translate(cropRect.center.dx + offset.dx, cropRect.center.dy + offset.dy);
    canvas.rotate(rotationQuarterTurns * (math.pi / 2.0));
    canvas.scale(
      (flipX ? -1.0 : 1.0) * baseScale * scale,
      (flipY ? -1.0 : 1.0) * baseScale * scale,
    );

    final Paint imgPaint = Paint()..filterQuality = FilterQuality.medium;
    canvas.drawImage(
      image,
      Offset(-image.width / 2.0, -image.height / 2.0),
      imgPaint,
    );
    canvas.restore();

    // 2. Dimmed Mask Outside Crop Rect
    final Path outsidePath = Path.combine(
      PathOperation.difference,
      Path()..addRect(canvasRect),
      Path()..addRect(cropRect),
    );
    final Paint maskPaint = Paint()..color = const Color(0x990F172A); // Translucent Slate overlay
    canvas.drawPath(outsidePath, maskPaint);

    // 3. Rule of Thirds Grid Inside Crop Rect
    final Paint gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final double stepX = cropRect.width / 3.0;
    final double stepY = cropRect.height / 3.0;

    canvas.drawLine(
      Offset(cropRect.left + stepX, cropRect.top),
      Offset(cropRect.left + stepX, cropRect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left + stepX * 2, cropRect.top),
      Offset(cropRect.left + stepX * 2, cropRect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + stepY),
      Offset(cropRect.right, cropRect.top + stepY),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + stepY * 2),
      Offset(cropRect.right, cropRect.top + stepY * 2),
      gridPaint,
    );

    // 4. Crop Box Border
    final Paint borderPaint = Paint()
      ..color = ColorConstants.primary
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(cropRect, borderPaint);

    // 5. Studio Viewfinder L-shaped Corner Framing Brackets
    final Paint cornerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    const double cornerLen = 18.0;

    // Top-Left
    canvas.drawLine(Offset(cropRect.left, cropRect.top + cornerLen), Offset(cropRect.left, cropRect.top), cornerPaint);
    canvas.drawLine(Offset(cropRect.left, cropRect.top), Offset(cropRect.left + cornerLen, cropRect.top), cornerPaint);

    // Top-Right
    canvas.drawLine(Offset(cropRect.right - cornerLen, cropRect.top), Offset(cropRect.right, cropRect.top), cornerPaint);
    canvas.drawLine(Offset(cropRect.right, cropRect.top), Offset(cropRect.right, cropRect.top + cornerLen), cornerPaint);

    // Bottom-Left
    canvas.drawLine(Offset(cropRect.left, cropRect.bottom - cornerLen), Offset(cropRect.left, cropRect.bottom), cornerPaint);
    canvas.drawLine(Offset(cropRect.left, cropRect.bottom), Offset(cropRect.left + cornerLen, cropRect.bottom), cornerPaint);

    // Bottom-Right
    canvas.drawLine(Offset(cropRect.right - cornerLen, cropRect.bottom), Offset(cropRect.right, cropRect.bottom), cornerPaint);
    canvas.drawLine(Offset(cropRect.right, cropRect.bottom), Offset(cropRect.right, cropRect.bottom - cornerLen), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _CropViewportPainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.offset != offset ||
        oldDelegate.rotationQuarterTurns != rotationQuarterTurns ||
        oldDelegate.flipX != flipX ||
        oldDelegate.flipY != flipY ||
        oldDelegate.cropRect != cropRect ||
        oldDelegate.baseScale != baseScale;
  }
}
