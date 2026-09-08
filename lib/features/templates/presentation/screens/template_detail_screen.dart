import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../projects/data/project_repository.dart';
import '../../../editor/presentation/screens/editor_screen.dart';
import '../../data/tutorial_project_builder.dart';
import '../../domain/template_model.dart';
import '../../../../core/widgets/primary_button.dart';

class TemplateDetailScreen extends StatefulWidget {
  final ProjectRepository repository;
  final TemplateModel template;

  const TemplateDetailScreen({
    super.key,
    required this.repository,
    required this.template,
  });

  @override
  State<TemplateDetailScreen> createState() => _TemplateDetailScreenState();
}

class _TemplateDetailScreenState extends State<TemplateDetailScreen> {
  int _currentFrameIndex = 0;
  Timer? _animationTimer;
  bool _isPlaying = true;
  TemplateMode _selectedMode = TemplateMode.useTemplate;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _startAnimationLoop();
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  void _startAnimationLoop() {
    _animationTimer?.cancel();
    if (widget.template.frameCount <= 1) return;
    _animationTimer = Timer.periodic(const Duration(milliseconds: 140), (timer) {
      if (mounted && _isPlaying) {
        setState(() {
          _currentFrameIndex = (_currentFrameIndex + 1) % widget.template.frameCount;
        });
      }
    });
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  Future<void> _startLesson() async {
    if (_isCreating) return;
    setState(() => _isCreating = true);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => PopScope(
          canPop: false,
          child: const AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
            content: Row(
              children: [
                CircularProgressIndicator(color: ColorConstants.primary),
                SizedBox(width: 20),
                Text(
                  'Starting Lesson...',
                  style: TextStyle(fontWeight: FontWeight.bold, color: ColorConstants.darkText),
                ),
              ],
            ),
          ),
        ),
      );

      // 1. Prepare genuine vector project state
      Map<String, dynamic> baseState = widget.template.projectState != null
          ? Map<String, dynamic>.from(widget.template.projectState!)
          : TutorialProjectBuilder.buildProjectForTutorial(
              widget.template.id,
              widget.template.name,
              widget.template.frameCount,
            );

      Map<String, dynamic> stateToSave;

      if (_selectedMode == TemplateMode.drawAccordingTemplate) {
        // Guided Stencil Mode:
        // - layer_0: Stencil Guide (the lesson artwork at 0.28 opacity, locked)
        // - layer_1: Fresh Active Drawing Layer ('Your Drawing', unlocked, active)
        final canvasesList = (baseState['canvases'] as List<dynamic>?) ?? [];
        final updatedCanvases = [];

        for (final c in canvasesList) {
          final cMap = Map<String, dynamic>.from(c as Map<String, dynamic>);
          final layers = (cMap['layers'] as List<dynamic>?) ?? [];
          final updatedLayers = [];

          for (final l in layers) {
            final lMap = Map<String, dynamic>.from(l as Map<String, dynamic>);
            // Convert base artwork layer to locked semi-transparent stencil guide
            lMap['name'] = 'Stencil Guide';
            lMap['opacity'] = 0.28;
            lMap['isLocked'] = true;
            lMap['isGuide'] = true; // Editor-only guide stencil, excluded from playback & export
            updatedLayers.add(lMap);
          }

          // Add fresh empty active drawing layer for the student
          updatedLayers.add({
            'id': 'layer_1',
            'name': 'Your Drawing',
            'isVisible': true,
            'isLocked': false,
            'isGuide': false,
            'opacity': 1.0,
            'blendMode': BlendMode.srcOver.index,
            'currentIndex': 0,
            'history': <Map<String, dynamic>>[],
          });

          cMap['layers'] = updatedLayers;
          cMap['activeLayerId'] = 'layer_1'; // Focus user on their new drawing layer!
          updatedCanvases.add(cMap);
        }

        stateToSave = Map<String, dynamic>.from(baseState);
        stateToSave['canvases'] = updatedCanvases;
      } else {
        // Full Template Mode: Load complete editable artwork on layer_0
        stateToSave = Map<String, dynamic>.from(baseState);
      }

