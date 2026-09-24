import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
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
  }) async {
    try {
      final id = projectId ?? _uuid.v4();
      final dir = await _getProjectDirectory(id);
      final dirPath = dir.path;

      // Run disk writes, thumbnail saving, and JSON serialization in background isolate thread
      await Isolate.run(() {
        String? thumbnailPath;
        if (thumbnailBytes != null && thumbnailBytes.isNotEmpty) {
          final thumbFile = File('$dirPath/thumb.png');
          thumbFile.writeAsBytesSync(thumbnailBytes, flush: true);
          thumbnailPath = thumbFile.path;
        }

        ProjectMeta meta;
        final metaFile = File('$dirPath/meta.json');
        if (metaFile.existsSync()) {
          try {
            final metaStr = metaFile.readAsStringSync();
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
            if (!rawPath.startsWith(dirPath) && srcFile.existsSync()) {
              final assetsDir = Directory('$dirPath/assets');
              if (!assetsDir.existsSync()) {
                assetsDir.createSync(recursive: true);
              }
              final ext = rawPath.contains('.') ? rawPath.split('.').last : 'png';
              final destFile = File('${assetsDir.path}/bg_image.$ext');
              try {
                srcFile.copySync(destFile.path);
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
                            if (!rawUrl.startsWith(dirPath) && srcFile.existsSync()) {
                              if (!assetsDir.existsSync()) {
                                assetsDir.createSync(recursive: true);
                              }
                              final fileName = srcFile.uri.pathSegments.isNotEmpty
                                  ? srcFile.uri.pathSegments.last
                                  : 'img_${DateTime.now().millisecondsSinceEpoch}.png';
                              final destFile = File('${assetsDir.path}/$fileName');
                              try {
                                srcFile.copySync(destFile.path);
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

        // 1. Write data.json atomically with flush
        final dataTmp = File('$dirPath/data.json.tmp');
        dataTmp.writeAsStringSync(jsonEncode(persistentState), flush: true);
        final dataFile = File('$dirPath/data.json');
        if (dataFile.existsSync()) {
          try {
            dataFile.deleteSync();
          } catch (_) {}
        }
        dataTmp.renameSync(dataFile.path);

        // 2. Write meta.json atomically with flush
        final metaTmp = File('$dirPath/meta.json.tmp');
        metaTmp.writeAsStringSync(jsonEncode(meta.toJson()), flush: true);
        if (metaFile.existsSync()) {
          try {
            metaFile.deleteSync();
          } catch (_) {}
        }
        metaTmp.renameSync(metaFile.path);
      });

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

  Future<void> deleteProject(String projectId) async {
    try {
      final dir = await _getProjectDirectory(projectId);
      final dirPath = dir.path;
      await Isolate.run(() {
        final d = Directory(dirPath);
        if (d.existsSync()) {
          d.deleteSync(recursive: true);
        }
      });
    } catch (e) {
      debugPrint('Error deleting project $projectId: $e');
    }
  }
}
