import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class CanvasSelector extends StatelessWidget {
  final List<ui.Image?> thumbnails;
  final int currentIndex;
  final Function(int) onSelect;
  final VoidCallback onAdd;
  final VoidCallback onOpenGallery;
  final VoidCallback onOpenFrames;
  final VoidCallback onImportVideo;
  final VoidCallback onPlay;
  final void Function(String action, int index) onFrameAction;
  final List<Key> canvasKeys;
  final void Function(int oldIndex, int newIndex) onReorder;

  const CanvasSelector({
    super.key,
    required this.thumbnails,
    required this.currentIndex,
    required this.onSelect,
    required this.onAdd,
    required this.onOpenGallery,
    required this.onOpenFrames,
    required this.onImportVideo,
    required this.onPlay,
    required this.onFrameAction,
    required this.canvasKeys,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 0),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        children: [
          // Layers Button
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: const Icon(Icons.layers_rounded, size: 28, color: AppColors.darkText),
                onPressed: onOpenFrames,
                tooltip: 'Layers',
              ),
            ),
          ),
          // Play Button
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: const Icon(Icons.play_arrow_rounded, size: 28, color: AppColors.darkText),
                onPressed: onPlay,
                tooltip: 'Play Animation',
              ),
            ),
          ),
          // Reorderable Frame Thumbnails list
          Expanded(
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              buildDefaultDragHandles: false,
              proxyDecorator:
                  (Widget child, int index, Animation<double> animation) {
                    return Material(color: Colors.transparent, child: child);
                  },
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemCount: thumbnails.length,
              onReorder: onReorder,
              itemBuilder: (context, index) {
                return ReorderableDelayedDragStartListener(
                  key: canvasKeys[index],
                  index: index,
                  child: _buildThumbnailItem(index),
                );
              },
            ),
          ),
          // Dashed Add Frame Button
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: _buildDashedAddButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedAddButton() {
    return GestureDetector(
      onTap: onAdd,
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: Colors.grey.shade400,
          strokeWidth: 1.5,
          gap: 4.0,
          radius: 12,
        ),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(Icons.add, size: 24, color: AppColors.darkText),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailItem(int index) {
    final isSelected = index == currentIndex;

    return GestureDetector(
      onTap: () => onSelect(index),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 56,
            margin: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2.0,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const CheckerboardBackground(),
                  if (thumbnails[index] != null)
                    RawImage(image: thumbnails[index], fit: BoxFit.contain)
                  else
                    const Center(
                      child: Icon(
                        Icons.palette_outlined,
                        color: Colors.black26,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          Positioned(
            top: 2,
            right: 4,
            child: PopupMenuButton<String>(
              tooltip: 'Frame Actions',
              position: PopupMenuPosition.under,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (action) => onFrameAction(action, index),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'copy',
                  child: Row(
                    children: [
                      Icon(Icons.copy_rounded, size: 20),
                      SizedBox(width: 12),
                      Text('Copy'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'paste',
                  child: Row(
                    children: [
                      Icon(Icons.paste_rounded, size: 20),
                      SizedBox(width: 12),
                      Text('Paste'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'left',
                  child: Row(
                    children: [
                      Icon(Icons.add_box_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('Add Left'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'right',
                  child: Row(
                    children: [
                      Icon(Icons.add_box_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('Add Right'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Text('Delete', style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.more_vert_rounded,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double radius;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));

    final dashedPath = Path();
    double distance = 0.0;
    bool draw = true;
    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        final length = gap;
        final nextDistance = distance + length;
        if (draw) {
          dashedPath.addPath(
            pathMetric.extractPath(distance, nextDistance.clamp(0.0, pathMetric.length)),
            Offset.zero,
          );
        }
        distance = nextDistance;
        draw = !draw;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) => false;
}

class CheckerboardBackground extends StatelessWidget {
  const CheckerboardBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: CheckerboardPainter());
  }
}

class CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double squareSize = 8.0;
    final Paint lightPaint = Paint()..color = Colors.grey.shade100;
    final Paint darkPaint = Paint()..color = Colors.grey.shade200;

    for (double i = 0; i < size.width; i += squareSize) {
      for (double j = 0; j < size.height; j += squareSize) {
        final Rect rect = Rect.fromLTWH(i, j, squareSize, squareSize);
        canvas.drawRect(
          rect,
          ((i / squareSize).floor() + (j / squareSize).floor()) % 2 == 0
              ? lightPaint
              : darkPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
