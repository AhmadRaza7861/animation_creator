import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Service managing Firebase Remote Config flags for ads and feature toggles.
class RemoteConfigService {
  RemoteConfigService._();

  static final RemoteConfigService instance = RemoteConfigService._();

  /// Remote Config parameter keys (must match Firebase Console names exactly).
  static const String keyIsShowAds = 'Is_show_ads';
  static const String keyIsShowOpenAppAd = 'is_show_open_app_ad';
  static const String keyIsShowTutorialAd = 'is_show_tutorial_ad';
  static const String keyIsShowCreateProjectBtn = 'is_show_create_project_btn';
  static const String keyIsShowHistoryAd = 'is_show_history_ad';
  static const String keyIsShowExportAd = 'is_show_export_ad';
  static const String keyProjectSttingAd = 'project_stting_ad';
  static const String keyIsShowAdOnImport = 'is_show_ad_on_import';
  static const String keyIsShowAplyBrushAd = 'is_show_aply_brush_ad';

  /// When true, Yandex ads are shown instead of AdMob (Russian users).
  static const String keyIsRussian = 'is_russian';

  FirebaseRemoteConfig? _remoteConfig;
  Future<void>? _initFuture;
  bool _defaultsApplied = false;
  bool? _testIsShowAds;
  bool? _testIsShowOpenAppAd;
  bool? _testIsShowTutorialAd;
  bool? _testIsShowCreateProjectBtn;
  bool? _testIsShowHistoryAd;
  bool? _testIsShowExportAd;
  bool? _testProjectSttingAd;
  bool? _testIsShowAdOnImport;
  bool? _testIsShowAplyBrushAd;
  bool? _testIsRussian;

  @visibleForTesting
  void setTestValues({
    bool? isShowAds,
    bool? isShowOpenAppAd,
    bool? isShowTutorialAd,
    bool? isShowCreateProjectBtn,
    bool? isShowHistoryAd,
    bool? isShowExportAd,
    bool? projectSttingAd,
    bool? isShowAdOnImport,
    bool? isShowAplyBrushAd,
    bool? isRussian,
  }) {
    _testIsShowAds = isShowAds;
    _testIsShowOpenAppAd = isShowOpenAppAd;
    _testIsShowTutorialAd = isShowTutorialAd;
    _testIsShowCreateProjectBtn = isShowCreateProjectBtn;
    _testIsShowHistoryAd = isShowHistoryAd;
    _testIsShowExportAd = isShowExportAd;
    _testProjectSttingAd = projectSttingAd;
    _testIsShowAdOnImport = isShowAdOnImport;
    _testIsShowAplyBrushAd = isShowAplyBrushAd;
    _testIsRussian = isRussian;
  }

  @visibleForTesting
  void resetTestValues() {
    _testIsShowAds = null;
    _testIsShowOpenAppAd = null;
    _testIsShowTutorialAd = null;
    _testIsShowCreateProjectBtn = null;
    _testIsShowHistoryAd = null;
    _testIsShowExportAd = null;
    _testProjectSttingAd = null;
    _testIsShowAdOnImport = null;
    _testIsShowAplyBrushAd = null;
    _testIsRussian = null;
  }

  FirebaseRemoteConfig? get _rc {
    if (_remoteConfig != null) return _remoteConfig;
    if (Firebase.apps.isNotEmpty) {
      try {
        _remoteConfig = FirebaseRemoteConfig.instance;
      } catch (e) {
        debugPrint('[RemoteConfig] Initialization error: $e');
      }
    }
    return _remoteConfig;
  }

  /// Initializes Remote Config, sets defaults, and fetches + activates values.
  /// Safe to call multiple times; concurrent callers share the same future.
  Future<void> init() {
    return _initFuture ??= _initInternal();
  }

  /// Awaits the initial Remote Config fetch, bounded by [timeout].
  Future<void> ensureFetched({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      await init().timeout(timeout);
    } catch (e) {
      debugPrint('[RemoteConfig] Fetch wait timed out or failed: $e');
    }
  }

