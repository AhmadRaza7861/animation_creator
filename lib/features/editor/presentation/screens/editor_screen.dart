import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dummy/core/constants/app_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../package_code/paint_contents.dart';
import '../../../../package_code/src/drawing_controller.dart';
import '../../../../package_code/src/ruler/ruler_config.dart';
import 'canvas_size_screen.dart';
import 'fps_screen.dart';
import 'background_presets_screen.dart';
import 'frames_reorder_screen.dart';
import 'video_trimming_screen.dart';
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
import '../../../../core/widgets/color_picker_screen.dart';
import '../../../../core/widgets/custom_switch.dart';
import '../../../projects/presentation/screens/create_project_screen.dart';

class EditorScreen extends ConsumerStatefulWidget {
  final String? projectId;

  const EditorScreen({
    super.key,
    required this.projectId,
  });

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> with WidgetsBindingObserver {
  final TransformationController _transformationController = TransformationController();
  bool _isRulerMenuExpanded = false;
  bool _isRulerBarCollapsed = false;
  bool _isBrushPanelCollapsed = false;
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
    _transformationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      ref.read(editorControllerProvider(widget.projectId)).saveProject();
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
                final textSticker = controller.activeSticker as ActiveTextSticker;
                textSticker.color = newColor.withValues(alpha: newOpacity);
                textSticker.opacity = newOpacity;
              } else if (controller.activeSticker is ActiveShapeSticker) {
                final shapeSticker = controller.activeSticker as ActiveShapeSticker;
                shapeSticker.content.paint.color = newColor.withValues(alpha: newOpacity);
              } else if (controller.activeSticker is ActiveStraightLineSticker) {
                final lineSticker = controller.activeSticker as ActiveStraightLineSticker;
                lineSticker.paint.color = newColor.withValues(alpha: newOpacity);
              } else if (controller.activeSticker is ActiveFreehandLineSticker) {
                final freehandSticker = controller.activeSticker as ActiveFreehandLineSticker;
                freehandSticker.content.paint.color = newColor.withValues(alpha: newOpacity);
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
            final currentController = ref.watch(editorControllerProvider(widget.projectId));

            // Helper to get Canvas Size Label
            String canvasSizeLabel = 'Landscape (16:9)';
            final double ratio = currentController.aspectRatio ?? (16.0 / 9.0);
            if ((ratio - 1.0).abs() < 0.05) {
              canvasSizeLabel = 'Square (1:1)';
            } else if ((ratio - 9.0 / 16.0).abs() < 0.05) {
              canvasSizeLabel = 'Portrait (9:16)';
            } else if ((ratio - 4.0 / 3.0).abs() < 0.05) {
              canvasSizeLabel = 'Standard (4:3)';
            } else if ((ratio - 16.0 / 9.0).abs() < 0.05) {
              canvasSizeLabel = 'Landscape (16:9)';
            } else {
              canvasSizeLabel = 'Custom (${ratio.toStringAsFixed(2)})';
            }

            // Helper to get background label
            String bgLabel = 'Plain Canvas';
            if (currentController.globalBackground.pattern != null) {
              bgLabel = currentController.globalBackground.pattern!.toUpperCase();
            } else if (currentController.globalBackground.imagePath != null) {
              bgLabel = 'Custom Image';
            }

            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Settings',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: ColorConstants.darkText),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          )
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
                          child: const Icon(Icons.settings_suggest_rounded, color: Colors.orangeAccent, size: 22),
                        ),
                        title: const Text('Project settings', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Title, dimensions & export options', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.black45),
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
                          child: const Icon(Icons.layers_rounded, color: Colors.amber, size: 22),
                        ),
                        title: const Text('Onion', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Ghost previous/next frames', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _showOnionSettingsSheet(context, currentController);
                              },
                              child: const Text(
                                'Edit',
                                style: TextStyle(color: ColorConstants.accent, fontWeight: FontWeight.bold),
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
                          child: const Icon(Icons.grid_on_rounded, color: Colors.cyan, size: 22),
                        ),
                        title: const Text('Grid', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Alignment and spacing guide', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _showGridSettingsSheet(context, currentController);
                              },
                              child: const Text(
                                'Edit',
                                style: TextStyle(color: ColorConstants.accent, fontWeight: FontWeight.bold),
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
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.pinkAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.palette_rounded, color: Colors.pinkAccent, size: 22),
                        ),
                        title: const Text('Add as Sticker', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Treat strokes as selectable objects', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        trailing: CustomSwitch(
                          value: currentController.enableStickers,
                          onChanged: (bool value) {
                            currentController.enableStickers = value;
                          },
                        ),
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

  void _showOnionSettingsSheet(BuildContext context, EditorController controller) {
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
              final double opacity = (0.4 * (1.0 - (i - 1) / ctrl.onionBefore)).clamp(0.05, 0.4);

              previewCircles.add(
                Transform.translate(
                  offset: Offset(dx, dy),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ctrl.isOnionEnabled
                          ? (ctrl.onionColorMode ? Colors.red.withOpacity(opacity) : Colors.black.withOpacity(opacity * 0.5))
                          : Colors.black.withOpacity(0.05),
                      border: Border.all(
                        color: ctrl.isOnionEnabled
                            ? (ctrl.onionColorMode ? Colors.red.withOpacity(opacity * 1.5) : Colors.black.withOpacity(opacity))
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
              final double opacity = (0.4 * (1.0 - (j - 1) / ctrl.onionAfter)).clamp(0.05, 0.4);

              previewCircles.add(
                Transform.translate(
                  offset: Offset(dx, dy),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ctrl.isOnionEnabled
                          ? (ctrl.onionColorMode ? Colors.green.withOpacity(opacity) : Colors.black.withOpacity(opacity * 0.5))
                          : Colors.black.withOpacity(0.05),
                      border: Border.all(
                        color: ctrl.isOnionEnabled
                            ? (ctrl.onionColorMode ? Colors.green.withOpacity(opacity * 1.5) : Colors.black.withOpacity(opacity))
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
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
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
                        icon: const Icon(Icons.close, color: ColorConstants.darkText),
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
                    title: const Text('Color', style: TextStyle(fontWeight: FontWeight.w600, color: ColorConstants.darkText)),
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
                    title: const Text('Loop', style: TextStyle(fontWeight: FontWeight.w600, color: ColorConstants.darkText)),
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
                            const Text('Frames before', style: TextStyle(fontWeight: FontWeight.w600, color: ColorConstants.darkText)),
                            Row(
                              children: [
                                Text('${ctrl.onionBefore}', style: const TextStyle(fontWeight: FontWeight.bold, color: ColorConstants.accent)),
                                const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
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
                            const Text('Frames after', style: TextStyle(fontWeight: FontWeight.w600, color: ColorConstants.darkText)),
                            Row(
                              children: [
                                Text('${ctrl.onionAfter}', style: const TextStyle(fontWeight: FontWeight.bold, color: ColorConstants.accent)),
                                const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
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

  void _showGridSettingsSheet(BuildContext context, EditorController controller) {
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
                        icon: const Icon(Icons.close, color: ColorConstants.darkText),
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
                                opacity: ctrl.isGridEnabled ? ctrl.gridOpacity : 0.05,
                                verticalSpacing: ctrl.gridVerticalSpacing / 2,
                                horizontalSpacing: ctrl.gridHorizontalSpacing / 2,
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
                            const Text('Line opacity', style: TextStyle(fontWeight: FontWeight.w600, color: ColorConstants.darkText)),
                            Text('${(ctrl.gridOpacity * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: ColorConstants.accent)),
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
                            const Text('Vertical line spacing', style: TextStyle(fontWeight: FontWeight.w600, color: ColorConstants.darkText)),
                            Text('${ctrl.gridVerticalSpacing.round()}px', style: const TextStyle(fontWeight: FontWeight.bold, color: ColorConstants.accent)),
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
                            const Text('Horizontal line spacing', style: TextStyle(fontWeight: FontWeight.w600, color: ColorConstants.darkText)),
                            Text('${ctrl.gridHorizontalSpacing.round()}px', style: const TextStyle(fontWeight: FontWeight.bold, color: ColorConstants.accent)),
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


  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(editorControllerProvider(widget.projectId));

    if (controller.isLoadingProject) {
      return const Scaffold(
        backgroundColor: ColorConstants.background,
        body: Center(
          child: CircularProgressIndicator(color: ColorConstants.accent),
        ),
      );
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: SafeArea(
          child: Container(
            height: kToolbarHeight,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration:  BoxDecoration(
              color: ColorConstants.border_color,
           //   border: Border(bottom: BorderSide(color: Color(0xFFE5E5EA), width: 0.5)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: ColorConstants.darkText),
                  onPressed: () async {
                    await controller.saveProject();
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),
                ValueListenableBuilder<DrawConfig>(
                  valueListenable: controller.drawingController.drawConfig,
                  builder: (context, config, child) {
                    final bool isTextActive = controller.activeSticker is ActiveTextSticker ||
                        controller.isTextToolSelected ||
                        controller.activeCategory == 'Text';

                    final bool hasActiveSticker = controller.activeSticker != null;

                    final showColor = isTextActive ||
                        hasActiveSticker ||
                        (config.contentType != Eraser &&
                        config.contentType != Lasso &&
                        config.contentType != BlurContent &&
                        config.contentType != SmudgeContent);

                    if (!showColor) return const SizedBox.shrink();

                    Color activeColor = config.color;
                    if (controller.activeSticker is ActiveTextSticker) {
                      activeColor = (controller.activeSticker as ActiveTextSticker).color;
                    } else if (controller.activeSticker is ActiveShapeSticker) {
                      activeColor = (controller.activeSticker as ActiveShapeSticker).content.paint.color;
                    } else if (controller.activeSticker is ActiveStraightLineSticker) {
                      activeColor = (controller.activeSticker as ActiveStraightLineSticker).paint.color;
                    } else if (controller.activeSticker is ActiveFreehandLineSticker) {
                      activeColor = (controller.activeSticker as ActiveFreehandLineSticker).content.paint.color;
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
                                border: Border.all(color: Colors.white, width: 1.5),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 1.5,
                                    offset: Offset(0, 0.5),
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
                const SizedBox(width: 8),
                ValueListenableBuilder<DrawConfig>(
                  valueListenable: controller.drawingController.drawConfig,
                  builder: (context, config, child) {
                    final showSize = config.contentType != Lasso &&
                        config.contentType != BlurContent &&
                        config.contentType != SmudgeContent;
                    if (!showSize) return const SizedBox.shrink();

                    return MenuAnchor(
                      style: MenuStyle(
                        padding: WidgetStateProperty.all(const EdgeInsets.all(16)),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        backgroundColor: WidgetStateProperty.all(Colors.white),
                        elevation: WidgetStateProperty.all(8),
                      ),
                      builder: (BuildContext context, MenuController menuController, Widget? child) {
                        return GestureDetector(
                          onTap: () {
                            if (menuController.isOpen) {
                              menuController.close();
                            } else {
                              menuController.open();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            //  border: Border.all(color: Colors.black.withOpacity(0.05)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Container(
                                //   width: 14,
                                //   height: 14,
                                //   alignment: Alignment.center,
                                //   decoration: const BoxDecoration(
                                //     shape: BoxShape.circle,
                                //     color: Colors.white,
                                //   ),
                                //   child: Container(
                                //     width: (controller.globalStrokeWidth * 0.4).clamp(2.0, 12.0),
                                //     height: (controller.globalStrokeWidth * 0.4).clamp(2.0, 12.0),
                                //     decoration: BoxDecoration(
                                //       shape: BoxShape.circle,
                                //       color: config.color,
                                //     ),
                                //   ),
                                // ),
                                SvgPicture.asset(AssetConstants.stock_icon),
                                const SizedBox(width: 6),
                                Text(
                                  '${controller.globalStrokeWidth.round()}px',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black,
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
                            final double currentWidth = controller.globalStrokeWidth;
                            final double currentOpacity = controller.colorOpacity;
                            final sizePresets = [2.0, 5.0, 10.0, 18.0, 30.0, 50.0];
                            final opacityPresets = [0.2, 0.45, 0.7, 1.0];

                            final baseColor = config.color.withOpacity(1.0);
                            final previewColor = baseColor.withOpacity(currentOpacity);

                            return Container(
                              width: 250,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    height: 58,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
                                            child: CustomPaint(
                                              painter: const _CheckerboardPainter(),
                                            ),
                                          ),
                                          Positioned.fill(
                                            child: CustomPaint(
                                              painter: StrokePreviewPainter(
                                                currentWidth,
                                                previewColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Brush Size',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                      Text(
                                        '${currentWidth.round()} px',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: ColorConstants.accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: sizePresets.map((p) {
                                      final isSelected = currentWidth.round() == p.round();
                                      return GestureDetector(
                                        onTap: () {
                                          setPopupState(() {
                                            controller.globalStrokeWidth = p;
                                          });
                                          controller.drawingController.setStyle(strokeWidth: p);
                                          setState(() {});
                                        },
                                        child: Container(
                                          width: 34,
                                          height: 34,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isSelected ? ColorConstants.accent : Colors.grey.shade50,
                                            border: Border.all(
                                              color: isSelected ? Colors.transparent : Colors.grey.shade200,
                                            ),
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                      color: ColorConstants.accent.withValues(alpha: 0.3),
                                                      blurRadius: 6,
                                                      offset: const Offset(0, 2),
                                                    )
                                                  ]
                                                : null,
                                          ),
                                          child: Text(
                                            '${p.round()}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? Colors.white : Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 14),
                                  Center(
                                    child: Container(
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ContinuousPressButton(
                                            icon: Icons.remove,
                                            isCapsuleSide: true,
                                            onPress: () {
                                              final val = (currentWidth - 1.0).clamp(1.0, 50.0);
                                              setPopupState(() {
                                                controller.globalStrokeWidth = val;
                                              });
                                              controller.drawingController.setStyle(strokeWidth: val);
                                              setState(() {});
                                            },
                                            onStep: () {
                                              final val = (controller.globalStrokeWidth - 1.0).clamp(1.0, 50.0);
                                              setPopupState(() {
                                                controller.globalStrokeWidth = val;
                                              });
                                              controller.drawingController.setStyle(strokeWidth: val);
                                              setState(() {});
                                            },
                                          ),
                                          Container(width: 1, height: 18, color: Colors.grey.shade200),
                                          Container(
                                            width: 60,
                                            alignment: Alignment.center,
                                            child: Text(
                                              '${currentWidth.round()}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: ColorConstants.darkText,
                                              ),
                                            ),
                                          ),
                                          Container(width: 1, height: 18, color: Colors.grey.shade200),
                                          ContinuousPressButton(
                                            icon: Icons.add,
                                            isCapsuleSide: true,
                                            onPress: () {
                                              final val = (currentWidth + 1.0).clamp(1.0, 50.0);
                                              setPopupState(() {
                                                controller.globalStrokeWidth = val;
                                              });
                                              controller.drawingController.setStyle(strokeWidth: val);
                                              setState(() {});
                                            },
                                            onStep: () {
                                              final val = (controller.globalStrokeWidth + 1.0).clamp(1.0, 50.0);
                                              setPopupState(() {
                                                controller.globalStrokeWidth = val;
                                              });
                                              controller.drawingController.setStyle(strokeWidth: val);
                                              setState(() {});
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 1,
                                    margin: const EdgeInsets.symmetric(vertical: 18),
                                    color: Colors.grey.shade200,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Opacity',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                      Text(
                                        '${(currentOpacity * 100).round()}%',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: ColorConstants.accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: opacityPresets.map((o) {
                                      final isSelected = (currentOpacity - o).abs() < 0.04;
                                      return GestureDetector(
                                        onTap: () {
                                          setPopupState(() {
                                            controller.colorOpacity = o;
                                          });
                                          controller.drawingController.setStyle(color: baseColor.withOpacity(o));
                                          setState(() {});
                                        },
                                        child: Container(
                                          width: 48,
                                          height: 32,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(16),
                                            color: isSelected ? ColorConstants.accent : Colors.grey.shade50,
                                            border: Border.all(
                                              color: isSelected ? Colors.transparent : Colors.grey.shade200,
                                            ),
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                      color: ColorConstants.accent.withValues(alpha: 0.3),
                                                      blurRadius: 6,
                                                      offset: const Offset(0, 2),
                                                    )
                                                  ]
                                                : null,
                                          ),
                                          child: Text(
                                            '${(o * 100).round()}%',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? Colors.white : Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 14),
                                  Center(
                                    child: Container(
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ContinuousPressButton(
                                            icon: Icons.remove,
                                            isCapsuleSide: true,
                                            onPress: () {
                                              final val = (currentOpacity - 0.05).clamp(0.05, 1.0);
                                              setPopupState(() {
                                                controller.colorOpacity = val;
                                              });
                                              controller.drawingController.setStyle(color: baseColor.withOpacity(val));
                                              setState(() {});
                                            },
                                            onStep: () {
                                              final val = (controller.colorOpacity - 0.05).clamp(0.05, 1.0);
                                              setPopupState(() {
                                                controller.colorOpacity = val;
                                              });
                                              controller.drawingController.setStyle(color: baseColor.withOpacity(val));
                                              setState(() {});
                                            },
                                          ),
                                          Container(width: 1, height: 18, color: Colors.grey.shade200),
                                          Container(
                                            width: 70,
                                            alignment: Alignment.center,
                                            child: Text(
                                              '${(currentOpacity * 100).round()}%',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: ColorConstants.darkText,
                                              ),
                                            ),
                                          ),
                                          Container(width: 1, height: 18, color: Colors.grey.shade200),
                                          ContinuousPressButton(
                                            icon: Icons.add,
                                            isCapsuleSide: true,
                                            onPress: () {
                                              final val = (currentOpacity + 0.05).clamp(0.05, 1.0);
                                              setPopupState(() {
                                                controller.colorOpacity = val;
                                              });
                                              controller.drawingController.setStyle(color: baseColor.withOpacity(val));
                                              setState(() {});
                                            },
                                            onStep: () {
                                              final val = (controller.colorOpacity + 0.05).clamp(0.05, 1.0);
                                              setPopupState(() {
                                                controller.colorOpacity = val;
                                              });
                                              controller.drawingController.setStyle(color: baseColor.withOpacity(val));
                                              setState(() {});
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
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
                IconButton(
                  icon: const Icon(Icons.undo_rounded, color: ColorConstants.darkText),
                  onPressed: () => controller.drawingController.undo(),
                ),
                IconButton(
                  icon: const Icon(Icons.redo_rounded, color: ColorConstants.darkText),
                  onPressed: () => controller.drawingController.redo(),
                ),
                IconButton(
                  icon: SvgPicture.asset(AssetConstants.expander_icon),
                  onPressed: _resetBoard,
                  tooltip: 'Reset Zoom / Position',
                ),
                IconButton(
                  icon:  SvgPicture.asset(AssetConstants.setting_icon),
                  onPressed: () => _showSettingsSheet(context, controller),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(systemNavigationBarColor: Colors.white),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: ColorConstants.selected_type
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
                  left: _brushPanelPosition?.dx ??
                      (MediaQuery.of(context).size.width - 58 - 16),
                  top: _brushPanelPosition?.dy ?? 120.0,
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
                          (_isRulerBarCollapsed ? 130.0 : 330.0) -
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
                  left: controller.layersPanelPosition?.dx ??
                      (MediaQuery.of(context).size.width - 250 - 16),
                  top: controller.layersPanelPosition?.dy ??
                      (MediaQuery.of(context).size.height - 480),
                  child: LayerPanel(
                    controller: controller.drawingController,
                    onClose: () {
                      controller.showLayerPanel = false;
                    },
                    onHeaderDrag: (details) {
                      final double currentX = controller.layersPanelPosition?.dx ??
                          (MediaQuery.of(context).size.width - 250 - 16);
                      final double currentY = controller.layersPanelPosition?.dy ??
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightVerticalPanel(EditorController controller) {
    return AnimatedBuilder(
      animation: Listenable.merge([controller, controller.drawingController]),
      builder: (context, child) {
        final bool isBrushTipsActive = controller.activeCategory == 'Brush' &&
            controller.drawingController.activeBrushPresetId != null;
        final bool isSingleBrushActive = controller.activeCategory == 'Brush' &&
            controller.drawingController.activeBrushPresetId == null;

        return ValueListenableBuilder<RulerConfig>(
          valueListenable: controller.drawingController.rulerConfig,
          builder: (context, rulerConfig, child) {
            final bool isRulerActive =
                _isRulerMenuExpanded && rulerConfig.type != RulerType.none;

            return Container(
              width: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Grip Drag Handle
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanUpdate: (details) {
                      setState(() {
                        final double currentX = _brushPanelPosition?.dx ??
                            (MediaQuery.of(context).size.width - 58 - 16);
                        final double currentY =
                            _brushPanelPosition?.dy ?? 120.0;

                        final double newX = (currentX + details.delta.dx).clamp(
                          16.0,
                          MediaQuery.of(context).size.width - 58 - 16,
                        );
                        final double newY = (currentY + details.delta.dy).clamp(
                          MediaQuery.of(context).padding.top + 20.0,
                          MediaQuery.of(context).size.height - 240.0,
                        );

                        _brushPanelPosition = Offset(newX, newY);
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      alignment: Alignment.center,
                      child: Container(
                        width: 18,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),

                  if (_isBrushPanelCollapsed) ...[
                    // Collapsed View: active tool icon + tap to expand
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          _isBrushPanelCollapsed = false;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(top: 2, bottom: 2),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: ColorConstants.accent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              isBrushTipsActive
                                  ? AssetConstants.brush_tips
                                  : (isRulerActive
                                      ? AssetConstants.ruler_icon
                                      : AssetConstants.brush_icon),
                              width: 22,
                              height: 22,
                              colorFilter: const ColorFilter.mode(
                                ColorConstants.accent,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 14,
                              color: ColorConstants.accent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // Expanded View: full tools
                    const SizedBox(height: 2),

                    // 1. Brush Tips Studio Button
                    GestureDetector(
                      onTap: () {
                        BrushStudioScreen.open(
                          context,
                          drawingController: controller.drawingController,
                          editorController: controller,
                        );
                      },
                      child: Container(
                        width: 42,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isBrushTipsActive
                              ? ColorConstants.accent.withOpacity(0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              AssetConstants.brush_tips,
                              width: 22,
                              height: 22,
                              colorFilter: ColorFilter.mode(
                                isBrushTipsActive
                                    ? ColorConstants.accent
                                    : Colors.grey.shade700,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tips',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: isBrushTipsActive
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isBrushTipsActive
                                    ? ColorConstants.accent
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 2. Single Brush Tool Button
                    GestureDetector(
                      onTap: () {
                        controller.activeCategory = 'Brush';
                        controller.drawingController.activeBrushPresetId = null;
                        controller.drawingController
                            .setPaintContent(FreehandLine());
                        controller.drawingController
                            .setStyle(strokeWidth: controller.globalStrokeWidth);
                      },
                      child: Container(
                        width: 42,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSingleBrushActive
                              ? ColorConstants.accent.withOpacity(0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              AssetConstants.brush_icon,
                              width: 22,
                              height: 22,
                              colorFilter: ColorFilter.mode(
                                isSingleBrushActive
                                    ? ColorConstants.accent
                                    : Colors.grey.shade700,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Brush',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: isSingleBrushActive
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSingleBrushActive
                                    ? ColorConstants.accent
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 3. Ruler Button (Toggles Ruler completely on/off)
                    GestureDetector(
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
                      child: Container(
                        width: 42,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isRulerActive
                              ? ColorConstants.accent.withOpacity(0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              AssetConstants.ruler_icon,
                              width: 22,
                              height: 22,
                              colorFilter: ColorFilter.mode(
                                isRulerActive
                                    ? ColorConstants.accent
                                    : Colors.grey.shade700,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ruler',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: isRulerActive ? FontWeight.w800 : FontWeight.w600,
                                color: isRulerActive ? ColorConstants.accent : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Collapse button
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          _isBrushPanelCollapsed = true;
                        });
                      },
                      child: Container(
                        width: 24,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_up_rounded,
                          size: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHorizontalRulerBar(EditorController controller) {
    return ValueListenableBuilder<RulerConfig>(
      valueListenable: controller.drawingController.rulerConfig,
      builder: (context, rulerConfig, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.grey.shade200, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 0. Drag Grip Handle (Movable)
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: (details) {
                  setState(() {
                    final double screenW = MediaQuery.of(context).size.width;
                    final double barW = _isRulerBarCollapsed ? 130.0 : 330.0;
                    final double barH = 48.0;
                    final double defaultX = (screenW - barW) / 2;
                    final double stackH = MediaQuery.of(context).size.height -
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  alignment: Alignment.center,
                  child: Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
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
                  icon: rulerConfig.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                  isSelected: rulerConfig.isLocked,
                  onTap: () {
                    controller.drawingController.rulerConfig.value =
                        rulerConfig.copyWith(isLocked: !rulerConfig.isLocked);
                  },
                ),
                // Hairline vertical divider
                Container(
                  height: 24,
                  width: 1,
                  color: Colors.grey.shade200,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                ),
                // 2. LINE
                _buildHorizontalRulerItem(
                  label: 'LINE',
                  assetPath: AssetConstants.ruler_line,
                  isSelected: rulerConfig.type == RulerType.line,
                  onTap: () {
                    final newType = rulerConfig.type == RulerType.line ? RulerType.none : RulerType.line;
                    controller.drawingController.rulerConfig.value = rulerConfig.copyWith(type: newType);
                    if (newType == RulerType.none) {
                      setState(() {
                        _isRulerMenuExpanded = false;
                      });
                    }
                  },
                ),
                const SizedBox(width: 3),
                // 3. CIRC
                _buildHorizontalRulerItem(
                  label: 'CIRC',
                  assetPath: AssetConstants.ruler_circle,
                  isSelected: rulerConfig.type == RulerType.circle,
                  onTap: () {
                    final newType = rulerConfig.type == RulerType.circle ? RulerType.none : RulerType.circle;
                    controller.drawingController.rulerConfig.value = rulerConfig.copyWith(type: newType);
                    if (newType == RulerType.none) {
                      setState(() {
                        _isRulerMenuExpanded = false;
                      });
                    }
                  },
                ),
                const SizedBox(width: 3),
                // 4. BOX
                _buildHorizontalRulerItem(
                  label: 'BOX',
                  assetPath: AssetConstants.ruller_box,
                  isSelected: rulerConfig.type == RulerType.box,
                  onTap: () {
                    final newType = rulerConfig.type == RulerType.box ? RulerType.none : RulerType.box;
                    controller.drawingController.rulerConfig.value = rulerConfig.copyWith(type: newType);
                    if (newType == RulerType.none) {
                      setState(() {
                        _isRulerMenuExpanded = false;
                      });
                    }
                  },
                ),
                const SizedBox(width: 3),
                // 5. MIRR
                _buildHorizontalRulerItem(
                  label: 'MIRR',
                  assetPath: AssetConstants.ruler_mirer,
                  isSelected: rulerConfig.type == RulerType.mirror,
                  onTap: () {
                    final newType = rulerConfig.type == RulerType.mirror ? RulerType.none : RulerType.mirror;
                    controller.drawingController.rulerConfig.value = rulerConfig.copyWith(type: newType);
                    if (newType == RulerType.none) {
                      setState(() {
                        _isRulerMenuExpanded = false;
                      });
                    }
                  },
                ),
                // Collapse Button
                Container(
                  height: 24,
                  width: 1,
                  color: Colors.grey.shade200,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _isRulerBarCollapsed = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(5),
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
        width: 46,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? ColorConstants.accent.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 24,
              alignment: Alignment.center,
              child: assetPath != null
                  ? SvgPicture.asset(
                      assetPath,
                      width: 22,
                      height: 22,
                      colorFilter: ColorFilter.mode(
                        isSelected ? ColorConstants.accent : Colors.grey.shade700,
                        BlendMode.srcIn,
                      ),
                    )
                  : Icon(
                      icon,
                      size: 20,
                      color: isSelected ? ColorConstants.accent : Colors.grey.shade700,
                    ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? ColorConstants.accent : Colors.grey.shade600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
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
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
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
          color: widget.isCapsuleSide ? Colors.transparent : Colors.grey.shade100,
          borderRadius: widget.isCapsuleSide
              ? BorderRadius.horizontal(
                  left: widget.icon == Icons.remove ? const Radius.circular(20) : Radius.zero,
                  right: widget.icon == Icons.add ? const Radius.circular(20) : Radius.zero,
                )
              : BorderRadius.circular(19),
          border: widget.isCapsuleSide ? null : Border.all(color: Colors.grey.shade200),
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
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth.clamp(1.0, 50.0)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(20, size.height / 2);
    path.cubicTo(
      size.width * 0.25,
      size.height / 2 - 15,
      size.width * 0.75,
      size.height / 2 + 15,
      size.width - 20,
      size.height / 2,
    );
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
    final paintLight = Paint()..color = Colors.white;
    final paintDark = Paint()..color = Colors.grey.shade200;
    const double sizeSquare = 8.0;

    for (double y = 0; y < size.height; y += sizeSquare) {
      for (double x = 0; x < size.width; x += sizeSquare) {
        final isDark = ((x / sizeSquare).floor() + (y / sizeSquare).floor()) % 2 == 0;
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
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    ));

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
