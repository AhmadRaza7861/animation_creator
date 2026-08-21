import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, AssetManifest;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../projects/data/project_repository.dart';
import '../../../editor/presentation/screens/editor_screen.dart';
import '../../domain/template_model.dart';
import 'template_detail_screen.dart';

class TemplatesScreen extends StatefulWidget {
  final ProjectRepository repository;

  const TemplatesScreen({super.key, required this.repository});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  List<TemplateModel> _templates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplatesFromManifest();
  }

  Future<void> _loadTemplatesFromManifest() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final List<String> allAssets = manifest.listAssets();

      final Map<String, List<String>> folders = {};
      for (final asset in allAssets) {
        if (asset.startsWith('assets/templates/')) {
          final parts = asset.split('/');
          if (parts.length >= 4) {
            final folderName = parts[2];
            folders.putIfAbsent(folderName, () => []).add(asset);
          }
        }
      }

      final List<TemplateModel> loadedTemplates = [];
      for (final folder in folders.keys) {
        final frameAssets = folders[folder]!..sort();
        if (frameAssets.isEmpty) continue;

        final firstFile = frameAssets.first;
        final dotIndex = firstFile.lastIndexOf('.');
        final ext = dotIndex != -1 ? firstFile.substring(dotIndex) : '.png';
        final name = _getDisplayName(folder);

        loadedTemplates.add(TemplateModel(
          id: folder,
          name: name,
          folder: folder,
          extension: ext,
          frameCount: frameAssets.length,
          frameAssets: frameAssets,
        ));
      }

      loadedTemplates.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      if (mounted) {
        setState(() {
          _templates = loadedTemplates;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading templates manifest: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _getDisplayName(String folder) {
    if (folder == '01_01_Nope') return 'Nope';
    final words = folder
        .split(RegExp(r'[_.\s-]+'))
        ..removeWhere((w) => w.isEmpty);
    return words.map((w) {
      if (w.isEmpty) return '';
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }

  Future<ui.Image> _loadUiImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.darkText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Templates',
          style: TextStyle(
            color: AppColors.darkText,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                )
              : GridView.builder(
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
                          color: AppColors.background,
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
                                      color: AppColors.darkText,
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
                                      color: AppColors.primary,
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
