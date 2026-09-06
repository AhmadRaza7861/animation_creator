import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../projects/data/project_repository.dart';
import '../../../projects/presentation/screens/create_project_screen.dart';
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
  TemplateMode _selectedMode = TemplateMode.useTemplate;

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
    // Play loop at roughly 8 frames per second for smooth preview
    _animationTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (mounted) {
        setState(() {
          _currentFrameIndex = (_currentFrameIndex + 1) % widget.template.frameCount;
        });
      }
    });
  }

  void _navigateToCreateProject() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateProjectScreen(
          repository: widget.repository,
          template: widget.template,
          templateMode: _selectedMode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.background,
      appBar: AppBar(
        backgroundColor: ColorConstants.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: ColorConstants.darkText, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: null,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Top Animated Preview Card (Responsive height)
                          Container(
                            width: double.infinity,
                            height: (constraints.maxHeight * 0.28).clamp(130.0, 190.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F3F6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Center(
                                child: Image.asset(
                                  widget.template.frameAssets[_currentFrameIndex],
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey);
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 2. Frames list
                          const Text(
                            'Frames',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: ColorConstants.darkText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 66,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: widget.template.frameCount,
                              itemBuilder: (context, index) {
                                final isCurrent = index == _currentFrameIndex;
                                return Container(
                                  width: 62,
                                  height: 62,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F3F6),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isCurrent ? ColorConstants.primary : Colors.transparent,
                                      width: 2.0,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      widget.template.frameAssets[index],
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 3. Mode Selection
                          const Text(
                            'Mode',
                            style: TextStyle(
                              fontSize: 16,
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
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F3F6),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: _selectedMode == TemplateMode.useTemplate
                                            ? const Color(0xFF5C52E5)
                                            : Colors.transparent,
                                        width: 2.0,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          height: 48,
                                          child: Image.asset(
                                            widget.template.previewAsset,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          'Use Template',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: ColorConstants.darkText,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Draw According Template Option
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedMode = TemplateMode.drawAccordingTemplate;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F3F6),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: _selectedMode == TemplateMode.drawAccordingTemplate
                                            ? const Color(0xFF5C52E5)
                                            : Colors.transparent,
                                        width: 2.0,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          height: 48,
                                          child: Opacity(
                                            opacity: 0.3,
                                            child: Image.asset(
                                              widget.template.previewAsset,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          'Draw According Template',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: ColorConstants.darkText,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // 4. Continue Button (Always fits comfortably at bottom)
                      Padding(
                        padding: const EdgeInsets.only(top: 14.0, bottom: 6.0),
                        child: PrimaryButton(
                          text: 'Continue',
                          onPressed: _navigateToCreateProject,
                          backgroundColor: const Color(0xFF5C52E5),
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
}
