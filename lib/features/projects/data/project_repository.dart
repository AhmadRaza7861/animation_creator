import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/painting.dart';
import '../../../../core/utils/app_path_provider.dart';
import '../domain/project_model.dart';
import 'project_thumbnail_helper.dart';

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

  String generateId() => _uuid.v4();

  Future<Directory> getProjectDirectory(String projectId) => _getProjectDirectory(projectId);

  Future<List<ProjectMeta>> listProjects() async {
    try {
      final dir = await _getProjectsDirectory();
      final dirPath = dir.path;
      return await Isolate.run<List<ProjectMeta>>(() {
        final List<ProjectMeta> projects = [];
        final d = Directory(dirPath);
        if (!d.existsSync()) return projects;
        final entities = d.listSync();
        for (final entity in entities) {
          if (entity is Directory) {
            final metaFile = File('${entity.path}/meta.json');
            if (metaFile.existsSync()) {
              try {
                final jsonStr = metaFile.readAsStringSync();
                projects.add(ProjectMeta.fromJson(jsonDecode(jsonStr)));
              } catch (_) {}
            }
          }
        }
        projects.sort((a, b) => b.lastModified.compareTo(a.lastModified));
        return projects;
      });
    } catch (e) {
      debugPrint('Error listing projects: $e');
      return [];
    }
  }

  Future<ProjectData?> loadProject(String projectId) async {
    try {
      final dir = await _getProjectDirectory(projectId);
      final dirPath = dir.path;
      return await Isolate.run<ProjectData?>(() {
        File metaFile = File('$dirPath/meta.json');
        File dataFile = File('$dirPath/data.json');

        // Fallback to .tmp files if app was killed mid-write
        if (!metaFile.existsSync()) {
          final metaTmp = File('$dirPath/meta.json.tmp');
          if (metaTmp.existsSync()) {
            metaFile = metaTmp;
          }
        }

        if (!dataFile.existsSync()) {
          final dataTmp = File('$dirPath/data.json.tmp');
          if (dataTmp.existsSync()) {
            dataFile = dataTmp;
          }
        }

        if (!metaFile.existsSync() || !dataFile.existsSync()) {
          return null;
        }

        final metaStr = metaFile.readAsStringSync();
        final meta = ProjectMeta.fromJson(jsonDecode(metaStr));

        final dataStr = dataFile.readAsStringSync();
        final state = jsonDecode(dataStr) as Map<String, dynamic>;

        return ProjectData(meta: meta, state: state);
      });
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
    bool preserveLastModified = false,
  }) async {
    try {
      final id = projectId ?? _uuid.v4();
      final dir = await _getProjectDirectory(id);
      final dirPath = dir.path;

      String? thumbnailPath;
      if (thumbnailBytes != null && thumbnailBytes.isNotEmpty) {
        final thumbFile = File('$dirPath/thumb.png');
        await thumbFile.writeAsBytes(thumbnailBytes, flush: true);
        thumbnailPath = thumbFile.path;
      }

      ProjectMeta meta;
      final metaFile = File('$dirPath/meta.json');
      if (await metaFile.exists()) {
        try {
          final metaStr = await metaFile.readAsString();
          final oldMeta = ProjectMeta.fromJson(jsonDecode(metaStr));
          meta = ProjectMeta(
            id: id,
            title: title ?? oldMeta.title,
            createdAt: oldMeta.createdAt,
            lastModified: preserveLastModified ? oldMeta.lastModified : DateTime.now(),
            thumbnailPath: thumbnailPath ?? oldMeta.thumbnailPath,
            fps: state['fps'] as int? ?? oldMeta.fps,
            frameCount: ((state['canvases'] as List?)?.length ?? 0) > 0
                ? (state['canvases'] as List).length
                : (oldMeta.frameCount ?? 1),
          );
        } catch (_) {
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

      // 0. Ensure all external/temporary image assets are copied into the project's permanent directory
      final Map<String, dynamic> persistentState = Map<String, dynamic>.from(state);

      if (persistentState['globalBackground'] is Map) {
        final bgMap = Map<String, dynamic>.from(persistentState['globalBackground'] as Map);
        final rawPath = bgMap['imagePath'] as String?;
        if (rawPath != null && rawPath.isNotEmpty) {
          final srcFile = File(rawPath);
          if (!rawPath.startsWith(dirPath) && await srcFile.exists()) {
            final assetsDir = Directory('$dirPath/assets');
            if (!await assetsDir.exists()) {
              await assetsDir.create(recursive: true);
            }
            final ext = rawPath.contains('.') ? rawPath.split('.').last : 'png';
            final destFile = File('${assetsDir.path}/bg_image.$ext');
            try {
              await srcFile.copy(destFile.path);
              bgMap['imagePath'] = destFile.path;
              persistentState['globalBackground'] = bgMap;
            } catch (_) {}
          }
        }
      }

      // 0.2 Ensure all canvas layer image assets are copied into the project directory
      final canvasesList = persistentState['canvases'] as List<dynamic>?;
      if (canvasesList != null) {
        final assetsDir = Directory('$dirPath/assets');
        for (final c in canvasesList) {
          if (c is Map) {
            final layersList = c['layers'] as List<dynamic>?;
            if (layersList != null) {
              for (final l in layersList) {
                if (l is Map) {
                  final historyList = l['history'] as List<dynamic>?;
                  if (historyList != null) {
                    for (final item in historyList) {
                      if (item is Map && item['type'] == 'ImageContent') {
                        final rawUrl = item['imageUrl'] as String?;
                        if (rawUrl != null && rawUrl.isNotEmpty && !rawUrl.startsWith('http') && !rawUrl.startsWith('assets/')) {
                          final srcFile = File(rawUrl);
                          if (!rawUrl.startsWith(dirPath) && await srcFile.exists()) {
                            if (!await assetsDir.exists()) {
                              await assetsDir.create(recursive: true);
                            }
                            final fileName = srcFile.uri.pathSegments.isNotEmpty
                                ? srcFile.uri.pathSegments.last
                                : 'img_${DateTime.now().millisecondsSinceEpoch}.png';
                            final destFile = File('${assetsDir.path}/$fileName');
                            try {
                              if (!await destFile.exists() || await destFile.length() != await srcFile.length()) {
                                await srcFile.copy(destFile.path);
                              }
                              item['imageUrl'] = destFile.path;
                            } catch (_) {}
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      // 1. Write data.json atomically with flush using async I/O
      final dataTmp = File('$dirPath/data.json.tmp');
      await dataTmp.writeAsString(jsonEncode(persistentState), flush: true);
      final dataFile = File('$dirPath/data.json');
      if (await dataFile.exists()) {
        try {
          await dataFile.delete();
        } catch (_) {}
      }
      await dataTmp.rename(dataFile.path);

      // 2. Write meta.json atomically with flush using async I/O
      final metaTmp = File('$dirPath/meta.json.tmp');
      await metaTmp.writeAsString(jsonEncode(meta.toJson()), flush: true);
      if (await metaFile.exists()) {
        try {
          await metaFile.delete();
        } catch (_) {}
      }
      await metaTmp.rename(metaFile.path);

      if (thumbnailBytes != null && thumbnailBytes.isNotEmpty) {
        try {
          final thumbFile = File('$dirPath/thumb.png');
          await FileImage(thumbFile).evict();
        } catch (_) {}
      }

      return id;
    } catch (e) {
      debugPrint('Error saving project: $e');
      rethrow;
    }
  }

  /// Backfills `thumb.png` for an existing saved project whose thumbnail is
  /// missing on disk while keeping its original `lastModified` timestamp.
  Future<ProjectMeta?> ensureThumbnailFromSavedState(String projectId) async {
    try {
      final dir = await _getProjectDirectory(projectId);
      final dirPath = dir.path;

      File metaFile = File('$dirPath/meta.json');
      File dataFile = File('$dirPath/data.json');
      if (!metaFile.existsSync()) {
        final metaTmp = File('$dirPath/meta.json.tmp');
        if (metaTmp.existsSync()) metaFile = metaTmp;
      }
      if (!dataFile.existsSync()) {
        final dataTmp = File('$dirPath/data.json.tmp');
        if (dataTmp.existsSync()) dataFile = dataTmp;
      }
      if (!metaFile.existsSync() || !dataFile.existsSync()) return null;

      final ProjectMeta oldMeta = ProjectMeta.fromJson(
        jsonDecode(await metaFile.readAsString()),
      );
      if (oldMeta.thumbnailPath != null &&
          oldMeta.thumbnailPath!.isNotEmpty &&
          File(oldMeta.thumbnailPath!).existsSync()) {
        return oldMeta;
      }

      // If thumb.png exists on disk even though meta.thumbnailPath was null, link it cleanly.
      final File thumbFile = File('$dirPath/thumb.png');
      Uint8List? thumbBytes;
      if (!thumbFile.existsSync()) {
        final Map<String, dynamic> state =
            jsonDecode(await dataFile.readAsString()) as Map<String, dynamic>;
        if (!ProjectThumbnailHelper.stateHasVisualContent(state)) {
          return null;
        }
        thumbBytes = await ProjectThumbnailHelper.renderFromState(state);
        if (thumbBytes == null || thumbBytes.isEmpty) {
          return null;
        }
        await thumbFile.writeAsBytes(thumbBytes, flush: true);
      }

      final ProjectMeta updatedMeta = ProjectMeta(
        id: oldMeta.id,
        title: oldMeta.title,
        createdAt: oldMeta.createdAt,
        lastModified: oldMeta.lastModified,
        thumbnailPath: thumbFile.path,
        fps: oldMeta.fps,
        frameCount: oldMeta.frameCount,
      );

      final File realMetaFile = File('$dirPath/meta.json');
      final File metaTmp = File('$dirPath/meta.json.tmp');
      await metaTmp.writeAsString(jsonEncode(updatedMeta.toJson()), flush: true);
      if (await realMetaFile.exists()) {
        try {
          await realMetaFile.delete();
        } catch (_) {}
      }
      await metaTmp.rename(realMetaFile.path);

      try {
        await FileImage(thumbFile).evict();
      } catch (_) {}

      return updatedMeta;
    } catch (e) {
      debugPrint('Error backfilling thumbnail for $projectId: $e');
      return null;
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
