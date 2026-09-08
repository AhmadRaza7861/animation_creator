import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../data/project_repository.dart';
import '../../domain/project_model.dart';
import '../widgets/project_card.dart';
import 'create_project_screen.dart';
import '../../../templates/presentation/screens/templates_screen.dart';
import '../../../templates/presentation/screens/template_detail_screen.dart';
import '../../../templates/data/tutorials_data.dart';
import '../../../templates/data/tutorial_project_builder.dart';
import '../../../templates/domain/template_model.dart';
import '../../../editor/presentation/screens/editor_screen.dart';
import '../../../../core/widgets/animated_dashed_border.dart';

class ProjectsScreen extends StatefulWidget {
  final ProjectRepository repository;

  const ProjectsScreen({super.key, required this.repository});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<ProjectMeta> _projects = [];
  List<TemplateModel> _featuredTemplates = [];
  bool _isLoading = true;
  int _currentTab = 0; // 0: Home, 1: Projects

  // Projects search state
  String _projectSearchQuery = '';
  final TextEditingController _projectSearchController = TextEditingController();

  // Animation ticker for tutorial cards live frames
  int _animFrameTick = 0;
  Timer? _previewTicker;

  @override
  void initState() {
    super.initState();
    _loadData();
    _previewTicker = Timer.periodic(const Duration(milliseconds: 140), (t) {
      if (mounted) {
        setState(() => _animFrameTick++);
      }
    });
  }

  @override
  void dispose() {
    _previewTicker?.cancel();
    _projectSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadProjectsInternal(),
      _loadFeaturedTutorials(),
    ]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProjectsInternal() async {
    final projects = await widget.repository.listProjects();
    if (mounted) {
      _projects = projects;
    }
  }

  Future<void> _loadProjects() async {
    final projects = await widget.repository.listProjects();
    if (mounted) {
      setState(() {
        _projects = projects;
      });
    }
  }

  Future<void> _loadFeaturedTutorials() async {
    try {
      final all = await TutorialsData.loadAllTutorials();
      if (mounted) {
        // Pick 6 great diverse tutorials for Home
        final ids = [
          'bouncing_ball',
          'squash_and_stretch',
          'pendulum_swing',
          'walk_cycle',
          'water_drop_and_splash',
          'morphing_shapes',
        ];
        _featuredTemplates = all.where((t) => ids.contains(t.id)).toList();
        if (_featuredTemplates.isEmpty && all.isNotEmpty) {
          _featuredTemplates = all.take(6).toList();
        }
      }
    } catch (e) {
      debugPrint('Error loading featured tutorials: $e');
    }
  }

