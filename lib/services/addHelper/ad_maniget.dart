import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/remote_config_service.dart';
import 'ad_helper.dart';

class AdManager {
  static AnalyticsService? analyticsService;
  static Future<void>? _initFuture;

  /// Initializes the Google Mobile Ads SDK once when `Is_show_ads` is true.
  static Future<void> initialize() {
    if (!RemoteConfigService.instance.isShowAds) {
      return Future.value();
    }
    return _initFuture ??= MobileAds.instance
        .initialize()
        .then((_) {})
        .catchError((Object e) {
          debugPrint('MobileAds initialize error: $e');
          _initFuture = null;
        });
  }

  // Interstitial ad
  static InterstitialAd? interstitialAd;
  static int numInterstitialLoadAttempts = 0;
  static int maxFailedLoadAttempts = 3;
  static Function()? _onAdShowedCallback;
  static Function()? _onAdDismissedCallback;
  static Function(AdError)? _onAdFailedToShowCallback;

  static void checkConsentFormStatus() {
    if (!RemoteConfigService.instance.isShowAds) return;
    _checkConsentAndLoadAd(() {});
  }

  static void createInterstitialAd() {
    if (!RemoteConfigService.instance.isShowAds) return;
    _checkConsentAndLoadAd(() {
      if (interstitialAd == null) {
        InterstitialAd.load(
          adUnitId: AdHelper.interstitialAdUnitId,
          request: AdRequest(),
          adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (InterstitialAd ad) {
              interstitialAd = ad;
              numInterstitialLoadAttempts = 0;
              interstitialAd!.setImmersiveMode(true);

              interstitialAd!.onPaidEvent =
                  (ad, valueMicros, precision, currencyCode) {};
            },
            onAdFailedToLoad: (LoadAdError error) {
              numInterstitialLoadAttempts += 1;
              interstitialAd = null;
              if (numInterstitialLoadAttempts < maxFailedLoadAttempts) {
                createInterstitialAd();
              }
            },
          ),
        );
      } else {
        debugPrint("CONTROLL NOT ENTER 22");
      }
    });
  }

  static void showInterstitialAd({
    Function()? onAdShowed,
    Function()? onAdDismissed,
    Function(AdError)? onAdFailed,
  })
  {
    if (!RemoteConfigService.instance.isShowAds) {
      onAdDismissed?.call();
      return;
    }
    _onAdShowedCallback = onAdShowed;
    _onAdDismissedCallback = onAdDismissed;
    _onAdFailedToShowCallback = onAdFailed;

    if (interstitialAd == null) {
      createInterstitialAd();
      _onAdDismissedCallback?.call();
      return;
    }
    try {
      AppLifecycleReactor().skipNextAdAndDoNotLoad();
      interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (InterstitialAd ad) {
          _onAdShowedCallback?.call();
        },
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          createInterstitialAd();
          _onAdDismissedCallback?.call();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          createInterstitialAd();
          _onAdFailedToShowCallback?.call(error);
        },
      );
      interstitialAd!.show();
      interstitialAd = null;
    } catch (e) {
      onAdDismissed?.call();
      print("EXCEPTION $e");
    }
  }

  static Future<void> _showInterstitialIfCondition(
    bool Function() isFeatureAdEnabled,
  ) {
    // 1st check Is_show_ads, then check the specific feature parameter
    if (!RemoteConfigService.instance.isShowAds) {
      return Future.value();
    }
    if (!isFeatureAdEnabled()) {
      return Future.value();
    }

    final completer = Completer<void>();
    void complete() {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }

    showInterstitialAd(
      onAdDismissed: complete,
      onAdFailed: (_) => complete(),
    );

    return completer.future;
  }

  /// Shows the preloaded interstitial ad when `Is_show_ads` and
  /// `is_show_tutorial_ad` are both true, then resolves once closed or skipped.
  static Future<void> showTutorialInterstitialIfEnabled() {
    return _showInterstitialIfCondition(
      () => RemoteConfigService.instance.isShowTutorialAd,
    );
  }

  /// Shows the preloaded interstitial ad when `Is_show_ads` and
  /// `is_show_create_project_btn` are both true, then resolves once closed or skipped.
  static Future<void> showCreateProjectInterstitialIfEnabled() {
    return _showInterstitialIfCondition(
      () => RemoteConfigService.instance.isShowCreateProjectBtn,
    );
  }

  /// Shows the preloaded interstitial ad when `Is_show_ads` and
  /// `is_show_history_ad` are both true, then resolves once closed or skipped.
  static Future<void> showHistoryInterstitialIfEnabled() {
    return _showInterstitialIfCondition(
      () => RemoteConfigService.instance.isShowHistoryAd,
    );
  }

  /// Shows the preloaded interstitial ad when `Is_show_ads` and
  /// `is_show_export_ad` are both true, then resolves once closed or skipped.
  static Future<void> showExportInterstitialIfEnabled() {
    return _showInterstitialIfCondition(
      () => RemoteConfigService.instance.isShowExportAd,
    );
  }

  /// Shows the preloaded interstitial ad when `Is_show_ads` and
  /// `project_stting_ad` are both true, then resolves once closed or skipped.
  static Future<void> showProjectSettingInterstitialIfEnabled() {
    return _showInterstitialIfCondition(
      () => RemoteConfigService.instance.isShowProjectSettingAd,
    );
  }

  /// Shows the preloaded interstitial ad when `Is_show_ads` and
  /// `is_show_ad_on_import` are both true, then resolves once closed or skipped.
  static Future<void> showImportInterstitialIfEnabled() {
    return _showInterstitialIfCondition(
      () => RemoteConfigService.instance.isShowAdOnImport,
    );
  }

  static int _applyBrushClickCount = 0;

  @visibleForTesting
  static void resetApplyBrushClickCount() {
    _applyBrushClickCount = 0;
  }

  /// Checks `Is_show_ads` then `is_show_aply_brush_ad`, and returns true only
  /// on every 4th click (clicks 1-3 skip, 4th shows, and repeats).
  @visibleForTesting
  static bool shouldShowApplyBrushAdOnClick() {
    if (!RemoteConfigService.instance.isShowAds) return false;
    if (!RemoteConfigService.instance.isShowApplyBrushAd) return false;
    _applyBrushClickCount++;
    return _applyBrushClickCount % 4 == 0;
  }

  /// Shows the Apply Brush interstitial ad on every 4th click when enabled.
  static Future<void> showApplyBrushInterstitialIfEnabled() {
    if (!shouldShowApplyBrushAdOnClick()) {
      return Future.value();
    }
    return _showInterstitialIfCondition(
      () => RemoteConfigService.instance.isShowApplyBrushAd,
    );
  }

  // Open App Ad
  static AppOpenAd? openAd;

  static void loadOpenAppAd({
    bool isResume = false,
    Function()? onAdLoaded,
    Function(LoadAdError)? onAdFailedToLoad,
    Function()? onAdDismissed,
  }) async {
    if (!RemoteConfigService.instance.isShowAds) {
      onAdDismissed?.call();
      return;
    }
    if (!RemoteConfigService.instance.isShowOpenAppAd) {
      onAdDismissed?.call();
      return;
    }
    await initialize();
    debugPrint('[AdManager] Requesting consent & loading OpenAppAd...');
    _checkConsentAndLoadAd(() async {
      try {
        final unitId = isResume
            ? AdHelper.resumeOpenAdUnitId
            : AdHelper.openAdUnitId;
        debugPrint('[AdManager] Calling AppOpenAd.load for $unitId');
        await AppOpenAd.load(
          adUnitId: unitId,
          request: const AdRequest(),
          adLoadCallback: AppOpenAdLoadCallback(
            onAdLoaded: (ad) {
              debugPrint('[AdManager] OpenAppAd loaded');
              openAd = ad;

              openAd!.onPaidEvent =
                  (ad, valueMicros, precision, currencyCode) {};

              openAd!.fullScreenContentCallback = FullScreenContentCallback(
                onAdShowedFullScreenContent: (ad) {
                  debugPrint('[AdManager] OpenAppAd showed');
                },
                onAdFailedToShowFullScreenContent: (ad, error) {
                  debugPrint('[AdManager] OpenAppAd failed to show: $error');
                  ad.dispose();
                  openAd = null;
                  onAdDismissed?.call();
                },
                onAdDismissedFullScreenContent: (ad) {
                  debugPrint('[AdManager] OpenAppAd dismissed');
                  openAd = null;
                  onAdDismissed?.call();
                  ad.dispose();
                },
              );

              openAd!.show();
              onAdLoaded?.call();
            },
            onAdFailedToLoad: (error) {
              debugPrint('[AdManager] OpenAppAd failed to load: $error');
              onAdFailedToLoad?.call(error);
            },
          ),
        );
      } catch (e) {
        debugPrint('[AdManager] Exception while loading open app ad: $e');
        onAdDismissed?.call();
      }
    });
  }

  // Rewarded ad
  // Rewarded ad
  static int _numRewardedLoadAttempts = 0;
  static RewardedAd? _rewardedAd;
  static void createRewardedAd({
    Function(RewardedAd)? onAdLoaded,
    Function(LoadAdError)? onAdFailedToLoad,
  }) {
    if (!RemoteConfigService.instance.isShowAds) return;
    _checkConsentAndLoadAd(() {
      if (_rewardedAd == null) {
        RewardedAd.load(
          adUnitId: AdHelper.rewardedAdUnitId,
          request: const AdRequest(),
          rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (RewardedAd ad) {
              print('$ad loaded.');
              _rewardedAd = ad;
              _numRewardedLoadAttempts = 0;
              onAdLoaded?.call(ad);

              _rewardedAd!.onPaidEvent =
                  (ad, valueMicros, precision, currencyCode) {};
            },
            onAdFailedToLoad: (LoadAdError error) {
              print('RewardedAd failed to load: $error');
              _rewardedAd = null;
              _numRewardedLoadAttempts += 1;
              onAdFailedToLoad?.call(error);
              if (_numRewardedLoadAttempts < maxFailedLoadAttempts) {
                //   createRewardedAd();
              }
            },
          ),
        );
      }
    });
  }

  static void showRewardedAd({
    Function()? onAdShowed,
    Function()? onAdDismissed,
    Function(AdError)? onAdFailed,
    Function(RewardItem)? onUserEarnedReward,
  }) {
    if (!RemoteConfigService.instance.isShowAds) {
      onAdDismissed?.call();
      return;
    }
    if (_rewardedAd == null) {
      debugPrint('Warning: attempt to show rewarded ad before loaded.');
      onAdDismissed?.call();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        debugPrint('Ad onAdShowedFullScreenContent.');
        onAdShowed?.call();
        AppLifecycleReactor().suppressAdForNextResume(
          duration: Duration(seconds: 35),
        );
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        debugPrint('$ad onAdDismissedFullScreenContent.');
        onAdDismissed?.call();
        ad.dispose();
        //   createRewardedAd(); // Reload ad after dismissal
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        debugPrint('$ad onAdFailedToShowFullScreenContent: $error');
        onAdFailed?.call(error);
        ad.dispose();
        //    createRewardedAd(); // Reload ad after failure
      },
    );

    _rewardedAd!.setImmersiveMode(true);
    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint('User earned reward: ${reward.amount} ${reward.type}');
        onUserEarnedReward?.call(reward);
      },
    );

    _rewardedAd = null;
  }

  //   Rewarded Interstitial ad
  // Rewarded Interstitial ad

  static int _numRewardedInterStitialLoadAttempts = 0;
  static RewardedInterstitialAd? _rewardedInterstitialAd;
  static void createRewardedInterstitialAd({
    Function(RewardedInterstitialAd)? onAdLoaded,
    Function(LoadAdError)? onAdFailedToLoad,
  }) {
    if (!RemoteConfigService.instance.isShowAds) return;
    _checkConsentAndLoadAd(() {
      if (_rewardedInterstitialAd == null) {
        RewardedInterstitialAd.load(
          adUnitId: AdHelper.rewardedInterstitialAdUnitId,
          request: const AdRequest(),
          rewardedInterstitialAdLoadCallback:
              RewardedInterstitialAdLoadCallback(
                onAdLoaded: (RewardedInterstitialAd ad) {
                  print('$ad loaded.');
                  _rewardedInterstitialAd = ad;
                  _numRewardedInterStitialLoadAttempts = 0;
                  onAdLoaded?.call(ad);

                  _rewardedInterstitialAd!.onPaidEvent =
                      (ad, valueMicros, precision, currencyCode) {};
                },
                onAdFailedToLoad: (LoadAdError error) {
                  print('RewardedAd failed to load: $error');
                  _rewardedInterstitialAd = null;
                  _numRewardedInterStitialLoadAttempts += 1;
                  onAdFailedToLoad?.call(error);
                  if (_numRewardedInterStitialLoadAttempts <
                      maxFailedLoadAttempts) {
                    //   createRewardedAd();
                  }
                },
              ),
        );
      }
    });
  }

  static void showRewardedInterStitialAd({
    Function()? onAdShowed,
    Function()? onAdDismissed,
    Function(AdError)? onAdFailed,
    Function(RewardItem)? onUserEarnedReward,
  }) {
    if (!RemoteConfigService.instance.isShowAds) {
      onAdDismissed?.call();
      return;
    }
    if (_rewardedInterstitialAd == null) {
      debugPrint('Warning: attempt to show rewarded ad before loaded.');
      onAdDismissed?.call();
      return;
    }

    _rewardedInterstitialAd!.fullScreenContentCallback =
        FullScreenContentCallback(
          onAdShowedFullScreenContent: (RewardedInterstitialAd ad) {
            debugPrint('Ad onAdShowedFullScreenContent.');
            onAdShowed?.call();
            AppLifecycleReactor().suppressAdForNextResume(
              duration: Duration(seconds: 35),
            );
          },
          onAdDismissedFullScreenContent: (RewardedInterstitialAd ad) {
            debugPrint('$ad onAdDismissedFullScreenContent.');
            onAdDismissed?.call();
            ad.dispose();
            //   createRewardedAd(); // Reload ad after dismissal
          },
          onAdFailedToShowFullScreenContent:
              (RewardedInterstitialAd ad, AdError error) {
                debugPrint('$ad onAdFailedToShowFullScreenContent: $error');
                onAdFailed?.call(error);
                ad.dispose();
                //    createRewardedAd(); // Reload ad after failure
              },
        );

    _rewardedInterstitialAd!.setImmersiveMode(true);
    _rewardedInterstitialAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint('User earned reward: ${reward.amount} ${reward.type}');
        onUserEarnedReward?.call(reward);
      },
    );

    _rewardedInterstitialAd = null;
  }

  // Consent Form Functions
  static bool _consentCompleted = false;
  static Completer<void>? _consentCompleter;

  static void checkConsentAndLoadAd(Function loadAdCallback) {
    if (!RemoteConfigService.instance.isShowAds) return;
    if (_consentCompleted) {
      loadAdCallback();
      return;
    }
    if (_consentCompleter != null) {
      _consentCompleter!.future.then((_) => loadAdCallback());
      return;
    }

    final completer = Completer<void>();
    _consentCompleter = completer;

    void finishConsent() {
      _consentCompleted = true;
      _consentCompleter = null;
      if (!completer.isCompleted) {
        completer.complete();
      }
      loadAdCallback();
    }

    final params = ConsentRequestParameters();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        var status = await ConsentInformation.instance.getConsentStatus();
        debugPrint('[AdManager] Consent status: $status');
        if (status == ConsentStatus.required) {
          if (await ConsentInformation.instance.isConsentFormAvailable()) {
            _loadConsentForm(finishConsent);
          } else {
            finishConsent();
          }
        } else {
          finishConsent();
        }
      },
      (FormError error) {
        debugPrint('[AdManager] Consent update error: ${error.message}');
        finishConsent();
        // Handle the error
      },
    );
  }

  static void _checkConsentAndLoadAd(Function loadAdCallback) {
    checkConsentAndLoadAd(loadAdCallback);
  }

  static void _loadConsentForm(Function loadAdCallback) {
    ConsentForm.loadConsentForm(
      (ConsentForm consentForm) async {
        consentForm.show((FormError? formError) async {
          var status = await ConsentInformation.instance.getConsentStatus();
          if (status == ConsentStatus.required) {
            _loadConsentForm(loadAdCallback);
          } else {
            loadAdCallback();
          }
        });
      },
      (formError) {
        loadAdCallback();
        // Handle the error
      },
    );
  }

  // Simple call ConsentForm
  static void callConsentForm() {
    if (!RemoteConfigService.instance.isShowAds) return;
    final params = ConsentRequestParameters();
    debugPrint("ETEER VALUEE");
    ConsentInformation.instance.requestConsentInfoUpdate(params, () async {
      if (await ConsentInformation.instance.isConsentFormAvailable()) {
        debugPrint("ETEER VALUEE 22");
        loadForm();
      } else {}
    }, (FormError error) {});
  }

  static void loadForm() {
    if (!RemoteConfigService.instance.isShowAds) return;
    ConsentForm.loadConsentForm(
      (ConsentForm consentForm) async {
        debugPrint("ETEER VALUEE 333");
        var status = await ConsentInformation.instance.getConsentStatus();
        debugPrint("ETEER VALUEE 444 ${status}");

        if (status == ConsentStatus.required) {
          consentForm.show((FormError? formError) {
            // Handle dismissal by reloading form
            loadForm();
          });
        } else if (status == ConsentStatus.unknown) {
          loadForm();
        } else {}
      },
      (formError) {
        // Handle the error
      },
    );
  }
}

