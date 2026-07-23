import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../repositories/project_repository.dart';
import '../main.dart';
import '../widgets/color_picker_dialog.dart';
import 'canvas_size_screen.dart';
import 'fps_screen.dart';

import 'templates_screen.dart';

class CreateProjectScreen extends StatefulWidget {
  final ProjectRepository repository;
  final TemplateModel? template;
  final TemplateMode? templateMode;

  const CreateProjectScreen({
    super.key,
    required this.repository,
    this.template,
    this.templateMode,
  });

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  // Background state
  Color _backgroundColor = Colors.white;
  String? _backgroundImagePath;
  String? _backgroundPattern; // 'grid', 'dots', 'lines', null

  // Format state
  int _canvasWidth = 1280;
  int _canvasHeight = 720;
  String _canvasSizeLabel = 'Landscape (16:9)';
  int _fps = 14;
  String _exportType = 'Mp4'; // 'Mp4' or 'GIF'

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      _nameController.text = '${widget.template!.name} Animation';
      _loadTemplateDimensions();
    }
  }

  Future<void> _loadTemplateDimensions() async {
    try {
      final data = await rootBundle.load(widget.template!.previewAsset);
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      
      setState(() {
        _canvasWidth = image.width;
        _canvasHeight = image.height;
        
        final double ratio = _canvasWidth / _canvasHeight;
        if ((ratio - 1.0).abs() < 0.05) {
          _canvasSizeLabel = 'Square (1:1)';
        } else if ((ratio - 16.0 / 9.0).abs() < 0.05) {
          _canvasSizeLabel = 'Landscape (16:9)';
        } else if ((ratio - 9.0 / 16.0).abs() < 0.05) {
          _canvasSizeLabel = 'Portrait (9:16)';
        } else {
          _canvasSizeLabel = 'Template Ratio (${_canvasWidth}:${_canvasHeight})';
        }
      });
    } catch (e) {
      debugPrint('Failed to load template dimensions: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _openCustomBackgroundColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ColorPickerDialog(
          initialColor: _backgroundColor,
          initialOpacity: _backgroundColor.opacity,
          onColorChanged: (Color newColor, double newOpacity) {
            setState(() {
              _backgroundColor = newColor.withValues(alpha: newOpacity);
              _backgroundImagePath = null;
            });
          },
        );
      },
    );
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final colors = [
          Colors.white,
          const Color(0xFFFDFBF7), // Ivory
          const Color(0xFFF3E5F5), // Lavender
          const Color(0xFFFFF3E0), // Peach
          const Color(0xFFE8F5E9), // Mint
          const Color(0xFFE1F5FE), // Sky
          const Color(0xFFECEFF1), // Light Grey
          const Color(0xFF37474F), // Slate/Dark Mode
          const Color(0xFF1E1E1E), // Black/Dark
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Background Color',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3C3043),
                ),
              ),
              const SizedBox(height: 24),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...colors.map((color) {
                      final isSelected = _backgroundColor == color && _backgroundImagePath == null;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _backgroundColor = color;
                            _backgroundImagePath = null;
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          margin: const EdgeInsets.only(right: 14),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? const Color(0xFFFF9114) : Colors.black12,
                              width: isSelected ? 3 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  color: color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                                )
                              : null,
                        ),
                      );
                    }).toList(),

                    // If custom color is currently selected, show it here!
                    if (_backgroundImagePath == null && !colors.contains(_backgroundColor))
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _openCustomBackgroundColorPicker();
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          margin: const EdgeInsets.only(right: 14),
                          decoration: BoxDecoration(
                            color: _backgroundColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFF9114),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: Icon(
                            Icons.check,
                            color: _backgroundColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                          ),
                        ),
                      ),

                    // Add Custom Color Button
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _openCustomBackgroundColorPicker();
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black12,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 24,
                          color: Color(0xFFBEB9C5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPresetsPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final presets = [
          {'name': 'Plain', 'value': null, 'icon': Icons.crop_din_rounded},
          {'name': 'Grid paper', 'value': 'grid', 'icon': Icons.grid_on_rounded},
          {'name': 'Dot paper', 'value': 'dots', 'icon': Icons.grain_rounded},
          {'name': 'Lined paper', 'value': 'lines', 'icon': Icons.format_align_justify_rounded},
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Background Presets',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3C3043),
                ),
              ),
              const SizedBox(height: 16),
              Column(
                children: presets.map((p) {
                  final isSelected = _backgroundPattern == p['value'];

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFFF2E5) : const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        p['icon'] as IconData,
                        color: isSelected ? const Color(0xFFFF9114) : Colors.black54,
                      ),
                    ),
                    title: Text(
                      p['name'] as String,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? const Color(0xFFFF9114) : const Color(0xFF3C3043),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Color(0xFFFF9114))
                        : null,
                    onTap: () {
                      setState(() {
                        _backgroundPattern = p['value'] as String?;
                      });
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _backgroundImagePath = pickedFile.path;
          _backgroundPattern = null;
        });
      }
    } catch (e) {
      debugPrint('Failed to pick background image: $e');
    }
  }


  Future<void> _createProject() async {
    final title = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'My Animation';

    if (widget.template != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: const Row(
              children: [
                CircularProgressIndicator(color: Color(0xFF5C52E5)),
                SizedBox(width: 24),
                Text(
                  'Creating Project...',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    try {
      final double aspectRatio = _canvasWidth / _canvasHeight;
      final List<Map<String, dynamic>> canvasesData = [];

      if (widget.template != null) {
        final paintColor = widget.templateMode == TemplateMode.drawAccordingTemplate
            ? Colors.grey.withOpacity(0.35)
            : Colors.black;

        for (int i = 0; i < widget.template!.frameCount; i++) {
          final imageUrl = widget.template!.frameAssets[i];
          final Map<String, dynamic> imageContentJson = {
            'type': 'ImageContent',
            'startPoint': {'dx': 0.0, 'dy': 0.0},
            'size': {'dx': _canvasWidth.toDouble(), 'dy': _canvasHeight.toDouble()},
            'imageUrl': imageUrl,
            'paint': {
              'color': paintColor.value,
              'strokeWidth': 4.0,
              'isAntiAlias': true,
              'style': PaintingStyle.stroke.index,
              'strokeCap': StrokeCap.round.index,
              'strokeJoin': StrokeJoin.round.index,
              'blendMode': BlendMode.srcOver.index,
              'invertColors': false,
              'filterQuality': ui.FilterQuality.none.index,
              'colorFilter': null,
              'imageFilter': null,
              'maskFilter': null,
            }
          };

          canvasesData.add({
            'size': null,
            'backgroundColor': Colors.white.value,
            'layers': [
              {
                'id': 'layer_0',
                'name': 'Layer 1',
                'isVisible': true,
                'isLocked': false,
                'opacity': 1.0,
                'blendMode': BlendMode.srcOver.index,
                'currentIndex': 1,
                'history': [imageContentJson],
              }
            ],
            'activeLayerId': 'layer_0',
          });
        }
      }

      final Map<String, dynamic> state = {
        'globalBackground': {
          'color': _backgroundColor.value,
          'imagePath': _backgroundImagePath,
          'imageOpacity': 1.0,
          'pattern': _backgroundPattern,
        },
        'aspectRatio': aspectRatio,
        'fps': _fps,
        'exportType': _exportType,
        'canvases': canvasesData,
      };

      final projectId = await widget.repository.saveProject(
        title: title,
        state: state,
      );

      if (mounted) {
        if (widget.template != null) {
          // Dismiss creating dialog
          Navigator.of(context, rootNavigator: true).pop();
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MyHomePage(
              repository: widget.repository,
              projectId: projectId,
            ),
          ),
        );
      }
    } catch (e) {
      if (widget.template != null && mounted) {
        // Dismiss dialog on error
        Navigator.of(context, rootNavigator: true).pop();
      }
      debugPrint('Failed to create template project: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF3C3043)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Project',
          style: TextStyle(
            color: Color(0xFF3C3043),
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Project Name Field
              const Text(
                'Project Name',
                style: TextStyle(
                  color: Color(0xFF3C3043),
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3C3043),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Name Your Animation',
                    hintStyle: TextStyle(
                      color: Color(0xFFBEB9C5),
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Aspect Ratio Dropdown
              const Text(
                'Aspect Ratio',
                style: TextStyle(
                  color: Color(0xFF3C3043),
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: widget.template != null ? null : () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CanvasSizeScreen(
                        initialWidth: _canvasWidth,
                        initialHeight: _canvasHeight,
                        initialName: _canvasSizeLabel,
                      ),
                    ),
                  );

                  if (result != null && result is Map<String, dynamic>) {
                    setState(() {
                      _canvasWidth = result['width'] as int;
                      _canvasHeight = result['height'] as int;
                      _canvasSizeLabel = result['name'] as String;
                    });
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  child: Row(
                    children: [
                      Text(
                        _canvasSizeLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3C3043),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        widget.template != null ? Icons.lock_outline_rounded : Icons.keyboard_arrow_down,
                        color: const Color(0xFF8E8895),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 3. Frame Rate Dropdown
              const Text(
                'Frame Rate',
                style: TextStyle(
                  color: Color(0xFF3C3043),
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FpsScreen(initialFps: _fps),
                    ),
                  );

                  if (result != null && result is int) {
                    setState(() {
                      _fps = result;
                    });
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  child: Row(
                    children: [
                      Text(
                        '${_fps}fps',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3C3043),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFF8E8895),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 4. Export Type Selector
              const Text(
                'Export Type',
                style: TextStyle(
                  color: Color(0xFF3C3043),
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(26),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    // Mp4
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _exportType = 'Mp4';
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _exportType == 'Mp4' ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: _exportType == 'Mp4'
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Mp4',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: _exportType == 'Mp4' ? FontWeight.bold : FontWeight.w600,
                              color: _exportType == 'Mp4' ? const Color(0xFF3C3043) : const Color(0xFF8E8895),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // GIF
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _exportType = 'GIF';
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _exportType == 'GIF' ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: _exportType == 'GIF'
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'GIF',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: _exportType == 'GIF' ? FontWeight.bold : FontWeight.w600,
                              color: _exportType == 'GIF' ? const Color(0xFF3C3043) : const Color(0xFF8E8895),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. Background Section
              Row(
                children: [
                  const Text(
                    'Background',
                    style: TextStyle(
                      color: Color(0xFF3C3043),
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  // Presets Icon
                  IconButton(
                    icon: const Icon(Icons.grid_on_outlined, color: Color(0xFF3C3043), size: 22),
                    onPressed: _showPresetsPicker,
                    tooltip: 'Presets',
                  ),
                  // Color Fill Icon
                  IconButton(
                    icon: const Icon(Icons.format_color_fill_outlined, color: Color(0xFF3C3043), size: 22),
                    onPressed: _showColorPicker,
                    tooltip: 'Colors',
                  ),
                  // Gallery Icon
                  IconButton(
                    icon: const Icon(Icons.image_outlined, color: Color(0xFF3C3043), size: 22),
                    onPressed: () => _pickImage(ImageSource.gallery),
                    tooltip: 'Gallery',
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Background Preview Box
              GestureDetector(
                onTap: () {
                  // Prompt to select background
                  _showColorPicker();
                },
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12.withOpacity(0.05)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      children: [
                        // Solid color
                        Positioned.fill(
                          child: Container(
                            color: _backgroundColor,
                          ),
                        ),
                        // Image file
                        if (_backgroundImagePath != null)
                          Positioned.fill(
                            child: Image.file(
                              File(_backgroundImagePath!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        // Pattern painter overlay
                        if (_backgroundPattern != null)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: PreviewPatternPainter(_backgroundPattern!),
                            ),
                          ),
                        // Center +Add text
                        const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '+ Add',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFBEB9C5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // 6. Apply Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9114),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _createProject,
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
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
      const double spacing = 15.0;
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    } else if (pattern == 'dots') {
      const double spacing = 15.0;
      final dotPaint = Paint()..color = Colors.black.withOpacity(0.15);
      for (double x = spacing / 2; x < size.width; x += spacing) {
        for (double y = spacing / 2; y < size.height; y += spacing) {
          canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
        }
      }
    } else if (pattern == 'lines') {
      const double spacing = 18.0;
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
      final marginPaint = Paint()
        ..color = Colors.redAccent.withOpacity(0.2)
        ..strokeWidth = 1.2;
      canvas.drawLine(const Offset(30, 0), Offset(30, size.height), marginPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PreviewPatternPainter oldDelegate) => oldDelegate.pattern != pattern;
}
