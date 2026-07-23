import 'dart:async';
import 'package:flutter/material.dart';
import '../repositories/project_repository.dart';
import 'templates_screen.dart';
import 'create_project_screen.dart';

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF3C3043), size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Animated Preview Card
              Container(
                width: double.infinity,
                height: 240,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F6),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Center(
                    child: Image.asset(
                      widget.template.frameAssets[_currentFrameIndex],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.broken_image_rounded, size: 64, color: Colors.grey);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Frames list
              const Text(
                'Frames',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3C3043),
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 84,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.template.frameCount,
                  itemBuilder: (context, index) {
                    final isCurrent = index == _currentFrameIndex;
                    return Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCurrent ? const Color(0xFFFF9114) : Colors.transparent,
                          width: 2.0,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          widget.template.frameAssets[index],
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // 3. Mode Selection
              const Text(
                'Mode',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3C3043),
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 12),
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
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F3F6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _selectedMode == TemplateMode.useTemplate
                                ? const Color(0xFF5C52E5)
                                : Colors.transparent,
                            width: 2.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Image.asset(
                                widget.template.previewAsset,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Use Template',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3C3043),
                                fontFamily: 'Outfit',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Draw According Template Option
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMode = TemplateMode.drawAccordingTemplate;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F3F6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _selectedMode == TemplateMode.drawAccordingTemplate
                                ? const Color(0xFF5C52E5)
                                : Colors.transparent,
                            width: 2.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Opacity(
                                opacity: 0.3,
                                child: Image.asset(
                                  widget.template.previewAsset,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Draw According Template',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3C3043),
                                fontFamily: 'Outfit',
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
              const SizedBox(height: 36),

              // 4. Continue Button
              ElevatedButton(
                onPressed: _navigateToCreateProject,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C52E5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 54),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Outfit',
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