/// Display native add
class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({super.key, this.isMedium = false, required this.adId});
  final bool isMedium;
  final String adId;
  @override
  _NativeAdWidgetState createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? nativeAd;
  bool _nativeAdIsLoaded = false;
  bool _nativeAdIsFailed = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (!RemoteConfigService.instance.isShowAds) {
      _nativeAdIsFailed = true;
      return;
    }
    nativeAd = NativeAd(
      adUnitId: widget.adId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          log('$NativeAd loaded.');
          setState(() {
            _nativeAdIsLoaded = true;
          });
        },
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {},
        onAdFailedToLoad: (ad, error) {
          // Dispose the ad here to free resources.
          log("FAILED TO LOAD");
          log('$NativeAd failed to load: $error');
          ad.dispose();
          setState(() {
            _nativeAdIsFailed = true;
          });
        },
      ),
      request: const AdRequest(),
      // Styling
      nativeTemplateStyle: NativeTemplateStyle(
        // Required: Choose a template.
        templateType: !widget.isMedium
            ? TemplateType.small
            : TemplateType.medium,
        // Optional: Customize the ad's style.
      ),
    )..load();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    nativeAd?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (nativeAd != null && _nativeAdIsLoaded) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: SizedBox(
          width: double.infinity,
          height: !widget.isMedium ? 110 : 360,
          child: AdWidget(ad: nativeAd!),
        ),
      );
    } else {
      return _nativeAdIsFailed
          ? Container()
          : Padding(
              padding: const EdgeInsets.only(bottom: 3, top: 8),
              child: SizedBox(
                width: double.infinity,
                height: widget.isMedium ? 360 : 110,
                child: Center(
                  child: Text(
                    "Advertisement",
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            );
    }
  }
}

class AppLifecycleReactor with WidgetsBindingObserver {
  static final AppLifecycleReactor _instance = AppLifecycleReactor._internal();
  factory AppLifecycleReactor() => _instance;
  AppLifecycleReactor._internal();

  bool _didGoToBackground = false;
  AppOpenAd? _openAd;
  bool _isLoadingAd = false;
  DateTime? _suppressAdsUntil;
  bool _skipNextAd = false;
  bool _suppressLoadNextAd = false; // NEW: Prevents loading ad when set

  void init() {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  /// Prevents both showing AND loading the ad on next resume
  void skipNextAdAndDoNotLoad() {
    _skipNextAd = true;
    _suppressLoadNextAd = true;
  }

  /// Prevent only showing the ad (but allows loading in background)
  void suppressAdForNextResume({
    Duration duration = const Duration(seconds: 3),
  }) {
    _suppressAdsUntil = DateTime.now().add(duration);
    log("Ad suppressed until: $_suppressAdsUntil");
  }

  void _loadOpenAppAd() {
    if (!RemoteConfigService.instance.shouldShowOpenAppAd) return;
    if (_suppressLoadNextAd) {
      log("Ad loading suppressed this time.");
      _suppressLoadNextAd = false; // reset flag
      return;
    }

    if (_isLoadingAd || _openAd != null) return;

    _isLoadingAd = true;
    AppOpenAd.load(
      adUnitId: AdHelper.openAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          log('Open App Ad Loaded');
          _isLoadingAd = false;
          _openAd = ad;

          _openAd!.onPaidEvent = (ad, valueMicros, precision, currencyCode) {};

          _openAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _openAd = null;
              // _loadOpenAppAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _openAd = null;
              // _loadOpenAppAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          log('Failed to load Open App Ad: $error');
          _isLoadingAd = false;
        },
      ),
    );
  }

  void _showAdIfAvailable() {
    if (!RemoteConfigService.instance.shouldShowOpenAppAd) return;
    if (_skipNextAd) {
      log("Ad skipped due to skipNextAd flag.");
      _skipNextAd = false;
      return;
    }

    if (_suppressAdsUntil != null &&
        DateTime.now().isBefore(_suppressAdsUntil!)) {
      log("Ad suppressed due to recent user activity.");
      return;
    }

    if (_openAd != null) {
      log("Showing Open App Ad...");
      _openAd!.show();
      _openAd = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _didGoToBackground = true;
      log("App paused → attempting to load ad...");
      _loadOpenAppAd();
    } else if (state == AppLifecycleState.resumed) {
      if (_didGoToBackground) {
        log("App resumed → checking ad...");
        Future.delayed(const Duration(milliseconds: 500), _showAdIfAvailable);
      }
      _didGoToBackground = false;
    }
  }
}

