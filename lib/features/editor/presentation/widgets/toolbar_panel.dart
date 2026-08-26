import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../package_code/paint_contents.dart';
import '../../../../../package_code/src/drawing_bar/brush_preset_panel.dart';
import '../../../../../package_code/src/paint_contents/simple_line.dart';
import '../../../../../package_code/src/paint_contents/smooth_line.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/font_presets.dart';
import '../controllers/editor_controller.dart';
import '../controllers/editor_providers.dart';
import 'sticker_widgets/text_sticker_widget.dart';

class ToolbarPanel extends ConsumerStatefulWidget {
  final String? projectId;

  const ToolbarPanel({
    super.key,
    required this.projectId,
  });

  @override
  ConsumerState<ToolbarPanel> createState() => _ToolbarPanelState();
}

class _ToolbarPanelState extends ConsumerState<ToolbarPanel> {
  final ImagePicker _picker = ImagePicker();

  Future<ui.Image> _getFileImage(String path) async {
    final Completer<ImageInfo> completer = Completer<ImageInfo>();
    final FileImage img = FileImage(File(path));
    img.resolve(ImageConfiguration.empty).addListener(
      ImageStreamListener((ImageInfo info, _) {
        completer.complete(info);
      }),
    );
    final ImageInfo imageInfo = await completer.future;
    return imageInfo.image;
  }

  Future<ui.Image> _getImage(String path) async {
    final Completer<ImageInfo> completer = Completer<ImageInfo>();
    final NetworkImage img = NetworkImage(path);
    img.resolve(ImageConfiguration.empty).addListener(
      ImageStreamListener((ImageInfo info, _) {
        completer.complete(info);
      }),
    );
    final ImageInfo imageInfo = await completer.future;
    return imageInfo.image;
  }

  Future<ui.Image> _getAssetImage(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    final Uint8List bytes = data.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo fi = await codec.getNextFrame();
    return fi.image;
  }

