import 'dart:io';
import 'dart:ui' as ui;
import 'package:dummy/common_widgets/show_toast.dart';
import 'package:dummy/core/constants/app_strings.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/widgets/color_picker_screen.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/custom_switch.dart';
import '../../data/project_repository.dart';
import '../../../templates/domain/template_model.dart';
import '../widgets/preview_pattern_painter.dart';
import '../../../editor/presentation/screens/editor_screen.dart';
import '../../../editor/presentation/screens/canvas_size_screen.dart';
import '../../../editor/presentation/screens/fps_screen.dart';
import '../../../editor/presentation/screens/background_presets_screen.dart';

class CreateProjectScreen extends StatefulWidget {
  final ProjectRepository repository;
  final TemplateModel? template;
  final TemplateMode? templateMode;
  final String? projectId;

  const CreateProjectScreen({
    super.key,
    required this.repository,
    this.template,
    this.templateMode,
    this.projectId,
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
  bool _enableStickers = true;

  @override
  void initState() {
    super.initState();
    if (widget.projectId != null) {
      _loadExistingProjectSettings();
    } else if (widget.template != null) {
      _nameController.text = '${widget.template!.name} Animation';
      _loadTemplateDimensions();
    }
  }

  Future<void> _loadExistingProjectSettings() async {
    try {
      final project = await widget.repository.loadProject(widget.projectId!);
      if (project != null) {
        setState(() {
          _nameController.text = project.meta.title;
          _fps = project.state['fps'] as int? ?? 14;
          _exportType = project.state['exportType'] as String? ?? 'Mp4';
          _enableStickers = project.state['enableStickers'] as bool? ?? true;
          final bgMap = project.state['globalBackground'] as Map<String, dynamic>?;
          if (bgMap != null) {
            _backgroundColor = Color(bgMap['color'] as int? ?? Colors.white.value);
            _backgroundImagePath = bgMap['imagePath'] as String?;
            _backgroundPattern = bgMap['pattern'] as String?;
          }
          final double? ratio = project.state['aspectRatio'] as double?;
          if (ratio != null) {
            if ((ratio - 1.0).abs() < 0.05) {
              _canvasWidth = 1000;
              _canvasHeight = 1000;
              _canvasSizeLabel = 'Square (1:1)';
            } else if ((ratio - 16.0 / 9.0).abs() < 0.05) {
              _canvasWidth = 1280;
              _canvasHeight = 720;
              _canvasSizeLabel = 'Landscape (16:9)';
            } else if ((ratio - 9.0 / 16.0).abs() < 0.05) {
              _canvasWidth = 720;
              _canvasHeight = 1280;
              _canvasSizeLabel = 'Portrait (9:16)';
            } else if ((ratio - 4.0 / 3.0).abs() < 0.05) {
              _canvasWidth = 1024;
              _canvasHeight = 768;
              _canvasSizeLabel = 'Tablet (4:3)';
            } else if ((ratio - 3.0 / 4.0).abs() < 0.05) {
              _canvasWidth = 768;
              _canvasHeight = 1024;
              _canvasSizeLabel = 'Tablet Portrait (3:4)';
            } else {
              _canvasWidth = 1280;
              _canvasHeight = (1280 / ratio).round();
              _canvasSizeLabel = 'Custom Aspect Ratio';
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Failed to load existing project settings: $e');
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ColorPickerScreen(
          initialColor: _backgroundColor,
          initialOpacity: _backgroundColor.opacity,
          onColorChanged: (Color newColor, double newOpacity) {
            setState(() {
              _backgroundColor = newColor.withValues(alpha: newOpacity);
              _backgroundImagePath = null;
            });
          },
        ),
      ),
    );
  }

  Future<void> _showPresetsPicker() async {
    final Map<String, dynamic>? result = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(
        builder: (context) => BackgroundPresetsScreen(
          initialPattern: _backgroundPattern,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _backgroundPattern = result['pattern'] as String?;
        _backgroundImagePath = null; // Clear image when a preset is selected
      });
    }
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

    if (widget.projectId != null) {
      try {
        final project = await widget.repository.loadProject(widget.projectId!);
        if (project != null) {
          final Map<String, dynamic> newState = Map<String, dynamic>.from(project.state);
          newState['globalBackground'] = {
            'color': _backgroundColor.value,
            'imagePath': _backgroundImagePath,
            'imageOpacity': 1.0,
            'pattern': _backgroundPattern,
          };
          newState['fps'] = _fps;
          newState['exportType'] = _exportType;
          newState['enableStickers'] = _enableStickers;

          await widget.repository.saveProject(
            projectId: widget.projectId,
            title: title,
            state: newState,
            thumbnailBytes: null, // Keep existing thumbnail
          );

          if (mounted) {
            Navigator.pop(context, true);
          }
          return;
        }
      } catch (e) {
        debugPrint('Failed to save project settings: $e');
      }
      return;
    }

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
        final bool isDrawAccordingMode = widget.templateMode == TemplateMode.drawAccordingTemplate;

        for (int i = 0; i < widget.template!.frameCount; i++) {
          List<Map<String, dynamic>> historyList = [];
          int currentIndex = 0;

          if (!isDrawAccordingMode) {
            final imageUrl = widget.template!.frameAssets[i];
            final Map<String, dynamic> imageContentJson = {
              'type': 'ImageContent',
              'startPoint': {'dx': 0.0, 'dy': 0.0},
              'size': {'dx': _canvasWidth.toDouble(), 'dy': _canvasHeight.toDouble()},
              'imageUrl': imageUrl,
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
            };
            historyList.add(imageContentJson);
            currentIndex = 1;
          }

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
                'currentIndex': currentIndex,
                'history': historyList,
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
        'templateFolder': widget.template?.folder,
        'templateExtension': widget.template?.extension,
        'templateMode': widget.templateMode == TemplateMode.drawAccordingTemplate
            ? 'drawAccordingTemplate'
            : (widget.template != null ? 'useTemplate' : null),
        'templateFrameCount': widget.template?.frameCount,
        'enableStickers': _enableStickers,
        'canvases': canvasesData,
      };

      List<int>? initialThumbnailBytes;
      if (widget.template != null) {
        try {
          final data = await rootBundle.load(widget.template!.previewAsset);
          initialThumbnailBytes = data.buffer.asUint8List();
        } catch (e) {
          debugPrint('Failed to load initial template preview bytes: $e');
        }
      }

      final projectId = await widget.repository.saveProject(
        title: title,
        state: state,
        thumbnailBytes: initialThumbnailBytes,
      );

      if (mounted) {
        if (widget.template != null) {
          // Dismiss creating dialog
          Navigator.of(context, rootNavigator: true).pop();
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EditorScreen(
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
      extendBodyBehindAppBar: true,
      //backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: ColorConstants.darkText,size: 20,),
          onPressed: () => Navigator.pop(context),
        ),
        title:Text(
          StringConstants.new_project,
          style: TextStyle(
            color: ColorConstants.darkText,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Project Name Field
               Text(
                StringConstants.project_name,
                style: TextStyle(
                  color: ColorConstants.text_color,
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color:Colors.white,
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(color: ColorConstants.border_color,
                  width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:ColorConstants.shodow.withValues(alpha: 0.05),
                      offset: Offset(2,2),
                      spreadRadius: 0,
                      blurRadius: 13,
                    )
                  ]
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                  decoration:  InputDecoration(
                    hintText: StringConstants.name_your_animation,
                    hintStyle: TextStyle(
                      color: ColorConstants.subTextColor,
                      fontWeight: FontWeight.w400,
                      fontSize: 16
                    ),
                    border:InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // 2. Aspect Ratio Dropdown
               Text(
                StringConstants.aspect_ratio,
                style: TextStyle(
                  color: ColorConstants.text_color,
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: widget.projectId != null
                    ? () {
                 showToast(message: StringConstants.aspect_ratio_cannot_be_changed);
                      }
                    : () async {
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
                    color: widget.projectId != null
                        ? const Color(0xFFF1F2F4)
                        : const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(21),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 16),
                  child: Row(
                    children: [
                      Text(
                        _canvasSizeLabel,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: widget.projectId != null
                              ? Colors.black
                              : ColorConstants.text_color,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        widget.projectId != null
                            ? Icons.lock_outline_rounded
                            : Icons.keyboard_arrow_down,
                        color: ColorConstants.subTextColor,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 3. Frame Rate Dropdown
               Text(
                StringConstants.frame_rate,
                style: TextStyle(
                  color: ColorConstants.text_color,
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
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
                    borderRadius: BorderRadius.circular(21),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 16),
                  child: Row(
                    children: [
                      Text(
                        '${_fps}fps',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: ColorConstants.text_color,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: ColorConstants.subTextColor,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 4. Export Type Selector
               Text(
                StringConstants.export_type,
                style: TextStyle(
                  color: ColorConstants.text_color,
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(
                    color: ColorConstants.border_color
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ColorConstants.shodow.withValues(alpha: 0.05),
                      blurRadius: 13,
                      spreadRadius: 0,
                      offset: Offset(2, 2)
                    )
                  ]
                ),
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
                            color: _exportType == 'Mp4' ? ColorConstants.selected_type : Colors.transparent,
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(21),bottomLeft:Radius.circular(21)),
                            // boxShadow: _exportType == 'Mp4'
                            //     ? [
                            //         BoxShadow(
                            //           color: Colors.black.withOpacity(0.04),
                            //           blurRadius: 4,
                            //           offset: const Offset(0, 2),
                            //         )
                            //       ]
                            //     : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            StringConstants.mp4,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: _exportType == 'Mp4' ? ColorConstants.text_color : ColorConstants.text_color,
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
                            color: _exportType == 'GIF' ?ColorConstants.selected_type : Colors.transparent,
                            borderRadius: BorderRadius.only(topRight: Radius.circular(21),bottomRight:Radius.circular(21)),
                            // boxShadow: _exportType == 'GIF'
                            //     ? [
                            //         BoxShadow(
                            //           color: Colors.black.withOpacity(0.04),
                            //           blurRadius: 4,
                            //           offset: const Offset(0, 2),
                            //         )
                            //       ]
                            //     : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            StringConstants.gif,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: _exportType == 'GIF' ? ColorConstants.text_color : ColorConstants.text_color,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              // 4.5 Sticker Mode Selector
               Text(
                StringConstants.add_as_sticker,
                style: TextStyle(
                  color: ColorConstants.text_color,
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            StringConstants.enable_sticker_mode,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: ColorConstants.darkText,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            StringConstants.add_shapes_lines,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8E8895),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 4),
                    CustomSwitch(
                      value: _enableStickers,
                      onChanged: (bool value) {
                        setState(() {
                          _enableStickers = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 5. Background Section
              Row(
                children: [
                   Text(
                    StringConstants.background,
                    style: TextStyle(
                      color: ColorConstants.darkText,
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),

                  // Color Fill Icon
                  IconButton(
                    onPressed: _openCustomBackgroundColorPicker,
                    icon: SvgPicture.asset(
                      AssetConstants.color_bucket,
                    ),
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  SizedBox(width: 18,),
                  IconButton(
                    icon:SvgPicture.asset(AssetConstants.image_picker),
                    onPressed: () => _pickImage(ImageSource.gallery),
                    tooltip: 'Gallery',
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  SizedBox(width: 18,),
                  // Presets Icon
                  IconButton(
                    icon:SvgPicture.asset(AssetConstants.bg_picker),
                    onPressed: _showPresetsPicker,
                    tooltip: 'Presets',
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  // Gallery Icon

                ],
              ),
              const SizedBox(height: 10),

              // Background Preview Box
              GestureDetector(
                onTap: () {
                  // Prompt to select background
                  _openCustomBackgroundColorPicker();
                },
                child: Container(
                  height: 116,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color:ColorConstants.background_color,
                    borderRadius: BorderRadius.circular(21),
                    border: Border.all(color: ColorConstants.border_color),
                    boxShadow: [
                      BoxShadow(
                        color: ColorConstants.shodow.withValues(alpha: 0.05),
                        offset: Offset(2, 2),
                        spreadRadius: 0,
                        blurRadius: 13
                      )
                    ]
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      children: [
                        // // Solid color
                        Positioned.fill(
                          child: Container(
                            color: _backgroundPattern == 'blueprint'
                                ? const Color(0xFF1E3D59)
                                : (_backgroundPattern == 'graph' ? const Color(0xFFF1F8F6) : _backgroundColor),
                          ),
                        ),
                      //  Image file
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
                                StringConstants.add,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: ColorConstants.subTextColor,
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
              const SizedBox(height: 20),

              // 6. Apply Button
              PrimaryButton(
                text: StringConstants.crate_project,
                onPressed: _createProject,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
