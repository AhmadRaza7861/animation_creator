import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../package_code/src/drawing_controller.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_back_button.dart';
import '../../../../../core/widgets/app_dialogs.dart';
import '../../controllers/editor_controller.dart';
import '../../../services/movie_export_service.dart';
import 'widgets/projector_animation.dart';
import 'share_movie_screen.dart';

import '../../../../audio/domain/models/audio_project_state.dart';

class ExportProgressScreen extends StatefulWidget {
  final List<DrawingController> canvases;
  final CanvasBackground globalBackground;
  final ExportOptions options;
  final AudioProjectState? audioState;

  const ExportProgressScreen({
    super.key,
    required this.canvases,
    required this.globalBackground,
    required this.options,
    this.audioState,
  });

  @override
  State<ExportProgressScreen> createState() => _ExportProgressScreenState();
}

class _ExportProgressScreenState extends State<ExportProgressScreen> {
  double _progress = 0.0;
  String _statusText = 'Preparing frames...';
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
        audioState: widget.audioState,
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

  void _onCancelPressed() async {
    final shouldCancel = await AppDialogs.showCancelExportDialog(context);
    if (shouldCancel && mounted) {
      _isCancelled = true;
      Navigator.pop(context);
    }
  }

  void _showErrorDialog(String error) async {
    await AppDialogs.showNoticeDialog(
      context,
      title: 'Export Notice',
      message: error,
      isError: true,
    );
    if (mounted) {
      Navigator.pop(context);
    }
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
          leading: AppBackButton(
            onPressed: _onCancelPressed,
          ),
          title: const Text(
            'Exporting Animation',
            style: TextStyle(
              color: ColorConstants.darkText,
              fontSize: 18,
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

                // Custom Clipax Studio Animated Illustration
                const ProjectorAnimation(size: 210),

                const SizedBox(height: 24),

                // Saved Location Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2533),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.folder_outlined, color: ColorConstants.primary, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Saved in: Movies/Clipax',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // Progress Labels & Percentage
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Creating Media',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.darkText,
                        ),
                      ),
                      Text(
                        '$percentage%',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Progress Bar with Clipax Orange Gradient
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: ColorConstants.primaryLight.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: constraints.maxWidth * _progress.clamp(0.0, 1.0),
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                ColorConstants.primary,
                                ColorConstants.primaryDark,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: ColorConstants.primary.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                // Live status text
                Text(
                  _statusText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ColorConstants.mediumText,
                    fontWeight: FontWeight.w500,
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
                      color: ColorConstants.subTextColor,
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
