import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/painting.dart';
import '../../../../core/utils/app_path_provider.dart';
import '../domain/project_model.dart';

class ProjectRepository {
  static const String _projectsDirName = 'drawing_projects';
  final Uuid _uuid = const Uuid();

  Future<Directory> _getProjectsDirectory() async {
    final root = await AppPathProvider.getSafeDocumentsDirectory();
    final dir = Directory('${root.path}/$_projectsDirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> _getProjectDirectory(String projectId) async {
    final root = await _getProjectsDirectory();
    final dir = Directory('${root.path}/$projectId');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<List<ProjectMeta>> listProjects() async {
    final List<ProjectMeta> projects = [];

    try {
      final dir = await _getProjectsDirectory();
      final entities = dir.listSync();
      for (final entity in entities) {
        if (entity is Directory) {
          final metaFile = File('${entity.path}/meta.json');
          final dataFile = File('${entity.path}/data.json');
          if (await metaFile.exists()) {
            if (await dataFile.exists()) {
              try {
                final dataStr = await dataFile.readAsString();
                final state = jsonDecode(dataStr) as Map<String, dynamic>;
                if (!_hasAnyContent(state)) {
                  // Automatically clean up blank project directory with 0 drawings
                  try {
                    await entity.delete(recursive: true);
                  } catch (_) {}
                  continue;
                }
              } catch (_) {}
            }
            final jsonStr = await metaFile.readAsString();
            projects.add(ProjectMeta.fromJson(jsonDecode(jsonStr)));
          }
        }
      }
      
      projects.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    } catch (e) {
      debugPrint('Error listing projects: $e');
    }

    return projects;
  }

  bool _hasAnyContent(Map<String, dynamic> state) {
    final String? templateFolder = state['templateFolder'] as String?;
    if (templateFolder != null && templateFolder.isNotEmpty) return true;

    final List? templateFrameAssets = state['templateFrameAssets'] as List?;
    if (templateFrameAssets != null && templateFrameAssets.isNotEmpty) return true;

    final globalBg = state['globalBackground'];
    if (globalBg is Map) {
      final String? bgImg = globalBg['imagePath'] as String?;
      if (bgImg != null && bgImg.isNotEmpty) return true;
    }

    final List? canvases = state['canvases'] as List?;
    if (canvases == null || canvases.isEmpty) return false;
    if (canvases.length > 1) return true;

    for (final canvas in canvases) {
      if (canvas is! Map) continue;
      final List? layers = canvas['layers'] as List?;
      if (layers == null) continue;
      for (final layer in layers) {
        if (layer is! Map) continue;
        final int currentIndex = layer['currentIndex'] as int? ?? 0;
        final List? history = layer['history'] as List?;
        if (history != null && history.isNotEmpty && currentIndex > 0) {
          final int validCount = currentIndex.clamp(0, history.length);
          for (int i = 0; i < validCount; i++) {
            final item = history[i];
            if (item is Map && item['type'] != 'EmptyContent') {
              return true;
            }
          }
        }
      }
    }
    return false;
  }

  Future<ProjectData?> loadProject(String projectId) async {
    try {
      final dir = await _getProjectDirectory(projectId);
      final metaFile = File('${dir.path}/meta.json');
      final dataFile = File('${dir.path}/data.json');

      if (!await metaFile.exists() || !await dataFile.exists()) {
        return null;
      }

      final metaStr = await metaFile.readAsString();
      final meta = ProjectMeta.fromJson(jsonDecode(metaStr));

      final dataStr = await dataFile.readAsString();
      final state = jsonDecode(dataStr) as Map<String, dynamic>;

      return ProjectData(meta: meta, state: state);
    } catch (e) {
      debugPrint('Error loading project $projectId: $e');
      return null;
    }
  }

  Future<String> saveProject({
    String? projectId,
    String? title,
    required Map<String, dynamic> state,
    List<int>? thumbnailBytes,
  }) async
  {
    try {
      final id = projectId ?? _uuid.v4();
      final dir = await _getProjectDirectory(id);

      String? thumbnailPath;
      if (thumbnailBytes != null) {
        final thumbFile = File('${dir.path}/thumb.png');
        await thumbFile.writeAsBytes(thumbnailBytes);
        thumbnailPath = thumbFile.path;
        try {
          await FileImage(thumbFile).evict();
        } catch (_) {}
      }

      ProjectMeta meta;
      final metaFile = File('${dir.path}/meta.json');
      if (await metaFile.exists()) {
        final metaStr = await metaFile.readAsString();
        final oldMeta = ProjectMeta.fromJson(jsonDecode(metaStr));
        meta = ProjectMeta(
          id: id,
          title: title ?? oldMeta.title,
          createdAt: oldMeta.createdAt,
          lastModified: DateTime.now(),
          thumbnailPath: thumbnailPath ?? oldMeta.thumbnailPath,
          fps: state['fps'] as int? ?? oldMeta.fps,
          frameCount: ((state['canvases'] as List?)?.length ?? 0) > 0
              ? (state['canvases'] as List).length
              : (oldMeta.frameCount ?? 1),
        );
      } else {
        meta = ProjectMeta(
          id: id,
          title: title ?? 'Untitled Project',
          createdAt: DateTime.now(),
          lastModified: DateTime.now(),
          thumbnailPath: thumbnailPath,
          fps: state['fps'] as int? ?? 12,
          frameCount: ((state['canvases'] as List?)?.length ?? 0) > 0
              ? (state['canvases'] as List).length
              : 1,
        );
      }

      await metaFile.writeAsString(jsonEncode(meta.toJson()));

      final dataFile = File('${dir.path}/data.json');
      await dataFile.writeAsString(jsonEncode(state));

      return id;
    } catch (e) {
      debugPrint('Error saving project: $e');
      rethrow;
    }
  }

  Future<void> deleteProject(String projectId) async {
    try {
      final dir = await _getProjectDirectory(projectId);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Error deleting project $projectId: $e');
    }
  }
}
