import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Centralized, crash-proof directory provider with multi-level fallbacks.
/// Handles transient platform channel disconnects, Pigeon errors, and sandboxed OS paths.
class AppPathProvider {
  /// Safely get temporary directory with multiple layers of fallbacks
  static Future<Directory> getSafeTempDirectory() async {
    // 1. Try standard getTemporaryDirectory()
    try {
      final dir = await getTemporaryDirectory();
      if (await dir.exists()) return dir;
      await dir.create(recursive: true);
      return dir;
    } catch (e) {
      debugPrint('AppPathProvider getTemporaryDirectory failed: $e');
    }

    // 2. Try getApplicationSupportDirectory()
    try {
      final dir = await getApplicationSupportDirectory();
      final tempDir = Directory('${dir.path}/temp');
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }
      return tempDir;
    } catch (e) {
      debugPrint('AppPathProvider getApplicationSupportDirectory fallback failed: $e');
    }

    // 3. Try getApplicationDocumentsDirectory()
    try {
      final dir = await getApplicationDocumentsDirectory();
      final tempDir = Directory('${dir.path}/temp');
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }
      return tempDir;
    } catch (e) {
      debugPrint('AppPathProvider getApplicationDocumentsDirectory fallback failed: $e');
    }

    // 4. Try Android specific internal storage paths
    if (Platform.isAndroid) {
      final candidatePaths = [
        '/data/user/0/com.example.dummy/cache',
        '/data/data/com.example.dummy/cache',
        '/data/user/0/com.example.dummy/app_flutter',
        '/data/data/com.example.dummy/app_flutter',
      ];
      for (final path in candidatePaths) {
        try {
          final dir = Directory(path);
          if (await dir.exists()) return dir;
          await dir.create(recursive: true);
          return dir;
        } catch (_) {}
      }
    }

    // 5. System temp directory fallback
    try {
      final sysTemp = Directory.systemTemp;
      if (await sysTemp.exists()) {
        final clipaxTemp = Directory('${sysTemp.path}/clipax_temp');
        if (!await clipaxTemp.exists()) {
          await clipaxTemp.create(recursive: true);
        }
        return clipaxTemp;
      }
    } catch (e) {
      debugPrint('AppPathProvider Directory.systemTemp fallback failed: $e');
    }

    return Directory.current;
  }

  /// Safely get documents / storage directory with fallbacks
  static Future<Directory> getSafeDocumentsDirectory() async {
    // 1. Try standard getApplicationDocumentsDirectory()
    try {
      final dir = await getApplicationDocumentsDirectory();
      if (await dir.exists()) return dir;
      await dir.create(recursive: true);
      return dir;
    } catch (e) {
      debugPrint('AppPathProvider getApplicationDocumentsDirectory failed: $e');
    }

    // 2. Try getApplicationSupportDirectory()
    try {
      final dir = await getApplicationSupportDirectory();
      if (await dir.exists()) return dir;
      await dir.create(recursive: true);
      return dir;
    } catch (e) {
      debugPrint('AppPathProvider getApplicationSupportDirectory fallback failed: $e');
    }

    // 3. Try getSafeTempDirectory()
    try {
      final dir = await getSafeTempDirectory();
      final docsDir = Directory('${dir.path}/documents');
      if (!await docsDir.exists()) {
        await docsDir.create(recursive: true);
      }
      return docsDir;
    } catch (e) {
      debugPrint('AppPathProvider getSafeTempDirectory docs fallback failed: $e');
    }

    // 4. Android internal storage
    if (Platform.isAndroid) {
      final candidatePaths = [
        '/data/user/0/com.example.dummy/app_flutter',
        '/data/data/com.example.dummy/app_flutter',
        '/data/user/0/com.example.dummy/files',
        '/data/data/com.example.dummy/files',
      ];
      for (final path in candidatePaths) {
        try {
          final dir = Directory(path);
          if (await dir.exists()) return dir;
          await dir.create(recursive: true);
          return dir;
        } catch (_) {}
      }
    }

    return Directory.systemTemp;
  }

  /// Safely get movie export destination directory
  static Future<Directory> getSafeExportDirectory() async {
    try {
      final docs = await getSafeDocumentsDirectory();
      final exportDir = Directory('${docs.path}/Movies/Clipax');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      return exportDir;
    } catch (e) {
      debugPrint('AppPathProvider getSafeExportDirectory from docs failed: $e');
    }

    try {
      final temp = await getSafeTempDirectory();
      final exportDir = Directory('${temp.path}/Movies/Clipax');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      return exportDir;
    } catch (e) {
      debugPrint('AppPathProvider getSafeExportDirectory from temp failed: $e');
    }

    return getSafeTempDirectory();
  }
}
