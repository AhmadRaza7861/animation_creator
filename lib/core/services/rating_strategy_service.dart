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
  static const int _maxLifetimePrompts = 3;
  static const Duration _cooldownDuration = Duration(days: 2);

  // In-memory cache
  static bool _hasRated = false;
  static int _promptCount = 0;
  static DateTime? _lastPromptTime;
  static int _exportCount = 0;
  static int _projectCreatedCount = 0;
  static int _tutorialCompletedCount = 0;
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
        'updated_at': DateTime.now().toIso8601String(),
      };
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('RatingStrategyService save error: $e');
    }
  }

  /// Evaluates whether the rating dialog is eligible to be shown.
  static Future<bool> shouldShowPrompt() async {
    if (!_isLoaded) await load();

    // Rule 1: Never prompt if user has already rated or submitted feedback
    if (_hasRated) return false;

    // Rule 2: Hard lifetime cap on automatic prompts
    if (_promptCount >= _maxLifetimePrompts) return false;

    // Rule 3: Enforce 2-day cooldown between prompts
    if (_lastPromptTime != null) {
      final difference = DateTime.now().difference(_lastPromptTime!);
      if (difference < _cooldownDuration) return false;
    }

    return true;
  }

  /// Mark that the user rated (1-5 stars or feedback submitted)
  static Future<void> markRated() async {
    if (!_isLoaded) await load();
    _hasRated = true;
    await _save();
  }

  /// Mark prompt shown (increments count and sets cooldown)
  static Future<void> markPromptShown() async {
    if (!_isLoaded) await load();
    _promptCount++;
    _lastPromptTime = DateTime.now();
    await _save();
  }

  /// Trigger 1: Called when animation export or gallery save completes (Peak Joy)
  static Future<void> recordExport(BuildContext context) async {
    if (!_isLoaded) await load();
    _exportCount++;
    await _save();

    // Trigger on 1st successful export and 3rd export
    if (_exportCount == 1 || _exportCount == 3) {
      if (await shouldShowPrompt() && context.mounted) {
        await _showDialogWithDelay(context);
      }
    }
  }

  /// Trigger 2: Called when user creates their 2nd or 3rd project
  static Future<void> recordProjectCreated(BuildContext context) async {
    if (!_isLoaded) await load();
    _projectCreatedCount++;
    await _save();

    // Trigger on 2nd project creation milestone
    if (_projectCreatedCount == 2) {
      if (await shouldShowPrompt() && context.mounted) {
        await _showDialogWithDelay(context);
      }
    }
  }

  /// Trigger 3: Called when user completes an animation tutorial
  static Future<void> recordTutorialCompleted(BuildContext context) async {
    if (!_isLoaded) await load();
    _tutorialCompletedCount++;
    await _save();

    // Trigger on 1st completed tutorial
    if (_tutorialCompletedCount == 1) {
      if (await shouldShowPrompt() && context.mounted) {
        await _showDialogWithDelay(context);
      }
    }
  }

  static Future<void> _showDialogWithDelay(BuildContext context) async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (!context.mounted) return;
    await markPromptShown();
    if (context.mounted) {
      await RateUsDialog.show(context);
    }
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
  static DateTime? get lastPromptTime => _lastPromptTime;
}
