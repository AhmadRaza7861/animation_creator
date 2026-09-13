import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_path_provider.dart';

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

class _VideoProcessingScreenState extends State<VideoProcessingScreen> with TickerProviderStateMixin {
  bool _isProcessing = true;
  String _statusMessage = 'Initializing video decoding...';
  String _detailMessage = 'Preparing high-resolution frames for canvas';

  double _progress = 0.05;
  int _extractedCount = 0;
  late int _expectedTotalFrames;

  Timer? _progressPollTimer;
  Directory? _targetDir;
  int? _activeSessionId;

  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _frameSlideController;

  @override
  void initState() {
    super.initState();

    final double durationSec = max(0.1, (widget.endMs - widget.startMs) / 1000.0);
    _expectedTotalFrames = max(1, (durationSec * widget.fps).round());

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _frameSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _extractFrames();
  }

  @override
  void dispose() {
    _progressPollTimer?.cancel();
    _pulseController.dispose();
    _rotationController.dispose();
    _frameSlideController.dispose();
    super.dispose();
  }

  Future<void> _extractFrames() async {
    try {
      final directory = await AppPathProvider.getSafeTempDirectory();
      _targetDir = Directory('${directory.path}/video_frames_${DateTime.now().millisecondsSinceEpoch}');
      if (!await _targetDir!.exists()) {
        await _targetDir!.create(recursive: true);
      }

      final double startSec = widget.startMs / 1000.0;
      final double durationSec = (widget.endMs - widget.startMs) / 1000.0;

      // Start periodic directory polling for real-time frame extraction progress
      _progressPollTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
        if (!mounted || !_isProcessing || _targetDir == null) return;
        try {
          if (_targetDir!.existsSync()) {
            final fileCount = _targetDir!.listSync().whereType<File>().length;
            if (fileCount != _extractedCount) {
              setState(() {
                _extractedCount = fileCount;
                final double realProgress = (fileCount / _expectedTotalFrames).clamp(0.05, 0.98);
                if (realProgress > _progress) {
                  _progress = realProgress;
                }

                if (_progress < 0.25) {
                  _statusMessage = 'Decoding video streams...';
                  _detailMessage = 'Extracting frame data @ ${widget.fps} FPS';
                } else if (_progress < 0.85) {
                  _statusMessage = 'Extracting frames ($_extractedCount / $_expectedTotalFrames)...';
                  _detailMessage = 'Converting to transparent animation layers';
                } else {
                  _statusMessage = 'Finalizing canvas layers...';
                  _detailMessage = 'Creating timeline frame sequence';
                }
              });
            }
          }
        } catch (_) {}
      });

      // Extract frames using ffmpeg
      final String command = '-ss $startSec -i "${widget.videoFile.path}" -t $durationSec -r ${widget.fps} -f image2 "${_targetDir!.path}/frame_%04d.png"';

      final session = await FFmpegKit.executeAsync(command, (session) async {
        _progressPollTimer?.cancel();
        final returnCode = await session.getReturnCode();

        if (ReturnCode.isSuccess(returnCode)) {
          if (!mounted) return;
          setState(() {
            _progress = 1.0;
            _statusMessage = 'Complete!';
            _detailMessage = 'All $_expectedTotalFrames frames ready';
          });

          await Future.delayed(const Duration(milliseconds: 350));

          final files = _targetDir!.listSync().whereType<File>().toList();
          files.sort((a, b) => a.path.compareTo(b.path));

          if (mounted) {
            Navigator.pop(context, files.map((e) => e.path).toList());
          }
        } else {
          // Failure
          if (!mounted) return;
          setState(() {
            _isProcessing = false;
            _statusMessage = 'Frame extraction failed';
            _detailMessage = 'Please try a shorter range or lower frame rate';
          });

          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Extraction Error',
                style: TextStyle(color: ColorConstants.darkText, fontWeight: FontWeight.bold),
              ),
              content: const Text(
                'Failed to process the video stream. Please check video format or trim range.',
                style: TextStyle(color: ColorConstants.mediumText),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, null);
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(color: ColorConstants.accent, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }
      });