// class AppLifecycleReactor with WidgetsBindingObserver {
//   static final AppLifecycleReactor _instance = AppLifecycleReactor._internal();
//   factory AppLifecycleReactor() => _instance;
//   AppLifecycleReactor._internal();
//
//   bool _didGoToBackground = false;
//   AppOpenAd? _openAd;
//   bool _isLoadingAd = false;
//   DateTime? _suppressAdsUntil;
//   bool _skipNextAd = false;
//   bool _suppressLoadNextAd = false;
//
//   /// Required for showing snackbars/toasts
//   // late GlobalKey<NavigatorState> navigatorKey;
//
//   void init() {
//     // navigatorKey = navKey;
//     WidgetsBinding.instance.addObserver(this);
//   }
//
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//   }
//
//   void skipNextAdAndDoNotLoad() {
//     _skipNextAd = true;
//     _suppressLoadNextAd = true;
//   }
//
//   void suppressAdForNextResume({Duration duration = const Duration(seconds: 3)}) {
//     _suppressAdsUntil = DateTime.now().add(duration);
//     log("Ad suppressed until: $_suppressAdsUntil");
//   }
//
//   // void _loadOpenAppAd({bool showWhenLoaded = false}) {
//   //   if (_suppressLoadNextAd) {
//   //     log("Ad loading suppressed this time.");
//   //     _suppressLoadNextAd = false;
//   //     return;
//   //   }
//   //
//   //   if (_isLoadingAd || _openAd != null) return;
//   //
//   //   _isLoadingAd = true;
//   //   AppOpenAd.load(
//   //     adUnitId: AdHelper.openAdUnitId, // Replace with your real unit ID
//   //     request: const AdRequest(),
//   //     adLoadCallback: AppOpenAdLoadCallback(
//   //       onAdLoaded: (ad) {
//   //         log('Open App Ad Loaded');
//   //         _isLoadingAd = false;
//   //         _openAd = ad;
//   //
//   //         _openAd!.fullScreenContentCallback = FullScreenContentCallback(
//   //           onAdDismissedFullScreenContent: (ad) {
//   //             ad.dispose();
//   //             _openAd = null;
//   //           },
//   //           onAdFailedToShowFullScreenContent: (ad, error) {
//   //             ad.dispose();
//   //             _openAd = null;
//   //           },
//   //         );
//   //
//   //         if (showWhenLoaded) {
//   //           _showAdIfAvailable();
//   //         }
//   //       },
//   //       onAdFailedToLoad: (error) {
//   //         log('Failed to load Open App Ad: $error');
//   //         _isLoadingAd = false;
//   //       },
//   //     ),
//   //   );
//   // }
//
//   // void _showAdIfAvailable() {
//   //   if (_skipNextAd) {
//   //     log("Ad skipped due to skipNextAd flag.");
//   //     _skipNextAd = false;
//   //     return;
//   //   }
//   //
//   //   if (_suppressAdsUntil != null && DateTime.now().isBefore(_suppressAdsUntil!)) {
//   //     log("Ad suppressed due to recent user activity.");
//   //     return;
//   //   }
//   //
//   //   if (_openAd != null) {
//   //     log("Showing Open App Ad...");
//   //     _openAd!.show();
//   //     _openAd = null;
//   //   }
//   // }
//
//   // void _showWelcomeBackMessage() {
//   //   final ctx = navigatorKey.currentContext;
//   //   if (ctx == null) return;
//   //
//   //   ScaffoldMessenger.of(ctx).showSnackBar(
//   //     const SnackBar(
//   //       content: Text("👋 Welcome back!"),
//   //       duration: Duration(seconds: 2),
//   //     ),
//   //   );
//   // }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//
//     if (state == AppLifecycleState.paused) {
//       _didGoToBackground = true;
//     } else if (state == AppLifecycleState.resumed) {
//       if (_didGoToBackground) {
//
//         if (_skipNextAd) {
//           log("Ad skipped due to skipNextAd flag.");
//           _skipNextAd = false;
//           return;
//         }
//         if (_suppressAdsUntil != null && DateTime.now().isBefore(_suppressAdsUntil!)) {
//           log("Ad suppressed due to recent user activity.");
//           return;
//         }
//
//         _didGoToBackground = false;
//
//         log("App resumed → showing welcome message");
//         //_showWelcomeBackMessage();
//         onLoadingWelcome();
//         AdManager.loadOpenAppAd(isResume: true,
//             onAdLoaded: ()
//             {
//
//             },
//             onAdDismissed: ()
//             {
//               Navigator.pop(NavigationService.navigatorKey.currentState!.context);
//             },
//             onAdFailedToLoad: (_)
//             {
//               Navigator.pop(NavigationService.navigatorKey.currentState!.context);
//             }
//         );
//         // Future.delayed(const Duration(seconds: 2), () {
//         //   _loadOpenAppAd(showWhenLoaded: true);
//         // });
//       }
//     }
//   }
// }

