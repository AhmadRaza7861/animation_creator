import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_assets.dart';

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

  static const List<CanvasPreset> _presets = [
    CanvasPreset('YouTube (1080p)', 1920, 1080),
    CanvasPreset('YouTube (720p)', 1280, 720),
    CanvasPreset('Instagram (16x9)', 1920, 1080),
    CanvasPreset('Instagram (1x1)', 1080, 1080),
    CanvasPreset('TikTok (1080p)', 1080, 1920),
    CanvasPreset('TikTok (720p)', 720, 1280),
    CanvasPreset('Vimeo (1080p)', 1920, 1080),
    CanvasPreset('Facebook (720p)', 1280, 720),
    CanvasPreset('Tumblr (16x9)', 1280, 720),
    CanvasPreset('Tumblr (4x3)', 1024, 768),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkText),
          onPressed: () {
            Navigator.pop(context, {
              'width': _width,
              'height': _height,
              'name': _presetName,
            });
          },
        ),
        title: const Text(
          'Canvas size',
          style: TextStyle(
            color: AppColors.darkText,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WIDTH',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                                  color: AppColors.darkText,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black12, width: 2),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: AppColors.accent, width: 2),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'px',
                              style: TextStyle(
                                color: Colors.grey[600],
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
                        color: _isAspectRatioLocked ? AppColors.accent : Colors.grey,
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
                          'HEIGHT',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                                  color: AppColors.darkText,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black12, width: 2),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: AppColors.accent, width: 2),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'px',
                              style: TextStyle(
                                color: Colors.grey[600],
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
            const Divider(height: 1),
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
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.darkText : Colors.black54,
                      ),
                    ),
                    subtitle: Text(
                      '${preset.width} x ${preset.height}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.accent,
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
