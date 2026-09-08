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
  double _playbackSpeed = 1.0; // 0.5x, 1.0x, 2.0x
  TemplateMode _selectedMode = TemplateMode.drawAccordingTemplate;
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

    final int intervalMs = (140 / _playbackSpeed).round().clamp(40, 500);
    _animationTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
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

  void _stepForward() {
    setState(() {
      _isPlaying = false;
      _currentFrameIndex = (_currentFrameIndex + 1) % widget.template.frameCount;
    });
  }

  void _stepBackward() {
    setState(() {
      _isPlaying = false;
      _currentFrameIndex = (_currentFrameIndex - 1 + widget.template.frameCount) % widget.template.frameCount;
    });
  }

  void _setSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
    _startAnimationLoop();
  }

  void _cycleSpeed() {
    if (_playbackSpeed == 1.0) {
      _setSpeed(2.0);
    } else if (_playbackSpeed == 2.0) {
      _setSpeed(0.5);
    } else {
      _setSpeed(1.0);
    }
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
          child: AlertDialog(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
            content: Row(
              children: [
                const CircularProgressIndicator(color: ColorConstants.primary),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    'Opening ${widget.template.name}...',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: ColorConstants.darkText),
                  ),
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
        // - layer_0: Stencil Guide (the lesson artwork at 0.28 opacity, locked, isGuide)
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
            lMap['isGuide'] = true; // Excluded from export
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
          cMap['activeLayerId'] = 'layer_1';
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

  Map<String, dynamic>? _getDisplayCanvas(Map<String, dynamic>? rawCanvas) {
    if (rawCanvas == null) return null;
    if (_selectedMode == TemplateMode.useTemplate) return rawCanvas;

    final cMap = Map<String, dynamic>.from(rawCanvas);
    final layers = (cMap['layers'] as List<dynamic>?) ?? [];
    final updatedLayers = [];

    for (final l in layers) {
      final lMap = Map<String, dynamic>.from(l as Map<String, dynamic>);
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
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F5F8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: ColorConstants.darkText, size: 16),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
          ),
        ),
        title: Text(
          widget.template.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: ColorConstants.darkText,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ColorConstants.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, size: 13, color: ColorConstants.primary),
                const SizedBox(width: 4),
                Text(
                  '~${widget.template.estimatedMinutes}m',
                  style: const TextStyle(
                    color: ColorConstants.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Interactive Studio Playback Stage
              _buildStudioPlaybackStage(activeCanvas),
              const SizedBox(height: 16),

              // 2. Overview / Principle Description Card
              _buildLessonOverviewCard(),
              const SizedBox(height: 16),

              // 3. Film-Strip Frame Scrubber
              _buildFrameScrubberStrip(),
              const SizedBox(height: 18),

              // 4. Learning Mode Selector (Guided Stencil vs Full Template)
              _buildLearningModeSelector(),
              const SizedBox(height: 24),

              // 5. Start Action Button
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: PrimaryButton(
                  text: _selectedMode == TemplateMode.drawAccordingTemplate
                      ? 'Start Guided Practice in Studio 🚀'
                      : 'Load Complete Artwork in Studio 🎨',
                  icon: Icons.draw_rounded,
                  height: 54,
                  borderRadius: 16,
                  onPressed: _startLesson,
                  isLoading: _isCreating,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Interactive Studio Playback Stage
  Widget _buildStudioPlaybackStage(Map<String, dynamic>? activeCanvas) {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFEEF0F5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B1D28).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Stack(
          children: [
            // Clean Vector Canvas Preview
            Positioned.fill(
              child: CustomPaint(
                painter: TutorialVectorPainter(
                  canvasData: activeCanvas,
                  showGrid: false,
                ),
              ),
            ),

            // Top Bar: Category Tag & Mode Badge
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: ColorConstants.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.template.category.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: ColorConstants.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _selectedMode == TemplateMode.drawAccordingTemplate
                          ? const Color(0xFF1E1B24)
                          : ColorConstants.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _selectedMode == TemplateMode.drawAccordingTemplate
                          ? '✏️ STENCIL GUIDE'
                          : '🎨 EDITABLE ART',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Playback Floating Control Bar (FittedBox to prevent any overflow on large numbers)
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Transport Buttons: Step Back, Play/Pause, Step Forward
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Step Back Button
                          IconButton(
                            icon: const Icon(Icons.skip_previous_rounded, size: 20, color: ColorConstants.darkText),
                            onPressed: _stepBackward,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            splashRadius: 16,
                          ),
                          const SizedBox(width: 2),

                          // Play/Pause Button
                          GestureDetector(
                            onTap: _togglePlayPause,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: ColorConstants.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: ColorConstants.primary.withValues(alpha: 0.3),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),

                          // Step Forward Button
                          IconButton(
                            icon: const Icon(Icons.skip_next_rounded, size: 20, color: ColorConstants.darkText),
                            onPressed: _stepForward,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            splashRadius: 16,
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),

                      // Frame Indicator Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Frame ${_currentFrameIndex + 1}/${widget.template.frameCount}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: ColorConstants.darkText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Playback Speed Toggle Pill (0.5x / 1.0x / 2.0x)
                      GestureDetector(
                        onTap: _cycleSpeed,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _playbackSpeed != 1.0
                                ? ColorConstants.primary
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _playbackSpeed != 1.0
                                  ? ColorConstants.primary
                                  : const Color(0xFFE2E8F0),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.speed_rounded,
                                size: 13,
                                color: _playbackSpeed != 1.0 ? Colors.white : ColorConstants.darkText,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${_playbackSpeed}x',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: _playbackSpeed != 1.0 ? Colors.white : ColorConstants.darkText,
                                ),
                              ),
                            ],
                          ),
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

  // 2. Overview & Principle Card
  Widget _buildLessonOverviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEF0F5), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B1D28).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildDifficultyBadge(widget.template.difficulty),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${widget.template.frameCount} Frames • 12 FPS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.mediumText,
                  ),
                ),
              ),
            ],
          ),
          if (widget.template.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.template.description,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: ColorConstants.darkText,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 3. Film-Strip Frame Scrubber
  Widget _buildFrameScrubberStrip() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.movie_creation_outlined, size: 18, color: ColorConstants.primary),
            const SizedBox(width: 6),
            const Flexible(
              child: Text(
                'Film Strip Breakdown',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: ColorConstants.darkText,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Tap frame to inspect',
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 72,
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
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 68,
                  height: 68,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isCurrent ? ColorConstants.primary : const Color(0xFFE2E8F0),
                      width: isCurrent ? 2.2 : 1.0,
                    ),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: ColorConstants.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
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
                          top: 3,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: isCurrent ? ColorConstants.primary : Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '#${index + 1}',
                              style: const TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
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
      ],
    );
  }

  // 4. Learning Mode Selector
  Widget _buildLearningModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Practice Mode',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: ColorConstants.darkText,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Guided Stencil Mode (Recommended)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMode = TemplateMode.drawAccordingTemplate;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _selectedMode == TemplateMode.drawAccordingTemplate
                        ? ColorConstants.primary.withValues(alpha: 0.06)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedMode == TemplateMode.drawAccordingTemplate
                          ? ColorConstants.primary
                          : const Color(0xFFE2E8F0),
                      width: _selectedMode == TemplateMode.drawAccordingTemplate ? 2.0 : 1.0,
                    ),
                    boxShadow: _selectedMode == TemplateMode.drawAccordingTemplate
                        ? [
                            BoxShadow(
                              color: ColorConstants.primary.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            size: 20,
                            color: _selectedMode == TemplateMode.drawAccordingTemplate
                                ? ColorConstants.primary
                                : ColorConstants.mediumText,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Guided Stencil',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _selectedMode == TemplateMode.drawAccordingTemplate
                                  ? ColorConstants.primary
                                  : ColorConstants.darkText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Trace ghost timing guides on your fresh layer (Best for learning)',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.grey.shade600,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Full Template Option
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMode = TemplateMode.useTemplate;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _selectedMode == TemplateMode.useTemplate
                        ? ColorConstants.primary.withValues(alpha: 0.06)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedMode == TemplateMode.useTemplate
                          ? ColorConstants.primary
                          : const Color(0xFFE2E8F0),
                      width: _selectedMode == TemplateMode.useTemplate ? 2.0 : 1.0,
                    ),
                    boxShadow: _selectedMode == TemplateMode.useTemplate
                        ? [
                            BoxShadow(
                              color: ColorConstants.primary.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
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
                            size: 20,
                            color: _selectedMode == TemplateMode.useTemplate
                                ? ColorConstants.primary
                                : ColorConstants.mediumText,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Full Artwork',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _selectedMode == TemplateMode.useTemplate
                                  ? ColorConstants.primary
                                  : ColorConstants.darkText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Load complete editable frames to color, edit & extend',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.grey.shade600,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
