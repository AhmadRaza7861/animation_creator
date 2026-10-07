import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../projects/data/project_repository.dart';
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
  final ValueNotifier<bool> _showBackToTop = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _loadTemplates();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _showBackToTop.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final shouldShow = _scrollController.hasClients && _scrollController.offset > 250;
    if (_showBackToTop.value != shouldShow) {
      _showBackToTop.value = shouldShow;
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


  void _openDetail(TemplateModel template) async {
    final projectId = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => TemplateDetailScreen(
          repository: widget.repository,
          template: template,
        ),
      ),
    );
    if (projectId != null && mounted) {
      Navigator.pop(context, projectId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTemplates = _getFilteredTemplates();
    final featuredTemplate = _allTemplates.isNotEmpty
        ? _allTemplates.firstWhere((t) => t.id == 'bouncing_ball', orElse: () => _allTemplates.first)
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AppBackButton(),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: ColorConstants.darkText, fontSize: 15, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: context.tr('searchLessonsHint'),
                  hintStyle: const TextStyle(color: ColorConstants.mediumText, fontSize: 13.5),
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.school_rounded, color: ColorConstants.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('animationAcademy'),
                    style: const TextStyle(
                      color: ColorConstants.darkText,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5F8),
              borderRadius: BorderRadius.circular(12),
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
                  // 1. Featured Spotlight Lesson Card
                  if (!_isSearching && featuredTemplate != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                        child: _buildFeaturedSpotlightCard(featuredTemplate),
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
                                _buildCategoryTab('All', label: '✨ ${context.tr('catAll')}'),
                                const SizedBox(width: 8),
                                _buildCategoryTab(
                                  TutorialsData.categoryAnimationBasics,
                                  label: '🟢 ${context.tr('catAnimationBasics')}',
                                ),
                                const SizedBox(width: 8),
                                _buildCategoryTab(
                                  TutorialsData.categoryThe12Principles,
                                  label: '🎬 ${context.tr('catThe12Principles')}',
                                ),
                                const SizedBox(width: 8),
                                _buildCategoryTab(
                                  TutorialsData.categoryCharacterAndLocomotion,
                                  label: '🏃 ${context.tr('catCharacterAndLocomotion')}',
                                ),
                                const SizedBox(width: 8),
                                _buildCategoryTab(
                                  TutorialsData.categoryVFXAndElements,
                                  label: '💥 ${context.tr('catVFXAndElements')}',
                                ),
                                const SizedBox(width: 8),
                                _buildCategoryTab(
                                  TutorialsData.categoryMasterPractice,
                                  label: '🏆 ${context.tr('catMasterPractice')}',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Difficulty Filter Row
                          Row(
                            children: [
                              _buildDifficultyFilter(null, context.tr('allLevels')),
                              const SizedBox(width: 6),
                              _buildDifficultyFilter(TutorialDifficulty.beginner, '🟢 ${context.tr('beginner')}'),
                              const SizedBox(width: 6),
                              _buildDifficultyFilter(TutorialDifficulty.intermediate, '🟠 ${context.tr('medium')}'),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Count Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                context.tr('tutorialsAvailableCount'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: ColorConstants.darkText,
                                ),
                              ),
                              Text(
                                context.tr('tapToPracticeAndInspect'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: ColorConstants.subTextColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),

                  // 3. Lesson Cards Grid
                  if (filteredTemplates.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 54, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              context.tr('noLessonsMatch', {'query': _searchQuery}),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: ColorConstants.mediumText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.78,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final template = filteredTemplates[index];
                            return _buildAcademyGridCard(template);
                          },
                          childCount: filteredTemplates.length,
                          addAutomaticKeepAlives: true,
                          addRepaintBoundaries: true,
                        ),
                      ),
                    ),
                ],
              ),
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: _showBackToTop,
        builder: (context, show, child) {
          if (!show) return const SizedBox.shrink();
          return FloatingActionButton.small(
            onPressed: _scrollToTop,
            backgroundColor: Colors.white,
            elevation: 4,
            shape: const CircleBorder(),
            child: const Icon(
              Icons.keyboard_arrow_up_rounded,
              color: ColorConstants.primary,
              size: 24,
            ),
          );
        },
      ),
    );
  }

  // Featured Spotlight Lesson Card
  Widget _buildFeaturedSpotlightCard(TemplateModel template) {
    final canvases = (template.projectState?['canvases'] as List?) ?? [];

    return GestureDetector(
      onTap: () => _openDetail(template),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFF7ED),
              Color(0xFFFFFFFF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: ColorConstants.primary.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorConstants.primary.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ColorConstants.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '⭐ ${context.tr('spotlightLesson').toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    template.getLocalizedName(context),
                    style: const TextStyle(
                      color: ColorConstants.darkText,
                      fontSize: 17.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    template.getLocalizedDescription(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: ColorConstants.mediumText,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: ColorConstants.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: ColorConstants.primary.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.tr('startLesson'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Right Live Preview Box
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEF0F5), width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    TutorialLivePreview(
                      canvases: canvases,
                      placeholder: const Center(
                        child: Icon(Icons.motion_photos_on_rounded, color: ColorConstants.primary, size: 36),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modern Academy Grid Card (2-Column)
  Widget _buildAcademyGridCard(TemplateModel template) {
    final canvases = (template.projectState?['canvases'] as List?) ?? [];

    return GestureDetector(
      onTap: () => _openDetail(template),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEEF0F5), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B1D28).withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Preview Canvas Box
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFAFBFD),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFF1F3F7), width: 1.0),
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                      child: TutorialLivePreview(
                        canvases: canvases,
                        placeholder: const Center(
                          child: Icon(Icons.motion_photos_on_rounded, color: ColorConstants.primary, size: 32),
                        ),
                      ),
                    ),

                    // Top-Left Frame Count
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          context.tr('framesCount', {'count': '${template.frameCount}'}),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Top-Right Difficulty Badge
                    Positioned(
                      top: 6,
                      right: 6,
                      child: _buildDifficultyTag(template.difficulty),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Info & Quick Action
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.getLocalizedName(context),
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
                          template.getLocalizedDescription(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: ColorConstants.mediumText,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 12, color: ColorConstants.primary),
                        const SizedBox(width: 3),
                        Text(
                          context.tr('minutesApprox', {'min': '${template.estimatedMinutes}'}),
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: ColorConstants.primary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: ColorConstants.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                context.tr('draw'),
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: ColorConstants.primary,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.arrow_forward_rounded, size: 10, color: ColorConstants.primary),
                            ],
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
      ),
    );
  }

  Widget _buildCategoryTab(String categoryKey, {required String label}) {
    final bool isSelected = _selectedCategory == categoryKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = categoryKey;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? ColorConstants.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? ColorConstants.primary : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: ColorConstants.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : ColorConstants.darkText,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyFilter(TutorialDifficulty? difficulty, String label) {
    final bool isSelected = _selectedDifficulty == difficulty;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDifficulty = difficulty;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E1B24) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E1B24) : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : ColorConstants.mediumText,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 11,
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
        label = context.tr('beginner');
        break;
      case TutorialDifficulty.intermediate:
        bg = ColorConstants.primaryLight;
        text = ColorConstants.primaryDark;
        label = context.tr('medium');
        break;
      case TutorialDifficulty.advanced:
        bg = const Color(0xFFFFEBEE);
        text = const Color(0xFFC62828);
        label = context.tr('master');
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