  void _createNewProject() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateProjectScreen(
          repository: widget.repository,
        ),
      ),
    ).then((_) => _loadProjects());
  }

  void _openProject(ProjectMeta project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditorScreen(
          projectId: project.id,
        ),
      ),
    ).then((_) => _loadProjects());
  }

  void _openTutorial(TemplateModel template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TemplateDetailScreen(
          repository: widget.repository,
          template: template,
        ),
      ),
    ).then((_) => _loadProjects());
  }

  void _openTemplatesLibrary() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TemplatesScreen(
          repository: widget.repository,
        ),
      ),
    ).then((_) => _loadProjects());
  }

  Future<void> _renameProject(ProjectMeta project) async {
    final controller = TextEditingController(text: project.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Rename Project',
          style: TextStyle(fontWeight: FontWeight.bold, color: ColorConstants.darkText),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'New Title',
            labelStyle: TextStyle(color: ColorConstants.primary),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: ColorConstants.primary, width: 2),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.trim().isNotEmpty) {
      try {
        final projectData = await widget.repository.loadProject(project.id);
        if (projectData != null) {
          await widget.repository.saveProject(
            projectId: project.id,
            title: newTitle.trim(),
            state: projectData.state,
            thumbnailBytes: null,
          );
        }
      } catch (e) {
        debugPrint('Error renaming project: $e');
      }
      _loadProjects();
    }
  }

  Future<void> _duplicateProject(ProjectMeta project) async {
    try {
      final projectData = await widget.repository.loadProject(project.id);
      if (projectData != null) {
        List<int>? thumbnailBytes;
        if (project.thumbnailPath != null) {
          final thumbFile = File(project.thumbnailPath!);
          if (await thumbFile.exists()) {
            thumbnailBytes = await thumbFile.readAsBytes();
          }
        }
        await widget.repository.saveProject(
          projectId: null,
          title: '${project.title} (Copy)',
          state: projectData.state,
          thumbnailBytes: thumbnailBytes,
        );
      }
    } catch (e) {
      debugPrint('Error duplicating project: $e');
    }
    _loadProjects();
  }

  Future<void> _deleteProject(ProjectMeta project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Delete Project?',
          style: TextStyle(fontWeight: FontWeight.bold, color: ColorConstants.darkText),
        ),
        content: Text('Are you sure you want to delete "${project.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.repository.deleteProject(project.id);
      _loadProjects();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: ColorConstants.primary),
              )
            : (_currentTab == 0 ? _buildHomeTab() : _buildProjectsTab()),
      ),
      floatingActionButton: SizedBox(
        width: 60,
        height: 60,
        child: FloatingActionButton(
          onPressed: _createNewProject,
          backgroundColor: ColorConstants.primary,
          elevation: 6,
          shape: const CircleBorder(),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 34,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        height: 72,
        color: Colors.white,
        elevation: 16,
        padding: EdgeInsets.zero,
        surfaceTintColor: Colors.white,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Color(0xFFEEF0F6),
                width: 1.2,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 42.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Home Tab
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  setState(() {
                    _currentTab = 0;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.home_rounded,
                        color: _currentTab == 0 ? ColorConstants.primary : const Color(0xFFB0A9B8),
                        size: 26,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        StringConstants.homeTab,
                        style: TextStyle(
                          color: _currentTab == 0 ? ColorConstants.primary : const Color(0xFFB0A9B8),
                          fontSize: 11,
                          fontWeight: _currentTab == 0 ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 48), // Gap for central FAB
              // Projects Tab
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  setState(() {
                    _currentTab = 1;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_rounded,
                        color: _currentTab == 1 ? ColorConstants.primary : const Color(0xFFB0A9B8),
                        size: 26,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        StringConstants.projectsTab,
                        style: TextStyle(
                          color: _currentTab == 1 ? ColorConstants.primary : const Color(0xFFB0A9B8),
                          fontSize: 11,
                          fontWeight: _currentTab == 1 ? FontWeight.w800 : FontWeight.w600,
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
    );
  }

  // ==========================================
  // HOME TAB
  // ==========================================
  Widget _buildHomeTab() {
    final recentProjects = _projects.take(4).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      color: ColorConstants.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0, bottom: 96.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Row (Brand Title + Get Pro + Info)
            _buildHomeHeader(),
            const SizedBox(height: 18),

            // 2. Hero Quick-Create Banner
            _buildHeroBanner(),
            const SizedBox(height: 22),

            // 3. Featured Tutorials & Academy Carousel
            _buildFeaturedTutorialsSection(),
            const SizedBox(height: 24),

            // 4. Recent Projects Section
            _buildRecentProjectsSection(recentProjects),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'clip',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: ColorConstants.darkText,
                    letterSpacing: -1.0,
                  ),
                ),
                ShaderMask(
                  shaderCallback: (bounds) {
                    return const LinearGradient(
                      colors: [
                        ColorConstants.primary,
                        Color(0xFFFFB038),
                      ],
                    ).createShader(bounds);
                  },
                  child: const Text(
                    'ax',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1.0,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: ColorConstants.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Text(
              'Where ideas turn into motion ✨',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: ColorConstants.mediumText,
              ),
            ),
          ],
        ),
        const Spacer(),

        // Get Pro Button
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('👑 Clipax Pro features unlocking soon!'),
                backgroundColor: ColorConstants.primary,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: ColorConstants.primary.withValues(alpha: 0.6),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: ColorConstants.primary.withValues(alpha: 0.10),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Get Pro',
                  style: TextStyle(
                    color: ColorConstants.darkText,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  '👑',
                  style: TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF9318),
            Color(0xFFFF7A1A),
            Color(0xFFFF5E28),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9318).withValues(alpha: 0.32),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background subtle decorative pattern circles
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -30,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'STUDIO CANVAS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Start Animating',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Draw frame by frame, animate ideas effortlessly with 110+ brushes.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 12.5,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.draw_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Action buttons row
                Row(
                  children: [
                    // New Project Button
                    GestureDetector(
                      onTap: _createNewProject,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_circle_rounded,
                              color: ColorConstants.primary,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'New Project',
                              style: TextStyle(
                                color: ColorConstants.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Explore Templates Button
                    GestureDetector(
                      onTap: _openTemplatesLibrary,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.40),
                            width: 1.0,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Templates',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedTutorialsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            const Icon(
              Icons.school_rounded,
              color: ColorConstants.primary,
              size: 20,
            ),
            const SizedBox(width: 6),
            const Text(
              'Animation Academy',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: ColorConstants.darkText,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _openTemplatesLibrary,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ColorConstants.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'See All (22)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ColorConstants.primary,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: ColorConstants.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Master professional frame-by-frame animation principles',
          style: TextStyle(
            fontSize: 12.5,
            color: ColorConstants.mediumText,
          ),
        ),
        const SizedBox(height: 14),

        // Horizontal Carousel
        if (_featuredTemplates.isEmpty)
          Container(
            height: 170,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEEF0F5)),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: ColorConstants.primary),
            ),
          )
        else
          SizedBox(
            height: 195,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _featuredTemplates.length,
              separatorBuilder: (c, i) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final template = _featuredTemplates[index];
                return _buildFeaturedTutorialCard(template);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFeaturedTutorialCard(TemplateModel template) {
    final canvases = (template.projectState?['canvases'] as List?) ?? [];
    Map<String, dynamic>? currentCanvas;
    if (canvases.isNotEmpty) {
      final frameIdx = _animFrameTick % canvases.length;
      currentCanvas = canvases[frameIdx] as Map<String, dynamic>?;
    }

    return GestureDetector(
      onTap: () => _openTutorial(template),
      child: Container(
        width: 190,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEEF0F5), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B1D28).withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Preview Canvas Box
            Container(
              height: 105,
              decoration: const BoxDecoration(
                color: Color(0xFFFAFBFD),
                borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF1F3F7), width: 1.0),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (currentCanvas != null)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                      child: CustomPaint(
                        painter: TutorialVectorPainter(
                          canvasData: currentCanvas,
                          showGrid: false,
                        ),
                      ),
                    )
                  else
                    const Center(
                      child: Icon(Icons.motion_photos_on_rounded, color: ColorConstants.primary, size: 36),
                    ),

                  // Frame count pill
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${template.frameCount} frames',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Difficulty pill
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildDifficultyBadge(template.difficulty),
                  ),
                ],
              ),
            ),

            // Bottom Info
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: ColorConstants.darkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    template.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: ColorConstants.mediumText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 12, color: ColorConstants.primary),
                      const SizedBox(width: 3),
                      Text(
                        '~${template.estimatedMinutes} min',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: ColorConstants.primary,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Practice →',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: ColorConstants.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildRecentProjectsSection(List<ProjectMeta> recentProjects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            const Icon(
              Icons.history_rounded,
              color: ColorConstants.primary,
              size: 20,
            ),
            const SizedBox(width: 6),
            const Text(
              'Recent Projects',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: ColorConstants.darkText,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            if (_projects.isNotEmpty)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentTab = 1;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ColorConstants.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All (${_projects.length})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ColorConstants.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: ColorConstants.primary,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        // Recent Projects Content
        if (recentProjects.isEmpty)
          _buildEmptyState()
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentProjects.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, index) {
              final project = recentProjects[index];
              return ProjectCard(
                project: project,
                onTap: () => _openProject(project),
                onRename: () => _renameProject(project),
                onDuplicate: () => _duplicateProject(project),
                onDelete: () => _deleteProject(project),
              );
            },
          ),
      ],
    );
  }

  // ==========================================
  // PROJECTS TAB (ALL PROJECTS)
  // ==========================================
  Widget _buildProjectsTab() {
    final filteredProjects = _projectSearchQuery.trim().isEmpty
        ? _projects
        : _projects
            .where((p) => p.title.toLowerCase().contains(_projectSearchQuery.toLowerCase()))
            .toList();

    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'All Projects',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: ColorConstants.darkText,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_projects.length} animations in your studio',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: ColorConstants.mediumText,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Quick New Project Button
              GestureDetector(
                onTap: _createNewProject,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: ColorConstants.primary,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: ColorConstants.primary.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Create',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEEF0F6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _projectSearchController,
              onChanged: (val) {
                setState(() => _projectSearchQuery = val);
              },
              decoration: InputDecoration(
                hintText: 'Search projects by name...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(Icons.search_rounded, color: ColorConstants.mediumText, size: 20),
                suffixIcon: _projectSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16, color: Colors.grey),
                        onPressed: () {
                          _projectSearchController.clear();
                          setState(() => _projectSearchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Projects grid or empty state
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadProjects,
              color: ColorConstants.primary,
              child: filteredProjects.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: _buildEmptyState(
                        isSearching: _projectSearchQuery.trim().isNotEmpty,
                      ),
                    )
                  : GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: filteredProjects.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.78,
                      ),
                      itemBuilder: (context, index) {
                        final project = filteredProjects[index];
                        return ProjectCard(
                          project: project,
                          onTap: () => _openProject(project),
                          onRename: () => _renameProject(project),
                          onDuplicate: () => _duplicateProject(project),
                          onDelete: () => _deleteProject(project),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({bool isSearching = false}) {
    return AnimatedDashedBorder(
      color: const Color(0xFFFFD4A3),
      strokeWidth: 1.5,
      dashLength: 8,
      dashGap: 6,
      borderRadius: 24,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 20.0),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFF7ED),
                ),
                child: Center(
                  child: Icon(
                    isSearching ? Icons.search_off_rounded : Icons.folder_open_outlined,
                    color: const Color(0xFFFFB054),
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isSearching ? 'No Matching Projects' : 'No Projects Yet',
                style: const TextStyle(
                  color: ColorConstants.darkText,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isSearching
                    ? 'Try searching with a different keyword'
                    : 'Start your creative journey — tap below to create your first animation!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ColorConstants.mediumText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
              if (!isSearching) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _createNewProject,
                  icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                  label: const Text(
                    'Create Animation',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
