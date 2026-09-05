import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../../../../core/constants/app_colors.dart';
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
  bool _isSaving = false;
  bool _isSaved = false;

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

  Future<void> _saveToGallery() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });

    try {
      final bool isGifFormat = widget.options.format.toUpperCase() == 'GIF' ||
          widget.filePath.toLowerCase().endsWith('.gif');

      if (isGifFormat) {
        await Gal.putImage(widget.filePath, album: 'Clipax');
      } else {
        await Gal.putVideo(widget.filePath, album: 'Clipax');
      }

      if (mounted) {
        setState(() {
          _isSaving = false;
          _isSaved = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2A2533),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: ColorConstants.primary, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Saved to Photos / Gallery in "Clipax" album!',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'OPEN',
              textColor: ColorConstants.primary,
              onPressed: () {
                try {
                  Gal.open();
                } catch (_) {}
              },
            ),
          ),
        );
      }
    } on GalException catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Text('Failed to save: ${e.type.message}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Text('Error saving: $e'),
          ),
        );
      }
    }
  }

  void _shareToPlatform(String platformName) {
    Share.shareXFiles(
      [XFile(widget.filePath)],
      text: '${widget.options.movieName} #Clipax #Animation',
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: ColorConstants.darkText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Export Ready',
          style: TextStyle(
            color: ColorConstants.darkText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Download to Device',
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: ColorConstants.primary),
                  )
                : Icon(
                    _isSaved ? Icons.check_circle_rounded : Icons.download_rounded,
                    color: _isSaved ? Colors.green : ColorConstants.primaryDark,
                    size: 24,
                  ),
            onPressed: _saveToGallery,
          ),
          const SizedBox(width: 8),
        ],
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
                          color: const Color(0xFF1E1B24),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
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
                                  child: CircularProgressIndicator(color: ColorConstants.primary),
                                ),

                              // Subtle dark gradient for badge readability
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.55),
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.65),
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ),
                                ),
                              ),

                              // Format Badge Top-Left
                              Positioned(
                                top: 14,
                                left: 14,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: ColorConstants.primary,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: ColorConstants.primary.withValues(alpha: 0.4),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    widget.options.format.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),

                              // Watermark indicator Top-Right if enabled
                              if (widget.options.includeWatermark)
                                Positioned(
                                  top: 14,
                                  right: 14,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified_rounded, color: ColorConstants.primary, size: 14),
                                        SizedBox(width: 4),
                                        Text(
                                          'Clipax',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              // Center Play Button Overlay
                              Center(
                                child: Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white38, width: 1.5),
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 38,
                                  ),
                                ),
                              ),

                              // Bottom info bar (FPS & Resolution)
                              Positioned(
                                bottom: 12,
                                right: 14,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

                    const SizedBox(height: 24),

                    // DOWNLOAD / SAVE TO DEVICE CARD
                    Container(
                      decoration: BoxDecoration(
                        color: _isSaved
                            ? Colors.green.shade50
                            : ColorConstants.primaryLight.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isSaved
                              ? Colors.green.shade200
                              : ColorConstants.primary.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _saveToGallery,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _isSaved ? Colors.green : ColorConstants.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_isSaved ? Colors.green : ColorConstants.primary).withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: _isSaving
                                      ? const Padding(
                                          padding: EdgeInsets.all(12.0),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Icon(
                                          _isSaved ? Icons.check_rounded : Icons.file_download_outlined,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _isSaved
                                            ? 'Saved to Gallery!'
                                            : 'Download to Device',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: _isSaved ? Colors.green.shade800 : ColorConstants.darkText,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _isSaved
                                            ? 'Tap to save again or open Photos'
                                            : 'Save directly to your Photos / Gallery',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _isSaved ? Colors.green.shade700 : ColorConstants.mediumText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _isSaved ? Colors.green : ColorConstants.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _isSaved ? 'SAVED' : 'SAVE',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // SHARE DESTINATION Section Header
                    const Text(
                      'SHARE & UPLOAD',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: ColorConstants.mediumText,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      decoration: BoxDecoration(
                        color: ColorConstants.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ColorConstants.border_color),
                      ),
                      child: Column(
                        children: [
                          // YouTube Option
                          _buildSocialTile(
                            icon: const Icon(Icons.play_circle_filled_rounded, color: Color(0xFFFF0000), size: 26),
                            title: 'YouTube',
                            subtitle: 'Share to YouTube Shorts or Videos',
                            onTap: () => _shareToPlatform('YouTube'),
                          ),

                          const Divider(height: 1, color: ColorConstants.border_color),

                          // TikTok Option
                          _buildSocialTile(
                            icon: Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 16),
                            ),
                            title: 'TikTok',
                            subtitle: 'Post animation to TikTok',
                            onTap: () => _shareToPlatform('TikTok'),
                          ),

                          const Divider(height: 1, color: ColorConstants.border_color),

                          // Instagram Option
                          _buildSocialTile(
                            icon: Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCAF45)],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 15),
                            ),
                            title: 'Instagram',
                            subtitle: 'Share to Stories or Reels',
                            onTap: () => _shareToPlatform('Instagram'),
                          ),

                          const Divider(height: 1, color: ColorConstants.border_color),

                          // Facebook Option
                          _buildSocialTile(
                            icon: const Icon(Icons.facebook_rounded, color: Color(0xFF1877F2), size: 26),
                            title: 'Facebook',
                            subtitle: 'Share to Facebook Feed',
                            onTap: () => _shareToPlatform('Facebook'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // MORE / SYSTEM SHARE Button (Bottom)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      ColorConstants.primary,
                      ColorConstants.primaryDark,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(27),
                  boxShadow: [
                    BoxShadow(
                      color: ColorConstants.primary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(27),
                    onTap: _shareGeneric,
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.share_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'SHARE ANIMATION',
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
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: ColorConstants.darkText,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: ColorConstants.mediumText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: ColorConstants.mediumText, size: 20),
          ],
        ),
      ),
    );
  }
}