  Future<void> _initInternal() async {
    final rc = _rc;
    if (rc == null) return;

    try {
      if (!_defaultsApplied) {
        await rc.setDefaults(const <String, dynamic>{
          keyIsShowAds: true,
          keyIsShowOpenAppAd: true,
          keyIsShowTutorialAd: true,
          keyIsShowCreateProjectBtn: true,
          keyIsShowHistoryAd: true,
          keyIsShowExportAd: true,
          keyProjectSttingAd: true,
          keyIsShowAdOnImport: true,
          keyIsShowAplyBrushAd: true,
          // Default to AdMob if Remote Config can't be fetched.
          keyIsRussian: false,
        });
        _defaultsApplied = true;
      }

      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 5),
          minimumFetchInterval: Duration.zero,
        ),
      );

      final updated = await rc.fetchAndActivate();
      debugPrint(
        '[RemoteConfig] Fetched (updated=$updated) | '
        '$keyIsShowAds=$isShowAds | $keyIsShowOpenAppAd=$isShowOpenAppAd | '
        '$keyIsShowTutorialAd=$isShowTutorialAd | '
        '$keyIsShowCreateProjectBtn=$isShowCreateProjectBtn | '
        '$keyIsShowHistoryAd=$isShowHistoryAd | '
        '$keyIsShowExportAd=$isShowExportAd | '
        '$keyProjectSttingAd=$isShowProjectSettingAd | '
        '$keyIsShowAdOnImport=$isShowAdOnImport | '
        '$keyIsShowAplyBrushAd=$isShowApplyBrushAd | '
        '$keyIsRussian=$isRussian',
      );
    } catch (e) {
      debugPrint('[RemoteConfig] fetchAndActivate error: $e');
    }
  }

  /// Controls whether ads are shown anywhere in the app.
  bool get isShowAds {
    if (_testIsShowAds != null) return _testIsShowAds!;
    final rc = _rc;
    if (rc == null) return false;
    return rc.getBool(keyIsShowAds);
  }

  /// Controls whether the open app ad is shown on splash.
  bool get isShowOpenAppAd {
    if (_testIsShowOpenAppAd != null) return _testIsShowOpenAppAd!;
    final rc = _rc;
    if (rc == null) return false;
    return rc.getBool(keyIsShowOpenAppAd);
  }

  /// Controls whether the interstitial ad is shown on tutorials/templates.
  bool get isShowTutorialAd {
    if (_testIsShowTutorialAd != null) return _testIsShowTutorialAd!;
    final rc = _rc;
    if (rc == null) return false;
    return rc.getBool(keyIsShowTutorialAd);
  }

  /// Controls whether the interstitial ad is shown on the Create Project button.
  bool get isShowCreateProjectBtn {
    if (_testIsShowCreateProjectBtn != null) {
      return _testIsShowCreateProjectBtn!;
    }
    final rc = _rc;
    if (rc == null) return false;
    return rc.getBool(keyIsShowCreateProjectBtn);
  }

  /// Controls whether the interstitial ad is shown when opening existing projects.
  bool get isShowHistoryAd {
    if (_testIsShowHistoryAd != null) return _testIsShowHistoryAd!;
    final rc = _rc;
    if (rc == null) return false;
    return rc.getBool(keyIsShowHistoryAd);
  }

  /// Controls whether the interstitial ad is shown when clicking Export.
  bool get isShowExportAd {
    if (_testIsShowExportAd != null) return _testIsShowExportAd!;
    final rc = _rc;
    if (rc == null) return false;
    return rc.getBool(keyIsShowExportAd);
  }

  /// Controls whether the interstitial ad is shown on Project settings.
  bool get isShowProjectSettingAd {
    if (_testProjectSttingAd != null) return _testProjectSttingAd!;
    final rc = _rc;
    if (rc == null) return false;
    return rc.getBool(keyProjectSttingAd);
  }

  /// Controls whether the interstitial ad is shown when importing media.
  bool get isShowAdOnImport {
    if (_testIsShowAdOnImport != null) return _testIsShowAdOnImport!;
    final rc = _rc;
    if (rc == null) return false;
    return rc.getBool(keyIsShowAdOnImport);
  }

  /// Controls whether the interstitial ad is shown on Apply Brush.
  bool get isShowApplyBrushAd {
    if (_testIsShowAplyBrushAd != null) return _testIsShowAplyBrushAd!;
    final rc = _rc;
    if (rc == null) return false;
    return rc.getBool(keyIsShowAplyBrushAd);
  }

  /// `is_russian`: when true, ads are served by Yandex instead of AdMob.
  /// All other ad flags (`Is_show_ads`, per-screen flags) apply to both.
  bool get isRussian {
    if (_testIsRussian != null) return _testIsRussian!;
    final rc = _rc;
    if (rc == null) return false;
    return rc.getBool(keyIsRussian);
  }

  /// 1st checks if `Is_show_ads` is true, then checks if `is_show_open_app_ad` is true.
  bool get shouldShowOpenAppAd {
    if (isShowAds) {
      if (isShowOpenAppAd) {
        return true;
      }
    }
    return false;
  }

  /// 1st checks if `Is_show_ads` is true, then checks if `is_show_tutorial_ad` is true.
  bool get shouldShowTutorialAd {
    if (isShowAds) {
      if (isShowTutorialAd) {
        return true;
      }
    }
    return false;
  }

  /// 1st checks if `Is_show_ads` is true, then checks if `is_show_create_project_btn` is true.
  bool get shouldShowCreateProjectBtnAd {
    if (isShowAds) {
      if (isShowCreateProjectBtn) {
        return true;
      }
    }
    return false;
  }

  /// 1st checks if `Is_show_ads` is true, then checks if `is_show_history_ad` is true.
  bool get shouldShowHistoryAd {
    if (isShowAds) {
      if (isShowHistoryAd) {
        return true;
      }
    }
    return false;
  }

  /// 1st checks if `Is_show_ads` is true, then checks if `is_show_export_ad` is true.
  bool get shouldShowExportAd {
    if (isShowAds) {
      if (isShowExportAd) {
        return true;
      }
    }
    return false;
  }

  /// 1st checks if `Is_show_ads` is true, then checks if `project_stting_ad` is true.
  bool get shouldShowProjectSettingAd {
    if (isShowAds) {
      if (isShowProjectSettingAd) {
        return true;
      }
    }
    return false;
  }

  /// 1st checks if `Is_show_ads` is true, then checks if `is_show_ad_on_import` is true.
  bool get shouldShowAdOnImport {
    if (isShowAds) {
      if (isShowAdOnImport) {
        return true;
      }
    }
    return false;
  }

  /// 1st checks if `Is_show_ads` is true, then checks if `is_show_aply_brush_ad` is true.
  bool get shouldShowApplyBrushAd {
    if (isShowAds) {
      if (isShowApplyBrushAd) {
        return true;
      }
    }
    return false;
  }
}

