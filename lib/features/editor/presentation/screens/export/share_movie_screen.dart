import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../../services/movie_export_service.dart';
import 'fullscreen_player_screen.dart';

class ShareMovieScreen extends StatefulWidget {
  final String filePath;
  final ExportOptions options;

  const ShareMovieScreen({
    super.key,
    required this.filePath,
    required this.options,
  });

  @override
  State<ShareMovieScreen> createState() => _ShareMovieScreenState();
}

class _ShareMovieScreenState extends State<ShareMovieScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isGif = false;

  @override
  void initState() {
    super.initState();
    _isGif = widget.options.format.toUpperCase() == 'GIF' || widget.filePath.toLowerCase().endsWith('.gif');
    if (!_isGif) {
      _initVideoPlayer();
    }
  }

  Future<void> _initVideoPlayer() async {
    try {
      final file = File(widget.filePath);
      _videoController = VideoPlayerController.file(file);
      await _videoController!.initialize();
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing thumbnail player: $e');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _openFullscreenPlayer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullscreenPlayerScreen(
          filePath: widget.filePath,
          format: widget.options.format,
          fps: widget.options.fps,
        ),
      ),
    );
  }

  void _shareToPlatform(String platformName) {
    Share.shareXFiles(
      [XFile(widget.filePath)],
      text: '${widget.options.movieName} #FlipaClip #Animation',
      subject: widget.options.movieName,
    );
  }

  void _shareGeneric() {
    Share.shareXFiles(
      [XFile(widget.filePath)],
      text: widget.options.movieName,
      subject: widget.options.movieName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF212121), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Make movie',
          style: TextStyle(
            color: Color(0xFF212121),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preview Card
                    GestureDetector(
                      onTap: _openFullscreenPlayer,
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E24),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Background Video / Image Thumbnail
                              if (_isGif)
                                Image.file(
                                  File(widget.filePath),
                                  fit: BoxFit.contain,
                                )
                              else if (_isVideoInitialized && _videoController != null)
                                FittedBox(
                                  fit: BoxFit.contain,
                                  child: SizedBox(
                                    width: _videoController!.value.size.width > 0
                                        ? _videoController!.value.size.width
                                        : 1920,
                                    height: _videoController!.value.size.height > 0
                                        ? _videoController!.value.size.height
                                        : 1080,
                                    child: VideoPlayer(_videoController!),
                                  ),
                                )
                              else
                                const Center(
                                  child: CircularProgressIndicator(color: Color(0xFFFF4B72)),
                                ),

                              // Subtle dark gradient for badge readability
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.5),
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.5),
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ),
                                ),
                              ),

                              // Format Badge Top-Left
                              Positioned(
                                top: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF4B72),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    widget.options.format.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              // Watermark indicator Top-Right if enabled
                              if (widget.options.includeWatermark)
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified_rounded, color: Colors.white70, size: 13),
                                        SizedBox(width: 4),
                                        Text(
                                          'FlipaClip',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              // Center Play Button Overlay
                              Center(
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white38, width: 1.5),
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),
                              ),

                              // Bottom info bar (FPS & Resolution)
                              Positioned(
                                bottom: 10,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${widget.options.fps} FPS • ${widget.options.outputSize.width.toInt()}x${widget.options.outputSize.height.toInt()}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // UPLOAD Section Header
                    const Text(
                      'UPLOAD',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Color(0xFF8E8E93),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // YouTube Option
                    _buildSocialTile(
                      icon: const Icon(Icons.play_circle_filled_rounded, color: Color(0xFFFF0000), size: 28),
                      title: 'YouTube',
                      onTap: () => _shareToPlatform('YouTube'),
                    ),

                    const Divider(height: 1, color: Color(0xFFEEEEEE)),

                    // TikTok Option
                    _buildSocialTile(
                      icon: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 18),
                      ),
                      title: 'TikTok',
                      onTap: () => _shareToPlatform('TikTok'),
                    ),

                    const Divider(height: 1, color: Color(0xFFEEEEEE)),

                    // Facebook Option
                    _buildSocialTile(
                      icon: const Icon(Icons.facebook_rounded, color: Color(0xFF1877F2), size: 28),
                      title: 'Facebook',
                      onTap: () => _shareToPlatform('Facebook'),
                    ),

                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  ],
                ),
              ),
            ),

            // MORE Button (Bottom)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4B72),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _shareGeneric,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.share_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'MORE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialTile({
    required Widget icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF212121),
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9E9E9E)),
          ],
        ),
      ),
    );
  }
}
