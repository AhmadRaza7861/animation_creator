import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../project_repository.dart';
import '../main.dart';
import 'canvas_size_screen.dart';
import 'fps_screen.dart';

class CreateProjectScreen extends StatefulWidget {
  final ProjectRepository repository;

  const CreateProjectScreen({super.key, required this.repository});

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
  String _canvasSizeName = 'YouTube (720p)';
  int _fps = 9;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
        ];

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Background Color',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: colors.length,
                  itemBuilder: (context, index) {
                    final color = colors[index];
                    final isSelected = _backgroundColor == color;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _backgroundColor = color;
                          _backgroundImagePath = null;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 50,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.pinkAccent : Colors.black12,
                            width: isSelected ? 3 : 1.5,
                          ),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
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
                  },
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final presets = [
          {'name': 'Plain', 'value': null, 'icon': Icons.crop_din_rounded},
          {'name': 'Grid paper', 'value': 'grid', 'icon': Icons.grid_on_rounded},
          {'name': 'Dot paper', 'value': 'dots', 'icon': Icons.grain_rounded},
          {'name': 'Lined paper', 'value': 'lines', 'icon': Icons.format_align_justify_rounded},
        ];

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Background Presets',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Column(
                children: presets.map((p) {
                  final isSelected = _backgroundPattern == p['value'];

                  return ListTile(
                    leading: Icon(p['icon'] as IconData, color: isSelected ? Colors.pinkAccent : Colors.black54),
                    title: Text(
                      p['name'] as String,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.pinkAccent : Colors.black87,
                      ),
                    ),
                    trailing: isSelected ? const Icon(Icons.check, color: Colors.pinkAccent) : null,
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

    final double aspectRatio = _canvasWidth / _canvasHeight;

    final Map<String, dynamic> state = {
      'globalBackground': {
        'color': _backgroundColor.value,
        'imagePath': _backgroundImagePath,
        'imageOpacity': 1.0,
        'pattern': _backgroundPattern,
      },
      'aspectRatio': aspectRatio,
      'fps': _fps,
      'canvases': [],
    };

    final projectId = await widget.repository.saveProject(
      title: title,
      state: state,
    );

    if (mounted) {
      // Open the editor screen
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project name section
              Text(
                'Project name',
                style: TextStyle(
                  color: Colors.pinkAccent[100],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                autofocus: false,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                decoration: const InputDecoration(
                  hintText: 'Name your animation',
                  hintStyle: TextStyle(color: Colors.black12),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black12, width: 2),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.pinkAccent, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Choose background section
              Text(
                'Choose background',
                style: TextStyle(
                  color: Colors.pinkAccent[100],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              // Background Preview Box
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    children: [
                      // Paper/Solid Color background
                      Positioned.fill(
                        child: Container(
                          color: _backgroundColor,
                        ),
                      ),
                      // Custom Image background
                      if (_backgroundImagePath != null)
                        Positioned.fill(
                          child: Image.file(
                            File(_backgroundImagePath!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      // Preset Pattern overlay
                      if (_backgroundPattern != null)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: PreviewPatternPainter(_backgroundPattern!),
                          ),
                        ),
                      // Floating Toolbar
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.bookmark_border_rounded, color: Colors.black54),
                                  onPressed: _showPresetsPicker,
                                  tooltip: 'Presets',
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.format_color_fill_rounded, color: Colors.black54),
                                  onPressed: _showColorPicker,
                                  tooltip: 'Colors',
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.image_outlined, color: Colors.black54),
                                  onPressed: () => _pickImage(ImageSource.gallery),
                                  tooltip: 'Gallery',
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.camera_alt_outlined, color: Colors.black54),
                                  onPressed: () => _pickImage(ImageSource.camera),
                                  tooltip: 'Camera',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Format Section
              Text(
                'Format',
                style: TextStyle(
                  color: Colors.pinkAccent[100],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Choose canvas size', style: TextStyle(fontWeight: FontWeight.w500)),
                trailing: Text(
                  _canvasSizeName,
                  style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CanvasSizeScreen(
                        initialWidth: _canvasWidth,
                        initialHeight: _canvasHeight,
                        initialName: _canvasSizeName,
                      ),
                    ),
                  );

                  if (result != null && result is Map<String, dynamic>) {
                    setState(() {
                      _canvasWidth = result['width'] as int;
                      _canvasHeight = result['height'] as int;
                      _canvasSizeName = result['name'] as String;
                    });
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Choose frames per second', style: TextStyle(fontWeight: FontWeight.w500)),
                trailing: Text(
                  '$_fps FPS',
                  style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold),
                ),
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
              ),
              const SizedBox(height: 48),

              // Create project button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF8BBD0), // Light pink color
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _createProject,
                  child: const Text(
                    'CREATE PROJECT',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
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
