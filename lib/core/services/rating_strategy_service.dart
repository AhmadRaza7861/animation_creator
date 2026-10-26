import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/app_path_provider.dart';
import '../../features/settings/presentation/dialogs/rate_us_dialog.dart';

enum RatingTriggerType {
  exportCompleted,
  projectCreated,
  tutorialCompleted,
}

class RatingStrategyService {
  RatingStrategyService._();

  static const String _fileName = 'rating_strategy.json';

  // In-memory cache
  static bool _hasRated = false;
  static int _promptCount = 0;
  static DateTime? _lastPromptTime;
  static int _exportCount = 0;
  static int _projectCreatedCount = 0;
  static int _tutorialCompletedCount = 0;
  static int _appOpenCount = 0;
  static bool _sessionRecordedThisLaunch = false;
  static bool _isLoaded = false;

  /// Load persisted state
  static Future<void> load() async {
    try {
      final dir = await AppPathProvider.getSafeDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        _hasRated = data['has_rated'] as bool? ?? false;
        _promptCount = data['prompt_count'] as int? ?? 0;
        final lastPromptStr = data['last_prompt_time'] as String?;
        _lastPromptTime = lastPromptStr != null ? DateTime.tryParse(lastPromptStr) : null;
        _exportCount = data['export_count'] as int? ?? 0;
        _projectCreatedCount = data['project_created_count'] as int? ?? 0;
        _tutorialCompletedCount = data['tutorial_completed_count'] as int? ?? 0;
        _appOpenCount = data['app_open_count'] as int? ?? 0;
      }
    } catch (e) {
      debugPrint('RatingStrategyService load error: $e');
    }
    _isLoaded = true;
  }

  /// Save state to file
  static Future<void> _save() async {
    try {
      final dir = await AppPathProvider.getSafeDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      final data = {
        'has_rated': _hasRated,
        'prompt_count': _promptCount,
        'last_prompt_time': _lastPromptTime?.toIso8601String(),
        'export_count': _exportCount,
        'project_created_count': _projectCreatedCount,
        'tutorial_completed_count': _tutorialCompletedCount,
        'app_open_count': _appOpenCount,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('RatingStrategyService save error: $e');
    }
  }

  static bool _isShowingDialog = false;

  /// Evaluates whether the rating dialog is eligible to be shown.
  static Future<bool> shouldShowPrompt() async {
    if (!_isLoaded) await load();

    // Stop only when the user has rated the app (1-5 stars or feedback submitted)
    if (_hasRated) return false;

    return true;
  }

  /// Mark that the user rated (1-5 stars or feedback submitted)
  static Future<void> markRated() async {
    if (!_isLoaded) await load();
    _hasRated = true;
    await _save();
  }

  /// Mark prompt shown
  static Future<void> markPromptShown() async {
    if (!_isLoaded) await load();
    _promptCount++;
    _lastPromptTime = DateTime.now();
    await _save();
  }

  /// Trigger 1: Called when animation export completes (after the result screen)
  static Future<void> recordExport(BuildContext context) async {
    if (!_isLoaded) await load();
    _exportCount++;
    await _save();

    // Show every time after the result until user rates the app
    if (await shouldShowPrompt() && context.mounted) {
      await _showDialogWithDelay(context);
    }
  }

  /// Trigger 2: Called when user creates a project
  static Future<void> recordProjectCreated(BuildContext context) async {
    if (!_isLoaded) await load();
    _projectCreatedCount++;
    await _save();
  }

  /// Trigger 3: Called when user completes an animation tutorial
  static Future<void> recordTutorialCompleted(BuildContext context) async {
    if (!_isLoaded) await load();
    _tutorialCompletedCount++;
    await _save();
  }

  /// Trigger 4: Called when user visits the home page (projects screen)
  static Future<void> recordHomeVisit(BuildContext context) async {
    if (!_isLoaded) await load();
    if (!_sessionRecordedThisLaunch) {
      _sessionRecordedThisLaunch = true;
      _appOpenCount++;
      await _save();
    }

    // Show rating dialog on home page when user visits 2nd time (or subsequent times before rating)
    if (_appOpenCount >= 2 && await shouldShowPrompt() && context.mounted) {
      await _showDialogWithDelay(context);
    }
  }

  /// Trigger 5: Called when user returns home from the editor screen
  static Future<void> recordReturnedFromEditor(BuildContext context) async {
    if (!_isLoaded) await load();
    if (await shouldShowPrompt() && context.mounted) {
      await _showDialogWithDelay(context);
    }
  }

  static Future<void> _showDialogWithDelay(BuildContext context) async {
    if (_isShowingDialog) return;
    _isShowingDialog = true;
    try {
      await Future.delayed(const Duration(milliseconds: 700));
      if (!context.mounted) return;
      if (!await shouldShowPrompt()) return;
      await markPromptShown();
      if (context.mounted) {
        await RateUsDialog.show(context);
      }
    } finally {
      _isShowingDialog = false;
    }
  }

  /// For testing: resets session flag to simulate new app launch
  @visibleForTesting
  static void resetSessionForTesting() {
    _sessionRecordedThisLaunch = false;
    _isShowingDialog = false;
  }

  /// For testing/debugging purposes: resets all strategy metrics
  @visibleForTesting
  static Future<void> resetForTesting() async {
    _hasRated = false;
    _promptCount = 0;
    _lastPromptTime = null;
    _exportCount = 0;
    _projectCreatedCount = 0;
    _tutorialCompletedCount = 0;
    _appOpenCount = 0;
    _sessionRecordedThisLaunch = false;
    _isShowingDialog = false;
    _isLoaded = true;
    try {
      final dir = await AppPathProvider.getSafeDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  // Getters for inspection
  static bool get hasRated => _hasRated;
  static int get promptCount => _promptCount;
  static int get exportCount => _exportCount;
  static int get projectCreatedCount => _projectCreatedCount;
  static int get tutorialCompletedCount => _tutorialCompletedCount;
  static int get appOpenCount => _appOpenCount;
  static DateTime? get lastPromptTime => _lastPromptTime;
}
