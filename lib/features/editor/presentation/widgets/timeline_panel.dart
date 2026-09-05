import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/editor_providers.dart';
import 'canvas_selector.dart';
import '../screens/gallery_screen.dart';
import '../screens/video_trimming_screen.dart';
import '../screens/animation_preview_screen.dart';
import 'package:image_picker/image_picker.dart';

class TimelinePanel extends ConsumerWidget {
  final String? projectId;

  const TimelinePanel({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(editorControllerProvider(projectId));

    void openGallery() {
      final validImages = controller.thumbnails.whereType<ui.Image>().toList();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GalleryScreen(images: validImages),
        ),
      );
    }

    void importVideo() async {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickVideo(source: ImageSource.gallery);
      if (file == null) return;

      final trimmedFrames = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoTrimmingScreen(videoFile: File(file.path)),
        ),
      );

      if (trimmedFrames != null && trimmedFrames is List<String>) {
        await controller.importVideoFrames(trimmedFrames);
      }
    }

    void openPreview() async {
      // Save state before preview
      controller.saveProject();

      final updatedFps = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnimationPreviewScreen(
            canvases: controller.canvases,
            aspectRatio: controller.aspectRatio,
            globalBackground: controller.globalBackground,
            initialFps: controller.fps,
          ),
        ),
      );

      if (updatedFps != null && updatedFps is int) {
        controller.fps = updatedFps;
      }
    }

    void onFrameAction(String action, int index) {
      if (action == 'copy') {
        controller.copyFrame(index);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Frame copied to clipboard'),
            duration: Duration(milliseconds: 1200),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (action == 'paste') {
        if (controller.hasClipboardFrame) {
          controller.pasteFrame(index);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No frame in clipboard'),
              duration: Duration(milliseconds: 1200),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (action == 'duplicate') {
        controller.duplicateFrame(index);
      } else if (action == 'left') {
        controller.addFrameAt(index, isRight: false);
      } else if (action == 'right') {
        controller.addFrameAt(index, isRight: true);
      } else if (action == 'delete') {
        if (controller.canvases.length > 1) {
          controller.deleteFrame(index);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot delete the last frame'),
              duration: Duration(milliseconds: 1200),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }

    return CanvasSelector(
      thumbnails: controller.thumbnails,
      currentIndex: controller.currentIndex,
      onSelect: (index) => controller.selectCanvas(index),
      onAdd: () => controller.addFrame(),
      onOpenGallery: openGallery,
      onOpenFrames: () {
        controller.showLayerPanel = !controller.showLayerPanel;
      },
      onImportVideo: importVideo,
      onPlay: openPreview,
      onFrameAction: onFrameAction,
      canvasKeys: controller.canvases.map((c) => ObjectKey(c)).toList(),
      onReorder: (oldIdx, newIdx) => controller.reorderFrames(oldIdx, newIdx),
      globalBackground: controller.globalBackground,
    );
  }
}
