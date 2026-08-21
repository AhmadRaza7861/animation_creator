import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_assets.dart';
import '../../data/project_repository.dart';
import '../../domain/project_model.dart';
import '../widgets/project_card.dart';
import 'create_project_screen.dart';
import '../../../templates/presentation/screens/templates_screen.dart';
import '../../../editor/presentation/screens/editor_screen.dart';

class ProjectsScreen extends StatefulWidget {
  final ProjectRepository repository;

  const ProjectsScreen({super.key, required this.repository});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<ProjectMeta> _projects = [];
  bool _isLoading = true;
  int _currentTab = 0; // 0: Home, 1: Projects

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
    });
    final projects = await widget.repository.listProjects();
    setState(() {
      _projects = projects;
      _isLoading = false;
    });
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

  Future<void> _renameProject(ProjectMeta project) async {
    final controller = TextEditingController(text: project.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Rename Project',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkText),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'New Title',
            labelStyle: TextStyle(color: AppColors.primary),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, controller.text),
            child: const Text('Rename', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.trim().isNotEmpty) {
      setState(() {
        _isLoading = true;
      });
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
    setState(() {
      _isLoading = true;
    });
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
          title: '${project.title} Copy',
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Project?',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkText),
        ),
        content: Text('Are you sure you want to delete "${project.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : Padding(
                padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0),
                child: _currentTab == 0 ? _buildHomeTab() : _buildProjectsTab(),
              ),
      ),
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          BottomAppBar(
            height: 72,
            color: Colors.white,
            elevation: 16,
            padding: EdgeInsets.zero,
            surfaceTintColor: Colors.white,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFF1F2F6),
                    width: 1.5,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Home Tab
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentTab = 0;
                      });
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.home,
                          color: _currentTab == 0 ? AppColors.primary : const Color(0xFFBEB9C5),
                          size: 26,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          StringConstants.homeTab,
                          style: TextStyle(
                            color: _currentTab == 0 ? AppColors.primary : const Color(0xFFBEB9C5),
                            fontSize: 11,
                            fontWeight: _currentTab == 0 ? FontWeight.w800 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48), // Spacer to leave gap for FAB
                  // Projects Tab
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentTab = 1;
                      });
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          color: _currentTab == 1 ? AppColors.primary : const Color(0xFFBEB9C5),
                          size: 26,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          StringConstants.projectsTab,
                          style: TextStyle(
                            color: _currentTab == 1 ? AppColors.primary : const Color(0xFFBEB9C5),
                            fontSize: 11,
                            fontWeight: _currentTab == 1 ? FontWeight.w800 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: -28,
            child: FloatingActionButton(
              onPressed: _createNewProject,
              backgroundColor: AppColors.primary,
              elevation: 6,
              shape: const CircleBorder(),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final recentProjects = _projects.take(2).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          children: [
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Clip',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: -1.0,
                    ),
                  ),
                  TextSpan(
                    text: 'ax',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF8B5CF6),
                      letterSpacing: -1.0,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Get Pro Pill
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pro Subscription features coming soon!'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Get Pro',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                       '👑',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Menu Button
            IconButton(
              icon: const Icon(
                Icons.menu,
                color: AppColors.darkText,
                size: 28,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings menu is under development.')),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Where Ideas turn into motion',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.mediumText,
          ),
        ),
        const SizedBox(height: 24),

        // Explore Templates Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Colors.grey.shade100,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Explore Templates',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Start faster with ready-made animations for any project',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.mediumText,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              // Browse Templates Button
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TemplatesScreen(
                        repository: widget.repository,
                      ),
                    ),
                  ).then((_) => _loadProjects());
                },
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Browse Templates',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Recent Projects Header
        Row(
          children: [
            const Text(
              'Recent Projects',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.darkText,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                setState(() {
                  _currentTab = 1;
                });
              },
              child: const Text(
                'See all',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFBEB9C5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Projects grid or empty state
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadProjects,
            color: AppColors.primary,
            child: recentProjects.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: _buildEmptyState(),
                  )
                : _buildProjectsGrid(recentProjects),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        const Text(
          'All Projects',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage and view all your anims (${_projects.length})',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.mediumText,
          ),
        ),
        const SizedBox(height: 24),

        // Projects grid or empty state
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadProjects,
            color: AppColors.primary,
            child: _projects.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: _buildEmptyState(),
                  )
                : _buildProjectsGrid(_projects),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60.0),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No Project Yet',
              style: TextStyle(
                color: Color(0xFFBEB9C5),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Click + to create one',
              style: TextStyle(
                color: Color(0xFFBEB9C5),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectsGrid(List<ProjectMeta> projectsList) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: projectsList.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final project = projectsList[index];
        return ProjectCard(
          project: project,
          onTap: () => _openProject(project),
          onRename: () => _renameProject(project),
          onDuplicate: () => _duplicateProject(project),
          onDelete: () => _deleteProject(project),
        );
      },
    );
  }
}
