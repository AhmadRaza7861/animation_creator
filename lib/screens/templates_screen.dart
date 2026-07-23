import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../main.dart';
import '../repositories/project_repository.dart';
import 'template_detail_screen.dart';

enum TemplateMode {
  useTemplate,
  drawAccordingTemplate,
}

class TemplateModel {
  final String id;
  final String name;
  final String folder;
  final String extension;
  final int frameCount;

  const TemplateModel({
    required this.id,
    required this.name,
    required this.folder,
    required this.extension,
    required this.frameCount,
  });

  String get previewAsset => 'assets/animal/$folder/1$extension';

  List<String> get frameAssets {
    return List.generate(frameCount, (index) => 'assets/animal/$folder/${index + 1}$extension');
  }
}

class TemplatesScreen extends StatefulWidget {
  final ProjectRepository repository;

  const TemplatesScreen({super.key, required this.repository});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  final List<TemplateModel> _templates = const [
    TemplateModel(id: 'bird', name: 'Bird', folder: 'bird', extension: '.png', frameCount: 5),
    TemplateModel(id: 'bird1', name: 'Bird 1', folder: 'bird1', extension: '.webp', frameCount: 6),
    TemplateModel(id: 'birdfly', name: 'Bird Fly', folder: 'birdfly', extension: '.webp', frameCount: 9),
    TemplateModel(id: 'cat', name: 'Cat', folder: 'cat', extension: '.png', frameCount: 12),
    TemplateModel(id: 'catlove', name: 'Cat Love', folder: 'catlove', extension: '.webp', frameCount: 6),
    TemplateModel(id: 'cute_dog', name: 'Cute Dog', folder: 'cute_dog', extension: '.webp', frameCount: 6),
    TemplateModel(id: 'dancingDog', name: 'Dancing Dog', folder: 'dancingDog', extension: '.webp', frameCount: 12),
    TemplateModel(id: 'dog', name: 'Dog', folder: 'dog', extension: '.webp', frameCount: 8),
    TemplateModel(id: 'duckWalk', name: 'Duck Walk', folder: 'duckWalk', extension: '.webp', frameCount: 7),
    TemplateModel(id: 'monkeey', name: 'Monkeey', folder: 'monkeey', extension: '.png', frameCount: 4),
    TemplateModel(id: 'monkey', name: 'Monkey', folder: 'monkey', extension: '.webp', frameCount: 8),
    TemplateModel(id: 'penguin', name: 'Penguin', folder: 'penguin', extension: '.webp', frameCount: 8),
    TemplateModel(id: 'rabbit', name: 'Rabbit', folder: 'rabbit', extension: '.webp', frameCount: 8),
    TemplateModel(id: 'turtle', name: 'Turtle', folder: 'turtle', extension: '.webp', frameCount: 8),
  ];

  Future<ui.Image> _loadUiImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<void> _selectTemplate(TemplateModel template) async {
    // Show Loading Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              const CircularProgressIndicator(color: Color(0xFFFF9114)),
              const SizedBox(width: 24),
              Expanded(
                child: Text(
                  'Importing "${template.name}"...',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF3C3043)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final List<Map<String, dynamic>> canvasesData = [];
      ui.Image? firstFrameImage;

      // Load all frames
      for (int i = 0; i < template.frameCount; i++) {
        final assetPath = template.frameAssets[i];
        final image = await _loadUiImage(assetPath);
        if (i == 0) {
          firstFrameImage = image;
        }

        final double width = image.width.toDouble();
        final double height = image.height.toDouble();

        // Build history layer for ImageContent
        final List<Map<String, dynamic>> historyJson = [
          {
            'type': 'ImageContent',
            'startPoint': {'dx': 0.0, 'dy': 0.0},
            'size': {'dx': width, 'dy': height},
            'imageUrl': assetPath,
            'paint': {
              'color': Colors.black.value,
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
          }
        ];

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
              'history': historyJson,
            }
          ],
          'activeLayerId': 'layer_0',
        });
      }

      // Calculate aspect ratio
      double aspectRatio = 1.0;
      if (firstFrameImage != null) {
        aspectRatio = firstFrameImage.width.toDouble() / firstFrameImage.height.toDouble();
      }

      // Construct project state
      final Map<String, dynamic> state = {
        'globalBackground': {
          'color': Colors.white.value,
          'imagePath': null,
          'imageOpacity': 1.0,
          'pattern': null,
        },
        'aspectRatio': aspectRatio,
        'fps': 12,
        'canvases': canvasesData,
      };

      // Create thumbnail from first frame
      List<int>? thumbnailBytes;
      if (firstFrameImage != null) {
        final byteData = await firstFrameImage.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          thumbnailBytes = byteData.buffer.asUint8List();
        }
      }

      // Save project
      final projectId = await widget.repository.saveProject(
        projectId: null,
        title: '${template.name} Animation',
        state: state,
        thumbnailBytes: thumbnailBytes,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Navigate to MyHomePage (the drawing board editor)
      if (mounted) {
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
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }
      debugPrint('Failed to load template project: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load template: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF3C3043), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Templates',
          style: TextStyle(
            color: Color(0xFF3C3043),
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.82,
            ),
            itemCount: _templates.length,
            itemBuilder: (context, index) {
              final template = _templates[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TemplateDetailScreen(
                        repository: widget.repository,
                        template: template,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.grey.shade100,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Preview Image
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            child: Image.asset(
                              template.previewAsset,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(Icons.broken_image_rounded, color: Colors.grey),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      // Text Info
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              template.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF3C3043),
                                fontFamily: 'Outfit',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${template.frameCount} Frames',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFF9114),
                                fontFamily: 'Outfit',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
