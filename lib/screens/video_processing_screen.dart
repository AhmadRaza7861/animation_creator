import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';

class VideoProcessingScreen extends StatefulWidget {
  final File videoFile;
  final int startMs;
  final int endMs;
  final int fps;

  const VideoProcessingScreen({
    super.key, 
    required this.videoFile, 
    required this.startMs, 
    required this.endMs,
    this.fps = 10,
  });

  @override
  State<VideoProcessingScreen> createState() => _VideoProcessingScreenState();
}

class _VideoProcessingScreenState extends State<VideoProcessingScreen> {
  bool _isProcessing = true;
  String _statusMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _extractFrames();
  }

  Future<void> _extractFrames() async {
    try {
      setState(() {
        _statusMessage = 'Extracting frames...';
      });

      final directory = await getApplicationDocumentsDirectory();
      final targetDir = Directory('${directory.path}/video_frames_${DateTime.now().millisecondsSinceEpoch}');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final double startSec = widget.startMs / 1000.0;
      final double durationSec = (widget.endMs - widget.startMs) / 1000.0;

      // Extract frames using ffmpeg with specified framerate and strict duration bounds
      final String command = '-ss $startSec -i "${widget.videoFile.path}" -t $durationSec -r ${widget.fps} -f image2 "${targetDir.path}/frame_%04d.png"';
      
      await FFmpegKit.executeAsync(command, (session) async {
        final returnCode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returnCode)) {
          // Success
          final files = targetDir.listSync().whereType<File>().toList();
          files.sort((a, b) => a.path.compareTo(b.path));
          
          if (mounted) {
            Navigator.pop(context, files.map((e) => e.path).toList());
          }
        } else {
          // Failure
          if (mounted) {
            setState(() {
              _isProcessing = false;
              _statusMessage = 'Failed to extract frames';
            });
            // Show error dialog
            showDialog(
              context: context, 
              builder: (_) => AlertDialog(
                title: const Text('Error'),
                content: const Text('Failed to process the video.'),
                actions: [
                  TextButton(
                    onPressed: () {
                       Navigator.pop(context); // dialog
                       Navigator.pop(context, null); // screen
                    },
                    child: const Text('OK'),
                  )
                ]
              )
            );
          }
        }
      });
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'Error occurred: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isProcessing) const CircularProgressIndicator(color: Colors.pinkAccent),
            const SizedBox(height: 24),
            Text(
              _statusMessage, 
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
            ),
          ],
        ),
      ),
    );
  }
}
