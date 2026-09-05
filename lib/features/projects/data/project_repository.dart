import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/painting.dart';
import '../domain/project_model.dart';

class ProjectRepository {
  static const String _projectsDirName = 'drawing_projects';
  final Uuid _uuid = const Uuid();

  Future<Directory> _getProjectsDirectory() async {
    Directory? root;
    try {
      root = await getApplicationDocumentsDirectory();
    } catch (e) {
      debugPrint('path_provider getApplicationDocumentsDirectory error: $e');
      try {
        root = await getApplicationSupportDirectory();
      } catch (e2) {
        debugPrint('path_provider getApplicationSupportDirectory error: $e2');
      }
    }

    if (root == null) {
      if (Platform.isAndroid) {
        final fallbackDir = Directory('/data/user/0/com.example.dummy/app_flutter');
        if (await fallbackDir.exists()) {
          root = fallbackDir;
        } else {
          final fallbackDataDir = Directory('/data/data/com.example.dummy/app_flutter');
          if (await fallbackDataDir.exists()) {
            root = fallbackDataDir;
          } else {
            root = Directory.systemTemp;
          }
        }
      } else {
        root = Directory.systemTemp;
      }
    }

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
          if (await metaFile.exists()) {
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
