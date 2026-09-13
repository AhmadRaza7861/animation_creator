import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/models/audio_clip.dart';
import '../../services/audio_recorder_service.dart';
import 'audio_trimmer_screen.dart';

class AudioRecorderScreen extends StatefulWidget {
  final int defaultTrackIndex;

  const AudioRecorderScreen({
    super.key,
    this.defaultTrackIndex = 0,
  });

  @override
  State<AudioRecorderScreen> createState() => _AudioRecorderScreenState();
}

class _AudioRecorderScreenState extends State<AudioRecorderScreen> with SingleTickerProviderStateMixin {
  final AudioRecorderService _recorderService = AudioRecorderService();
  bool _isRecording = false;
  int _elapsedMillis = 0;
  Timer? _timer;
  final List<double> _liveAmplitudes = [];
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _recorderService.dispose();
    super.dispose();
  }

  String _formatTimecode(int ms) {
    final int minutes = ms ~/ 60000;
    final int seconds = (ms % 60000) ~/ 1000;
    final int millis = ms % 1000;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${millis.toString().padLeft(3, '0')}';
  }

  void _startRecording() async {
    final hasPerm = await _recorderService.hasPermission();
    if (!hasPerm) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required to record audio.')),
        );
      }
      return;
    }

    _liveAmplitudes.clear();
    setState(() {
      _isRecording = true;
      _elapsedMillis = 0;
    });

    await _recorderService.startRecording(onAmplitude: (amp) {
      if (mounted) {
        setState(() {
          _liveAmplitudes.add(amp);
          if (_liveAmplitudes.length > 80) {
            _liveAmplitudes.removeAt(0);
          }
        });
      }
    });

    _timer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      if (!_isRecording || !mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _elapsedMillis += 33;
      });
    });
  }

  void _stopRecording() async {
    if (!_isRecording) return;
    _timer?.cancel();

    final result = await _recorderService.stopRecording();
    setState(() {
      _isRecording = false;
    });

    if (result != null && mounted) {
      final clip = AudioClip(
        title: 'Recording ${DateTime.now().second}',
        filePath: result.filePath,
        trackIndex: widget.defaultTrackIndex,
        durationMs: result.durationMs,
        waveformSamples: result.waveformSamples,
      );

      final trimmedClip = await Navigator.push<AudioClip>(
        context,
        MaterialPageRoute(
          builder: (context) => AudioTrimmerScreen(clip: clip),
        ),
      );

      if (trimmedClip != null && mounted) {
        Navigator.pop(context, trimmedClip);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E1E24)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Audio Recorder',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E1E24),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Middle Waveform Visualizer
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Center dotted horizontal line
                  Positioned(
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 2,
                      color: const Color(0xFFFF4B72).withValues(alpha: 0.25),
                    ),
                  ),

                  // Live Amplitude Waveform Bars
                  if (_liveAmplitudes.isNotEmpty)
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: CustomPaint(
                          painter: _LiveWaveformPainter(
                            amplitudes: _liveAmplitudes,
                            color: const Color(0xFFFF4B72),
                          ),
                        ),
                      ),
                    ),

                  // Timecode pill
                  Positioned(
                    bottom: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        _formatTimecode(_elapsedMillis),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2C2D35),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Record Button & Instructions matching Image 3
            Padding(
              padding: const EdgeInsets.only(bottom: 48.0, top: 12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_isRecording) {
                        _stopRecording();
                      } else {
                        _startRecording();
                      }
                    },
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final double scale = _isRecording ? 1.0 + (_pulseController.value * 0.12) : 1.0;
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFF4B72),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF4B72).withValues(alpha: _isRecording ? 0.5 : 0.25),
                                  blurRadius: _isRecording ? 20 : 12,
                                  spreadRadius: _isRecording ? 4 : 1,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isRecording ? 'Tap to stop recording' : 'Tap to start recording',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveWaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;

  _LiveWaveformPainter({required this.amplitudes, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final Paint paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final double centerY = size.height / 2;
    const double barStep = 5.0;
    final int maxBars = (size.width / barStep).floor();
    final int count = amplitudes.length.clamp(0, maxBars);

    final double startX = size.width - (count * barStep);

    for (int i = 0; i < count; i++) {
      final double x = startX + (i * barStep);
      final double amp = amplitudes[i].clamp(0.08, 1.0);
      final double barHeight = amp * (size.height * 0.7);
      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LiveWaveformPainter oldDelegate) => true;
}
