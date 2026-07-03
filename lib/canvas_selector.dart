import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class CanvasSelector extends StatelessWidget {
  final List<ui.Image?> thumbnails;
  final int currentIndex;
  final Function(int) onSelect;
  final VoidCallback onAdd;
  final VoidCallback onOpenGallery;
  final VoidCallback onOpenFrames;
  final VoidCallback onImportVideo;
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
    required this.onFrameAction,
    required this.canvasKeys,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // _buildGalleryButton(),
                _buildImportVideoButton(),
                _buildFramesButton(),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              buildDefaultDragHandles: false,
              proxyDecorator:
                  (Widget child, int index, Animation<double> animation) {
                    return Material(color: Colors.transparent, child: child);
                  },
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
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
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _buildAddButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryButton() {
    return _buildActionButton(
      icon: Icons.collections_bookmark_rounded,
      label: 'GALLERY',
      color: Colors.blueAccent,
      onTap: onOpenGallery,
    );
  }

  Widget _buildImportVideoButton() {
    return _buildActionButton(
      icon: Icons.video_library_rounded,
      label: 'VIDEO',
      color: Colors.green,
      onTap: onImportVideo,
    );
  }

  Widget _buildFramesButton() {
    return _buildActionButton(
      icon: Icons.view_sidebar_rounded,
      label: 'FRAMES',
      color: Colors.purpleAccent,
      onTap: onOpenFrames,
    );
  }

  Widget _buildAddButton() {
    return _buildActionButton(
      icon: Icons.add_rounded,
      label: 'NEW',
      color: Colors.pinkAccent,
      onTap: onAdd,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
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
            width: 100,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.pinkAccent : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.pinkAccent.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                13.5,
              ), // Adjust for border width
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Checkerboard background for transparency
                  const CheckerboardBackground(),

                  if (thumbnails[index] != null)
                    RawImage(image: thumbnails[index], fit: BoxFit.contain)
                  else
                    const Center(
                      child: Icon(
                        Icons.palette_outlined,
                        color: Colors.black26,
                      ),
                    ),

                  // Canvas Index Label
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Canvas ${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Context Menu Badge
          Positioned(
            top: -4,
            left: -4,
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
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF5A52FF),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
