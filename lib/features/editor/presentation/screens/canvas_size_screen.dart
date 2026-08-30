import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';

class CanvasPreset {
  final String name;
  final int width;
  final int height;

  const CanvasPreset(this.name, this.width, this.height);

  double get aspectRatio => width / height;
}

class CanvasSizeScreen extends StatefulWidget {
  final int initialWidth;
  final int initialHeight;
  final String initialName;

  const CanvasSizeScreen({
    super.key,
    required this.initialWidth,
    required this.initialHeight,
    required this.initialName,
  });

  @override
  State<CanvasSizeScreen> createState() => _CanvasSizeScreenState();
}

class _CanvasSizeScreenState extends State<CanvasSizeScreen> {
  late int _width;
  late int _height;
  late String _presetName;
  bool _isAspectRatioLocked = true;

  late TextEditingController _widthController;
  late TextEditingController _heightController;

  static final List<CanvasPreset> _presets = [
    CanvasPreset('${StringConstants.youTube} (1080p)', 1920, 1080),
    CanvasPreset('${StringConstants.youTube} (720p)', 1280, 720),
    CanvasPreset('${StringConstants.instagram} (16x9)', 1920, 1080),
    CanvasPreset('${StringConstants.instagram} (1x1)', 1080, 1080),
    CanvasPreset('${StringConstants.tikTok} (1080p)', 1080, 1920),
    CanvasPreset('${StringConstants.tikTok} (720p)', 720, 1280),
    CanvasPreset('${StringConstants.vimeo} (1080p)', 1920, 1080),
    CanvasPreset('${StringConstants.facebook} (720p)', 1280, 720),
    CanvasPreset('${StringConstants.tumblr} (16x9)', 1280, 720),
    CanvasPreset('${StringConstants.tumblr} (4x3)', 1024, 768),
  ];

  @override
  void initState() {
    super.initState();
    _width = widget.initialWidth;
    _height = widget.initialHeight;
    _presetName = widget.initialName;

    _widthController = TextEditingController(text: '$_width');
    _heightController = TextEditingController(text: '$_height');
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _onPresetSelected(CanvasPreset preset) {
    setState(() {
      _width = preset.width;
      _height = preset.height;
      _presetName = preset.name;
      _widthController.text = '$_width';
      _heightController.text = '$_height';
    });
  }

  void _onWidthChanged(String value) {
    final newWidth = int.tryParse(value);
    if (newWidth == null || newWidth <= 0) return;

    setState(() {
      final oldWidth = _width;
      _width = newWidth;
      if (_isAspectRatioLocked && oldWidth > 0) {
        final ratio = _height / oldWidth;
        _height = (newWidth * ratio).round();
        _heightController.text = '$_height';
      }
      _updatePresetNameForDimensions();
    });
  }

  void _onHeightChanged(String value) {
    final newHeight = int.tryParse(value);
    if (newHeight == null || newHeight <= 0) return;

    setState(() {
      final oldHeight = _height;
      _height = newHeight;
      if (_isAspectRatioLocked && oldHeight > 0) {
        final ratio = _width / oldHeight;
        _width = (newHeight * ratio).round();
        _widthController.text = '$_width';
      }
      _updatePresetNameForDimensions();
    });
  }

  void _updatePresetNameForDimensions() {
    for (final preset in _presets) {
      if (preset.width == _width && preset.height == _height) {
        _presetName = preset.name;
        return;
      }
    }
    _presetName = 'Custom';
  }

  IconData _getPlatformIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('youtube')) {
      return Icons.play_circle_fill_rounded;
    } else if (lower.contains('instagram')) {
      return Icons.camera_alt_rounded;
    } else if (lower.contains('tiktok')) {
      return Icons.phone_android_rounded;
    } else if (lower.contains('vimeo')) {
      return Icons.video_collection_rounded;
    } else if (lower.contains('facebook')) {
      return Icons.facebook_rounded;
    } else if (lower.contains('tumblr')) {
      return Icons.photo_size_select_actual_rounded;
    }
    return Icons.aspect_ratio_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
   //   backgroundColor: ColorConstants.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorConstants.darkText),
          onPressed: () {
            Navigator.pop(context); // Pop without returning data (cancels changes)
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, {
                'width': _width,
                'height': _height,
                'name': _presetName,
              });
            },
            child: const Text(
              'Done',
              style: TextStyle(
                color: ColorConstants.accent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        title:  Text(
          StringConstants.canvasSize,
          style: TextStyle(
            color: ColorConstants.text_color,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Aspect Ratio Preview Section
            Container(
              height: 170,
              width: double.infinity,
              color: Colors.grey.shade50,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Center(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final double maxW = constraints.maxWidth - 20;
                            final double maxH = constraints.maxHeight - 20;
                            final double ratio = _width / _height;
                            
                            double widthVal;
                            double heightVal;
                            if (ratio > maxW / maxH) {
                              widthVal = maxW;
                              heightVal = maxW / ratio;
                            } else {
                              heightVal = maxH;
                              widthVal = maxH * ratio;
                            }

                            final IconData platformIcon = _getPlatformIcon(_presetName);

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              width: widthVal,
                              height: heightVal,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: ColorConstants.accent,
                                  width: 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Grid pattern overlay for canvas texture
                                  Positioned.fill(
                                    child: Opacity(
                                      opacity: 0.04,
                                      child: CustomPaint(
                                        painter: const PreviewGridPainter(),
                                      ),
                                    ),
                                  ),
                                  // Center labels & Icon
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          platformIcon,
                                          size: (heightVal > 60) ? 24 : 16,
                                          color: ColorConstants.accent,
                                        ),
                                        if (heightVal > 70) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            _presetName,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: ColorConstants.darkText,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${_width}x${_height}',
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.grey[500],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1,color: ColorConstants.divider_color,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          StringConstants.width,
                          style: TextStyle(
                            color: ColorConstants.text_sub2_color,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _widthController,
                                keyboardType: TextInputType.number,
                                onChanged: _onWidthChanged,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: ColorConstants.darkText,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black12, width: 2),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: ColorConstants.accent, width: 2),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'px',
                              style: TextStyle(
                                color: ColorConstants.text_sub2_color,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: IconButton(
                      icon: Icon(
                        _isAspectRatioLocked ? Icons.link : Icons.link_off,
                        color: _isAspectRatioLocked ? ColorConstants.accent : Colors.grey,
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() {
                          _isAspectRatioLocked = !_isAspectRatioLocked;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          StringConstants.height,
                          style: TextStyle(
                            color: ColorConstants.text_sub2_color,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _heightController,
                                keyboardType: TextInputType.number,
                                onChanged: _onHeightChanged,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: ColorConstants.darkText,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black12, width: 2),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: ColorConstants.accent, width: 2),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'px',
                              style: TextStyle(
                                color: ColorConstants.text_sub2_color,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
             Divider(height: 1,color: ColorConstants.divider_color,),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: _presets.length,
                itemBuilder: (context, index) {
                  final preset = _presets[index];
                  final isSelected = _presetName == preset.name &&
                      _width == preset.width &&
                      _height == preset.height;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    title: Text(
                      preset.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                        color: isSelected ? ColorConstants.text_color : ColorConstants.text_color,
                      ),
                    ),
                    subtitle: Text(
                      '${preset.width} x ${preset.height}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 16,fontWeight: FontWeight.w400),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: ColorConstants.accent,
                            size: 24,
                          )
                        : null,
                    onTap: () => _onPresetSelected(preset),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PreviewGridPainter extends CustomPainter {
  const PreviewGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 0.5;

    const double step = 8.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
