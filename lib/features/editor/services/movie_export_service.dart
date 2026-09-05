import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../package_code/src/drawing_controller.dart';
import '../presentation/controllers/editor_controller.dart';

class ExportOptions {
  final String movieName;
  final String format; // 'MP4' or 'GIF'
  final Size outputSize;
  final int fps;
  final bool transparentBackground;
  final bool includeWatermark;

  ExportOptions({
    required this.movieName,
    required this.format,
    required this.outputSize,
    required this.fps,
    this.transparentBackground = false,
    this.includeWatermark = true,
  });
}

class MovieExportService {
  static Future<String> exportMovie({
    required List<DrawingController> canvases,
    required CanvasBackground globalBackground,
    required ExportOptions options,
    required void Function(double progress, String status) onProgress,
    bool Function()? isCancelled,
  }) async {
    if (canvases.isEmpty) {
      throw Exception('No frames to export.');
    }

    onProgress(0.05, 'Preparing frames...');

    // 1. Create temporary directory for frame images
    final tempDir = await getTemporaryDirectory();
    final framesDir = Directory('${tempDir.path}/export_frames_${DateTime.now().millisecondsSinceEpoch}');
    if (!await framesDir.exists()) {
      await framesDir.create(recursive: true);
    }

    try {
      final int totalCanvases = canvases.length;
      final Size targetSize = options.outputSize;
      final int fps = options.fps.clamp(1, 60);

      // If user only created 1 frame, write fps frames (1 full second) so FFmpeg has a valid sequence
      final int totalFrames = (totalCanvases == 1) ? fps : totalCanvases;

      // 2. Render each canvas frame to PNG
      for (int i = 0; i < totalFrames; i++) {
        if (isCancelled != null && isCancelled()) {
          throw Exception('Export cancelled');
        }

        final int canvasIndex = (totalCanvases == 1) ? 0 : i;
        final canvasController = canvases[canvasIndex];
        final Uint8List pngBytes = await _renderCanvasToPng(
          controller: canvasController,
          targetSize: targetSize,
          background: globalBackground,
          transparentBackground: options.transparentBackground,
          includeWatermark: options.includeWatermark,
        );

        final String frameIndexStr = (i + 1).toString().padLeft(4, '0');
        final File frameFile = File('${framesDir.path}/frame_$frameIndexStr.png');
        await frameFile.writeAsBytes(pngBytes);

        final double frameProgress = 0.05 + (0.45 * (i + 1) / totalFrames);
        onProgress(frameProgress, 'Rendering frame ${i + 1}/$totalFrames...');
      }

      if (isCancelled != null && isCancelled()) {
        throw Exception('Export cancelled');
      }

      onProgress(0.55, 'Encoding ${options.format}...');

      // 3. Prepare destination file
      final Directory exportDir = await _getExportDirectory();
      final String safeName = options.movieName.replaceAll(RegExp(r'[^\w\s\.-]'), '_').trim().replaceAll(' ', '_');
      final String ext = options.format.toUpperCase() == 'GIF' ? 'gif' : 'mp4';
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
      final String outputFilePath = '${exportDir.path}/${safeName}_$timestamp.$ext';

      // 4. Construct FFmpeg arguments
      final String inputPattern = '${framesDir.path}/frame_%04d.png';
      final bool isGif = options.format.toUpperCase() == 'GIF';

      final List<String> args;
      if (isGif) {
        final String gifFilter = options.transparentBackground
            ? 'fps=$fps,split[s0][s1];[s0]palettegen=reserve_transparent=1[p];[s1][p]paletteuse=alpha_threshold=128'
            : 'fps=$fps,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse';

        args = [
          '-y',
          '-framerate', '$fps',
          '-i', inputPattern,
          '-vf', gifFilter,
          outputFilePath,
        ];
      } else {
        args = [
          '-y',
          '-framerate', '$fps',
          '-i', inputPattern,
          '-c:v', 'libx264',
          '-pix_fmt', 'yuv420p',
          '-vf', 'pad=ceil(iw/2)*2:ceil(ih/2)*2',
          outputFilePath,
        ];
      }

      final Completer<bool> ffmpegCompleter = Completer<bool>();

      await FFmpegKit.executeWithArgumentsAsync(
        args,
        (session) async {
          final returnCode = await session.getReturnCode();
          if (ReturnCode.isSuccess(returnCode)) {
            ffmpegCompleter.complete(true);
          } else {
            final failLogs = await session.getAllLogsAsString();
            debugPrint('FFmpeg primary attempt failed logs: $failLogs');
            
            // If primary GIF encoding with palettegen fails, retry with simple GIF filter
            if (isGif) {
              debugPrint('Retrying GIF export with standard filter...');
              final fallbackArgs = [
                '-y',
                '-framerate', '$fps',
                '-i', inputPattern,
                '-vf', 'fps=$fps',
                outputFilePath,
              ];
              
              await FFmpegKit.executeWithArgumentsAsync(
                fallbackArgs,
                (retrySession) async {
                  final retryCode = await retrySession.getReturnCode();
                  if (ReturnCode.isSuccess(retryCode)) {
                    ffmpegCompleter.complete(true);
                  } else {
                    final retryLogs = await retrySession.getAllLogsAsString();
                    debugPrint('FFmpeg fallback failed logs: $retryLogs');
                    ffmpegCompleter.complete(false);
                  }
                },
              );
            } else {
              ffmpegCompleter.complete(false);
            }
          }
        },
        null,
        (statistics) {
          final int frameNumber = statistics.getVideoFrameNumber();
          if (frameNumber > 0 && totalFrames > 0) {
            final double encodingProgress = (frameNumber / totalFrames).clamp(0.0, 1.0);
            final double overall = 0.55 + (0.45 * encodingProgress);
            onProgress(overall.clamp(0.0, 0.99), 'Encoding ${options.format}...');
          }
        },
      );

      final bool success = await ffmpegCompleter.future;

      if (!success) {
        throw Exception('Failed to encode ${options.format} with FFmpeg.');
      }

      onProgress(1.0, 'Complete!');
      return outputFilePath;
    } finally {
      // Clean up temporary frame images
      try {
        if (await framesDir.exists()) {
          await framesDir.delete(recursive: true);
        }
      } catch (e) {
        debugPrint('Failed to delete temp frames: $e');
      }
    }
  }

