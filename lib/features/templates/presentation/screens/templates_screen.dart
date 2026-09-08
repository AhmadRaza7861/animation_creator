import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../projects/data/project_repository.dart';
import '../../../editor/presentation/screens/editor_screen.dart';
import '../../data/tutorials_data.dart';
import '../../data/tutorial_project_builder.dart';
import '../../domain/template_model.dart';
import 'template_detail_screen.dart';

class TemplatesScreen extends StatefulWidget {
  final ProjectRepository repository;

  const TemplatesScreen({super.key, required this.repository});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  List<TemplateModel> _allTemplates = [];
  bool _loading = true;

  // Search & Filter State
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All'; // 'All', 'Animation Basics', 'The 12 Principles', 'Master Practice'
  TutorialDifficulty? _selectedDifficulty; // null = All, beginner, intermediate

  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

  // Live preview timer for card thumbnails
  int _animFrameTick = 0;
  Timer? _previewTicker;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
    _scrollController.addListener(_onScroll);
    _previewTicker = Timer.periodic(const Duration(milliseconds: 130), (t) {
      if (mounted) {
        setState(() => _animFrameTick++);
      }
    });
  }

  @override
  void dispose() {
    _previewTicker?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 250 && !_showBackToTop) {
      setState(() => _showBackToTop = true);
    } else if (_scrollController.offset <= 250 && _showBackToTop) {
      setState(() => _showBackToTop = false);
    }
  }

  Future<void> _loadTemplates() async {
    try {
      final templates = await TutorialsData.loadAllTutorials();
      if (mounted) {
        setState(() {
          _allTemplates = templates;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading tutorials: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  List<TemplateModel> _getFilteredTemplates() {
    return _allTemplates.where((t) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = t.name.toLowerCase().contains(q);
        final matchDesc = t.description.toLowerCase().contains(q);
        if (!matchTitle && !matchDesc) return false;
      }

      // Category filter
      if (_selectedCategory != 'All' && t.category != _selectedCategory) {
        return false;
      }

      // Difficulty filter
      if (_selectedDifficulty != null && t.difficulty != _selectedDifficulty) {
        return false;
      }

      return true;
    }).toList();
  }

  Future<void> _quickStartTutorial(TemplateModel template) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Row(
              children: [
                const CircularProgressIndicator(color: ColorConstants.primary),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    'Loading ${template.name}...',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: ColorConstants.darkText),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final stateToSave = template.projectState ??
          TutorialProjectBuilder.buildProjectForTutorial(template.id, template.name, template.frameCount);

      final newProjectId = await widget.repository.saveProject(
        title: template.name,
        state: stateToSave,
      );

      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditorScreen(projectId: newProjectId),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error quick starting tutorial: $e');
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTemplates = _getFilteredTemplates();
    final featuredTemplate = _allTemplates.isNotEmpty ? _allTemplates.first : null;

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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: ColorConstants.darkText, size: 16),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
          ),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: ColorConstants.darkText, fontSize: 16, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  hintText: 'Search lessons (e.g., ball, wave, timing)...',
                  hintStyle: TextStyle(color: ColorConstants.subTextColor, fontSize: 14),
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
              )
            : const Text(
                'Tutorials',
                style: TextStyle(
                  color: ColorConstants.darkText,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ColorConstants.border_color),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                _isSearching ? Icons.close_rounded : Icons.search_rounded,
                color: ColorConstants.darkText,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  if (_isSearching) {
                    _isSearching = false;
                    _searchQuery = '';
                    _searchController.clear();
                  } else {
                    _isSearching = true;
                  }
                });
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: ColorConstants.primary))
            : CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. Featured Lesson Card (Clean Warm App Theme)
                  if (!_isSearching && featuredTemplate != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                        child: _buildFeaturedCard(featuredTemplate),
                      ),
                    ),

                  // 2. Category & Difficulty Filter Tabs
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Tabs
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                _buildCategoryTab('All', label: 'All Lessons'),
                                const SizedBox(width: 8),
                                _buildCategoryTab(
                                  TutorialsData.categoryAnimationBasics,
                                  label: 'Fundamentals',
                                ),
                                const SizedBox(width: 8),
                                _buildCategoryTab(
                                  TutorialsData.categoryThe12Principles,
                                  label: '12 Principles',
                                ),
                                const SizedBox(width: 8),
                                _buildCategoryTab(
                                  TutorialsData.categoryMasterPractice,
                                  label: 'Master Practice',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Difficulty Filter Row
                          Row(
                            children: [
                              _buildDifficultyFilter(null, 'All Levels'),
                              const SizedBox(width: 6),
                              _buildDifficultyFilter(TutorialDifficulty.beginner, '🟢 Beginner (Few frames)'),
                              const SizedBox(width: 6),
                              _buildDifficultyFilter(TutorialDifficulty.intermediate, '🟠 Medium'),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Count Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${filteredTemplates.length} Lessons Available',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: ColorConstants.darkText,
                                ),
                              ),
                              Text(
                                'Tap to practice',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: ColorConstants.subTextColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),

                  // 3. Lesson Cards (Clean 2-Column Grid or List)
                  if (filteredTemplates.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.palette_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No lessons match "$_searchQuery"',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: ColorConstants.subTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final template = filteredTemplates[index];
                            return _buildCleanLessonCard(template);
                          },
                          childCount: filteredTemplates.length,
                        ),
                      ),
                    ),
                ],
              ),
      ),
      floatingActionButton: _showBackToTop
          ? FloatingActionButton.small(
              onPressed: _scrollToTop,
              backgroundColor: Colors.white,
              elevation: 3,
              shape: const CircleBorder(),
              child: const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: ColorConstants.primary,
                size: 24,
              ),
            )
          : null,
    );
  }

  // Clean Featured Lesson Card in App Theme
  Widget _buildFeaturedCard(TemplateModel template) {
    final frameIndex = _animFrameTick % template.frameCount;
    final liveCanvas = template.getCanvasForFrame(frameIndex);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ColorConstants.primary.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.primary.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ColorConstants.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'FEATURED LESSON',
                    style: TextStyle(
                      color: ColorConstants.primaryDark,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  template.name,
                  style: const TextStyle(
                    color: ColorConstants.darkText,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  template.description,
                  style: const TextStyle(
                    color: ColorConstants.subTextColor,
                    fontSize: 12,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _quickStartTutorial(template),
                      icon: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                      label: const Text(
                        'Start Lesson',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstants.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${template.frameCount} frames',
                      style: const TextStyle(
                        color: ColorConstants.mediumText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Clean Pure Solid White Canvas Preview
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEEF0F5), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: CustomPaint(
                painter: TutorialVectorPainter(
                  canvasData: liveCanvas,
                  showGrid: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(String category, {required String label}) {
    final bool isSelected = _selectedCategory == category;

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? ColorConstants.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? ColorConstants.primary : ColorConstants.border_color,
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: ColorConstants.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : ColorConstants.darkText,
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyFilter(TutorialDifficulty? difficulty, String label) {
    final bool isSelected = _selectedDifficulty == difficulty;

    return GestureDetector(
      onTap: () => setState(() => _selectedDifficulty = difficulty),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? ColorConstants.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isSelected ? ColorConstants.primary : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? ColorConstants.primaryDark : ColorConstants.subTextColor,
          ),
        ),
      ),
    );
  }

  /// Clean, simple and attractive card in app theme with solid white preview
  Widget _buildCleanLessonCard(TemplateModel template) {
    final frameIndex = _animFrameTick % template.frameCount;
    final currentCanvas = template.getCanvasForFrame(frameIndex);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF0F5), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B1D28).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TemplateDetailScreen(
                  repository: widget.repository,
                  template: template,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // 1. Clean Solid White Live Vector Preview (No Grid Presets)
                Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE8EAF0), width: 1.0),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: CustomPaint(
                          painter: TutorialVectorPainter(
                            canvasData: currentCanvas,
                            showGrid: false,
                          ),
                        ),
                      ),
                    ),
                    // Frame count badge on bottom right
                    Positioned(
                      bottom: 3,
                      right: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xD91E1B24),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '${template.frameCount}f',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // 2. Lesson Title, Category, and Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          _buildDifficultyTag(template.difficulty),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              template.category,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: ColorConstants.subTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        template.name,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.darkText,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        template.description,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: ColorConstants.subTextColor,
                          height: 1.25,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // 3. Draw Action Button (Orange Theme)
                ElevatedButton.icon(
                  onPressed: () => _quickStartTutorial(template),
                  icon: const Icon(Icons.edit_rounded, size: 13, color: Colors.white),
                  label: const Text(
                    'Draw',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyTag(TutorialDifficulty difficulty) {
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
