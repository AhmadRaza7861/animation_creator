import 'dart:io' show Platform;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to access the [AnalyticsService] anywhere via Riverpod.
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService.instance;
});

/// Comprehensive Analytics Service for Clipax.
///
/// Encapsulates Firebase Analytics with safe error-handling, debug logging,
/// automatic navigator tracking, user properties, and specialized tracking
/// methods for projects, drawing tools, animations, export, and onboarding.
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics? _analyticsInstance;

  /// Lazily obtains the FirebaseAnalytics instance if Firebase is initialized.
  FirebaseAnalytics? get _analytics {
    if (_analyticsInstance != null) {
      return _analyticsInstance;
    }
    if (Firebase.apps.isNotEmpty) {
      try {
        _analyticsInstance = FirebaseAnalytics.instance;
      } catch (e) {
        debugPrint('[Analytics] FirebaseAnalytics initialization error: $e');
      }
    }
    return _analyticsInstance;
  }

  /// Navigator observer for automatic screen tracking with MaterialApp.
  FirebaseAnalyticsObserver? _observer;
  FirebaseAnalyticsObserver get observer {
    _observer ??= FirebaseAnalyticsObserver(
      analytics: _analytics ?? FirebaseAnalytics.instance,
      nameExtractor: (settings) => settings.name,
    );
    return _observer!;
  }

  /// Helper to safely record events without crashing or blocking the app.
  Future<void> _safeLog(
    String eventName,
    Future<void> Function(FirebaseAnalytics analytics) action, {
    Map<String, Object?>? parameters,
  }) async {
    if (kDebugMode) {
      debugPrint('[Analytics] 📊 Event: $eventName | params: $parameters');
    }
    try {
      final analytics = _analytics;
      if (analytics != null) {
        await action(analytics);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Analytics] ⚠️ Failed to log event $eventName: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 1. User Properties & Device Identity
  // ---------------------------------------------------------------------------

  /// Sets the unique user identifier.
  Future<void> setUserId(String? userId) async {
    await _safeLog('set_user_id', (a) => a.setUserId(id: userId));
  }

  /// Sets a custom user property.
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _safeLog(
      'set_user_property',
      (a) => a.setUserProperty(name: name, value: value),
      parameters: {'name': name, 'value': value},
    );
  }

  /// Updates core global user properties (language, platform, etc.).
  Future<void> syncDefaultUserProperties({
    required String languageCode,
    required String themeMode,
  }) async {
    final String platform = kIsWeb
        ? 'web'
        : Platform.isAndroid
            ? 'android'
            : Platform.isIOS
                ? 'ios'
                : Platform.isMacOS
                    ? 'macos'
                    : 'other';

    await setUserProperty(name: 'app_language', value: languageCode);
    await setUserProperty(name: 'app_theme', value: themeMode);
    await setUserProperty(name: 'platform', value: platform);
  }

  // ---------------------------------------------------------------------------
  // 2. Screen & Navigation Tracking
  // ---------------------------------------------------------------------------

  /// Logs a screen view explicitly.
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _safeLog(
      'screen_view',
      (a) => a.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      ),
      parameters: {'screen_name': screenName, 'screen_class': screenClass},
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Onboarding Funnel
  // ---------------------------------------------------------------------------

  Future<void> logOnboardingStart() async {
    await _safeLog('onboarding_start', (a) => a.logTutorialBegin());
  }

  Future<void> logOnboardingStep({
    required int stepIndex,
    required String stepTitle,
  }) async {
    await _safeLog(
      'onboarding_step',
      (a) => a.logEvent(
        name: 'onboarding_step',
        parameters: {
          'step_index': stepIndex,
          'step_title': stepTitle,
        },
      ),
      parameters: {'step_index': stepIndex, 'step_title': stepTitle},
    );
  }

  Future<void> logOnboardingComplete() async {
    await _safeLog('onboarding_complete', (a) => a.logTutorialComplete());
  }

  Future<void> logOnboardingSkip({required int atStepIndex}) async {
    await _safeLog(
      'onboarding_skip',
      (a) => a.logEvent(
        name: 'onboarding_skip',
        parameters: {'at_step_index': atStepIndex},
      ),
      parameters: {'at_step_index': atStepIndex},
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Project Creation & Management
  // ---------------------------------------------------------------------------

  Future<void> logProjectCreated({
    required String projectId,
    required String name,
    required double aspectRatio,
    required int fps,
    String? templateMode,
  }) async {
    await _safeLog(
      'project_created',
      (a) => a.logEvent(
        name: 'project_created',
        parameters: {
          'project_id': projectId,
          'project_name': name,
          'aspect_ratio': aspectRatio.toStringAsFixed(2),
          'fps': fps,
          'template_mode': templateMode ?? 'blank',
        },
      ),
      parameters: {
        'project_id': projectId,
        'aspect_ratio': aspectRatio,
        'fps': fps,
        'template_mode': templateMode,
      },
    );
  }

  Future<void> logProjectOpened({
    required String projectId,
    int? frameCount,
  }) async {
    await _safeLog(
      'project_opened',
      (a) => a.logEvent(
        name: 'project_opened',
        parameters: {
          'project_id': projectId,
          'frame_count': ?frameCount,
        },
      ),
      parameters: {'project_id': projectId, 'frame_count': frameCount},
    );
  }

  Future<void> logProjectDeleted({required String projectId}) async {
    await _safeLog(
      'project_deleted',
      (a) => a.logEvent(
        name: 'project_deleted',
        parameters: {'project_id': projectId},
      ),
      parameters: {'project_id': projectId},
    );
  }

  Future<void> logProjectDuplicated({required String projectId}) async {
    await _safeLog(
      'project_duplicated',
      (a) => a.logEvent(
        name: 'project_duplicated',
        parameters: {'project_id': projectId},
      ),
      parameters: {'project_id': projectId},
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Drawing & Editor Tools
  // ---------------------------------------------------------------------------

  Future<void> logToolSelected({required String toolName}) async {
    await _safeLog(
      'tool_selected',
      (a) => a.logEvent(
        name: 'tool_selected',
        parameters: {'tool_name': toolName},
      ),
      parameters: {'tool_name': toolName},
    );
  }

  Future<void> logBrushChanged({
    required String brushType,
    double? strokeWidth,
    double? opacity,
    String? colorHex,
  }) async {
    await _safeLog(
      'brush_changed',
      (a) => a.logEvent(
        name: 'brush_changed',
        parameters: {
          'brush_type': brushType,
          if (strokeWidth != null) 'stroke_width': strokeWidth.round(),
          if (opacity != null) 'opacity': (opacity * 100).round(),
          'color_hex': ?colorHex,
        },
      ),
      parameters: {'brush_type': brushType, 'width': strokeWidth},
    );
  }

  Future<void> logLayerAction({
    required String action,
    int? layerIndex,
    int? totalLayers,
  }) async {
    await _safeLog(
      'layer_action',
      (a) => a.logEvent(
        name: 'layer_action',
        parameters: {
          'action': action,
          'layer_index': ?layerIndex,
          'total_layers': ?totalLayers,
        },
      ),
      parameters: {'action': action, 'layers': totalLayers},
    );
  }

  Future<void> logFrameAction({
    required String action,
    int? frameIndex,
    int? totalFrames,
  }) async {
    await _safeLog(
      'frame_action',
      (a) => a.logEvent(
        name: 'frame_action',
        parameters: {
          'action': action,
          'frame_index': ?frameIndex,
          'total_frames': ?totalFrames,
        },
      ),
      parameters: {'action': action, 'frames': totalFrames},
    );
  }

  Future<void> logPlaybackAction({
    required String action,
    required int fps,
    required int totalFrames,
  }) async {
    await _safeLog(
      'animation_playback',
      (a) => a.logEvent(
        name: 'animation_playback',
        parameters: {
          'action': action,
          'fps': fps,
          'total_frames': totalFrames,
        },
      ),
      parameters: {'action': action, 'fps': fps, 'frames': totalFrames},
    );
  }

  Future<void> logAudioAction({
    required String action,
    String? trackType,
  }) async {
    await _safeLog(
      'audio_action',
      (a) => a.logEvent(
        name: 'audio_action',
        parameters: {
          'action': action,
          'track_type': ?trackType,
        },
      ),
      parameters: {'action': action, 'track': trackType},
    );
  }

  Future<void> logBackgroundChanged({required String backgroundType}) async {
    await _safeLog(
      'background_changed',
      (a) => a.logEvent(
        name: 'background_changed',
        parameters: {'type': backgroundType},
      ),
      parameters: {'type': backgroundType},
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Export, Movie & Sharing Funnel
  // ---------------------------------------------------------------------------

  Future<void> logExportStarted({
    required String format,
    required int fps,
    required String resolution,
    required int totalFrames,
  }) async {
    await _safeLog(
      'export_started',
      (a) => a.logEvent(
        name: 'export_started',
        parameters: {
          'format': format.toLowerCase(),
          'fps': fps,
          'resolution': resolution,
          'total_frames': totalFrames,
        },
      ),
      parameters: {
        'format': format,
        'fps': fps,
        'res': resolution,
        'frames': totalFrames,
      },
    );
  }

  Future<void> logExportCompleted({
    required String format,
    required int durationSeconds,
    int? fileSizeBytes,
  }) async {
    await _safeLog(
      'export_completed',
      (a) => a.logEvent(
        name: 'export_completed',
        parameters: {
          'format': format.toLowerCase(),
          'duration_seconds': durationSeconds,
          if (fileSizeBytes != null)
            'file_size_kb': (fileSizeBytes / 1024).round(),
        },
      ),
      parameters: {'format': format, 'duration_s': durationSeconds},
    );
  }

  Future<void> logExportFailed({
    required String format,
    required String error,
  }) async {
    await _safeLog(
      'export_failed',
      (a) => a.logEvent(
        name: 'export_failed',
        parameters: {
          'format': format.toLowerCase(),
          'error': error.length > 100 ? error.substring(0, 100) : error,
        },
      ),
      parameters: {'format': format, 'error': error},
    );
  }

  Future<void> logShareClicked({
    required String contentType,
    String? format,
  }) async {
    await _safeLog(
      'share_content',
      (a) => a.logShare(
        contentType: contentType,
        itemId: format ?? 'animation',
        method: 'system_share_sheet',
      ),
      parameters: {'content_type': contentType, 'format': format},
    );
  }

  // ---------------------------------------------------------------------------
  // 7. Settings, Rating & User Engagement
  // ---------------------------------------------------------------------------

  Future<void> logRatingDialogShown() async {
    await _safeLog(
      'rating_dialog_shown',
      (a) => a.logEvent(name: 'rating_dialog_shown'),
    );
  }

  Future<void> logRatingSubmitted({
    required int stars,
    bool hadFeedback = false,
  }) async {
    await _safeLog(
      'rating_submitted',
      (a) => a.logEvent(
        name: 'rating_submitted',
        parameters: {
          'stars': stars,
          'had_feedback': hadFeedback ? 1 : 0,
        },
      ),
      parameters: {'stars': stars, 'had_feedback': hadFeedback},
    );
  }

  Future<void> logLanguageChanged({required String languageCode}) async {
    await setUserProperty(name: 'app_language', value: languageCode);
    await _safeLog(
      'language_changed',
      (a) => a.logEvent(
        name: 'language_changed',
        parameters: {'language': languageCode},
      ),
      parameters: {'language': languageCode},
    );
  }

  Future<void> logTutorialViewed({required String tutorialTitle}) async {
    await _safeLog(
      'tutorial_viewed',
      (a) => a.logEvent(
        name: 'tutorial_viewed',
        parameters: {'title': tutorialTitle},
      ),
      parameters: {'title': tutorialTitle},
    );
  }

  Future<void> logTemplateSelected({required String templateId}) async {
    await _safeLog(
      'template_selected',
      (a) => a.logSelectContent(
        contentType: 'template',
        itemId: templateId,
      ),
      parameters: {'template_id': templateId},
    );
  }

  // ---------------------------------------------------------------------------
  // 8. Generic Custom Event
  // ---------------------------------------------------------------------------

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await _safeLog(
      name,
      (a) => a.logEvent(name: name, parameters: parameters),
      parameters: parameters,
    );
  }
}
