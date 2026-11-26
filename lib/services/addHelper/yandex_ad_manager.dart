import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

/// Yandex Mobile Ads, used instead of AdMob when Remote Config `is_russian`
/// is true. Do not call this directly from screens: go through `AdManager`,
/// which checks `is_russian` and the other ad flags, then picks the network.
///
/// Kept in its own file because Yandex and Google Mobile Ads both define
/// `InterstitialAd`, `AppOpenAd` and `AdRequest`.
class YandexAdManager {
  YandexAdManager._();

  static const String openAppAdUnitId = 'R-M-20328915-1';
  static const String interstitialAdUnitId = 'R-M-20328915-2';

  static Future<void>? _initFuture;

  /// Initializes the Yandex SDK once. Safe to call repeatedly.
  static Future<void> initialize() {
    return _initFuture ??= YandexAds.initialize().catchError((Object e) {
      debugPrint('[YandexAds] initialize error: $e');
      _initFuture = null;
    });
  }

  // ================= OPEN APP AD =================

  static AppOpenAd? _openAd;
  static bool _isShowingOpenAd = false;

  /// Loads the open app ad and shows it as soon as it is loaded
  /// (same behaviour as the AdMob splash ad).
  static Future<void> loadOpenAppAd({
    VoidCallback? onAdLoaded,
    void Function(String error)? onAdFailedToLoad,
    VoidCallback? onAdDismissed,
  }) async {
    try {
      await initialize();
      final AppOpenAd ad = await AppOpenAdLoader().loadAd(
        adRequest: const AdRequest(adUnitId: openAppAdUnitId),
      );
      debugPrint('[YandexAds] Open app ad loaded');
      _openAd = ad;
      onAdLoaded?.call();
      await _showOpenAd(onAdDismissed);
    } catch (e) {
      debugPrint('[YandexAds] Open app ad failed to load: $e');
      onAdFailedToLoad?.call(e is AdRequestError ? e.description : e.toString());
    }
  }

  static Future<void> _showOpenAd(VoidCallback? onAdDismissed) async {
    final AppOpenAd? ad = _openAd;
    if (ad == null || _isShowingOpenAd) return;
    _isShowingOpenAd = true;

    bool finished = false;
    void finish() {
      if (finished) return;
      finished = true;
      _clearOpenAd();
      onAdDismissed?.call();
    }

    await ad.setAdEventListener(
      eventListener: AppOpenAdEventListener(
        onAdShown: () => debugPrint('[YandexAds] Open app ad shown'),
        onAdFailedToShow: (AdError error) {
          debugPrint('[YandexAds] Open app ad failed to show: ${error.description}');
          finish();
        },
        onAdDismissed: finish,
        onAdClicked: () {},
        onAdImpression: (_) {},
      ),
    );
    try {
      await ad.show();
      await ad.waitForDismiss();
    } catch (e) {
      debugPrint('[YandexAds] Open app ad show error: $e');
      finish();
    }
  }

  static void _clearOpenAd() {
    _openAd?.destroy();
    _openAd = null;
    _isShowingOpenAd = false;
  }

  // ================= INTERSTITIAL AD =================

  static InterstitialAd? _interstitialAd;
  static bool _isLoadingInterstitial = false;
  static bool _isShowingInterstitial = false;
  static int _numLoadAttempts = 0;
  static const int _maxFailedLoadAttempts = 3;

  /// Preloads an interstitial so it is ready when [showInterstitialAd] runs.
  static Future<void> createInterstitialAd() async {
    if (_interstitialAd != null || _isLoadingInterstitial) return;
    _isLoadingInterstitial = true;
    try {
      await initialize();
      final InterstitialAd ad = await InterstitialAdLoader().loadAd(
        adRequest: const AdRequest(adUnitId: interstitialAdUnitId),
      );
      debugPrint('[YandexAds] Interstitial loaded');
      _interstitialAd = ad;
      _numLoadAttempts = 0;
      _isLoadingInterstitial = false;
    } catch (e) {
      debugPrint('[YandexAds] Interstitial failed to load: $e');
      _interstitialAd = null;
      _isLoadingInterstitial = false;
      _numLoadAttempts++;
      if (_numLoadAttempts < _maxFailedLoadAttempts) {
        unawaited(createInterstitialAd());
      }
    }
  }

  /// Shows the preloaded interstitial. If none is ready, [onAdDismissed] is
  /// called immediately (so the app continues) and a new one starts loading.
  static Future<void> showInterstitialAd({
    VoidCallback? onAdShowed,
    VoidCallback? onAdDismissed,
    void Function(String error)? onAdFailed,
  }) async {
    final InterstitialAd? ad = _interstitialAd;
    if (ad == null || _isShowingInterstitial) {
      _numLoadAttempts = 0;
      unawaited(createInterstitialAd());
      onAdDismissed?.call();
      return;
    }
    _interstitialAd = null;
    _isShowingInterstitial = true;

    bool finished = false;
    void finish(VoidCallback done) {
      if (finished) return;
      finished = true;
      ad.destroy();
      _isShowingInterstitial = false;
      _numLoadAttempts = 0;
      unawaited(createInterstitialAd());
      done();
    }

    await ad.setAdEventListener(
      eventListener: InterstitialAdEventListener(
        onAdShown: () => onAdShowed?.call(),
        onAdFailedToShow: (AdError error) {
          debugPrint('[YandexAds] Interstitial failed to show: ${error.description}');
          finish(() => onAdFailed?.call(error.description));
        },
        onAdDismissed: () => finish(() => onAdDismissed?.call()),
        onAdClicked: () {},
        onAdImpression: (_) {},
      ),
    );
    try {
      await ad.show();
      await ad.waitForDismiss();
    } catch (e) {
      debugPrint('[YandexAds] Interstitial show error: $e');
      finish(() => onAdFailed?.call(e.toString()));
    }
  }
}
