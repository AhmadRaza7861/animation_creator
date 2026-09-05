import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../package_code/paint_contents.dart';
import '../../../../../package_code/src/drawing_board.dart';
import '../../../../../package_code/src/drawing_controller.dart';
import '../../../../../package_code/src/ruler/ruler_config.dart';
import '../controllers/editor_providers.dart';
import '../controllers/editor_controller.dart';
import '../widgets/sticker_widgets/text_sticker_widget.dart';
import '../widgets/sticker_widgets/shape_sticker_widget.dart';
import '../widgets/sticker_widgets/straight_line_sticker_widget.dart';
import '../widgets/sticker_widgets/freehand_line_sticker_widget.dart';

class CanvasArea extends ConsumerWidget {
  final String? projectId;
  final TransformationController transformationController;

  const CanvasArea({
    super.key,
    required this.projectId,
    required this.transformationController,
  });

  void _showAddTextStickerDialogAtPosition(
    BuildContext context,
    EditorController controller,
    Offset position,
  ) {
    if (controller.drawingController.isCurrentLayerLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current layer is locked.')),
      );
      return;
    }
    String text = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Text Sticker'),
          content: TextField(
            autofocus: true,
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
                  controller.addTextSticker(text, position);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(editorControllerProvider(projectId));
    final activeSticker = controller.activeSticker;

    Widget buildBoard(BoxConstraints c) {
      return GestureDetector(
        onTapDown: (controller.isTextToolSelected && activeSticker == null)
            ? (details) {
                final renderBox = context.findRenderObject() as RenderBox?;
                if (renderBox != null) {
                  final localPosition = details.localPosition;
                  final Matrix4 matrix = transformationController.value;
                  final Matrix4 inverse = Matrix4.inverted(matrix);
                  final Offset canvasPoint = MatrixUtils.transformPoint(inverse, localPosition);
                  _showAddTextStickerDialogAtPosition(context, controller, canvasPoint);
                }
              }
            : null,
        child: Stack(
          children: [
            DrawingBoard(
              transformationController: transformationController,
              controller: controller.drawingController,
              isGridEnabled: controller.isGridEnabled,
              gridOpacity: controller.gridOpacity,
              gridVerticalSpacing: controller.gridVerticalSpacing,
              gridHorizontalSpacing: controller.gridHorizontalSpacing,
              isOnionEnabled: controller.isOnionEnabled,
              onionColorMode: controller.onionColorMode,
              onionLoop: controller.onionLoop,
              onionBefore: controller.onionBefore,
              onionAfter: controller.onionAfter,
              allControllers: controller.canvases,
              currentIndex: controller.currentIndex,
              onPointerDown: (e) {
                if (controller.drawingController.isCurrentLayerLocked) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Current layer is locked.')),
                  );
                  return;
                }
                if (activeSticker != null) {
                  controller.stampActiveSticker();
                }
              },
              boardPanEnabled: activeSticker == null && !controller.drawingController.isCurrentLayerLocked,
              boardScaleEnabled: activeSticker == null && !controller.drawingController.isCurrentLayerLocked,
              isDrawingEnabled: activeSticker == null && !controller.isTextToolSelected && !controller.drawingController.isCurrentLayerLocked,
              background: ValueListenableBuilder<DrawConfig>(
                valueListenable: controller.drawingController.drawConfig,
                builder: (context, config, child) {
                  Widget? guideWidget;
                  if (controller.templateMode == 'drawAccordingTemplate' &&
                      controller.currentIndex < controller.templateFrameAssets.length) {
                    final String assetPath = controller.templateFrameAssets[controller.currentIndex];
                    guideWidget = Positioned.fill(
                      child: Opacity(
                        opacity: 0.25,
                        child: Image.asset(
                          assetPath,
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  }

                  final bg = controller.globalBackground;

                  return Container(
                    width: config.size?.width ?? c.maxWidth,
                    height: config.size?.height ?? c.maxHeight,
                    color: bg.pattern == 'blueprint'
                        ? const Color(0xFF1E3D59)
                        : (bg.pattern == 'graph' ? const Color(0xFFF1F8F6) : bg.color),
                    child: Stack(
                      children: [
                        if (guideWidget != null) guideWidget,
                        if (bg.image != null)
                          Positioned.fill(
                            child: Opacity(
                              opacity: bg.imageOpacity,
                              child: RawImage(
                                image: bg.image,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        if (bg.pattern != null && bg.pattern != 'none')
                          Positioned.fill(
                            child: CustomPaint(
                              painter: CanvasPatternPainter(
                                bg.pattern!,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              foreground: activeSticker == null
                  ? null
                  : Stack(
                      fit: StackFit.expand,
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              controller.stampActiveSticker();
                            },
                          ),
                        ),
                        if (activeSticker is ActiveTextSticker)
                          TextStickerWidget(
                            key: ValueKey((activeSticker).id),
                            data: activeSticker,
                            onUpdate: (offset, scale, rotation) {
                              (activeSticker).offset = offset;
                              (activeSticker).scale = scale;
                              (activeSticker).rotation = rotation;
                              controller.updateSnapshot();
                            },
                            onUpdateEnd: () => controller.recordActiveStickerState(),
                            onDelete: () {
                              controller.activeSticker = null;
                              controller.updateSnapshot();
                            },
                            onConfirm: () {
                              controller.stampActiveSticker();
                            },
                          ),
                        if (activeSticker is ActiveFreehandLineSticker)
                          FreehandLineStickerWidget(
                            key: ValueKey((activeSticker).id),
                            data: activeSticker,
                            onSnap: (raw, anchor) {
                              if (controller.showRulerMenu &&
                                  controller.drawingController.rulerConfig.value.type != RulerType.none) {
                                return controller.drawingController.rulerConfig.value.projectPoint(raw, anchor);
                              }
                              return raw;
                            },
                            onUpdate: () {
                              controller.updateSnapshot();
                            },
                            onUpdateEnd: () => controller.recordActiveStickerState(),
                            onDelete: () {
                              controller.activeSticker = null;
                              controller.updateSnapshot();
                            },
                            onConfirm: () {
                              controller.stampActiveSticker();
                            },
                          ),
                        if (activeSticker is ActiveShapeSticker)
                          ShapeStickerWidget(
                            key: ValueKey((activeSticker).id),
                            data: activeSticker,
                            canvasSize: controller.drawingController.drawConfig.value.size,
                            onUpdate: (offset, scale, rotation) {
                              (activeSticker).offset = offset;
                              (activeSticker).scale = scale;
                              (activeSticker).rotation = rotation;
                              controller.updateSnapshot();
                            },
                            onUpdateEnd: () => controller.recordActiveStickerState(),
                            onDelete: () {
                              controller.activeSticker = null;
                              controller.updateSnapshot();
                            },
                            onConfirm: () {
                              controller.stampActiveSticker();
                            },
                          ),
                        if (activeSticker is ActiveStraightLineSticker)
                          StraightLineStickerWidget(
                            key: ValueKey((activeSticker).id),
                            data: activeSticker,
                            onSnap: (raw, anchor) {
                              if (controller.showRulerMenu &&
                                  controller.drawingController.rulerConfig.value.type != RulerType.none) {
                                return controller.drawingController.rulerConfig.value.projectPoint(raw, anchor);
                              }
                              return raw;
                            },
                            onUpdate: (start, end) {
                              (activeSticker).startPoint = start;
                              (activeSticker).endPoint = end;
                              controller.updateSnapshot();
                            },
                            onUpdateEnd: () => controller.recordActiveStickerState(),
                            onDelete: () {
                              controller.activeSticker = null;
                              controller.updateSnapshot();
                            },
                            onConfirm: () {
                              controller.stampActiveSticker();
                            },
                          ),
                      ],
                    ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (controller.aspectRatio != null) {
          return Center(
            child: AspectRatio(
              aspectRatio: controller.aspectRatio!,
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints aspectConstraints) {
                  return buildBoard(aspectConstraints);
                },
              ),
            ),
          );
        } else {
          return buildBoard(constraints);
        }
      },
    );
  }
}

class CanvasPatternPainter extends CustomPainter {
  final String pattern;
  const CanvasPatternPainter(this.pattern);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..strokeWidth = 1.0;

    if (pattern == 'grid') {
      const double spacing = 20.0;
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    } else if (pattern == 'dots') {
      const double spacing = 20.0;
      final dotPaint = Paint()..color = Colors.black.withOpacity(0.15);
      for (double x = spacing / 2; x < size.width; x += spacing) {
        for (double y = spacing / 2; y < size.height; y += spacing) {
          canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
        }
      }
    } else if (pattern == 'lines') {
      const double spacing = 24.0;
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
      final marginPaint = Paint()
        ..color = Colors.redAccent.withOpacity(0.2)
        ..strokeWidth = 1.5;
      canvas.drawLine(const Offset(40, 0), Offset(40, size.height), marginPaint);
    } else if (pattern == 'checkboard') {
      const double spacing = 30.0;
      final cellPaint = Paint()..color = Colors.black.withOpacity(0.04);
      for (double x = 0; x < size.width; x += spacing) {
        for (double y = 0; y < size.height; y += spacing) {
          if (((x / spacing).floor() + (y / spacing).floor()) % 2 == 0) {
            canvas.drawRect(Rect.fromLTWH(x, y, spacing, spacing), cellPaint);
          }
        }
      }
    } else if (pattern == 'isometric') {
      const double spacing = 24.0;
      final double h = spacing * 0.866025;
      for (double x = 0; x < size.width + spacing; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      final double slope = 0.57735;
      for (double y = -size.width * slope; y < size.height; y += h * 2) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y + size.width * slope), paint);
        canvas.drawLine(Offset(0, y + size.width * slope), Offset(size.width, y), paint);
      }
    } else if (pattern == 'blueprint') {
      final bpPaint = Paint()
        ..color = Colors.white.withOpacity(0.12)
        ..strokeWidth = 1.0;
      const double spacing = 25.0;
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), bpPaint);
      }
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), bpPaint);
      }
    } else if (pattern == 'graph') {
      final minorPaint = Paint()
        ..color = const Color(0xFF81B214).withOpacity(0.1)
        ..strokeWidth = 0.5;
      final majorPaint = Paint()
        ..color = const Color(0xFF81B214).withOpacity(0.25)
        ..strokeWidth = 1.0;
      const double minorSpacing = 10.0;
      const double majorSpacing = 50.0;
      for (double x = 0; x < size.width; x += minorSpacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), (x % majorSpacing == 0) ? majorPaint : minorPaint);
      }
      for (double y = 0; y < size.height; y += minorSpacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), (y % majorSpacing == 0) ? majorPaint : minorPaint);
      }
    } else if (pattern == 'polar') {
      final center = Offset(size.width / 2, size.height / 2);
      final maxRadius = sqrt(size.width * size.width + size.height * size.height) / 2;
      for (double r = 40.0; r < maxRadius; r += 40.0) {
        canvas.drawCircle(center, r, paint);
      }
      for (int angle = 0; angle < 360; angle += 30) {
        final rad = angle * pi / 180;
        final end = center + Offset(cos(rad) * maxRadius, sin(rad) * maxRadius);
        canvas.drawLine(center, end, paint);
      }
    } else if (pattern == 'brick') {
      const double brickW = 40.0;
      const double brickH = 20.0;
      int rowIndex = 0;
      for (double y = 0; y < size.height + brickH; y += brickH) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        final double offset = (rowIndex % 2 == 0) ? 0 : brickW / 2;
        for (double x = -offset; x < size.width + brickW; x += brickW) {
          canvas.drawLine(Offset(x, y), Offset(x, y + brickH), paint);
        }
        rowIndex++;
      }
    } else if (pattern == 'music') {
      const double lineSpacing = 8.0;
      const double groupSpacing = 40.0;
      double y = 30.0;
      while (y < size.height - 40.0) {
        for (int i = 0; i < 5; i++) {
          final double py = y + i * lineSpacing;
          canvas.drawLine(Offset(0, py), Offset(size.width, py), paint);
        }
        y += 4 * lineSpacing + groupSpacing;
      }
    } else if (pattern == 'hex') {
      const double r = 16.0;
      final double h = r * sin(pi / 3);
      final path = Path();
      for (double x = 0; x < size.width + r * 2; x += r * 3) {
        int col = 0;
        for (double y = 0; y < size.height + r * 2; y += h) {
          final double ox = (col % 2 == 0) ? 0 : r * 1.5;
          path.moveTo(ox + x, y);
          path.lineTo(ox + x + r / 2, y + h);
          path.lineTo(ox + x + r * 1.5, y + h);
          path.lineTo(ox + x + r * 2, y);
          col++;
        }
      }
      canvas.drawPath(path, paint..style = PaintingStyle.stroke);
    } else if (pattern == 'cross') {
      const double spacing = 25.0;
      const double crossSize = 3.0;
      for (double x = spacing; x < size.width; x += spacing) {
        for (double y = spacing; y < size.height; y += spacing) {
          canvas.drawLine(Offset(x - crossSize, y), Offset(x + crossSize, y), paint);
          canvas.drawLine(Offset(x, y - crossSize), Offset(x, y + crossSize), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CanvasPatternPainter oldDelegate) => oldDelegate.pattern != pattern;
}
