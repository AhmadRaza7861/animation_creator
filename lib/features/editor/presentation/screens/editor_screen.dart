import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:dummy/core/constants/app_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../../package_code/paint_contents.dart';
import '../../../../package_code/src/drawing_controller.dart';
import '../../../../package_code/src/ruler/ruler_config.dart';
import 'brush_studio_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/editor_providers.dart';
import '../controllers/editor_controller.dart';
import '../widgets/canvas_area.dart';
import '../widgets/timeline_panel.dart';
import '../widgets/toolbar_panel.dart';
import '../widgets/layer_panel.dart';
import '../widgets/sticker_widgets/text_sticker_widget.dart';
import '../widgets/sticker_widgets/shape_sticker_widget.dart';
import '../widgets/sticker_widgets/straight_line_sticker_widget.dart';
import '../widgets/sticker_widgets/freehand_line_sticker_widget.dart';
import '../widgets/project_loading_view.dart';
import '../../../../core/widgets/color_picker_screen.dart';
import '../../../../core/widgets/custom_switch.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../projects/presentation/screens/create_project_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

class EditorScreen extends ConsumerStatefulWidget {
  final String? projectId;

  const EditorScreen({super.key, required this.projectId});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen>
    with WidgetsBindingObserver {
  final TransformationController _transformationController =
      TransformationController();
  bool _isRulerMenuExpanded = false;
  bool _isRulerBarCollapsed = false;
  Offset? _brushPanelPosition;
  Offset? _rulerBarPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    try {
      ref.read(editorControllerProvider(widget.projectId)).saveProject(immediate: true);
    } catch (_) {}
    _transformationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      try {
        ref.read(editorControllerProvider(widget.projectId)).saveProject(immediate: true);
      } catch (_) {}
    }
  }

  void _resetBoard() {
    _transformationController.value = Matrix4.identity();
  }

  void _openColorPicker(Color currentColor, EditorController controller) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ColorPickerScreen(
          initialColor: currentColor,
          initialOpacity: controller.colorOpacity,
          onColorChanged: (Color newColor, double newOpacity) {
            setState(() {
              controller.colorOpacity = newOpacity;
              if (controller.activeSticker is ActiveTextSticker) {
                final textSticker =
                    controller.activeSticker as ActiveTextSticker;
                textSticker.color = newColor.withValues(alpha: newOpacity);
                textSticker.opacity = newOpacity;
              } else if (controller.activeSticker is ActiveShapeSticker) {
                final shapeSticker =
                    controller.activeSticker as ActiveShapeSticker;
                shapeSticker.content.paint.color = newColor.withValues(
                  alpha: newOpacity,
                );
              } else if (controller.activeSticker
                  is ActiveStraightLineSticker) {
                final lineSticker =
                    controller.activeSticker as ActiveStraightLineSticker;
                lineSticker.paint.color = newColor.withValues(
                  alpha: newOpacity,
                );
              } else if (controller.activeSticker
                  is ActiveFreehandLineSticker) {
                final freehandSticker =
                    controller.activeSticker as ActiveFreehandLineSticker;
                freehandSticker.content.paint.color = newColor.withValues(
                  alpha: newOpacity,
                );
              }
            });
            controller.drawingController.setStyle(
              color: newColor.withValues(alpha: newOpacity),
            );
            controller.updateSnapshot();
          },
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context, EditorController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final currentController = ref.watch(
              editorControllerProvider(widget.projectId),
            );

            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 20.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: ColorConstants.darkText,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.settings_suggest_rounded,
                            color: Colors.orangeAccent,
                            size: 22,
                          ),
                        ),
                        title: const Text(
                          'Project settings',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Title, dimensions & export options',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.black45,
                        ),
                        onTap: () async {
                          Navigator.pop(context);
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateProjectScreen(
                                repository: currentController.repository,
                                projectId: widget.projectId,
                              ),
                            ),
                          );
                          if (result == true) {
                            currentController.loadProjectData();
                          }
                        },
                      ),
                      const Divider(height: 1),
                      // ListTile(
                      //   contentPadding: EdgeInsets.zero,
                      //   leading: Container(
                      //     padding: const EdgeInsets.all(8),
                      //     decoration: BoxDecoration(
                      //       color: Colors.indigoAccent.withValues(alpha: 0.12),
                      //       borderRadius: BorderRadius.circular(10),
                      //     ),
                      //     child: const Icon(Icons.dashboard_customize_rounded, color: Colors.indigoAccent, size: 22),
                      //   ),
                      //   title: const Text('Frames Viewer', style: TextStyle(fontWeight: FontWeight.w600)),
                      //   subtitle: Text('${currentController.canvases.length} frames', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      //   trailing: const Icon(Icons.chevron_right, color: Colors.black45),
                      //   onTap: () async {
                      //     Navigator.pop(context);
                      //     final result = await Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) => FramesReorderScreen(
                      //           thumbnails: currentController.thumbnails,
                      //           currentIndex: currentController.currentIndex,
                      //         ),
                      //       ),
                      //     );
                      //     if (result != null && result is Map<String, dynamic>) {
                      //       final order = (result['order'] as List<dynamic>?)?.cast<int>();
                      //       final active = result['active'] as int? ?? 0;
                      //       if (order != null) {
                      //         currentController.applyFramesOrder(order, active);
                      //       }
                      //     }
                      //   },
                      // ),
                      // const Divider(height: 1),
                      // ListTile(
                      //   contentPadding: EdgeInsets.zero,
                      //   leading: Container(
                      //     padding: const EdgeInsets.all(8),
                      //     decoration: BoxDecoration(
                      //       color: Colors.deepOrangeAccent.withValues(alpha: 0.12),
                      //       borderRadius: BorderRadius.circular(10),
                      //     ),
                      //     child: const Icon(Icons.video_library_rounded, color: Colors.deepOrangeAccent, size: 22),
                      //   ),
                      //   title: const Text('Import Video', style: TextStyle(fontWeight: FontWeight.w600)),
                      //   subtitle: const Text('Trim and extract video frames into canvas', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      //   trailing: const Icon(Icons.chevron_right, color: Colors.black45),
                      //   onTap: () async {
                      //     Navigator.pop(context);
                      //     final ImagePicker picker = ImagePicker();
                      //     final XFile? file = await picker.pickVideo(source: ImageSource.gallery);
                      //     if (file == null) return;
                      //
                      //     final trimmedFrames = await Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) => VideoTrimmingScreen(videoFile: File(file.path)),
                      //       ),
                      //     );
                      //
                      //     if (trimmedFrames != null && trimmedFrames is List<String>) {
                      //       await currentController.importVideoFrames(trimmedFrames);
                      //     }
                      //   },
                      // ),
                      // const Divider(height: 1),
                      // ListTile(
                      //   contentPadding: EdgeInsets.zero,
                      //   leading: Container(
                      //     padding: const EdgeInsets.all(8),
                      //     decoration: BoxDecoration(
                      //       color: Colors.deepPurpleAccent.withValues(alpha: 0.12),
                      //       borderRadius: BorderRadius.circular(10),
                      //     ),
                      //     child: const Icon(Icons.aspect_ratio_rounded, color: Colors.deepPurpleAccent, size: 22),
                      //   ),
                      //   title: const Text('Canvas Size', style: TextStyle(fontWeight: FontWeight.w600)),
                      //   subtitle: Text(canvasSizeLabel, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      //   trailing: const Icon(Icons.chevron_right, color: Colors.black45),
                      //   onTap: () async {
                      //     Navigator.pop(context);
                      //     int initW = 1280;
                      //     int initH = 720;
                      //     String initName = 'Landscape (16:9)';
                      //     if ((ratio - 1.0).abs() < 0.05) {
                      //       initW = 1000;
                      //       initH = 1000;
                      //       initName = 'Square (1:1)';
                      //     } else if ((ratio - 9.0 / 16.0).abs() < 0.05) {
                      //       initW = 720;
                      //       initH = 1280;
                      //       initName = 'Portrait (9:16)';
                      //     } else if ((ratio - 4.0 / 3.0).abs() < 0.05) {
                      //       initW = 1024;
                      //       initH = 768;
                      //       initName = 'Standard (4:3)';
                      //     }
                      //     final result = await Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) => CanvasSizeScreen(
                      //           initialWidth: initW,
                      //           initialHeight: initH,
                      //           initialName: initName,
                      //         ),
                      //       ),
                      //     );
                      //     if (result != null && result is Map<String, dynamic>) {
                      //       final double? newRatio = result['aspectRatio'] as double?;
                      //       if (newRatio != null) {
                      //         currentController.aspectRatio = newRatio;
                      //       }
                      //     }
                      //   },
                      // ),
                      // const Divider(height: 1),
                      // ListTile(
                      //   contentPadding: EdgeInsets.zero,
                      //   leading: Container(
                      //     padding: const EdgeInsets.all(8),
                      //     decoration: BoxDecoration(
                      //       color: Colors.teal.withValues(alpha: 0.12),
                      //       borderRadius: BorderRadius.circular(10),
                      //     ),
                      //     child: const Icon(Icons.speed_rounded, color: Colors.teal, size: 22),
                      //   ),
                      //   title: const Text('Frames per second', style: TextStyle(fontWeight: FontWeight.w600)),
                      //   subtitle: Text('${currentController.fps} FPS', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      //   trailing: const Icon(Icons.chevron_right, color: Colors.black45),
                      //   onTap: () async {
                      //     Navigator.pop(context);
                      //     final result = await Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) => FpsScreen(initialFps: currentController.fps),
                      //       ),
                      //     );
                      //     if (result != null && result is int) {
                      //       currentController.fps = result;
                      //     }
                      //   },
                      // ),
                      // const Divider(height: 1),
                      // ListTile(
                      //   contentPadding: EdgeInsets.zero,
                      //   leading: Container(
                      //     padding: const EdgeInsets.all(8),
                      //     decoration: BoxDecoration(
                      //       color: Colors.blueAccent.withValues(alpha: 0.12),
                      //       borderRadius: BorderRadius.circular(10),
                      //     ),
                      //     child: const Icon(Icons.wallpaper_rounded, color: Colors.blueAccent, size: 22),
                      //   ),
                      //   title: const Text('Background', style: TextStyle(fontWeight: FontWeight.w600)),
                      //   subtitle: Text(bgLabel, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      //   trailing: const Icon(Icons.chevron_right, color: Colors.black45),
                      //   onTap: () async {
                      //     Navigator.pop(context);
                      //     final result = await Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) => BackgroundPresetsScreen(
                      //           initialPattern: currentController.globalBackground.pattern,
                      //         ),
                      //       ),
                      //     );
                      //     if (result != null && result is Map<String, dynamic>) {
                      //       final String? pattern = result['pattern'] as String?;
                      //       currentController.globalBackground = currentController.globalBackground.copyWith(
                      //         pattern: pattern,
                      //       );
                      //     }
                      //   },
                      // ),
                      //  const Divider(height: 1),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.layers_rounded,
                            color: Colors.amber,
                            size: 22,
                          ),
                        ),
                        title: const Text(
                          'Onion',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Ghost previous/next frames',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _showOnionSettingsSheet(
                                  context,
                                  currentController,
                                );
                              },
                              child: const Text(
                                'Edit',
                                style: TextStyle(
                                  color: ColorConstants.accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            CustomSwitch(
                              value: currentController.isOnionEnabled,
                              onChanged: (bool value) {
                                currentController.updateOnion(enabled: value);
                              },
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.cyan.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.grid_on_rounded,
                            color: Colors.cyan,
                            size: 22,
                          ),
                        ),
                        title: const Text(
                          'Grid',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Alignment and spacing guide',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _showGridSettingsSheet(
                                  context,
                                  currentController,
                                );
                              },
                              child: const Text(
                                'Edit',
                                style: TextStyle(
                                  color: ColorConstants.accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            CustomSwitch(
                              value: currentController.isGridEnabled,
                              onChanged: (bool value) {
                                currentController.updateGrid(enabled: value);
                              },
                            ),
                          ],
                        ),
                      ),
                      // const Divider(height: 1),
                      // ListTile(
                      //   contentPadding: EdgeInsets.zero,
                      //   leading: Container(
                      //     padding: const EdgeInsets.all(8),
                      //     decoration: BoxDecoration(
                      //       color: Colors.pinkAccent.withValues(alpha: 0.12),
                      //       borderRadius: BorderRadius.circular(10),
                      //     ),
                      //     child: const Icon(Icons.auto_awesome_rounded, color: Colors.pinkAccent, size: 22),
                      //   ),
                      //   title: const Text('Sticker / Object Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                      //   subtitle: const Text('Show transform handles on drawn strokes to move, resize & rotate before placing', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      //   trailing: CustomSwitch(
                      //     value: currentController.enableStickers,
                      //     onChanged: (bool value) {
                      //       currentController.enableStickers = value;
                      //     },
                      //   ),
                      // ),
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

  void _showOnionSettingsSheet(
    BuildContext context,
    EditorController controller,
  )
  {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final ctrl = ref.watch(editorControllerProvider(widget.projectId));
            final List<Widget> previewCircles = [];

            for (int i = ctrl.onionBefore; i >= 1; i--) {
              final double dx = -i * 22.0;
              final double dy = -30.0 + (i * 8.0) + (i * i * 0.8);
              final double opacity = (0.4 * (1.0 - (i - 1) / ctrl.onionBefore))
                  .clamp(0.05, 0.4);

              previewCircles.add(
                Transform.translate(
                  offset: Offset(dx, dy),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ctrl.isOnionEnabled
                          ? (ctrl.onionColorMode
                                ? Colors.red.withOpacity(opacity)
                                : Colors.black.withOpacity(opacity * 0.5))
                          : Colors.black.withOpacity(0.05),
                      border: Border.all(
                        color: ctrl.isOnionEnabled
                            ? (ctrl.onionColorMode
                                  ? Colors.red.withOpacity(opacity * 1.5)
                                  : Colors.black.withOpacity(opacity))
                            : Colors.black.withOpacity(0.1),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              );
            }

            for (int j = ctrl.onionAfter; j >= 1; j--) {
              final double dx = j * 22.0;
              final double dy = -30.0 + (j * 8.0) + (j * j * 0.8);
              final double opacity = (0.4 * (1.0 - (j - 1) / ctrl.onionAfter))
                  .clamp(0.05, 0.4);

              previewCircles.add(
                Transform.translate(
                  offset: Offset(dx, dy),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ctrl.isOnionEnabled
                          ? (ctrl.onionColorMode
                                ? Colors.green.withOpacity(opacity)
                                : Colors.black.withOpacity(opacity * 0.5))
                          : Colors.black.withOpacity(0.05),
                      border: Border.all(
                        color: ctrl.isOnionEnabled
                            ? (ctrl.onionColorMode
                                  ? Colors.green.withOpacity(opacity * 1.5)
                                  : Colors.black.withOpacity(opacity))
                            : Colors.black.withOpacity(0.1),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              );
            }

            previewCircles.add(
              Transform.translate(
                offset: const Offset(0, -30),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade400,
                    border: Border.all(color: Colors.grey.shade600, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            );

            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: ColorConstants.darkText,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Onion',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.darkText,
                        ),
                      ),
                      CustomSwitch(
                        value: ctrl.isOnionEnabled,
                        onChanged: (val) {
                          ctrl.updateOnion(enabled: val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: previewCircles,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Color',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.darkText,
                      ),
                    ),
                    trailing: CustomSwitch(
                      value: ctrl.onionColorMode,
                      onChanged: ctrl.isOnionEnabled
                          ? (val) {
                              ctrl.updateOnion(colorMode: val);
                            }
                          : null,
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Loop',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.darkText,
                      ),
                    ),
                    trailing: CustomSwitch(
                      value: ctrl.onionLoop,
                      onChanged: ctrl.isOnionEnabled
                          ? (val) {
                              ctrl.updateOnion(loop: val);
                            }
                          : null,
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Frames before',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: ColorConstants.darkText,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '${ctrl.onionBefore}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: ColorConstants.accent,
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ],
                        ),
                        Slider(
                          value: ctrl.onionBefore.toDouble(),
                          min: 0,
                          max: 5,
                          divisions: 5,
                          activeColor: ColorConstants.accent,
                          onChanged: ctrl.isOnionEnabled
                              ? (val) {
                                  ctrl.updateOnion(before: val.round());
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Frames after',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: ColorConstants.darkText,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '${ctrl.onionAfter}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: ColorConstants.accent,
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ],
                        ),
                        Slider(
                          value: ctrl.onionAfter.toDouble(),
                          min: 0,
                          max: 5,
                          divisions: 5,
                          activeColor: ColorConstants.accent,
                          onChanged: ctrl.isOnionEnabled
                              ? (val) {
                                  ctrl.updateOnion(after: val.round());
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showGridSettingsSheet(
    BuildContext context,
    EditorController controller,
  )
  {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final ctrl = ref.watch(editorControllerProvider(widget.projectId));
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: ColorConstants.darkText,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Grid',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.darkText,
                        ),
                      ),
                      CustomSwitch(
                        value: ctrl.isGridEnabled,
                        onChanged: (val) {
                          ctrl.updateGrid(enabled: val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _GridPainterPreview(
                                opacity: ctrl.isGridEnabled
                                    ? ctrl.gridOpacity
                                    : 0.05,
                                verticalSpacing: ctrl.gridVerticalSpacing / 2,
                                horizontalSpacing:
                                    ctrl.gridHorizontalSpacing / 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Line opacity',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: ColorConstants.darkText,
                              ),
                            ),
                            Text(
                              '${(ctrl.gridOpacity * 100).round()}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: ColorConstants.accent,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: ctrl.gridOpacity,
                          min: 0.05,
                          max: 1.0,
                          activeColor: ColorConstants.accent,
                          onChanged: ctrl.isGridEnabled
                              ? (val) {
                                  ctrl.updateGrid(opacity: val);
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Vertical line spacing',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: ColorConstants.darkText,
                              ),
                            ),
                            Text(
                              '${ctrl.gridVerticalSpacing.round()}px',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: ColorConstants.accent,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: ctrl.gridVerticalSpacing,
                          min: 20.0,
                          max: 200.0,
                          activeColor: ColorConstants.accent,
                          onChanged: ctrl.isGridEnabled
                              ? (val) {
                                  ctrl.updateGrid(vertical: val);
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Horizontal line spacing',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: ColorConstants.darkText,
                              ),
                            ),
                            Text(
                              '${ctrl.gridHorizontalSpacing.round()}px',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: ColorConstants.accent,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: ctrl.gridHorizontalSpacing,
                          min: 20.0,
                          max: 200.0,
                          activeColor: ColorConstants.accent,
                          onChanged: ctrl.isGridEnabled
                              ? (val) {
                                  ctrl.updateGrid(horizontal: val);
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleBack(
    BuildContext context,
    EditorController controller,
  ) async {
    if (controller.isAudioStudioOpen) {
      controller.isAudioStudioOpen = false;
      return;
    }
    await controller.saveProject(immediate: true);
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(editorControllerProvider(widget.projectId));

    if (controller.isLoadingProject) {
      return const ProjectLoadingView();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack(context, controller);
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: SafeArea(
            child: Container(
              height: kToolbarHeight,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: ColorConstants.border_color,
                //   border: Border(bottom: BorderSide(color: Color(0xFFE5E5EA), width: 0.5)),
              ),
              child: Row(
                children: [
                  AppBackButton(
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    size: 36,
                    borderRadius: 10,
                    onPressed: () => _handleBack(context, controller),
                  ),
                  ValueListenableBuilder<DrawConfig>(
                    valueListenable: controller.drawingController.drawConfig,
                    builder: (context, config, child) {
                      final bool isTextActive =
                          controller.activeSticker is ActiveTextSticker ||
                          controller.isTextToolSelected ||
                          controller.activeCategory == 'Text';

                      final bool hasActiveSticker =
                          controller.activeSticker != null;

                      final showColor =
                          isTextActive ||
                          hasActiveSticker ||
                          (config.contentType != Eraser &&
                              config.contentType != Lasso &&
                              config.contentType != BlurContent &&
                              config.contentType != SmudgeContent);

                      if (!showColor) return const SizedBox.shrink();

                      Color activeColor = config.color;
                      if (controller.activeSticker is ActiveTextSticker) {
                        activeColor =
                            (controller.activeSticker as ActiveTextSticker)
                                .color;
                      } else if (controller.activeSticker
                          is ActiveShapeSticker) {
                        activeColor =
                            (controller.activeSticker as ActiveShapeSticker)
                                .content
                                .paint
                                .color;
                      } else if (controller.activeSticker
                          is ActiveStraightLineSticker) {
                        activeColor =
                            (controller.activeSticker
                                    as ActiveStraightLineSticker)
                                .paint
                                .color;
                      } else if (controller.activeSticker
                          is ActiveFreehandLineSticker) {
                        activeColor =
                            (controller.activeSticker
                                    as ActiveFreehandLineSticker)
                                .content
                                .paint
                                .color;
                      }

                      return GestureDetector(
                        onTap: () => _openColorPicker(activeColor, controller),
                        child: Container(
                          width: 30,
                          height: 30,
                          margin: const EdgeInsets.only(left: 4),
                          alignment: Alignment.center,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SvgPicture.asset(
                                AssetConstants.color_picker_icon,
                                width: 28,
                                height: 28,
                                fit: BoxFit.contain,
                              ),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: activeColor.withValues(alpha: 1.0),
                                  shape: BoxShape.circle,
                                  // border: Border.all(color: Colors.white, width: 1.5),
                                  // boxShadow: const [
                                  //   BoxShadow(
                                  //     color: Colors.black26,
                                  //     blurRadius: 1.5,
                                  //     offset: Offset(0, 0.5),
                                  //   ),
                                  // ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder<DrawConfig>(
                    valueListenable: controller.drawingController.drawConfig,
                    builder: (context, config, child) {
                      final showSize =
                          config.contentType != Lasso;
                      if (!showSize) return const SizedBox.shrink();

                      return MenuAnchor(
                        style: MenuStyle(
                          padding: WidgetStateProperty.all(EdgeInsets.zero),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          backgroundColor: WidgetStateProperty.all(
                            Colors.white,
                          ),
                          elevation: WidgetStateProperty.all(12),
                          shadowColor: WidgetStateProperty.all(
                            Colors.black.withValues(alpha: 0.12),
                          ),
                          surfaceTintColor: WidgetStateProperty.all(
                            Colors.transparent,
                          ),
                        ),
                        builder:
                            (
                              BuildContext context,
                              MenuController menuController,
                              Widget? child,
                            ) {
                              return GestureDetector(
                                onTap: () {
                                  if (menuController.isOpen) {
                                    menuController.close();
                                  } else {
                                    menuController.open();
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SvgPicture.asset(
                                        (controller.activeCategory == 'Blur' ||
                                                config.contentType == BlurContent)
                                            ? AssetConstants.blur_icon
                                            : (controller.activeCategory == 'Smudge' ||
                                                    config.contentType == SmudgeContent)
                                                ? AssetConstants.smudge_icon
                                                : AssetConstants.stock_icon,
                                        width: 14,
                                        height: 14,
                                        colorFilter: const ColorFilter.mode(
                                          Color(0xFF475569),
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        (controller.activeCategory == 'Blur' ||
                                                config.contentType == BlurContent)
                                            ? 'Blur • ${(controller.blurStrength * 100).round()}%'
                                            : (controller.activeCategory == 'Smudge' ||
                                                    config.contentType == SmudgeContent)
                                                ? 'Smudge • ${(controller.smudgeStrength * 100).round()}%'
                                                : '${controller.globalStrokeWidth.round()}px',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF334155),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                        menuChildren: [
                          StatefulBuilder(
                            builder: (context, setPopupState) {
                              final bool isBlurActive =
                                  controller.activeCategory == 'Blur' ||
                                  config.contentType == BlurContent;
                              final bool isSmudgeActive =
                                  controller.activeCategory == 'Smudge' ||
                                  config.contentType == SmudgeContent;
                              final double currentWidth =
                                  controller.globalStrokeWidth;
                              final double currentOpacity =
                                  controller.colorOpacity;
                              final sizePresets = [
                                2.0,
                                5.0,
                                10.0,
                                18.0,
                                30.0,
                                50.0,
                              ];
                              final opacityPresets = [0.25, 0.50, 0.75, 1.0];
                              final blurPresets = [0.0, 0.25, 0.50, 0.75, 1.0];
                              final smudgePresets = [0.0, 0.25, 0.50, 0.75, 1.0];

                              final baseColor = config.color.withOpacity(1.0);
                              final previewColor = baseColor.withOpacity(
                                currentOpacity,
                              );

                              return Container(
                                width: 268,
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // 1. Live Preview Card
                                    Container(
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                          width: 1.0,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.03,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: Stack(
                                          children: [
                                            if (!isBlurActive && !isSmudgeActive)
                                              const Positioned.fill(
                                                child: CustomPaint(
                                                  painter: _CheckerboardPainter(),
                                                ),
                                              ),
                                            Positioned.fill(
                                              child: CustomPaint(
                                                painter: isBlurActive
                                                    ? BlurPreviewPainter(
                                                        controller.blurStrength,
                                                        currentWidth,
                                                      )
                                                    : isSmudgeActive
                                                        ? SmudgePreviewPainter(
                                                            controller.smudgeStrength,
                                                            currentWidth,
                                                          )
                                                        : StrokePreviewPainter(
                                                            currentWidth,
                                                            previewColor,
                                                          ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // 2. Brush Size Header
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SvgPicture.asset(
                                              isBlurActive
                                                  ? AssetConstants.blur_icon
                                                  : isSmudgeActive
                                                      ? AssetConstants.smudge_icon
                                                      : AssetConstants.stock_icon,
                                              width: 14,
                                              height: 14,
                                              colorFilter:
                                                  const ColorFilter.mode(
                                                    Color(0xFF475569),
                                                    BlendMode.srcIn,
                                                  ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              isBlurActive
                                                  ? 'Blur Size'
                                                  : isSmudgeActive
                                                      ? 'Smudge Size'
                                                      : 'Brush Size',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: ColorConstants.accent
                                                .withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            '${currentWidth.round()} px',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: ColorConstants.accent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),

                                    // 3. Brush Size Slider
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 5,
                                        activeTrackColor: ColorConstants.accent,
                                        inactiveTrackColor: const Color(
                                          0xFFF1F5F9,
                                        ),
                                        thumbColor: Colors.white,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 8,
                                          elevation: 3,
                                          pressedElevation: 5,
                                        ),
                                        overlayColor: ColorConstants.accent
                                            .withValues(alpha: 0.15),
                                        overlayShape:
                                            const RoundSliderOverlayShape(
                                              overlayRadius: 16,
                                            ),
                                        trackShape:
                                            const RoundedRectSliderTrackShape(),
                                      ),
                                      child: Slider(
                                        value: currentWidth.clamp(1.0, 50.0),
                                        min: 1.0,
                                        max: 50.0,
                                        onChanged: (val) {
                                          setPopupState(() {
                                            controller.globalStrokeWidth = val;
                                          });
                                          controller.drawingController
                                              .setStyle(strokeWidth: val);
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 4),

                                    // 4. Brush Size Quick Presets
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: sizePresets.map((p) {
                                        final isSelected =
                                            currentWidth.round() == p.round();
                                        return GestureDetector(
                                          onTap: () {
                                            setPopupState(() {
                                              controller.globalStrokeWidth = p;
                                            });
                                            controller.drawingController
                                                .setStyle(strokeWidth: p);
                                            setState(() {});
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 150,
                                            ),
                                            width: 34,
                                            height: 30,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: isSelected
                                                  ? ColorConstants.accent
                                                  : const Color(0xFFF8FAFC),
                                              border: Border.all(
                                                color: isSelected
                                                    ? Colors.transparent
                                                    : const Color(0xFFE2E8F0),
                                                width: 1.0,
                                              ),
                                              boxShadow: isSelected
                                                  ? [
                                                      BoxShadow(
                                                        color: ColorConstants
                                                            .accent
                                                            .withValues(
                                                              alpha: 0.3,
                                                            ),
                                                        blurRadius: 6,
                                                        offset: const Offset(
                                                          0,
                                                          2,
                                                        ),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            child: Text(
                                              '${p.round()}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: isSelected
                                                    ? Colors.white
                                                    : const Color(0xFF475569),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),

                                    // 5. Divider
                                    Container(
                                      height: 1,
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      color: const Color(0xFFF1F5F9),
                                    ),

                                    if (isBlurActive) ...[
                                      // 6. Blur Intensity Header
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SvgPicture.asset(
                                                AssetConstants.blur_icon,
                                                width: 15,
                                                height: 15,
                                                colorFilter:
                                                    const ColorFilter.mode(
                                                      Color(0xFF475569),
                                                      BlendMode.srcIn,
                                                    ),
                                              ),
                                              const SizedBox(width: 6),
                                              const Text(
                                                'Blur Intensity',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: ColorConstants.accent
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${(controller.blurStrength * 100).round()}%',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: ColorConstants.accent,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),

                                      // 7. Blur Intensity Slider (0% to 100%)
                                      SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 5,
                                          activeTrackColor:
                                              ColorConstants.accent,
                                          inactiveTrackColor: const Color(
                                            0xFFF1F5F9,
                                          ),
                                          thumbColor: Colors.white,
                                          thumbShape:
                                              const RoundSliderThumbShape(
                                                enabledThumbRadius: 8,
                                                elevation: 3,
                                                pressedElevation: 5,
                                              ),
                                          overlayColor: ColorConstants.accent
                                              .withValues(alpha: 0.15),
                                          overlayShape:
                                              const RoundSliderOverlayShape(
                                                overlayRadius: 16,
                                              ),
                                          trackShape:
                                              const RoundedRectSliderTrackShape(),
                                        ),
                                        child: Slider(
                                          value: controller.blurStrength
                                              .clamp(0.0, 1.0),
                                          min: 0.0,
                                          max: 1.0,
                                          onChanged: (val) {
                                            setPopupState(() {
                                              controller.blurStrength = val;
                                            });
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      // 8. Blur Intensity Quick Presets
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: blurPresets.map((b) {
                                          final isSelected =
                                              (controller.blurStrength - b)
                                                      .abs() <
                                                  0.04;
                                          return GestureDetector(
                                            onTap: () {
                                              setPopupState(() {
                                                controller.blurStrength = b;
                                              });
                                              setState(() {});
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 150,
                                              ),
                                              width: 42,
                                              height: 30,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                color: isSelected
                                                    ? ColorConstants.accent
                                                    : const Color(0xFFF8FAFC),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? Colors.transparent
                                                      : const Color(
                                                        0xFFE2E8F0,
                                                      ),
                                                  width: 1.0,
                                                ),
                                                boxShadow: isSelected
                                                    ? [
                                                        BoxShadow(
                                                          color: ColorConstants
                                                              .accent
                                                              .withValues(
                                                                alpha: 0.3,
                                                              ),
                                                          blurRadius: 6,
                                                          offset: const Offset(
                                                            0,
                                                            2,
                                                          ),
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                              child: Text(
                                                '${(b * 100).round()}%',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : const Color(
                                                        0xFF475569,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ] else if (isSmudgeActive) ...[
                                      // 6. Smudge Intensity Header
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SvgPicture.asset(
                                                AssetConstants.smudge_icon,
                                                width: 15,
                                                height: 15,
                                                colorFilter:
                                                    const ColorFilter.mode(
                                                      Color(0xFF475569),
                                                      BlendMode.srcIn,
                                                    ),
                                              ),
                                              const SizedBox(width: 6),
                                              const Text(
                                                'Smudge Intensity',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: ColorConstants.accent
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${(controller.smudgeStrength * 100).round()}%',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: ColorConstants.accent,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),

                                      // 7. Smudge Intensity Slider (0% to 100%)
                                      SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 5,
                                          activeTrackColor:
                                              ColorConstants.accent,
                                          inactiveTrackColor: const Color(
                                            0xFFF1F5F9,
                                          ),
                                          thumbColor: Colors.white,
                                          thumbShape:
                                              const RoundSliderThumbShape(
                                                enabledThumbRadius: 8,
                                                elevation: 3,
                                                pressedElevation: 5,
                                              ),
                                          overlayColor: ColorConstants.accent
                                              .withValues(alpha: 0.15),
                                          overlayShape:
                                              const RoundSliderOverlayShape(
                                                overlayRadius: 16,
                                              ),
                                          trackShape:
                                              const RoundedRectSliderTrackShape(),
                                        ),
                                        child: Slider(
                                          value: controller.smudgeStrength
                                              .clamp(0.0, 1.0),
                                          min: 0.0,
                                          max: 1.0,
                                          onChanged: (val) {
                                            setPopupState(() {
                                              controller.smudgeStrength = val;
                                            });
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      // 8. Smudge Intensity Quick Presets
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: smudgePresets.map((b) {
                                          final isSelected =
                                              (controller.smudgeStrength - b)
                                                      .abs() <
                                                  0.04;
                                          return GestureDetector(
                                            onTap: () {
                                              setPopupState(() {
                                                controller.smudgeStrength = b;
                                              });
                                              setState(() {});
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 150,
                                              ),
                                              width: 42,
                                              height: 30,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                color: isSelected
                                                    ? ColorConstants.accent
                                                    : const Color(0xFFF8FAFC),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? Colors.transparent
                                                      : const Color(
                                                        0xFFE2E8F0,
                                                      ),
                                                  width: 1.0,
                                                ),
                                                boxShadow: isSelected
                                                    ? [
                                                        BoxShadow(
                                                          color: ColorConstants
                                                              .accent
                                                              .withValues(
                                                                alpha: 0.3,
                                                              ),
                                                          blurRadius: 6,
                                                          offset: const Offset(
                                                            0,
                                                            2,
                                                          ),
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                              child: Text(
                                                '${(b * 100).round()}%',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : const Color(
                                                        0xFF475569,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ] else ...[
                                      // 6. Opacity Header
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.opacity_rounded,
                                                size: 15,
                                                color: Color(0xFF475569),
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                'Opacity',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: ColorConstants.accent
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    8,
                                                  ),
                                            ),
                                            child: Text(
                                              '${(currentOpacity * 100).round()}%',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: ColorConstants.accent,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),

                                      // 7. Opacity Slider
                                      SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 5,
                                          activeTrackColor: ColorConstants.accent,
                                          inactiveTrackColor: const Color(
                                            0xFFF1F5F9,
                                          ),
                                          thumbColor: Colors.white,
                                          thumbShape: const RoundSliderThumbShape(
                                            enabledThumbRadius: 8,
                                            elevation: 3,
                                            pressedElevation: 5,
                                          ),
                                          overlayColor: ColorConstants.accent
                                              .withValues(alpha: 0.15),
                                          overlayShape:
                                              const RoundSliderOverlayShape(
                                                overlayRadius: 16,
                                              ),
                                          trackShape:
                                              const RoundedRectSliderTrackShape(),
                                        ),
                                        child: Slider(
                                          value: currentOpacity.clamp(0.05, 1.0),
                                          min: 0.05,
                                          max: 1.0,
                                          onChanged: (val) {
                                            setPopupState(() {
                                              controller.colorOpacity = val;
                                            });
                                            controller.drawingController.setStyle(
                                              color: baseColor.withOpacity(val),
                                            );
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      // 8. Opacity Quick Presets
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: opacityPresets.map((o) {
                                          final isSelected =
                                              (currentOpacity - o).abs() < 0.04;
                                          return GestureDetector(
                                            onTap: () {
                                              setPopupState(() {
                                                controller.colorOpacity = o;
                                              });
                                              controller.drawingController
                                                  .setStyle(
                                                    color: baseColor.withOpacity(
                                                      o,
                                                    ),
                                                  );
                                              setState(() {});
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 150,
                                              ),
                                              width: 54,
                                              height: 30,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                color: isSelected
                                                    ? ColorConstants.accent
                                                    : const Color(0xFFF8FAFC),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? Colors.transparent
                                                      : const Color(0xFFE2E8F0),
                                                  width: 1.0,
                                                ),
                                                boxShadow: isSelected
                                                    ? [
                                                        BoxShadow(
                                                          color: ColorConstants
                                                              .accent
                                                              .withValues(
                                                                alpha: 0.3,
                                                              ),
                                                          blurRadius: 6,
                                                          offset: const Offset(
                                                            0,
                                                            2,
                                                          ),
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                              child: Text(
                                                '${(o * 100).round()}%',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : const Color(0xFF475569),
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const Spacer(),

                  ListenableBuilder(
                    listenable: controller.drawingController,
                    builder: (context, _) {
                      final bool canUndo = controller.drawingController.canUndo();
                      final bool canRedo = controller.drawingController.canRedo();

                      return Container(
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Undo
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(16),
                                ),
                                onTap: canUndo
                                    ? () => controller.drawingController.undo()
                                    : null,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  child: Icon(
                                    Icons.undo_rounded,
                                    size: 19,
                                    color: canUndo
                                        ? ColorConstants.darkText
                                        : const Color(0xFFCBD5E1),
                                  ),
                                ),
                              ),
                            ),
                            // Divider
                            Container(
                              width: 1,
                              height: 14,
                              color: const Color(0xFFE2E8F0),
                            ),
                            // Redo
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(16),
                                ),
                                onTap: canRedo
                                    ? () => controller.drawingController.redo()
                                    : null,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  child: Icon(
                                    Icons.redo_rounded,
                                    size: 19,
                                    color: canRedo
                                        ? ColorConstants.darkText
                                        : const Color(0xFFCBD5E1),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: SvgPicture.asset(
                      AssetConstants.expander_icon,
                      width: 20,
                      height: 20,
                    ),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: _resetBoard,
                    tooltip: 'Reset Zoom / Position',
                  ),
                  IconButton(
                    icon: SvgPicture.asset(
                      AssetConstants.setting_icon,
                      width: 20,
                      height: 20,
                    ),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _showSettingsSheet(context, controller),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            systemNavigationBarColor: Colors.white,
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: ColorConstants.selected_type,
                        ),
                        child: CanvasArea(
                          projectId: widget.projectId,
                          transformationController: _transformationController,
                        ),
                      ),
                    ),
                    ToolbarPanel(projectId: widget.projectId),
                    const SizedBox(height: 80),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: TimelinePanel(projectId: widget.projectId),
                ),
                if (controller.activeCategory == 'Brush')
                  Positioned(
                    left: (_brushPanelPosition?.dx ??
                            (MediaQuery.of(context).size.width - 44.0 - 16.0))
                        .clamp(
                          2.0,
                          (MediaQuery.of(context).size.width - 44.0 - 2.0)
                              .clamp(2.0, 4000.0),
                        ),
                    top: (_brushPanelPosition?.dy ?? 12.0)
                        .clamp(
                          0.0,
                          (MediaQuery.of(context).size.height - 140.0)
                              .clamp(0.0, 4000.0),
                        ),
                    child: _buildRightVerticalPanel(controller),
                  ),
                if (controller.activeCategory == 'Brush' &&
                    _isRulerMenuExpanded &&
                    controller.drawingController.rulerConfig.value.type !=
                        RulerType.none)
                  if (_rulerBarPosition == null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 155.0,
                      child: Center(
                        child: _buildHorizontalRulerBar(controller),
                      ),
                    )
                  else
                    Positioned(
                      left: _rulerBarPosition!.dx.clamp(
                        8.0,
                        MediaQuery.of(context).size.width -
                            (_isRulerBarCollapsed ? 110.0 : 325.0) -
                            8.0,
                      ),
                      top: _rulerBarPosition!.dy.clamp(
                        10.0,
                        MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.top -
                            50.0 -
                            MediaQuery.of(context).padding.bottom -
                            140.0,
                      ),
                      child: _buildHorizontalRulerBar(controller),
                    ),
                if (controller.showLayerPanel)
                  Positioned(
                    left:
                        controller.layersPanelPosition?.dx ??
                        (MediaQuery.of(context).size.width - 250 - 16),
                    top:
                        controller.layersPanelPosition?.dy ??
                        (MediaQuery.of(context).size.height - 480),
                    child: LayerPanel(
                      controller: controller.drawingController,
                      onClose: () {
                        controller.showLayerPanel = false;
                      },
                      onHeaderDrag: (details) {
                        final double currentX =
                            controller.layersPanelPosition?.dx ??
                            (MediaQuery.of(context).size.width - 250 - 16);
                        final double currentY =
                            controller.layersPanelPosition?.dy ??
                            (MediaQuery.of(context).size.height - 480);

                        final double newX = (currentX + details.delta.dx).clamp(
                          0.0,
                          MediaQuery.of(context).size.width - 250,
                        );
                        final double newY = (currentY + details.delta.dy).clamp(
                          MediaQuery.of(context).padding.top,
                          MediaQuery.of(context).size.height - 180,
                        );

                        controller.layersPanelPosition = Offset(newX, newY);
                      },
                    ),
                  ),
                if (controller.activeCategory == 'Lasso' &&
                    controller.activeSticker == null &&
                    controller.canPasteLassoSelection)
                  Positioned(
                    bottom: 160,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () async {
                          final ok = await controller.pasteLassoSelection();
                          if (ok) {
                            Fluttertoast.showToast(
                              msg: 'Selection pasted',
                              backgroundColor: const Color(0xFFFF9318),
                              textColor: Colors.white,
                              toastLength: Toast.LENGTH_SHORT,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFFFF9318).withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.paste_rounded,
                                size: 18,
                                color: Color(0xFFFF9318),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Paste Selection',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRightVerticalPanel(EditorController controller) {
    return AnimatedBuilder(
      animation: Listenable.merge([controller, controller.drawingController]),
      builder: (context, child) {
        final bool isBrushTipsActive =
            controller.activeCategory == 'Brush' &&
            controller.drawingController.activeBrushPresetId != null;
        final bool isSingleBrushActive =
            controller.activeCategory == 'Brush' &&
            controller.drawingController.activeBrushPresetId == null;

        return ValueListenableBuilder<RulerConfig>(
          valueListenable: controller.drawingController.rulerConfig,
          builder: (context, rulerConfig, child) {
            final bool isRulerActive =
                _isRulerMenuExpanded && rulerConfig.type != RulerType.none;

            return ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  width: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.95),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 18,
                        spreadRadius: 0,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag Grab Pill (dedicated drag handle)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: _onBrushPanelPanUpdate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          child: Container(
                            width: 18,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),

                      // 1. Brush Tips Studio Button
                      _buildFloatingDockItem(
                        tooltip: 'Brush Studio',
                        svgAsset: AssetConstants.brush_tips,
                        isActive: isBrushTipsActive,
                        onTap: () {
                          BrushStudioScreen.open(
                            context,
                            drawingController: controller.drawingController,
                            editorController: controller,
                          );
                        },
                      ),
                      const SizedBox(height: 5),

                      // 2. Single Brush Tool Button
                      _buildFloatingDockItem(
                        tooltip: 'Freehand Brush',
                        svgAsset: AssetConstants.brush_icon,
                        isActive: isSingleBrushActive,
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
                      const SizedBox(height: 5),

                      // 3. Ruler Quick Toggle Button
                      _buildFloatingDockItem(
                        tooltip: 'Ruler',
                        svgAsset: AssetConstants.ruler_icon,
                        isActive: isRulerActive,
                        onTap: () {
                          setState(() {
                            if (isRulerActive) {
                              _isRulerMenuExpanded = false;
                              controller.drawingController.rulerConfig.value =
                                  rulerConfig.copyWith(type: RulerType.none);
                            } else {
                              _isRulerMenuExpanded = true;
                              controller.drawingController.rulerConfig.value =
                                  rulerConfig.copyWith(type: RulerType.line);
                            }
                          });
                        },
                      ),

                      // 4. Sticker / Object Mode Toggle Button
                      if (isSingleBrushActive) ...[
                        const SizedBox(height: 5),
                        _buildFloatingDockItem(
                          tooltip: 'Sticker Mode',
                          iconData: Icons.auto_awesome_rounded,
                          isActive: controller.enableStickers,
                          onTap: () {
                            controller.enableStickers =
                                !controller.enableStickers;
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      controller.enableStickers
                                          ? Icons.auto_awesome_rounded
                                          : Icons.edit_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        controller.enableStickers
                                            ? '🎯 Sticker Mode Active: Strokes can be moved & rotated'
                                            : '✏️ Freehand Mode Active: Direct drawing on canvas',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
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

  Widget _buildFloatingDockItem({
    required String tooltip,
    String? svgAsset,
    IconData? iconData,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive
                ? ColorConstants.accent.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isActive
                ? Border.all(
                    color: ColorConstants.accent.withValues(alpha: 0.35),
                    width: 1,
                  )
                : null,
          ),
          child: svgAsset != null
              ? SvgPicture.asset(
                  svgAsset,
                  width: 19,
                  height: 19,
                  colorFilter: ColorFilter.mode(
                    isActive ? ColorConstants.accent : const Color(0xFF475569),
                    BlendMode.srcIn,
                  ),
                )
              : Icon(
                  iconData,
                  size: 19,
                  color: isActive
                      ? ColorConstants.accent
                      : const Color(0xFF475569),
                ),
        ),
      ),
    );
  }

  void _onBrushPanelPanUpdate(DragUpdateDetails details) {
    setState(() {
      final double defaultX = MediaQuery.of(context).size.width - 44.0 - 16.0;
      final double defaultY = 12.0;
      final double currentX = _brushPanelPosition?.dx ?? defaultX;
      final double currentY = _brushPanelPosition?.dy ?? defaultY;

      const double panelW = 44.0;
      const double panelH = 175.0;

      final double newX = (currentX + details.delta.dx).clamp(
        2.0,
        (MediaQuery.of(context).size.width - panelW - 2.0).clamp(2.0, 4000.0),
      );
      final double newY = (currentY + details.delta.dy).clamp(
        0.0,
        (MediaQuery.of(context).size.height - panelH - 120.0).clamp(0.0, 4000.0),
      );

      _brushPanelPosition = Offset(newX, newY);
    });
  }

  Widget _buildHorizontalRulerBar(EditorController controller) {
    return ValueListenableBuilder<RulerConfig>(
      valueListenable: controller.drawingController.rulerConfig,
      builder: (context, rulerConfig, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.grey.shade200, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 0. Drag Grip Handle (Movable 6-dot matrix in capsule)
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: (details) {
                  setState(() {
                    final double screenW = MediaQuery.of(context).size.width;
                    final double barW = _isRulerBarCollapsed ? 110.0 : 325.0;
                    final double barH = 48.0;
                    final double defaultX = (screenW - barW) / 2;
                    final double stackH =
                        MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        50.0 -
                        MediaQuery.of(context).padding.bottom;
                    final double defaultY = stackH - 155.0 - barH;

                    final double currentX = _rulerBarPosition?.dx ?? defaultX;
                    final double currentY = _rulerBarPosition?.dy ?? defaultY;

                    final double newX = (currentX + details.delta.dx).clamp(
                      8.0,
                      screenW - barW - 8.0,
                    );
                    final double newY = (currentY + details.delta.dy).clamp(
                      10.0,
                      stackH - 140.0,
                    );

                    _rulerBarPosition = Offset(newX, newY);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 2,
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildGripDot(size: 3.0),
                            const SizedBox(width: 2.5),
                            _buildGripDot(size: 3.0),
                          ],
                        ),
                        const SizedBox(height: 2.5),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildGripDot(size: 3.0),
                            const SizedBox(width: 2.5),
                            _buildGripDot(size: 3.0),
                          ],
                        ),
                        const SizedBox(height: 2.5),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildGripDot(size: 3.0),
                            const SizedBox(width: 2.5),
                            _buildGripDot(size: 3.0),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (_isRulerBarCollapsed) ...[
                // Collapsed View: active ruler indicator + expand button
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _isRulerBarCollapsed = false;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildRulerActiveMiniIndicator(rulerConfig),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.open_in_full_rounded,
                          size: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Expanded View: full options
                // 1. LOCK Button
                _buildHorizontalRulerItem(
                  label: 'LOCK',
                  icon: rulerConfig.isLocked
                      ? Icons.lock_rounded
                      : Icons.lock_open_rounded,
                  isSelected: rulerConfig.isLocked,
                  onTap: () {
                    controller.drawingController.rulerConfig.value = rulerConfig
                        .copyWith(isLocked: !rulerConfig.isLocked);
                  },
                ),
                // Hairline vertical divider
                Container(
                  height: 22,
                  width: 1,
                  color: Colors.grey.shade200,
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                ),
                // 2. LINE
                _buildHorizontalRulerItem(
                  label: 'LINE',
                  assetPath: AssetConstants.ruler_line,
                  isSelected: rulerConfig.type == RulerType.line,
                  onTap: () {
                    final newType = rulerConfig.type == RulerType.line
                        ? RulerType.none
                        : RulerType.line;
                    controller.drawingController.rulerConfig.value = rulerConfig
                        .copyWith(type: newType);
                    if (newType == RulerType.none) {
                      setState(() {
                        _isRulerMenuExpanded = false;
                      });
                    }
                  },
                ),
                const SizedBox(width: 2),
                // 3. CIRC
                _buildHorizontalRulerItem(
                  label: 'CIRC',
                  assetPath: AssetConstants.ruler_circle,
                  isSelected: rulerConfig.type == RulerType.circle,
                  onTap: () {
                    final newType = rulerConfig.type == RulerType.circle
                        ? RulerType.none
                        : RulerType.circle;
                    controller.drawingController.rulerConfig.value = rulerConfig
                        .copyWith(type: newType);
                    if (newType == RulerType.none) {
                      setState(() {
                        _isRulerMenuExpanded = false;
                      });
                    }
                  },
                ),
                const SizedBox(width: 2),
                // 4. BOX
                _buildHorizontalRulerItem(
                  label: 'BOX',
                  assetPath: AssetConstants.ruller_box,
                  isSelected: rulerConfig.type == RulerType.box,
                  onTap: () {
                    final newType = rulerConfig.type == RulerType.box
                        ? RulerType.none
                        : RulerType.box;
                    controller.drawingController.rulerConfig.value = rulerConfig
                        .copyWith(type: newType);
                    if (newType == RulerType.none) {
                      setState(() {
                        _isRulerMenuExpanded = false;
                      });
                    }
                  },
                ),
                const SizedBox(width: 2),
                // 5. MIRR (2-Way Mirror)
                _buildHorizontalRulerItem(
                  label: 'MIRR',
                  assetPath: AssetConstants.ruler_mirer,
                  isSelected: rulerConfig.type == RulerType.mirror,
                  onTap: () {
                    final newType = rulerConfig.type == RulerType.mirror
                        ? RulerType.none
                        : RulerType.mirror;
                    final double defaultAngle =
                        (rulerConfig.type == RulerType.none ||
                                rulerConfig.angle == 0.0) &&
                            newType == RulerType.mirror
                        ? (pi / 2)
                        : rulerConfig.angle;
                    controller.drawingController.rulerConfig.value = rulerConfig
                        .copyWith(
                          type: newType,
                          angle: defaultAngle,
                          scale: rulerConfig.scale <= 0
                              ? 140.0
                              : rulerConfig.scale,
                        );
                    if (newType == RulerType.none) {
                      setState(() {
                        _isRulerMenuExpanded = false;
                      });
                    }
                  },
                ),
                const SizedBox(width: 2),
                // 6. 4-MIRR (4-Way Quadrant Symmetry)
                _buildHorizontalRulerItem(
                  label: '4-MIRR',
                  icon: Icons.grid_view_rounded,
                  isSelected: rulerConfig.type == RulerType.quadMirror,
                  onTap: () {
                    final newType = rulerConfig.type == RulerType.quadMirror
                        ? RulerType.none
                        : RulerType.quadMirror;
                    controller.drawingController.rulerConfig.value = rulerConfig
                        .copyWith(
                          type: newType,
                          scale: rulerConfig.scale <= 0
                              ? 140.0
                              : rulerConfig.scale,
                        );
                    if (newType == RulerType.none) {
                      setState(() {
                        _isRulerMenuExpanded = false;
                      });
                    }
                  },
                ),
                // Collapse Button
                Container(
                  height: 22,
                  width: 1,
                  color: Colors.grey.shade200,
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _isRulerBarCollapsed = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close_fullscreen_rounded,
                      size: 13,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildRulerActiveMiniIndicator(RulerConfig config) {
    String label = 'RULER';
    String? asset;
    IconData? icon;
    switch (config.type) {
      case RulerType.line:
        label = 'LINE';
        asset = AssetConstants.ruler_line;
        break;
      case RulerType.circle:
        label = 'CIRC';
        asset = AssetConstants.ruler_circle;
        break;
      case RulerType.box:
        label = 'BOX';
        asset = AssetConstants.ruller_box;
        break;
      case RulerType.mirror:
        label = 'MIRR';
        asset = AssetConstants.ruler_mirer;
        break;
      case RulerType.quadMirror:
        label = '4-MIRR';
        icon = Icons.grid_view_rounded;
        break;
      case RulerType.none:
        label = 'NONE';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ColorConstants.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (asset != null) ...[
            SvgPicture.asset(
              asset,
              width: 14,
              height: 14,
              colorFilter: const ColorFilter.mode(
                ColorConstants.accent,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 4),
          ] else if (icon != null) ...[
            Icon(icon, size: 14, color: ColorConstants.accent),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: ColorConstants.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalRulerItem({
    required String label,
    String? assetPath,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 38,
        padding: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorConstants.accent.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 22,
              alignment: Alignment.center,
              child: assetPath != null
                  ? SvgPicture.asset(
                      assetPath,
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        isSelected
                            ? ColorConstants.accent
                            : Colors.grey.shade700,
                        BlendMode.srcIn,
                      ),
                    )
                  : Icon(
                      icon,
                      size: 18,
                      color: isSelected
                          ? ColorConstants.accent
                          : Colors.grey.shade700,
                    ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.0,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? ColorConstants.accent
                    : Colors.grey.shade600,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGripDot({double size = 3.2, Color? color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? const Color(0xFF9CA3AF),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _GridPainterPreview extends CustomPainter {
  final double opacity;
  final double verticalSpacing;
  final double horizontalSpacing;
  const _GridPainterPreview({
    required this.opacity,
    required this.verticalSpacing,
    required this.horizontalSpacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ColorConstants.accent.withOpacity(opacity)
      ..strokeWidth = 1.0;
    for (double x = 0; x <= size.width; x += verticalSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += horizontalSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainterPreview oldDelegate) => true;
}

class CustomSliderTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 4.0;
    const double padding = 8.0;
    final double trackLeft = offset.dx + padding;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width - (padding * 2);
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}

class ContinuousPressButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPress;
  final VoidCallback onStep;
  final bool isCapsuleSide;

  const ContinuousPressButton({
    super.key,
    required this.icon,
    required this.onPress,
    required this.onStep,
    this.isCapsuleSide = false,
  });

  @override
  State<ContinuousPressButton> createState() => _ContinuousPressButtonState();
}

class _ContinuousPressButtonState extends State<ContinuousPressButton> {
  Timer? _timer;
  Timer? _delayTimer;

  void _startTimer() {
    _timer?.cancel();
    _delayTimer?.cancel();

    // Perform initial tap action
    widget.onPress();

    // Wait for a brief delay before starting continuous updates
    _delayTimer = Timer(const Duration(milliseconds: 300), () {
      _timer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
        widget.onStep();
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _delayTimer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _delayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _startTimer(),
      onTapUp: (_) => _stopTimer(),
      onTapCancel: () => _stopTimer(),
      child: Container(
        width: 44,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.isCapsuleSide
              ? Colors.transparent
              : Colors.grey.shade100,
          borderRadius: widget.isCapsuleSide
              ? BorderRadius.horizontal(
                  left: widget.icon == Icons.remove
                      ? const Radius.circular(20)
                      : Radius.zero,
                  right: widget.icon == Icons.add
                      ? const Radius.circular(20)
                      : Radius.zero,
                )
              : BorderRadius.circular(19),
          border: widget.isCapsuleSide
              ? null
              : Border.all(color: Colors.grey.shade200),
        ),
        child: Icon(widget.icon, size: 18, color: Colors.grey.shade700),
      ),
    );
  }
}

class StrokePreviewPainter extends CustomPainter {
  final double strokeWidth;
  final Color color;

  StrokePreviewPainter(this.strokeWidth, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final double clampedWidth = strokeWidth.clamp(1.0, 50.0);
    final paint = Paint()
      ..color = color
      ..strokeWidth = clampedWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Dynamically calculate wave amplitude to ensure thick strokes never clip or overlap
    final double maxAllowedAmp =
        (size.height / 2 - (clampedWidth / 2) - 4).clamp(0.0, 13.0);
    final double midY = size.height / 2;
    final double startX = 22.0;
    final double endX = size.width - 22.0;

    final path = Path();
    path.moveTo(startX, midY);
    if (maxAllowedAmp > 2.0) {
      path.cubicTo(
        startX + (endX - startX) * 0.32,
        midY - maxAllowedAmp,
        startX + (endX - startX) * 0.68,
        midY + maxAllowedAmp,
        endX,
        midY,
      );
    } else {
      path.lineTo(endX, midY);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant StrokePreviewPainter oldDelegate) {
    return oldDelegate.strokeWidth != strokeWidth || oldDelegate.color != color;
  }
}

class _CheckerboardPainter extends CustomPainter {
  const _CheckerboardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paintLight = Paint()..color = const Color(0xFFFAFAFA);
    final paintDark = Paint()..color = const Color(0xFFF1F5F9);
    const double sizeSquare = 8.0;

    for (double y = 0; y < size.height; y += sizeSquare) {
      for (double x = 0; x < size.width; x += sizeSquare) {
        final isDark =
            ((x / sizeSquare).floor() + (y / sizeSquare).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, sizeSquare, sizeSquare),
          isDark ? paintDark : paintLight,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double radius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 3.0,
    this.dashLength = 4.0,
    this.radius = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ),
    );

    final dashPath = Path();
    double distance = 0.0;
    for (final ui.PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashLength),
          Offset.zero,
        );
        distance += dashLength + gap;
      }
      distance = 0.0;
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.radius != radius;
  }
}

class BlurPreviewPainter extends CustomPainter {
  final double blurStrength;
  final double strokeWidth;

  const BlurPreviewPainter(this.blurStrength, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(15));
    canvas.clipRRect(rrect);

    // Draw rich gradient background
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, size.height),
        const [
          Color(0xFF4F46E5),
          Color(0xFF7C3AED),
          Color(0xFFDB2777),
          Color(0xFFF59E0B),
        ],
        [0.0, 0.35, 0.7, 1.0],
      );
    canvas.drawRect(rect, bgPaint);

    void drawSampleShapes() {
      canvas.drawCircle(
        Offset(size.width * 0.18, size.height * 0.5),
        15,
        Paint()..color = Colors.white.withValues(alpha: 0.95),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width * 0.48, size.height * 0.5),
            width: 28,
            height: 28,
          ),
          const Radius.circular(7),
        ),
        Paint()..color = const Color(0xFF10B981),
      );
      canvas.drawCircle(
        Offset(size.width * 0.78, size.height * 0.5),
        13,
        Paint()..color = const Color(0xFF38BDF8),
      );

      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'BLUR PREVIEW',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            shadows: [
              Shadow(
                color: Colors.black45,
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.width - textPainter.width) / 2,
          (size.height - textPainter.height) / 2,
        ),
      );
    }

    // 1. Draw base sample shapes
    drawSampleShapes();

    // 2. Draw blurred overlay on right side if blurStrength > 0
    final double sigma = (blurStrength * 12.0);
    if (sigma > 0.01) {
      final double splitX = size.width * 0.38;
      final blurRect = Rect.fromLTWH(splitX, 0, size.width - splitX, size.height);
      canvas.saveLayer(
        blurRect,
        Paint()
          ..imageFilter = ui.ImageFilter.blur(
            sigmaX: sigma,
            sigmaY: sigma,
            tileMode: TileMode.clamp,
          ),
      );
      canvas.drawRect(rect, bgPaint);
      drawSampleShapes();
      canvas.restore();

      // Divider line between Sharp and Blurred
      final linePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(splitX, 0),
        Offset(splitX, size.height),
        linePaint,
      );

      // Labels
      final labelSharp = TextPainter(
        text: TextSpan(
          text: 'Sharp',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      labelSharp.layout();
      labelSharp.paint(canvas, const Offset(6, 4));

      final labelBlur = TextPainter(
        text: TextSpan(
          text: 'Blur ${(blurStrength * 100).round()}%',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.95),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      labelBlur.layout();
      labelBlur.paint(canvas, Offset(size.width - labelBlur.width - 6, 4));
    }
  }

  @override
  bool shouldRepaint(covariant BlurPreviewPainter oldDelegate) {
    return oldDelegate.blurStrength != blurStrength ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class SmudgePreviewPainter extends CustomPainter {
  final double smudgeStrength;
  final double strokeWidth;

  const SmudgePreviewPainter(this.smudgeStrength, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(15));
    canvas.clipRRect(rrect);

    // Draw rich gradient background
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, size.height),
        const [
          Color(0xFF0F172A),
          Color(0xFF1E293B),
          Color(0xFF334155),
        ],
      );
    canvas.drawRect(rect, bgPaint);

    final double centerY = size.height * 0.5;

    // Base paint swatches on the left
    canvas.drawCircle(
      Offset(size.width * 0.18, centerY),
      14,
      Paint()..color = const Color(0xFFFF5252),
    );
    canvas.drawCircle(
      Offset(size.width * 0.28, centerY - 6),
      11,
      Paint()..color = const Color(0xFFFFD740),
    );
    canvas.drawCircle(
      Offset(size.width * 0.28, centerY + 8),
      10,
      Paint()..color = const Color(0xFF448AFF),
    );

    // Smudge dragged streaks extending to the right based on smudgeStrength
    final double dragLength = 15.0 + smudgeStrength * (size.width * 0.55);
    final double trailWidth = max(6.0, strokeWidth * 0.45);

    // Smudge trails with physical drag
    final pathRed = Path()
      ..moveTo(size.width * 0.18, centerY - 12)
      ..cubicTo(
        size.width * 0.18 + dragLength * 0.4,
        centerY - 10,
        size.width * 0.18 + dragLength * 0.7,
        centerY - 4,
        size.width * 0.18 + dragLength,
        centerY - 2,
      )
      ..lineTo(size.width * 0.18 + dragLength * 0.85, centerY + 3)
      ..cubicTo(
        size.width * 0.18 + dragLength * 0.5,
        centerY + 5,
        size.width * 0.18 + dragLength * 0.2,
        centerY + 8,
        size.width * 0.18,
        centerY + 12,
      )
      ..close();

    final redGradient = ui.Gradient.linear(
      Offset(size.width * 0.18, centerY),
      Offset(size.width * 0.18 + dragLength, centerY),
      [
        const Color(0xFFFF5252).withValues(alpha: 0.95),
        const Color(0xFFFF5252).withValues(alpha: (0.35 + 0.60 * smudgeStrength).clamp(0.0, 1.0)),
        const Color(0xFFFF5252).withValues(alpha: (0.05 + 0.90 * smudgeStrength).clamp(0.0, 1.0)),
      ],
      [0.0, 0.6, 1.0],
    );
    canvas.drawPath(pathRed, Paint()..shader = redGradient);

    // Blended yellow streak
    final pathYellow = Path()
      ..moveTo(size.width * 0.28, centerY - 6)
      ..cubicTo(
        size.width * 0.28 + dragLength * 0.35,
        centerY - 4,
        size.width * 0.28 + dragLength * 0.7,
        centerY,
        size.width * 0.28 + dragLength * 0.9,
        centerY + 1,
      );
    canvas.drawPath(
      pathYellow,
      Paint()
        ..color = const Color(0xFFFFD740).withValues(alpha: (0.4 + 0.6 * smudgeStrength).clamp(0.0, 1.0))
        ..strokeWidth = trailWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, (1.0 - smudgeStrength * 0.5) * 2.0),
    );

    // Blended blue streak
    final pathBlue = Path()
      ..moveTo(size.width * 0.28, centerY + 8)
      ..cubicTo(
        size.width * 0.28 + dragLength * 0.35,
        centerY + 7,
        size.width * 0.28 + dragLength * 0.65,
        centerY + 5,
        size.width * 0.28 + dragLength * 0.85,
        centerY + 4,
      );
    canvas.drawPath(
      pathBlue,
      Paint()
        ..color = const Color(0xFF448AFF).withValues(alpha: (0.4 + 0.6 * smudgeStrength).clamp(0.0, 1.0))
        ..strokeWidth = trailWidth * 0.85
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, (1.0 - smudgeStrength * 0.5) * 2.0),
    );

    // Subtle center blend zone
    canvas.drawCircle(
      Offset(size.width * 0.28 + dragLength * 0.45, centerY + 2),
      trailWidth * 0.9,
      Paint()
        ..color = const Color(0xFFFF80AB).withValues(alpha: (0.3 + 0.4 * smudgeStrength).clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
    );

    // Overlay text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'SMUDGE ${(smudgeStrength * 100).round()}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          shadows: [
            Shadow(
              color: Colors.black54,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size.width - textPainter.width - 10,
        size.height - textPainter.height - 6,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant SmudgePreviewPainter oldDelegate) {
    return oldDelegate.smudgeStrength != smudgeStrength ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

