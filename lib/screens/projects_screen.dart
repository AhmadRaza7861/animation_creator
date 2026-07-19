import 'dart:io';
import 'package:flutter/material.dart';
import '../main.dart';
import '../repositories/project_repository.dart';
import 'create_project_screen.dart';

class ProjectsScreen extends StatefulWidget {
  final ProjectRepository repository;

  const ProjectsScreen({super.key, required this.repository});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<ProjectMeta> _projects = [];
  bool _isLoading = true;

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
        builder: (context) => MyHomePage(
          repository: widget.repository,
          projectId: project.id,
        ),
      ),
    ).then((_) => _loadProjects());
  }

  Future<void> _deleteProject(ProjectMeta project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Project?',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3C3043)),
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
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF9114)))
            : RefreshIndicator(
                onRefresh: _loadProjects,
                color: const Color(0xFFFF9114),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
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
                                    color: Color(0xFF3C3043),
                                    letterSpacing: -1.0,
                                    fontFamily: 'Outfit',
                                  ),
                                ),
                                TextSpan(
                                  text: 'ax',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFFF9114),
                                    letterSpacing: -1.0,
                                    fontFamily: 'Outfit',
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
                                  backgroundColor: Color(0xFFFF9114),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFFF9114),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF9114).withOpacity(0.08),
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
                                      color: Color(0xFFFF9114),
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
                              color: Color(0xFF3C3043),
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
                          color: Color(0xFF8E8895),
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
                                color: Color(0xFF3C3043),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Start faster with ready-made animations for any project',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF8E8895),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Browse Templates Button
                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Templates library coming soon!')),
                                );
                              },
                              child: Container(
                                height: 50,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF9114),
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF9114).withOpacity(0.3),
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
                              color: Color(0xFF3C3043),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {},
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
                      _projects.isEmpty ? _buildEmptyState() : _buildProjectsGrid(),
                    ],
                  ),
                ),
              ),
      ),
      // Overlapping FAB in the center
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewProject,
        backgroundColor: const Color(0xFFFF9114),
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 32,
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
              GestureDetector(
                onTap: () {},
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.home,
                      color: Color(0xFFFF9114),
                      size: 26,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Home',
                      style: TextStyle(
                        color: Color(0xFFFF9114),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48), // Spacer to leave gap for FAB
              // Projects Tab
              GestureDetector(
                onTap: () {},
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_open,
                      color: Color(0xFFBEB9C5),
                      size: 26,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Projects',
                      style: TextStyle(
                        color: Color(0xFFBEB9C5),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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

  Widget _buildProjectsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _projects.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final project = _projects[index];
        return _ProjectCard(
          project: project,
          onTap: () => _openProject(project),
          onDelete: () => _deleteProject(project),
        );
      },
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectMeta project;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ProjectCard({
    required this.project,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final String timeAgo = _formatTimeAgo(project.lastModified);
    final int fps = project.fps ?? 12;
    final int frames = project.frameCount ?? 0;

    // Calculate duration
    final double durationSec = frames / fps;
    final String durationString = _formatDuration(durationSec);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
          border: Border.all(
            color: Colors.grey.shade100,
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Thumbnail / Background
            Positioned.fill(
              child: project.thumbnailPath != null
                  ? Image.file(
                      File(project.thumbnailPath!),
                      fit: BoxFit.cover,
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFE8EAFF),
                            Color(0xFFF9E7FF),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.image,
                          size: 40,
                          color: Color(0xFFBEB9C5),
                        ),
                      ),
                    ),
            ),

            // Top Play Time Tag
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 11,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      durationString,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Gradient Overlay + Text
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      project.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${fps}fps',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Edited $timeAgo',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // More/Delete Button in the Corner
            Positioned(
              bottom: 30,
              right: 0,
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white70,
                    size: 20,
                  ),
                  onPressed: onDelete,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(double durationSec) {
    if (durationSec <= 0) return '0:00';
    final int totalSeconds = durationSec.round();
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
