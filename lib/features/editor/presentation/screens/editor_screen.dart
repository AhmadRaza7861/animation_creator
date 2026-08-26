import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../package_code/paint_contents.dart';
import '../../../../package_code/src/drawing_controller.dart';
import '../../../../package_code/src/ruler/ruler_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/editor_providers.dart';
import '../controllers/editor_controller.dart';
import '../widgets/canvas_area.dart';
import '../widgets/timeline_panel.dart';
import '../widgets/toolbar_panel.dart';
import '../widgets/layer_panel.dart';
import '../widgets/sticker_widgets/text_sticker_widget.dart';
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
              }
            });
            controller.drawingController.setStyle(
              color: newColor.withValues(alpha: newOpacity),
            );
          },
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context, EditorController controller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final currentController = ref.watch(editorControllerProvider(widget.projectId));
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
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
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.wallpaper_rounded, color: Colors.orangeAccent),
                      title: const Text('Project settings', style: TextStyle(fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right),
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
                    ListTile(
                      leading: const Icon(Icons.layers_rounded, color: ColorConstants.darkText),
                      title: const Text('Onion', style: TextStyle(fontWeight: FontWeight.w600)),
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
                    ListTile(
                      leading: const Icon(Icons.grid_on_rounded, color: ColorConstants.darkText),
                      title: const Text('Grid', style: TextStyle(fontWeight: FontWeight.w600)),
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
                    ListTile(
                      leading: const Icon(Icons.palette_rounded, color: ColorConstants.darkText),
                      title: const Text('Add as Sticker', style: TextStyle(fontWeight: FontWeight.w600)),
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

  Widget _buildVerticalRulerMenu(EditorController controller) {
    return ValueListenableBuilder<RulerConfig>(
      valueListenable: controller.drawingController.rulerConfig,
      builder: (context, config, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _verticalRulerButton(
                controller,
                config.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                RulerType.none,
                config,
                isLock: true,
              ),
              const SizedBox(height: 12),
              _verticalRulerButton(
                controller,
                Icons.crop_square,
                RulerType.box,
                config,
              ),
              const SizedBox(height: 12),
              _verticalRulerButton(
                controller,
                Icons.circle_outlined,
                RulerType.circle,
                config,
              ),
              const SizedBox(height: 12),
              _verticalRulerButton(
                controller,
                Icons.horizontal_rule,
                RulerType.line,
                config,
              ),
              const SizedBox(height: 12),
              _verticalRulerButton(
                controller,
                Icons.flip_camera_android_rounded,
                RulerType.mirror,
                config,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _verticalRulerButton(
    EditorController controller,
    IconData icon,
    RulerType type,
    RulerConfig config, {
    bool isLock = false,
  }) {
    final isSelected = isLock ? config.isLocked : config.type == type;
    final color = isSelected ? ColorConstants.accent : Colors.grey.shade600;

    return GestureDetector(
      onTap: () {
        if (isLock) {
          controller.drawingController.rulerConfig.value = config.copyWith(
            isLocked: !config.isLocked,
          );
        } else {
          final newType = config.type == type ? RulerType.none : type;
          controller.drawingController.rulerConfig.value = config.copyWith(type: newType);
        }
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? ColorConstants.accent.withOpacity(0.1) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
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
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: SafeArea(
          child: Container(
            height: kToolbarHeight,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE5E5EA), width: 0.5)),
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
                    final showColor = config.contentType != Eraser &&
                        config.contentType != Lasso &&
                        config.contentType != BlurContent &&
                        config.contentType != SmudgeContent;
                    if (!showColor) return const SizedBox.shrink();

                    final activeColor = config.color;
                    return GestureDetector(
                      onTap: () => _openColorPicker(activeColor, controller),
                      child: Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: activeColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ValueListenableBuilder<DrawConfig>(
                    valueListenable: controller.drawingController.drawConfig,
                    builder: (context, config, child) {
                      return Row(
                        children: [
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 4,
                                trackShape: CustomSliderTrackShape(),
                                activeTrackColor: ColorConstants.accent,
                                inactiveTrackColor: const Color(0xFFFFF2E5),
                                thumbColor: ColorConstants.accent,
                                overlayColor: ColorConstants.accent.withValues(alpha: 0.2),
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                              ),
                              child: Slider(
                                value: controller.globalStrokeWidth.clamp(1.0, 50.0),
                                min: 1.0,
                                max: 50.0,
                                divisions: 49,
                                label: controller.globalStrokeWidth.round().toString(),
                                  onChanged: (double val) {
                                    controller.globalStrokeWidth = val;
                                    controller.drawingController.setStyle(strokeWidth: val);
                                  },
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 22,
                            child: Text(
                              '${controller.globalStrokeWidth.round()}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: ColorConstants.darkText,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                      );
                    }
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.undo_rounded, color: ColorConstants.darkText),
                  onPressed: () => controller.drawingController.undo(),
                ),
                IconButton(
                  icon: const Icon(Icons.redo_rounded, color: ColorConstants.darkText),
                  onPressed: () => controller.drawingController.redo(),
                ),
                IconButton(
                  icon: const Icon(Icons.center_focus_strong_rounded, color: ColorConstants.darkText),
                  onPressed: _resetBoard,
                  tooltip: 'Reset Zoom / Position',
                ),
                IconButton(
                  icon: const Icon(Icons.settings_rounded, color: ColorConstants.darkText),
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
                    child: CanvasArea(
                      projectId: widget.projectId,
                      transformationController: _transformationController,
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
              if (controller.showRulerMenu)
                Positioned(
                  right: 16,
                  top: 120,
                  child: _buildVerticalRulerMenu(controller),
                ),
              if (controller.showLayerPanel)
                Positioned(
                  left: controller.layersPanelPosition?.dx ?? (MediaQuery.of(context).size.width - 250 - 16),
                  top: controller.layersPanelPosition?.dy ?? (MediaQuery.of(context).size.height - 480),
                  child: LayerPanel(
                    controller: controller.drawingController,
                    onClose: () {
                      controller.showLayerPanel = false;
                    },
                    onHeaderDrag: (details) {
                      final double currentX = controller.layersPanelPosition?.dx ?? (MediaQuery.of(context).size.width - 250 - 16);
                      final double currentY = controller.layersPanelPosition?.dy ?? (MediaQuery.of(context).size.height - 480);
                      
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
