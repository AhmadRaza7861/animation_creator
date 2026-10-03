import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../core/utils/app_path_provider.dart';

class OnboardingService {
  static const String _fileName = 'onboarding_state.json';
  static bool? _isCompletedCache;

  /// Check if the user has previously completed onboarding
  static Future<bool> isOnboardingCompleted() async {
    if (_isCompletedCache != null) {
      return _isCompletedCache!;
    }
    try {
      final dir = await AppPathProvider.getSafeDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        _isCompletedCache = data['is_completed'] as bool? ?? false;
        return _isCompletedCache!;
      }
    } catch (e) {
      debugPrint('OnboardingService isOnboardingCompleted error: $e');
    }
    _isCompletedCache = false;
    return false;
  }

  /// Mark onboarding as completed
  static Future<void> markOnboardingCompleted() async {
    _isCompletedCache = true;
    try {
      final dir = await AppPathProvider.getSafeDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      await file.writeAsString(jsonEncode({
        'is_completed': true,
        'completed_at': DateTime.now().toIso8601String(),
      }));
    } catch (e) {
      debugPrint('OnboardingService markOnboardingCompleted error: $e');
    }
  }

  /// Reset onboarding state
  static Future<void> resetOnboarding() async {
    _isCompletedCache = false;
    try {
      final dir = await AppPathProvider.getSafeDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('OnboardingService resetOnboarding error: $e');
    }
  }
}