      stateToSave['enableStickers'] = true;

      // 2. Save project in local repository
      final newProjectId = await widget.repository.saveProject(
        title: widget.template.name,
        state: stateToSave,
      );

      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EditorScreen(
              projectId: newProjectId,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error starting tutorial lesson: $e');
      if (mounted) {
        Navigator.pop(context);
        setState(() => _isCreating = false);
      }
    }
  }

  /// Transforms the canvas data to preview stencil mode when selected
  Map<String, dynamic>? _getDisplayCanvas(Map<String, dynamic>? rawCanvas) {
    if (rawCanvas == null) return null;
    if (_selectedMode == TemplateMode.useTemplate) return rawCanvas;

    final cMap = Map<String, dynamic>.from(rawCanvas);
    final layers = (cMap['layers'] as List<dynamic>?) ?? [];
    final updatedLayers = [];

    for (final l in layers) {
      final lMap = Map<String, dynamic>.from(l as Map<String, dynamic>);
      // Dim drawing to onion-skin stencil in preview
      lMap['opacity'] = 0.32;
      updatedLayers.add(lMap);
    }
    cMap['layers'] = updatedLayers;
    return cMap;
  }

  @override
  Widget build(BuildContext context) {
    final rawCanvas = widget.template.getCanvasForFrame(_currentFrameIndex);
    final activeCanvas = _getDisplayCanvas(rawCanvas);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ColorConstants.border_color),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: ColorConstants.darkText, size: 16),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
          ),
        ),
        title: Text(
          widget.template.name,
          style: const TextStyle(
            color: ColorConstants.darkText,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Clean Solid White Canvas Preview Stage (No Grid Presets)
                          Container(
                            width: double.infinity,
                            height: (constraints.maxHeight * 0.32).clamp(170.0, 240.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFEEF0F5),
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(19),
                              child: Stack(
                                children: [
                                  // Clean Vector Frame Painter
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: TutorialVectorPainter(
                                        canvasData: activeCanvas,
                                        showGrid: false,
                                      ),
                                    ),
                                  ),

                                  // Play/Pause and Frame badge
                                  Positioned(
                                    bottom: 12,
                                    left: 12,
                                    child: GestureDetector(
                                      onTap: _togglePlayPause,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.94),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.06),
                                              blurRadius: 4,
                                            )
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                              size: 16,
                                              color: ColorConstants.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Frame ${_currentFrameIndex + 1}/${widget.template.frameCount}',
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
                                                color: ColorConstants.darkText,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Top Right: Mode Badge & Category
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_selectedMode == TemplateMode.drawAccordingTemplate)
                                          Container(
                                            margin: const EdgeInsets.only(right: 6),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1E1B24),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              '✏️ STENCIL MODE',
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: ColorConstants.primaryLight,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            widget.template.category,
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              color: ColorConstants.primaryDark,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 2. Overview / Principle Description
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFEEF0F5)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _buildDifficultyBadge(widget.template.difficulty),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${widget.template.frameCount} Frames • 12 FPS',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: ColorConstants.subTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                                if (widget.template.description.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    widget.template.description,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: ColorConstants.darkText,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 3. Frame scrubber strip
                          const Text(
                            'Lesson Frames',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: ColorConstants.darkText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 62,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: widget.template.frameCount,
                              itemBuilder: (context, index) {
                                final isCurrent = index == _currentFrameIndex;
                                final rawFrameCanvas = widget.template.getCanvasForFrame(index);
                                final frameCanvas = _getDisplayCanvas(rawFrameCanvas);

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _currentFrameIndex = index;
                                      _isPlaying = false;
                                    });
                                  },
                                  child: Container(
                                    width: 62,
                                    height: 62,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isCurrent ? ColorConstants.primary : const Color(0xFFE2E8F0),
                                        width: isCurrent ? 2.0 : 1.0,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
                                            child: CustomPaint(
                                              painter: TutorialVectorPainter(
                                                canvasData: frameCanvas,
                                                showGrid: false,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 2,
                                            left: 4,
                                            child: Text(
                                              '#${index + 1}',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: isCurrent ? ColorConstants.primary : ColorConstants.subTextColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 4. Learning Mode Selection
                          const Text(
                            'Learning Mode',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: ColorConstants.darkText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Use Template Option
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedMode = TemplateMode.useTemplate;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                                    decoration: BoxDecoration(
                                      color: _selectedMode == TemplateMode.useTemplate
                                          ? ColorConstants.primaryLight.withValues(alpha: 0.4)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: _selectedMode == TemplateMode.useTemplate
                                            ? ColorConstants.primary
                                            : const Color(0xFFE2E8F0),
                                        width: _selectedMode == TemplateMode.useTemplate ? 1.8 : 1.0,
                                      ),
                                      boxShadow: _selectedMode == TemplateMode.useTemplate
                                          ? [
                                              BoxShadow(
                                                color: ColorConstants.primary.withValues(alpha: 0.12),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              )
                                            ]
                                          : [],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.layers_rounded,
                                              size: 16,
                                              color: _selectedMode == TemplateMode.useTemplate
                                                  ? ColorConstants.primary
                                                  : ColorConstants.subTextColor,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Full Template',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.bold,
                                                color: _selectedMode == TemplateMode.useTemplate
                                                    ? ColorConstants.primary
                                                    : ColorConstants.darkText,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        const Text(
                                          'Editable complete art frames',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: ColorConstants.subTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Guided Stencil Option
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedMode = TemplateMode.drawAccordingTemplate;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                                    decoration: BoxDecoration(
                                      color: _selectedMode == TemplateMode.drawAccordingTemplate
                                          ? ColorConstants.primaryLight.withValues(alpha: 0.4)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: _selectedMode == TemplateMode.drawAccordingTemplate
                                            ? ColorConstants.primary
                                            : const Color(0xFFE2E8F0),
                                        width: _selectedMode == TemplateMode.drawAccordingTemplate ? 1.8 : 1.0,
                                      ),
                                      boxShadow: _selectedMode == TemplateMode.drawAccordingTemplate
                                          ? [
                                              BoxShadow(
                                                color: ColorConstants.primary.withValues(alpha: 0.12),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              )
                                            ]
                                          : [],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.brush_rounded,
                                              size: 16,
                                              color: _selectedMode == TemplateMode.drawAccordingTemplate
                                                  ? ColorConstants.primary
                                                  : ColorConstants.subTextColor,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Guided Stencil',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.bold,
                                                color: _selectedMode == TemplateMode.drawAccordingTemplate
                                                    ? ColorConstants.primary
                                                    : ColorConstants.darkText,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        const Text(
                                          'Trace onion-skin timing guides',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: ColorConstants.subTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),

                      // 5. Bottom Action Button
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
                        child: PrimaryButton(
                          text: _selectedMode == TemplateMode.drawAccordingTemplate
                              ? 'Start Guided Practice in Editor'
                              : 'Start Lesson in Editor',
                          icon: Icons.edit_rounded,
                          height: 52,
                          borderRadius: 14,
                          onPressed: _startLesson,
                          isLoading: _isCreating,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(TutorialDifficulty difficulty) {
    Color bg;
    Color text;
    String label;

    switch (difficulty) {
      case TutorialDifficulty.beginner:
        bg = const Color(0xFFE8F5E9);
        text = const Color(0xFF2E7D32);
        label = 'Beginner';
        break;
      case TutorialDifficulty.intermediate:
        bg = ColorConstants.primaryLight;
        text = ColorConstants.primaryDark;
        label = 'Medium';
        break;
      case TutorialDifficulty.advanced:
        bg = const Color(0xFFFFEBEE);
        text = const Color(0xFFC62828);
        label = 'Master';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
