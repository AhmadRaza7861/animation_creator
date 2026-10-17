import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../presentation/controllers/editor_controller.dart';
import '../presentation/screens/video_trimming_screen.dart';

class VideoImportHelper {
  VideoImportHelper._();

  static Future<void> importVideo({
    required BuildContext context,
    required EditorController controller,
    ImagePicker? picker,
  }) async {
    final ImagePicker videoPicker = picker ?? ImagePicker();
    VoidCallback? dismissSelectLoader;

    try {
      dismissSelectLoader = AppDialogs.showProcessingDialog(
        context,
        title: 'Loading Video',
        message: 'Preparing video for trimming... Please wait.',
        icon: Icons.video_collection_rounded,
      );

      // Allow Flutter engine to composite and paint dialog frame before Android opens gallery
      await Future<void>.delayed(const Duration(milliseconds: 140));
      if (!context.mounted) {
        dismissSelectLoader();
        return;
      }

      final XFile? file = await videoPicker.pickVideo(source: ImageSource.gallery);

      if (file == null || !context.mounted) {
        dismissSelectLoader();
        return;
      }

      final File videoFile = File(file.path);
      dismissSelectLoader();

      final trimmedFrames = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoTrimmingScreen(videoFile: videoFile),
        ),
      );

      if (trimmedFrames != null &&
          trimmedFrames is List<String> &&
          trimmedFrames.isNotEmpty &&
          context.mounted) {
        final dismissImportLoader = AppDialogs.showProcessingDialog(
          context,
          title: 'Importing Frames',
          message: 'Adding ${trimmedFrames.length} animation frames to timeline...',
          icon: Icons.auto_awesome_motion_rounded,
        );
        try {
          await Future<void>.delayed(const Duration(milliseconds: 60));
          await controller.importVideoFrames(trimmedFrames);
          await controller.saveProject(immediate: true);
        } finally {
          dismissImportLoader();
        }
      }
    } catch (e) {
      dismissSelectLoader?.call();
      debugPrint('Error importing video: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not import video: $e')),
        );
      }
    }
  }
}
