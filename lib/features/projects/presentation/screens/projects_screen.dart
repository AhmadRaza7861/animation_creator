import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_assets.dart';
import '../../data/project_repository.dart';
import '../../domain/project_model.dart';
import '../widgets/project_card.dart';
import 'create_project_screen.dart';
import '../../../templates/presentation/screens/templates_screen.dart';
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
          style: TextStyle(fontWeight: FontWeight.bold, color: ColorConstants.darkText),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'New Title',
            labelStyle: TextStyle(color: ColorConstants.primary),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: ColorConstants.primary),
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
            child: const Text('Rename', style: TextStyle(color: ColorConstants.primary, fontWeight: FontWeight.bold)),
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
          style: TextStyle(fontWeight: FontWeight.bold, color: ColorConstants.darkText),
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
            ? const Center(child: CircularProgressIndicator(color: ColorConstants.primary))
            : Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0),
                child: _currentTab == 0 ? _buildHomeTab() : _buildProjectsTab(),
              ),
      ),
      floatingActionButton: SizedBox(
        width: 58,
        height: 58,
        child: FloatingActionButton(
          onPressed: _createNewProject,
          backgroundColor: ColorConstants.primary,
          elevation: 6,
          shape: const CircleBorder(),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 32,
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
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    _currentTab = 0;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.home,
                        color: _currentTab == 0 ? ColorConstants.primary : const Color(0xFFBEB9C5),
                        size: 26,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        StringConstants.homeTab,
                        style: TextStyle(
                          color: _currentTab == 0 ? ColorConstants.primary : const Color(0xFFBEB9C5),
                          fontSize: 11,
                          fontWeight: _currentTab == 0 ? FontWeight.w800 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 48), // Spacer to leave gap for FAB
              // Projects Tab
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    _currentTab = 1;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        color: _currentTab == 1 ? ColorConstants.primary : const Color(0xFFBEB9C5),
                        size: 26,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        StringConstants.projectsTab,
                        style: TextStyle(
                          color: _currentTab == 1 ? ColorConstants.primary : const Color(0xFFBEB9C5),
                          fontSize: 11,
                          fontWeight: _currentTab == 1 ? FontWeight.w800 : FontWeight.w500,
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
                    text: 'C',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: 'lipax',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B5CF6),
                      letterSpacing: -0.5,
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
                    backgroundColor: ColorConstants.primary,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: ColorConstants.primary,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ColorConstants.primary.withValues(alpha: 0.08),
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
                        color: ColorConstants.darkText,
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
                color: ColorConstants.darkText,
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
        // const SizedBox(height: 2),
         Text(
          StringConstants.where_ideas_turn_into_motion,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: ColorConstants.subTextColor,
          ),
        ),
        const SizedBox(height: 16),

        // Explore Templates Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(left: 12,top: 16,bottom: 16,right: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            image: DecorationImage(image:AssetImage(
              AssetConstants.templates_card_bg,),
              fit: BoxFit.fill,
            ),
            // boxShadow: [
            //   BoxShadow(
            //     color: Colors.black.withOpacity(0.03),
            //     blurRadius: 20,
            //     offset: const Offset(0, 8),
            //   ),
            // ],
            border: Border.all(
              color: ColorConstants.border_color,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              SvgPicture.asset(AssetConstants.templates_card_icon,width: 90,height: 90,),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Padding(
                       padding: const EdgeInsets.only(left: 17),
                       child: Text(
                        StringConstants.explore_templates,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: ColorConstants.text_color,
                        ),
                                           ),
                     ),
                    const SizedBox(height:14),
                     Padding(
                       padding: const EdgeInsets.only(left: 17),
                       child: Text(
                        StringConstants.start_faster,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: ColorConstants.subTextColor,
                          height: 1.2,
                        ),
                                           ),
                     ),
                    const SizedBox(height: 16),
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
                        // height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        decoration: BoxDecoration(
                          color: ColorConstants.primary,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8.2,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                
                            BoxShadow(
                              color: ColorConstants.shadow_color.withValues(alpha: 0.1),
                              blurRadius: 8.7,
                              spreadRadius: 0,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child:  Padding(
                          padding: EdgeInsetsGeometry.only(top: 13,bottom: 13,),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  StringConstants.browse_templates,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Recent Projects Header
        Row(
          children: [
             Text(
              StringConstants.recent_projects,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: ColorConstants.text_color,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                setState(() {
                  _currentTab = 1;
                });
              },
              child:  Text(
                StringConstants.see_all,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color:ColorConstants.subTextColor,
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
            color: ColorConstants.primary,
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
            color: ColorConstants.darkText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage and view all your anims (${_projects.length})',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: ColorConstants.mediumText,
          ),
        ),
        const SizedBox(height: 24),

        // Projects grid or empty state
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadProjects,
            color: ColorConstants.primary,
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
    return AnimatedDashedBorder(
      color: const Color(0xFFFFD4A3),
      strokeWidth: 1.5,
      dashLength: 8,
      dashGap: 6,
      borderRadius: 24,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFF7ED),
                ),
                child: const Center(
                  child: Icon(
                    Icons.folder_open_outlined,
                    color: Color(0xFFFFB054),
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Project Yet',
                style: TextStyle(
                  color: ColorConstants.darkText,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Click + to create one',
                style: TextStyle(
                  color: ColorConstants.mediumText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
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
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.78,
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
