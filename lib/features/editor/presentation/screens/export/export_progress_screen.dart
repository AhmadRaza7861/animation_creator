import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../package_code/src/drawing_controller.dart';
import '../../controllers/editor_controller.dart';
import '../../../services/movie_export_service.dart';
import 'widgets/projector_animation.dart';
import 'share_movie_screen.dart';

class ExportProgressScreen extends StatefulWidget {
  final List<DrawingController> canvases;
  final CanvasBackground globalBackground;
  final ExportOptions options;

  const ExportProgressScreen({
    super.key,
    required this.canvases,
    required this.globalBackground,
    required this.options,
  });

  @override
  State<ExportProgressScreen> createState() => _ExportProgressScreenState();
}

class _ExportProgressScreenState extends State<ExportProgressScreen> {
  double _progress = 0.0;
  String _statusText = 'Preparing...';
  bool _isCancelled = false;
  bool _isExporting = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startExport();
  }

  Future<void> _startExport() async {
    try {
      final String outputPath = await MovieExportService.exportMovie(
        canvases: widget.canvases,
        globalBackground: widget.globalBackground,
        options: widget.options,
        onProgress: (progress, status) {
          if (mounted) {
            setState(() {
              _progress = progress;
              _statusText = status;
            });
          }
        },
        isCancelled: () => _isCancelled,
      );

      if (mounted && !_isCancelled) {
        setState(() {
          _isExporting = false;
          _progress = 1.0;
        });

        // Navigate to Share screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ShareMovieScreen(
              filePath: outputPath,
              options: widget.options,
            ),
          ),
        );
      }
    } catch (e) {
      if (!_isCancelled && mounted) {
        setState(() {
          _isExporting = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
        _showErrorDialog(_errorMessage ?? 'An error occurred during export.');
      }
    }
  }

  void _onCancelPressed() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Export?'),
        content: const Text('Are you sure you want to cancel the movie creation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('NO', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _isCancelled = true;
              Navigator.pop(context);
            },
            child: const Text('YES, CANCEL', style: TextStyle(color: Color(0xFFFF4B72))),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Failed'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('OK', style: TextStyle(color: Color(0xFFFF4B72))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _progress = 0.0;
                _isCancelled = false;
                _isExporting = true;
                _errorMessage = null;
              });
              _startExport();
            },
            child: const Text('RETRY', style: TextStyle(color: Color(0xFFFF4B72))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int percentage = (_progress * 100).round().clamp(0, 100);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _onCancelPressed();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF212121), size: 20),
            onPressed: _onCancelPressed,
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 1),

                // Animated Film Projector
                const ProjectorAnimation(),

                const SizedBox(height: 24),

                // "Movie saved in: Movies/FlipaClip" pill toast
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F2F33),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Movie saved in: Movies/FlipaClip',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // Progress Labels & Percentage
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Making movie',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212121),
                        ),
                      ),
                      Text(
                        '$percentage%',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF0F0F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF4B72)),
                  ),
                ),

                const SizedBox(height: 8),

                // Status Text
                Text(
                  _statusText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                  ),
                ),

                const Spacer(flex: 2),

                // Cancel Button
                TextButton(
                  onPressed: _onCancelPressed,
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Color(0xFFFF4B72),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
