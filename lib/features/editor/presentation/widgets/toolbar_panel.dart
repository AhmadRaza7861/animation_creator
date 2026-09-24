import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../package_code/paint_contents.dart';
import '../../../../../package_code/src/drawing_bar/brush_preset_panel.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/widgets/font_presets.dart';
import '../../../../../core/widgets/app_dialogs.dart';
import '../controllers/editor_controller.dart';
import '../controllers/editor_providers.dart';
import '../../../../../package_code/src/ruler/ruler_config.dart';
import '../screens/brush_studio_screen.dart';
import '../screens/export/make_movie_screen.dart';
import '../screens/video_trimming_screen.dart';
import '../screens/image_crop_screen.dart';
import 'sticker_widgets/text_sticker_widget.dart';
import 'sticker_widgets/shape_sticker_widget.dart';
import '../../services/global_clipboard.dart';

class ToolbarPanel extends ConsumerStatefulWidget {
  final String? projectId;

  const ToolbarPanel({super.key, required this.projectId});

  @override
  ConsumerState<ToolbarPanel> createState() => _ToolbarPanelState();
}

class _ToolbarPanelState extends ConsumerState<ToolbarPanel> {
  final ImagePicker _picker = ImagePicker();
  final ScrollController _toolbarScrollController = ScrollController();

  @override
  void dispose() {
    _toolbarScrollController.dispose();
    super.dispose();
  }

  Future<ui.Image> _getFileImage(String path) async {
    final Completer<ui.Image> completer = Completer<ui.Image>();
    final File file = File(path);
    if (!await file.exists()) {
      throw Exception('Image file does not exist at $path');
    }
    final Uint8List bytes = await file.readAsBytes();
    ui.decodeImageFromList(bytes, (ui.Image img) {
      completer.complete(img);
    });
    return completer.future;
  }