  static Future<Uint8List> _renderCanvasToPng({
    required DrawingController controller,
    required Size targetSize,
    required CanvasBackground background,
    required bool transparentBackground,
    required bool includeWatermark,
  }) async {
    final Size sourceSize = controller.drawConfig.value.size ?? targetSize;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, Offset.zero & targetSize);

    final double scaleX = targetSize.width / (sourceSize.width > 0 ? sourceSize.width : targetSize.width);
    final double scaleY = targetSize.height / (sourceSize.height > 0 ? sourceSize.height : targetSize.height);

    canvas.save();
    canvas.scale(scaleX, scaleY);

    // 1. Draw Background
    if (!transparentBackground) {
      final Paint bgPaint = Paint()..color = background.color;
      canvas.drawRect(Offset.zero & sourceSize, bgPaint);

      if (background.image != null) {
        final Paint imgPaint = Paint()
          ..color = Colors.white.withValues(alpha: background.imageOpacity.clamp(0.0, 1.0));
        final Rect src = Rect.fromLTWH(0, 0, background.image!.width.toDouble(), background.image!.height.toDouble());
        final Rect dst = Offset.zero & sourceSize;
        canvas.drawImageRect(background.image!, src, dst, imgPaint);
      }
    }

    // 2. Draw Layers
    canvas.saveLayer(Offset.zero & sourceSize, Paint());
    for (int i = controller.layers.length - 1; i >= 0; i--) {
      final layer = controller.layers[i];
      if (!layer.isVisible) continue;

      canvas.saveLayer(
        Offset.zero & sourceSize,
        Paint()
          ..blendMode = layer.blendMode
          ..color = Colors.white.withValues(alpha: layer.opacity.clamp(0.0, 1.0)),
      );

      final int count = layer.currentIndex.clamp(0, layer.history.length);
      for (int j = 0; j < count; j++) {
        layer.history[j].draw(canvas, sourceSize, false);
      }

      canvas.restore();
    }
    canvas.restore(); // restore layer stack

    // 3. Draw Watermark if enabled
    if (includeWatermark) {
      _drawWatermark(canvas, sourceSize);
    }

    canvas.restore(); // restore scale

    final ui.Picture picture = recorder.endRecording();
    final ui.Image img = await picture.toImage(targetSize.width.toInt(), targetSize.height.toInt());
    final ByteData? byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  static void _drawWatermark(Canvas canvas, Size canvasSize) {
    const String text = 'FlipaClip';
    const double fontSize = 16.0;

    final TextPainter textPainter = TextPainter(
      text: const TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white70,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto',
          shadows: [
            Shadow(
              color: Colors.black45,
              offset: Offset(1, 1),
              blurRadius: 3,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final double margin = 16.0;
    final Offset position = Offset(margin, canvasSize.height - textPainter.height - margin);

    // Draw subtle translucent badge behind watermark
    final RRect bgRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        position.dx - 6,
        position.dy - 3,
        textPainter.width + 12,
        textPainter.height + 6,
      ),
      const Radius.circular(8),
    );

    final Paint bgPaint = Paint()..color = Colors.black.withValues(alpha: 0.25);
    canvas.drawRRect(bgRRect, bgPaint);

    textPainter.paint(canvas, position);
  }

  static Future<Directory> _getExportDirectory() async {
    Directory? exportDir;
    try {
      final appDocs = await getApplicationDocumentsDirectory();
      final localMovies = Directory('${appDocs.path}/Movies/FlipaClip');
      if (!await localMovies.exists()) {
        await localMovies.create(recursive: true);
      }
      exportDir = localMovies;
    } catch (e) {
      debugPrint('Error accessing appDocs directory: $e');
    }

    if (exportDir == null || !await exportDir.exists()) {
      final tempDir = await getTemporaryDirectory();
      final localMovies = Directory('${tempDir.path}/Movies/FlipaClip');
      if (!await localMovies.exists()) {
        await localMovies.create(recursive: true);
      }
      exportDir = localMovies;
    }

    return exportDir;
  }
}