      _activeSessionId = session.getSessionId();
    } catch (e) {
      _progressPollTimer?.cancel();
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'Error occurred: $e';
        });
      }
    }
  }

  void _onCancel() {
    _progressPollTimer?.cancel();
    if (_activeSessionId != null) {
      FFmpegKit.cancel(_activeSessionId!);
    }
    Navigator.pop(context, null);
  }

  @override
  Widget build(BuildContext context) {
    final double durationSec = (widget.endMs - widget.startMs) / 1000.0;
    final int percentInt = (_progress * 100).round().clamp(0, 100);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Ambient Background Glowing Orb (Soft Light Mode Amber Glow)
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final double pulseVal = _pulseController.value;
              return Positioned(
                top: MediaQuery.of(context).size.height * 0.22,
                left: MediaQuery.of(context).size.width * 0.5 - 160,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        ColorConstants.accent.withOpacity(0.12 + pulseVal * 0.08),
                        const Color(0xFFFFEAD4).withOpacity(0.4 + pulseVal * 0.2),
                        Colors.white.withOpacity(0.0),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),

          // 2. Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Header Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4E8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFDAB3)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.auto_awesome, color: ColorConstants.accent, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'ROTOSCOPE IMPORT',
                              style: TextStyle(
                                color: Color(0xFFD96B00),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF2F2F7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: ColorConstants.darkText, size: 18),
                        ),
                        onPressed: _onCancel,
                      ),
                    ],
                  ),

                  // Center Cinematic Animation Hub
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated Rotating Film Reel & Pulsing Energy Rings
                      SizedBox(
                        width: 190,
                        height: 190,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer Pulsing Glow Ring
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                final double scale = 1.0 + _pulseController.value * 0.12;
                                final double alpha = 0.5 - _pulseController.value * 0.3;
                                return Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    width: 175,
                                    height: 175,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: ColorConstants.accent.withOpacity(alpha.clamp(0.0, 1.0)),
                                        width: 2.0,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            // Rotating Sprocket Ring (Light Theme Film Reel)
                            RotationTransition(
                              turns: _rotationController,
                              child: CustomPaint(
                                size: const Size(150, 150),
                                painter: _FilmReelPainter(),
                              ),
                            ),

                            // Central Hub Container (Clean Light White Container with Accent Border)
                            Container(
                              width: 95,
                              height: 95,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: ColorConstants.accent, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: ColorConstants.accent.withOpacity(0.25),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.movie_creation_outlined,
                                color: ColorConstants.accent,
                                size: 42,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Status Title & Subtitle (Light Mode Typography)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Column(
                          key: ValueKey(_statusMessage),
                          children: [
                            Text(
                              _statusMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: ColorConstants.darkText,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _detailMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: ColorConstants.mediumText,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // High-Tech Glowing Progress Bar & Percentage Pill
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$_extractedCount / $_expectedTotalFrames FRAMES',
                                  style: const TextStyle(
                                    color: ColorConstants.mediumText,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                Text(
                                  '$percentInt%',
                                  style: const TextStyle(
                                    color: ColorConstants.accent,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F0F6),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E2EA)),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                children: [
                                  AnimatedFractionallySizedBox(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOut,
                                    widthFactor: _progress.clamp(0.0, 1.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFFF9E24), Color(0xFFFF6E00)],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFFF8500).withOpacity(0.35),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Bottom Summary Info Card & Cancel Action
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8FC),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE8E8EE)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildInfoStat(
                              icon: Icons.timer_outlined,
                              label: 'DURATION',
                              value: '${durationSec.toStringAsFixed(1)}s',
                            ),
                            Container(width: 1, height: 26, color: const Color(0xFFE8E8EE)),
                            _buildInfoStat(
                              icon: Icons.speed_rounded,
                              label: 'FPS RATE',
                              value: '${widget.fps} FPS',
                            ),
                            Container(width: 1, height: 26, color: const Color(0xFFE8E8EE)),
                            _buildInfoStat(
                              icon: Icons.filter_none_rounded,
                              label: 'TOTAL',
                              value: '$_expectedTotalFrames Frames',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextButton.icon(
                        onPressed: _onCancel,
                        icon: const Icon(Icons.close_rounded, color: ColorConstants.mediumText, size: 16),
                        label: const Text(
                          'Cancel Import',
                          style: TextStyle(
                            color: ColorConstants.mediumText,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoStat({required IconData icon, required String label, required String value}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: ColorConstants.accent, size: 13),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: ColorConstants.mediumText,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: ColorConstants.darkText,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Custom painter that draws rotating filmstrip sprockets around the center hub for Light Mode
class _FilmReelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double center = size.width / 2;
    final double radius = size.width / 2;

    final Paint trackPaint = Paint()
      ..color = const Color(0xFFE6E6EE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;

    canvas.drawCircle(Offset(center, center), radius - 7, trackPaint);

    final Paint holePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    const int numHoles = 12;
    for (int i = 0; i < numHoles; i++) {
      final double angle = (i * 2 * pi) / numHoles;
      final double hx = center + (radius - 7) * cos(angle);
      final double hy = center + (radius - 7) * sin(angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(hx, hy), width: 5, height: 7),
          const Radius.circular(1.5),
        ),
        holePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