  void _showExportBottomSheet(WidgetRef ref) {
    final controller = ref.read(editorControllerProvider(widget.projectId));
    if (controller.activeSticker != null) {
      controller.stampActiveSticker();
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MakeMovieScreen(
          canvases: controller.canvases,
          globalBackground: controller.globalBackground,
          initialMovieName: controller.projectName,
          initialFormat: controller.exportType,
          fps: controller.fps,
          projectAspectRatio: controller.aspectRatio,
          audioState: controller.audioState,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(editorControllerProvider(widget.projectId));
    final activeSticker = controller.activeSticker;

    if (activeSticker is ActiveTextSticker) {
      return _buildTextStickerToolbar(activeSticker, controller);
    } else if (activeSticker is ActiveShapeSticker && activeSticker.isLasso) {
      return _buildLassoStickerToolbar(activeSticker, controller);
    } else if (controller.currentSubMenu == 'brush') {
      return _buildBrushSubMenu(controller);
    } else if (controller.currentSubMenu == 'shapes') {
      return _buildShapesSubMenu(controller);
    } else {
      return _buildBottomToolbar(controller);
    }
  }

  Widget _buildLassoStickerToolbar(
    ActiveShapeSticker sticker,
    EditorController controller,
  ) {
    final bool isPersp = sticker.transformMode == StickerTransformMode.perspective;
    final bool canPaste = controller.canPasteLassoSelection;

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
              controller.stampActiveSticker();
            },
            child: Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(left: 16, right: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 20,
                color: ColorConstants.accent,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  _bottomSubToolItem(
                    label: 'TRSF',
                    icon: Icons.crop_free_rounded,
                    isActive: !isPersp,
                    onTap: () {
                      controller.setShapeStickerTransformMode(StickerTransformMode.transform);
                    },
                  ),
                  const SizedBox(width: 4),
                  _bottomSubToolItem(
                    label: 'PERSP',
                    icon: Icons.filter_tilt_shift_rounded,
                    isActive: isPersp,
                    onTap: () {
                      controller.setShapeStickerTransformMode(StickerTransformMode.perspective);
                    },
                  ),
                  const SizedBox(width: 4),
                  _bottomSubToolItem(
                    label: 'Flip H',
                    icon: Icons.flip_rounded,
                    isActive: sticker.flipX,
                    onTap: () => controller.flipActiveShapeStickerH(),
                  ),
                  const SizedBox(width: 4),
                  _bottomSubToolItem(
                    label: 'Flip V',
                    icon: Icons.swap_vert_rounded,
                    isActive: sticker.flipY,
                    onTap: () => controller.flipActiveShapeStickerV(),
                  ),
                  const SizedBox(width: 4),
                  _bottomSubToolItem(
                    label: 'Copy',
                    icon: Icons.copy_rounded,
                    isActive: false,
                    onTap: () {
                      controller.copyActiveLassoSelection();
                      Fluttertoast.showToast(
                        msg: 'Selection copied to clipboard',
                        backgroundColor: const Color(0xFFFF9318),
                        textColor: Colors.white,
                        toastLength: Toast.LENGTH_SHORT,
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  _bottomSubToolItem(
                    label: 'Paste',
                    icon: Icons.paste_rounded,
                    isActive: false,
                    onTap: canPaste
                        ? () async {
                            final ok = await controller.pasteLassoSelection();
                            if (ok) {
                              Fluttertoast.showToast(
                                msg: 'Selection pasted',
                                backgroundColor: const Color(0xFFFF9318),
                                textColor: Colors.white,
                                toastLength: Toast.LENGTH_SHORT,
                              );
                            }
                          }
                        : () {
                            Fluttertoast.showToast(
                              msg: 'No selection in clipboard',
                              backgroundColor: Colors.grey.shade700,
                              textColor: Colors.white,
                              toastLength: Toast.LENGTH_SHORT,
                            );
                          },
                  ),
                  const SizedBox(width: 4),
                  _bottomSubToolItem(
                    label: 'Duplicate',
                    icon: Icons.control_point_duplicate_rounded,
                    isActive: false,
                    onTap: () => controller.duplicateActiveShapeSticker(),
                  ),
                  const SizedBox(width: 4),
                  _bottomSubToolItem(
                    label: 'Reset',
                    icon: Icons.refresh_rounded,
                    isActive: false,
                    onTap: () => controller.resetActiveShapeSticker(),
                  ),
                  const SizedBox(width: 4),
                  _bottomSubToolItem(
                    label: 'Delete',
                    icon: Icons.delete_outline_rounded,
                    isActive: false,
                    onTap: () => controller.deleteActiveSticker(),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
            svgAsset: AssetConstants.export_icon,
            onTap: () => _showExportBottomSheet(ref),
            isSelected: false,
          ),
          Container(
            height: 36,
            width: 1,
            color: Colors.grey.shade300,
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          Expanded(
            child: SingleChildScrollView(
              key: const PageStorageKey('bottom_toolbar_categories_scroll'),
              controller: _toolbarScrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _bottomToolbarCategoryItem(
                    label: 'Brush',
                    svgAsset: AssetConstants.brush_icon,
                    isSelected: controller.activeCategory == 'Brush' &&
                        controller.drawingController.activeBrushPresetId == null,
                    onTap: () {
                      controller.activeCategory = 'Brush';
                      controller.drawingController.activeBrushPresetId = null;
                      controller.drawingController.setPaintContent(
                        FreehandLine(),
                      );
                      controller.drawingController.setStyle(
                        strokeWidth: controller.globalStrokeWidth,
                      );
                    },
                  ),
                  _bottomToolbarCategoryItem(
                    label: 'Studio',
                    svgAsset: AssetConstants.brush_tips,
                    isSelected: controller.activeCategory == 'Brush' &&
                        controller.drawingController.activeBrushPresetId != null,
                    onTap: () {
                      BrushStudioScreen.open(
                        context,
                        drawingController: controller.drawingController,
                        editorController: controller,
                      );
                    },
                  ),
                  _bottomToolbarCategoryItem(
                    label: 'Erase',
                    svgAsset: AssetConstants.erase_icon,
                    isSelected: controller.activeCategory == 'Erase',
                    onTap: () {
                      controller.drawingController.setPaintContent(Eraser());
                      controller.drawingController.setStyle(
                        strokeWidth: controller.globalStrokeWidth,
                      );
                      controller.activeCategory = 'Erase';
                    },
                  ),
                  _bottomToolbarCategoryItem(
                    label: 'Paint',
                    svgAsset: AssetConstants.paint_icon,
                    isSelected: controller.activeCategory == 'Paint',
                    onTap: () {
                      controller.drawingController.setPaintContent(
                        FillContent(),
                      );
                      controller.drawingController.setStyle(
                        strokeWidth: controller.globalStrokeWidth,
                      );
                      controller.activeCategory = 'Paint';
                    },
                  ),

                  _bottomToolbarCategoryItem(
                    label: 'Lasso',
                    svgAsset: AssetConstants.lesso_icon,
                    isSelected: controller.activeCategory == 'Lasso',
                    onTap: () {
                      controller.drawingController.setPaintContent(Lasso());
                      controller.drawingController.setStyle(
                        strokeWidth: controller.globalStrokeWidth,
                      );
                      controller.activeCategory = 'Lasso';
                    },
                  ),

                  _bottomToolbarCategoryItem(
                    label: 'Eyedropper',
                    svgAsset: AssetConstants.eyedropper,
                    isSelected: controller.activeCategory == 'Eyedropper',
                    onTap: () {
                      controller.drawingController.setPaintContent(
                        Eyedropper(),
                      );
                      controller.activeCategory = 'Eyedropper';
                    },
                  ),

                  ValueListenableBuilder<RulerConfig>(
                    valueListenable: controller.drawingController.rulerConfig,
                    builder: (context, rulerConfig, child) {
                      final bool isRulerActive =
                          rulerConfig.type != RulerType.none;
                      return _bottomToolbarCategoryItem(
                        label: 'Ruler',
                        svgAsset: AssetConstants.ruler_icon,
                        isSelected: isRulerActive,
                        onTap: () {
                          if (isRulerActive) {
                            controller.drawingController.rulerConfig.value =
                                rulerConfig.copyWith(type: RulerType.none);
                          } else {
                            controller.drawingController.rulerConfig.value =
                                rulerConfig.copyWith(type: RulerType.line);
                          }
                        },
                      );
                    },
                  ),
                  _bottomToolbarCategoryItem(
                    label: 'Import',
                    svgAsset: AssetConstants.import_icon,
                    isSelected: controller.activeCategory == 'Import' || controller.activeCategory == 'Assets',
                    onTap: () => _showImportBottomSheet(context, controller),
                  ),

                  _bottomToolbarCategoryItem(
                    label: 'Text',
                    svgAsset: AssetConstants.text_icon,
                    isSelected: controller.isTextToolSelected,
                    onTap: () {
                      if (controller.drawingController.isCurrentLayerLocked) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Current layer is locked.'),
                          ),
                        );
                        return;
                      }
                      controller.isTextToolSelected =
                          !controller.isTextToolSelected;
                      if (controller.isTextToolSelected) {
                        controller.activeCategory = 'Text';
                        if (controller.activeSticker != null &&
                            controller.activeSticker is! ActiveTextSticker) {
                          controller.stampActiveSticker();
                        }
                      } else {
                        controller.activeCategory = 'Brush';
                      }
                    },
                  ),
                  _bottomToolbarCategoryItem(
                    label: 'Shapes',
                    svgAsset: AssetConstants.shapes_icon,
                    isSelected: controller.activeCategory == 'Shapes',
                    onTap: () {
                      controller.currentSubMenu = 'shapes';
                      controller.activeCategory = 'Shapes';
                      controller.selectShape(controller.selectedShape);
                    },
                  ),
                  _bottomToolbarCategoryItem(
                    label: 'Blur',
                    svgAsset: AssetConstants.blur_icon,
                    isSelected: controller.activeCategory == 'Blur',
                    onTap: () {
                      controller.drawingController.setPaintContent(
                        BlurContent(),
                      );
                      controller.drawingController.setStyle(
                        strokeWidth: controller.globalStrokeWidth,
                      );
                      controller.activeCategory = 'Blur';
                      controller.drawingController.prepareSnapshot();
                    },
                  ),
                  _bottomToolbarCategoryItem(
                    label: 'Smudge',
                    svgAsset: AssetConstants.smudge_icon,
                    isSelected: controller.activeCategory == 'Smudge',
                    onTap: () {
                      controller.drawingController.setPaintContent(
                        SmudgeContent(),
                      );
                      controller.drawingController.setStyle(
                        strokeWidth: controller.globalStrokeWidth,
                      );
                      controller.activeCategory = 'Smudge';
                      controller.drawingController.prepareSnapshot();
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
    IconData? icon,
    String? svgAsset,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    final Color displayColor = isSelected
        ? ColorConstants.accent
        : (label == 'Export' ? const Color(0xFF334155) : const Color(0xFF64748B));
    final controller = ref.read(editorControllerProvider(widget.projectId));
    return GestureDetector(
      onTap: () {
        if (label != 'Text' && label != 'Ruler') {
          controller.isTextToolSelected = false;
        }
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minWidth: 54),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorConstants.accent.withValues(alpha: 0.09)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (svgAsset != null)
              SvgPicture.asset(
                svgAsset,
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(displayColor, BlendMode.srcIn),
              )
            else if (icon != null)
              Icon(icon, color: displayColor, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: displayColor,
                fontSize: 11.5,
                fontWeight: isSelected || label == "Export"
                    ? FontWeight.w700
                    : FontWeight.w500,
                letterSpacing: -0.1,
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
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(left: 16, right: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Colors.black87,
              ),
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
                    controller.drawingController.setStyle(
                      strokeWidth: controller.globalStrokeWidth,
                    );
                    BrushPresetPanel.show(
                      context,
                      controller.drawingController,
                    );
                  },
                ),
                _bottomSubToolItem(
                  label: 'Pen',
                  icon: Icons.edit_rounded,
                  isActive: controller.selectedSubTool == 'pen',
                  onTap: () {
                    controller.selectedSubTool = 'pen';
                    controller.drawingController.setPaintContent(
                      FreehandLine(),
                    );
                    controller.drawingController.setStyle(
                      strokeWidth: controller.globalStrokeWidth,
                    );
                  },
                ),
                _bottomSubToolItem(
                  label: 'Pencil',
                  icon: Icons.create_rounded,
                  isActive: controller.selectedSubTool == 'pencil',
                  onTap: () {
                    controller.selectedSubTool = 'pencil';
                    controller.drawingController.setPaintContent(
                      FreehandLine(),
                    );
                    controller.drawingController.setStyle(
                      strokeWidth: controller.globalStrokeWidth,
                    );
                  },
                ),
                _bottomSubToolItem(
                  label: 'Line',
                  icon: Icons.horizontal_rule_rounded,
                  isActive: controller.selectedSubTool == 'line',
                  onTap: () {
                    controller.selectedSubTool = 'line';
                    controller.drawingController.setPaintContent(SimpleLine());
                    controller.drawingController.setStyle(
                      strokeWidth: controller.globalStrokeWidth,
                    );
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
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(left: 16, right: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _bottomSubToolItem(
                  label: 'Heart',
                  svgAsset: AssetConstants.heart,
                  isActive: controller.selectedShape == 'heart',
                  onTap: () {
                    controller.selectShape('heart');
                  },
                ),
                _bottomSubToolItem(
                  label: 'Circle',
                  svgAsset: AssetConstants.circle,
                  isActive: controller.selectedShape == 'circle',
                  onTap: () {
                    controller.selectShape('circle');
                  },
                ),
                _bottomSubToolItem(
                  label: 'Square',
                  svgAsset: AssetConstants.square,
                  isActive: controller.selectedShape == 'square',
                  onTap: () {
                    controller.selectShape('square');
                  },
                ),
                _bottomSubToolItem(
                  label: 'Triangle',
                  svgAsset: AssetConstants.triangle,
                  isActive: controller.selectedShape == 'triangle',
                  onTap: () {
                    controller.selectShape('triangle');
                  },
                ),
                _bottomSubToolItem(
                  label: 'Line',
                  svgAsset: AssetConstants.line_icon,
                  isActive: controller.selectedShape == 'line',
                  onTap: () {
                    controller.selectShape('line');
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
    IconData? icon,
    String? svgAsset,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final Color activeColor = ColorConstants.accent;
    final Color inactiveColor = Colors.grey.shade600;
    final Color itemColor = isActive ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isActive
              ? Border.all(color: activeColor.withValues(alpha: 0.4), width: 1.0)
              : Border.all(color: Colors.transparent, width: 1.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (svgAsset != null)
              SvgPicture.asset(
                svgAsset,
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(itemColor, BlendMode.srcIn),
              )
            else if (icon != null)
              Icon(icon, color: itemColor, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: itemColor,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextStickerToolbar(
    ActiveTextSticker sticker,
    EditorController controller,
  ) {
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
              controller.stampActiveSticker();
            },
            child: Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(left: 16, right: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _bottomSubToolItem(
                  label: 'Edit Text',
                  icon: Icons.edit_rounded,
                  isActive: false,
                  onTap: () => _editTextStickerContent(sticker, controller),
                ),
                _bottomSubToolItem(
                  label: 'Fonts',
                  icon: Icons.font_download_rounded,
                  isActive: false,
                  onTap: () => _showFontSelectionSheet(sticker, controller),
                ),
                _bottomSubToolItem(
                  label: 'Format',
                  icon: Icons.format_size_rounded,
                  isActive: false,
                  onTap: () => _showSizeOpacitySheet(sticker, controller),
                ),
                _bottomSubToolItem(
                  label: 'Flip H',
                  icon: Icons.flip_rounded,
                  isActive: sticker.flipX,
                  onTap: () => controller.flipActiveTextStickerH(),
                ),
                _bottomSubToolItem(
                  label: 'Delete',
                  icon: Icons.delete_outline_rounded,
                  isActive: false,
                  onTap: () => controller.deleteActiveSticker(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editTextStickerContent(
    ActiveTextSticker sticker,
    EditorController controller,
  ) async {
    final text = await AppDialogs.showTextStickerDialog(
      context,
      initialText: sticker.text,
      title: 'Edit Text Sticker',
    );
    if (text != null && text.trim().isNotEmpty) {
      sticker.text = text.trim();
      controller.updateSnapshot();
    }
  }

  void _showFontSelectionSheet(
    ActiveTextSticker sticker,
    EditorController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Text(
                            'Fonts',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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
                                ? const Icon(
                                    Icons.check_circle,
                                    color: ColorConstants.accent,
                                  )
                                : null,
                            onTap: () {
                              sticker.fontFamily = preset.name;
                              setModalState(() {});
                              controller.updateSnapshot();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSizeOpacitySheet(
    ActiveTextSticker sticker,
    EditorController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Text Style & Size',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                      const Text(
                        'Size',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            activeTrackColor: ColorConstants.accent,
                            thumbColor: ColorConstants.accent,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                          ),
                          child: Slider(
                            value: sticker.fontSize.clamp(10.0, 100.0),
                            min: 10.0,
                            max: 100.0,
                            onChanged: (val) {
                              sticker.fontSize = val;
                              setModalState(() {});
                              controller.updateSnapshot();
                            },
                          ),
                        ),
                      ),
                      Text(
                        '${sticker.fontSize.round()}px',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.opacity_rounded, color: Colors.grey),
                      const SizedBox(width: 12),
                      const Text(
                        'Opacity',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            activeTrackColor: ColorConstants.accent,
                            thumbColor: ColorConstants.accent,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                          ),
                          child: Slider(
                            value: sticker.opacity.clamp(0.0, 1.0),
                            min: 0.0,
                            max: 1.0,
                            onChanged: (val) {
                              sticker.opacity = val;
                              sticker.color = sticker.color.withValues(
                                alpha: val,
                              );
                              setModalState(() {});
                              controller.updateSnapshot();
                            },
                          ),
                        ),
                      ),
                      Text(
                        '${(sticker.opacity * 100).round()}%',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Format',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
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
                                    },
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  _styleToggleButton(
                                    label: 'I',
                                    isActive: sticker.isItalic,
                                    onTap: () {
                                      sticker.isItalic = !sticker.isItalic;
                                      setModalState(() {});
                                      controller.updateSnapshot();
                                    },
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontSize: 16,
                                    ),
                                  ),
                                  _styleToggleButton(
                                    label: 'U',
                                    isActive: sticker.isUnderline,
                                    onTap: () {
                                      sticker.isUnderline =
                                          !sticker.isUnderline;
                                      setModalState(() {});
                                      controller.updateSnapshot();
                                    },
                                    style: const TextStyle(
                                      decoration: TextDecoration.underline,
                                      fontSize: 16,
                                    ),
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
                            const Text(
                              'Alignment',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _alignmentButton(
                                    icon: Icons.format_align_left_rounded,
                                    isActive:
                                        sticker.textAlign == TextAlign.left,
                                    onTap: () {
                                      sticker.textAlign = TextAlign.left;
                                      setModalState(() {});
                                      controller.updateSnapshot();
                                    },
                                  ),
                                  _alignmentButton(
                                    icon: Icons.format_align_center_rounded,
                                    isActive:
                                        sticker.textAlign == TextAlign.center,
                                    onTap: () {
                                      sticker.textAlign = TextAlign.center;
                                      setModalState(() {});
                                      controller.updateSnapshot();
                                    },
                                  ),
                                  _alignmentButton(
                                    icon: Icons.format_align_right_rounded,
                                    isActive:
                                        sticker.textAlign == TextAlign.right,
                                    onTap: () {
                                      sticker.textAlign = TextAlign.right;
                                      setModalState(() {});
                                      controller.updateSnapshot();
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
            ),
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

  Future<void> _showImportBottomSheet(BuildContext context, EditorController controller) async {
    final selectedOption = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4.5,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: ColorConstants.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            AssetConstants.import_icon,
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                              ColorConstants.accent,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Import Media',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Add video animation or image stickers',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 1. Video Animation Option
                  _buildImportOptionTile(
                    icon: Icons.movie_creation_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    iconBgColor: const Color(0xFFF3E8FF),
                    title: 'Import Video Animation',
                    subtitle: 'Trim and import video clips into animation frames',
                    badge: 'Animation',
                    onTap: () => Navigator.of(context).pop('video'),
                  ),
                  const SizedBox(height: 10),

                  // 2. Photo Gallery Option
                  _buildImportOptionTile(
                    icon: Icons.photo_library_rounded,
                    iconColor: const Color(0xFF2563EB),
                    iconBgColor: const Color(0xFFEFF6FF),
                    title: 'Photo Gallery Image',
                    subtitle: 'Add an image sticker to the active canvas frame',
                    onTap: () => Navigator.of(context).pop('gallery'),
                  ),
                  const SizedBox(height: 10),

                  // 3. Camera Option
                  _buildImportOptionTile(
                    icon: Icons.photo_camera_rounded,
                    iconColor: const Color(0xFFEA580C),
                    iconBgColor: const Color(0xFFFFF7ED),
                    title: 'Camera Photo',
                    subtitle: 'Take a new photo with device camera',
                    onTap: () => Navigator.of(context).pop('camera'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selectedOption == null) return;

    if (selectedOption == 'video') {
      try {
        final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
        if (file == null) return;

        if (!mounted) return;
        final trimmedFrames = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoTrimmingScreen(videoFile: File(file.path)),
          ),
        );

        if (trimmedFrames != null && trimmedFrames is List<String>) {
          await controller.importVideoFrames(trimmedFrames);
        }
      } catch (e) {
        debugPrint('Error importing video: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not import video: $e')),
          );
        }
      }
    } else if (selectedOption == 'gallery' || selectedOption == 'camera') {
      try {
        final source = selectedOption == 'camera' ? ImageSource.camera : ImageSource.gallery;
        final XFile? file = await _picker.pickImage(
          source: source,
          maxWidth: 2560,
          maxHeight: 2560,
          imageQuality: 95,
        );
        if (file != null && mounted) {
          final ui.Image image = await _getFileImage(file.path);
          controller.addImageSticker(image, imageUrl: file.path);
        }
      } catch (e) {
        debugPrint('Error picking sticker image: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not pick image: $e'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Widget _buildImportOptionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: iconBgColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: iconColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