  void _showExportBottomSheet(WidgetRef ref) {
    final controller = ref.read(editorControllerProvider(widget.projectId));
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.image_rounded, color: Colors.blue),
                title: const Text('Export Current Frame'),
                onTap: () async {
                  Navigator.pop(context);
                  final Uint8List? data = (await controller.drawingController.getImageData())?.buffer.asUint8List();
                  if (data == null) return;
                  if (mounted) {
                    showDialog<void>(
                      context: this.context,
                      builder: (BuildContext c) {
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(c),
                            child: Image.memory(data),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.code_rounded, color: Colors.green),
                title: const Text('View Canvas JSON'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog<void>(
                    context: this.context,
                    builder: (BuildContext c) {
                      return Center(
                        child: Material(
                          color: Colors.white,
                          child: InkWell(
                            onTap: () => Navigator.pop(c),
                            child: Container(
                              constraints: const BoxConstraints(
                                maxWidth: 500,
                                maxHeight: 800,
                              ),
                              padding: const EdgeInsets.all(20.0),
                              child: SelectableText(
                                const JsonEncoder.withIndent('  ').convert(controller.drawingController.getJsonList()),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(editorControllerProvider(widget.projectId));
    final activeSticker = controller.activeSticker;

    if (activeSticker is ActiveTextSticker) {
      return _buildTextStickerToolbar(activeSticker, controller);
    } else if (controller.currentSubMenu == 'brush') {
      return _buildBrushSubMenu(controller);
    } else if (controller.currentSubMenu == 'shapes') {
      return _buildShapesSubMenu(controller);
    } else {
      return _buildBottomToolbar(controller);
    }
  }

  Widget _buildBottomToolbar(EditorController controller) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          _bottomToolbarCategoryItem(
            label: 'Export',
            icon: Icons.ios_share_rounded,
            onTap: () => _showExportBottomSheet(ref),
            color: ColorConstants.accent,
          ),
          Container(
            height: 36,
            width: 1,
            color: Colors.grey.shade300,
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _bottomToolbarCategoryItem(
                    label: 'Brush',
                    icon: Icons.brush_rounded,
                    color: controller.activeCategory == 'Brush' ? ColorConstants.accent : null,
                    onTap: () {
                      controller.currentSubMenu = 'brush';
                      controller.activeCategory = 'Brush';
                      if (controller.selectedSubTool == 'brush') {
                        controller.drawingController.setPaintContent(SmoothLine());
                      } else {
                        controller.drawingController.setPaintContent(FreehandLine());
                      }
                      controller.drawingController.setStyle(strokeWidth: controller.globalStrokeWidth);
                    },
                  ),
                  _bottomToolbarCategoryItem(
                    label: 'Paint',
                    icon: Icons.format_paint_rounded,
                    color: controller.activeCategory == 'Paint' ? ColorConstants.accent : null,
                    onTap: () {
                      controller.drawingController.setPaintContent(FillContent());
                      controller.drawingController.setStyle(strokeWidth: controller.globalStrokeWidth);
                      controller.activeCategory = 'Paint';
                    },
                  ),
                  _bottomToolbarCategoryItem(
                    label: 'Eyedropper',
                    icon: Icons.colorize_rounded,
                    color: controller.activeCategory == 'Eyedropper' ? ColorConstants.accent : null,
                    onTap: () {
                      controller.drawingController.setPaintContent(Eyedropper());
                      controller.activeCategory = 'Eyedropper';
                    },
                  ),
                  _bottomToolbarCategoryItem(
                    label: 'Blur',
                    icon: Icons.water_drop_rounded,
                    color: controller.activeCategory == 'Blur' ? ColorConstants.accent : null,
                    onTap: () {
                      controller.drawingController.setPaintContent(BlurContent());
                      controller.drawingController.setStyle(strokeWidth: controller.globalStrokeWidth);
                      controller.activeCategory = 'Blur';
                    },
                  ),
                  _bottomToolbarCategoryItem(
                    label: 'Smudge',
                    icon: Icons.fingerprint_rounded,
                    color: controller.activeCategory == 'Smudge' ? ColorConstants.accent : null,
                    onTap: () {
                      controller.drawingController.setPaintContent(SmudgeContent());
                      controller.drawingController.setStyle(strokeWidth: controller.globalStrokeWidth);
                      controller.activeCategory = 'Smudge';
                    },
                  ),
                  _bottomToolbarCategoryItem(
                    label: 'Shapes',
                    icon: Icons.interests_rounded,
                    color: controller.activeCategory == 'Shapes' ? ColorConstants.accent : null,
                    onTap: () {
                      controller.currentSubMenu = 'shapes';
                      controller.activeCategory = 'Shapes';
                      controller.drawingController.setPaintContent(Pentagon());
                      controller.drawingController.setStyle(strokeWidth: controller.globalStrokeWidth);
                    },
                  ),
                  _bottomToolbarCategoryItem(
                    label: 'Assets',
                    icon: Icons.photo_library_rounded,
                    onTap: () async {
                      final ImageSource? source = await showModalBottomSheet<ImageSource>(
                        context: context,
                        builder: (BuildContext context) {
                          return SafeArea(
                            child: Wrap(
                              children: <Widget>[
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text('Photo Gallery'),
                                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.photo_camera),
                                  title: const Text('Camera'),
                                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                                ),
                              ],
                            ),
                          );
                        },
                      );

                      if (source == null) return;
                      try {
                        final XFile? file = await _picker.pickImage(source: source);
                        if (file != null) {
                          final ui.Image image = await _getFileImage(file.path);
                          controller.drawingController.setPaintContent(
                            ImageContent(image, imageUrl: file.path),
                          );
                        }
                      } catch (e) {
                        debugPrint('Error picking sticker image: $e');
                      }
                    },
                  ),
                  _bottomToolbarCategoryItem(
                    label: 'Erase',
                    icon: Icons.auto_fix_normal_rounded,
                    color: controller.activeCategory == 'Erase' ? ColorConstants.accent : null,
                    onTap: () {
                      controller.drawingController.setPaintContent(Eraser());
                      controller.drawingController.setStyle(strokeWidth: controller.globalStrokeWidth);
                      controller.activeCategory = 'Erase';
                    },
                  ),
                  _bottomToolbarCategoryItem(
                    label: 'Lasso',
                    icon: Icons.gesture_rounded,
                    color: controller.activeCategory == 'Lasso' ? ColorConstants.accent : null,
                    onTap: () {
                      controller.drawingController.setPaintContent(Lasso());
                      controller.drawingController.setStyle(strokeWidth: controller.globalStrokeWidth);
                      controller.activeCategory = 'Lasso';
                    },
                  ),
                  _bottomToolbarCategoryItem(
                    label: 'Text',
                    icon: Icons.text_fields_rounded,
                    color: controller.isTextToolSelected ? ColorConstants.accent : null,
                    onTap: () {
                      if (controller.drawingController.isCurrentLayerLocked) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Current layer is locked.')),
                        );
                        return;
                      }
                      controller.isTextToolSelected = !controller.isTextToolSelected;
                      if (controller.isTextToolSelected) {
                        controller.activeCategory = 'Text';
                        controller.activeSticker = null;
                      } else {
                        controller.activeCategory = 'Brush';
                      }
                    },
                  ),
                  _bottomToolbarCategoryItem(
                    label: 'Ruler',
                    icon: Icons.straighten_rounded,
                    color: controller.showRulerMenu ? ColorConstants.accent : null,
                    onTap: () {
                      controller.showRulerMenu = !controller.showRulerMenu;
                    },
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomToolbarCategoryItem({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    final displayColor = color ?? Colors.grey.shade700;
    final controller = ref.read(editorControllerProvider(widget.projectId));
    return GestureDetector(
      onTap: () {
        if (label != 'Text' && label != 'Ruler') {
          controller.isTextToolSelected = false;
        }
        onTap();
      },
      child: Container(
        width: 64,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: displayColor, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: displayColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrushSubMenu(EditorController controller) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              controller.currentSubMenu = 'none';
            },
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(left: 16, right: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _bottomSubToolItem(
                  label: 'Brush',
                  icon: Icons.brush_rounded,
                  isActive: controller.selectedSubTool == 'brush',
                  onTap: () {
                    controller.selectedSubTool = 'brush';
                    controller.drawingController.setPaintContent(SmoothLine());
                    controller.drawingController.setStyle(strokeWidth: controller.globalStrokeWidth);
                    BrushPresetPanel.show(context, controller.drawingController);
                  },
                ),
                _bottomSubToolItem(
                  label: 'Pen',
                  icon: Icons.edit_rounded,
                  isActive: controller.selectedSubTool == 'pen',
                  onTap: () {
                    controller.selectedSubTool = 'pen';
                    controller.drawingController.setPaintContent(FreehandLine());
                    controller.drawingController.setStyle(strokeWidth: controller.globalStrokeWidth);
                  },
                ),
                _bottomSubToolItem(
                  label: 'Pencil',
                  icon: Icons.create_rounded,
                  isActive: controller.selectedSubTool == 'pencil',
                  onTap: () {
                    controller.selectedSubTool = 'pencil';
                    controller.drawingController.setPaintContent(FreehandLine());
                    controller.drawingController.setStyle(strokeWidth: controller.globalStrokeWidth);
                  },
                ),
                _bottomSubToolItem(
                  label: 'Line',
                  icon: Icons.horizontal_rule_rounded,
                  isActive: controller.selectedSubTool == 'line',
                  onTap: () {
                    controller.selectedSubTool = 'line';
                    controller.drawingController.setPaintContent(SimpleLine());
                    controller.drawingController.setStyle(strokeWidth: controller.globalStrokeWidth);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShapesSubMenu(EditorController controller) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              controller.currentSubMenu = 'none';
            },
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(left: 16, right: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _bottomSubToolItem(
                  label: 'Heart',
                  icon: Icons.favorite_border_rounded,
                  isActive: controller.drawingController.drawConfig.value.contentType == Heart,
                  onTap: () {
                    controller.drawingController.setPaintContent(Heart());
                    controller.drawingController.setStyle(strokeWidth: controller.globalStrokeWidth);
                  },
                ),
                _bottomSubToolItem(
                  label: 'Pentagon',
                  icon: Icons.pentagon_outlined,
                  isActive: controller.drawingController.drawConfig.value.contentType == Pentagon,
                  onTap: () {
                    controller.drawingController.setPaintContent(Pentagon());
                    controller.drawingController.setStyle(strokeWidth: controller.globalStrokeWidth);
                  },
                ),
                _bottomSubToolItem(
                  label: 'Circle',
                  icon: Icons.circle_outlined,
                  isActive: controller.drawingController.drawConfig.value.contentType == Circle,
                  onTap: () {
                    controller.drawingController.setPaintContent(Circle());
                    controller.drawingController.setStyle(strokeWidth: controller.globalStrokeWidth);
                  },
                ),
                _bottomSubToolItem(
                  label: 'Cube',
                  icon: Icons.inventory_2_outlined,
                  isActive: controller.drawingController.drawConfig.value.contentType == CubeShape,
                  onTap: () {
                    controller.drawingController.setPaintContent(CubeShape());
                    controller.drawingController.setStyle(strokeWidth: controller.globalStrokeWidth);
                  },
                ),
                _bottomSubToolItem(
                  label: 'Cylinder',
                  icon: Icons.data_usage_rounded,
                  isActive: controller.drawingController.drawConfig.value.contentType == CylinderShape,
                  onTap: () {
                    controller.drawingController.setPaintContent(CylinderShape());
                    controller.drawingController.setStyle(strokeWidth: controller.globalStrokeWidth);
                  },
                ),
                _bottomSubToolItem(
                  label: 'Line',
                  icon: Icons.horizontal_rule_rounded,
                  isActive: controller.drawingController.drawConfig.value.contentType == SimpleLine,
                  onTap: () {
                    controller.drawingController.setPaintContent(SimpleLine());
                    controller.drawingController.setStyle(strokeWidth: controller.globalStrokeWidth);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomSubToolItem({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? ColorConstants.accent : Colors.grey.shade600, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? ColorConstants.accent : Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextStickerToolbar(ActiveTextSticker sticker, EditorController controller) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _bottomTextToolItem(
            label: 'Edit Text',
            icon: Icons.edit_rounded,
            onTap: () => _editTextStickerContent(sticker, controller),
          ),
          _bottomTextToolItem(
            label: 'Fonts',
            icon: Icons.font_download_rounded,
            onTap: () => _showFontSelectionSheet(sticker, controller),
          ),
          _bottomTextToolItem(
            label: 'Format',
            icon: Icons.format_size_rounded,
            onTap: () => _showSizeOpacitySheet(sticker, controller),
          ),
        ],
      ),
    );
  }

  Widget _bottomTextToolItem({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        height: 60,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: ColorConstants.accent, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: ColorConstants.accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editTextStickerContent(ActiveTextSticker sticker, EditorController controller) {
    String text = sticker.text;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Text Sticker'),
          content: TextField(
            controller: TextEditingController(text: sticker.text),
            onChanged: (v) => text = v,
            decoration: const InputDecoration(hintText: 'Enter text here'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (text.isNotEmpty) {
                  sticker.text = text;
                  controller.updateSnapshot();
                  controller.notifyListeners();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showFontSelectionSheet(ActiveTextSticker sticker, EditorController controller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Text(
                          'Fonts',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: fontPresets.length,
                      itemBuilder: (context, index) {
                        final preset = fontPresets[index];
                        final isSelected = sticker.fontFamily == preset.name;
                        
                        return ListTile(
                          title: Text(
                            preset.name,
                            style: preset.getTextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: ColorConstants.accent)
                              : null,
                          onTap: () {
                            sticker.fontFamily = preset.name;
                            setModalState(() {});
                            controller.updateSnapshot();
                            controller.notifyListeners();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSizeOpacitySheet(ActiveTextSticker sticker, EditorController controller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Text Style & Size',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.format_size_rounded, color: Colors.grey),
                      const SizedBox(width: 12),
                      const Text('Size', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            activeTrackColor: ColorConstants.accent,
                            thumbColor: ColorConstants.accent,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          ),
                          child: Slider(
                            value: sticker.fontSize.clamp(10.0, 100.0),
                            min: 10.0,
                            max: 100.0,
                            onChanged: (val) {
                              sticker.fontSize = val;
                              setModalState(() {});
                              controller.updateSnapshot();
                              controller.notifyListeners();
                            },
                          ),
                        ),
                      ),
                      Text('${sticker.fontSize.round()}px', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.opacity_rounded, color: Colors.grey),
                      const SizedBox(width: 12),
                      const Text('Opacity', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            activeTrackColor: ColorConstants.accent,
                            thumbColor: ColorConstants.accent,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          ),
                          child: Slider(
                            value: sticker.opacity.clamp(0.0, 1.0),
                            min: 0.0,
                            max: 1.0,
                            onChanged: (val) {
                              sticker.opacity = val;
                              sticker.color = sticker.color.withOpacity(val);
                              setModalState(() {});
                              controller.updateSnapshot();
                              controller.notifyListeners();
                            },
                          ),
                        ),
                      ),
                      Text('${(sticker.opacity * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Format', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _styleToggleButton(
                                    label: 'B',
                                    isActive: sticker.isBold,
                                    onTap: () {
                                      sticker.isBold = !sticker.isBold;
                                      setModalState(() {});
                                      controller.updateSnapshot();
                                      controller.notifyListeners();
                                    },
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  _styleToggleButton(
                                    label: 'I',
                                    isActive: sticker.isItalic,
                                    onTap: () {
                                      sticker.isItalic = !sticker.isItalic;
                                      setModalState(() {});
                                      controller.updateSnapshot();
                                      controller.notifyListeners();
                                    },
                                    style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 16),
                                  ),
                                  _styleToggleButton(
                                    label: 'U',
                                    isActive: sticker.isUnderline,
                                    onTap: () {
                                      sticker.isUnderline = !sticker.isUnderline;
                                      setModalState(() {});
                                      controller.updateSnapshot();
                                      controller.notifyListeners();
                                    },
                                    style: const TextStyle(decoration: TextDecoration.underline, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Alignment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _alignmentButton(
                                    icon: Icons.format_align_left_rounded,
                                    isActive: sticker.textAlign == TextAlign.left,
                                    onTap: () {
                                      sticker.textAlign = TextAlign.left;
                                      setModalState(() {});
                                      controller.updateSnapshot();
                                      controller.notifyListeners();
                                    },
                                  ),
                                  _alignmentButton(
                                    icon: Icons.format_align_center_rounded,
                                    isActive: sticker.textAlign == TextAlign.center,
                                    onTap: () {
                                      sticker.textAlign = TextAlign.center;
                                      setModalState(() {});
                                      controller.updateSnapshot();
                                      controller.notifyListeners();
                                    },
                                  ),
                                  _alignmentButton(
                                    icon: Icons.format_align_right_rounded,
                                    isActive: sticker.textAlign == TextAlign.right,
                                    onTap: () {
                                      sticker.textAlign = TextAlign.right;
                                      setModalState(() {});
                                      controller.updateSnapshot();
                                      controller.notifyListeners();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _styleToggleButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required TextStyle style,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? ColorConstants.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: style.copyWith(
            color: isActive ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _alignmentButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? ColorConstants.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}
