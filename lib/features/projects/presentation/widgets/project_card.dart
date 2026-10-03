import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/project_model.dart';

class ProjectCard extends StatelessWidget {
  final ProjectMeta project;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    required this.onRename,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final String timeAgo = _formatTimeAgo(context, project.lastModified);
    final int fps = project.fps ?? 12;
    final int rawFrames = project.frameCount ?? 0;
    final int frames = rawFrames <= 0 ? 1 : rawFrames;

    // Calculate duration
    final double durationSec = fps > 0 ? (frames / fps) : 0;
    final String durationString = _formatDuration(durationSec);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFEEF0F5),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B1D28).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFF1B1D28).withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Canvas Artwork Preview (Pure Solid White Background)
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFFF1F3F7),
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Base Canvas with Artwork or Clean Placeholder
                      _buildCanvasArtwork(context),

                      // Top Left: FPS Badge
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: const Color(0x1A000000),
                              width: 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            '$fps FPS',
                            style: const TextStyle(
                              color: Color(0xFF2C323E),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),

                      // Top Right: Duration Pill
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xD91E1B24),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.play_arrow_rounded,
                                color: ColorConstants.primary,
                                size: 12,
                              ),
                              const SizedBox(width: 2.5),
                              Text(
                                durationString,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
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

              // 2. Bottom Metadata and Action Row
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 9, 6, 11),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title & Time / Frames Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            project.title,
                            style: const TextStyle(
                              color: Color(0xFF1E2026),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  timeAgo,
                                  style: const TextStyle(
                                    color: Color(0xFF8C93A3),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Text(
                                ' • ',
                                style: TextStyle(
                                  color: Color(0xFFBDC2CC),
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                frames == 1
                                    ? context.tr('singleFrameCount', {'num': '$frames'})
                                    : context.tr('framesCount', {'count': '$frames'}),
                                style: const TextStyle(
                                  color: Color(0xFF8C93A3),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 3-Dot More Options Menu
                    Theme(
                      data: Theme.of(context).copyWith(
                        cardColor: Colors.white,
                        popupMenuTheme: PopupMenuThemeData(
                          color: Colors.white,
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(
                              color: Color(0xFFEFF0F6),
                              width: 1.0,
                            ),
                          ),
                        ),
                      ),
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: Color(0xFF767F8D),
                          size: 19,
                        ),
                        splashRadius: 18,
                        onSelected: (action) {
                          if (action == 'open') {
                            onTap();
                          } else if (action == 'duplicate') {
                            onDuplicate();
                          } else if (action == 'rename') {
                            onRename();
                          } else if (action == 'delete') {
                            onDelete();
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem(
                            value: 'open',
                            height: 40,
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2C3038)),
                                const SizedBox(width: 10),
                                Text(
                                  context.tr('editAnimation'),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2C3038),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'duplicate',
                            height: 40,
                            child: Row(
                              children: [
                                const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF2C3038)),
                                const SizedBox(width: 10),
                                Text(
                                  context.tr('duplicate'),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2C3038),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'rename',
                            height: 40,
                            child: Row(
                              children: [
                                const Icon(Icons.drive_file_rename_outline_rounded, size: 18, color: Color(0xFF2C3038)),
                                const SizedBox(width: 10),
                                Text(
                                  context.tr('rename'),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2C3038),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(height: 1),
                          PopupMenuItem(
                            value: 'delete',
                            height: 40,
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                const SizedBox(width: 10),
                                Text(
                                  context.tr('delete'),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildCanvasArtwork(BuildContext context) {
    if (project.thumbnailPath != null && File(project.thumbnailPath!).existsSync()) {
      final thumbFile = File(project.thumbnailPath!);
      return Container(
        color: Colors.white,
        child: Center(
          child: Image.file(
            thumbFile,
            key: ValueKey('${project.id}_${project.lastModified.millisecondsSinceEpoch}'),
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(context),
          ),
        ),
      );
    }
    return _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE5E8EF),
                  width: 1.0,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.edit_note_rounded,
                  size: 24,
                  color: Color(0xFF8E97A6),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              context.tr('blankCanvas'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8E97A6),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(double durationSec) {
    if (durationSec <= 0) return '0:01';
    final int totalSeconds = durationSec.round();
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    if (minutes == 0 && seconds == 0) {
      return '0:01';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatTimeAgo(BuildContext context, DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 365) {
      final count = (difference.inDays / 365).floor();
      return context.tr('yearsAgo', {'num': '$count'});
    } else if (difference.inDays > 30) {
      final count = (difference.inDays / 30).floor();
      return context.tr('monthsAgo', {'num': '$count'});
    } else if (difference.inDays > 0) {
      return context.tr('daysAgo', {'num': '${difference.inDays}'});
    } else if (difference.inHours > 0) {
      return context.tr('hoursAgo', {'num': '${difference.inHours}'});
    } else if (difference.inMinutes > 0) {
      return context.tr('minutesAgo', {'num': '${difference.inMinutes}'});
    } else {
      return context.tr('justNow');
    }
  }
}