//CollapsibleBanner
class CollapsibleBannerAdWidget extends StatefulWidget {
  const CollapsibleBannerAdWidget({super.key});

  @override
  State<CollapsibleBannerAdWidget> createState() =>
      _CollapsibleBannerAdWidgetState();
}

class _CollapsibleBannerAdWidgetState extends State<CollapsibleBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  static const AdRequest adRequest = AdRequest(
    extras: {
      'collapsible': 'bottom', // Only works with adaptive banner ads
    },
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAd();
  }

  Future<void> _loadAd() async {
    if (!RemoteConfigService.instance.isShowAds) return;
    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
          MediaQuery.of(context).size.width.truncate(),
        );

    if (size == null) return;

    final banner = BannerAd(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-5030382499330999/3084224023'
          //'ca-app-pub-3940256099942544/2014213617' // ✅ Test ID for collapsible banner
          : 'ca-app-pub-3940256099942544/8388050270',
      size: size,
      request: adRequest,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint("Ad failed to load: $error");
        },
      ),
    );

    await banner.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Container(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          color: Colors.transparent,
          child: AdWidget(ad: _bannerAd!),
        ),
      ),
    );
  }
}

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key, required this.adId});
  final String adId;
  @override
  _BannerAdWidgetState createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isAdFailed = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    if (!RemoteConfigService.instance.isShowAds) {
      _isAdFailed = true;
      return;
    }
    _bannerAd = BannerAd(
      adUnitId: widget.adId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          log('BannerAd loaded.');
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          log('BannerAd failed to load: $error');
          ad.dispose();
          setState(() {
            _isAdFailed = true;
          });
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdLoaded && _bannerAd != null) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    } else {
      return _isAdFailed
          ? Container()
          : SizedBox(
              width: double.infinity,
              height: 50,
              child: Center(
                child: Text(
                  "Advertisement",
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.black
                        : Colors.white,
                  ),
                ),
              ),
            );
    }
  }
}
