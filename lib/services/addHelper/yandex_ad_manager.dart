// import 'package:flutter/foundation.dart';
// import 'package:yandex_mobileads/mobile_ads.dart';
// import 'package:flutter/material.dart';
// import 'dart:developer' as developer;

// class YandexAdManager {
//   static AppOpenAd? openAd;
//   static bool _isShowingAd = false;

//   static void loadOpenAppAd({
//     bool isResume = false,
//     VoidCallback? onAdLoaded,
//     Function(AdRequestError)? onAdFailedToLoad,
//     VoidCallback? onAdDismissed,
//   }) async {
//     try {
//       final loader = AppOpenAdLoader();
//       final ad = await loader.loadAd(
//         adRequest: const AdRequest(
//           adUnitId: 'R-M-18306009-6',
//         ),
//       );
//       debugPrint('Yandex Open App Ad loaded');
//       openAd = ad;
//       onAdLoaded?.call();
//       _showOpenAd(onAdDismissed);
//     } catch (e) {
//       debugPrint('Open App Ad failed to load: $e');
//       if (e is AdRequestError) {
//         onAdFailedToLoad?.call(e);
//       } else {
//         onAdFailedToLoad?.call(AdRequestError(0, e.toString(), 'R-M-18306009-6'));
//       }
//     }
//   }

//   // ================= SHOW =================

//   static Future<void> _showOpenAd(VoidCallback? onAdDismissed) async {
//     if (openAd == null || _isShowingAd) return;

//     _isShowingAd = true;

//     openAd!.setAdEventListener(
//       eventListener: AppOpenAdEventListener(
//         onAdShown: () {},
//         onAdFailedToShow: (error) {
//           _clearAd();
//         },
//         onAdDismissed: () {
//           onAdDismissed?.call();
//           _clearAd();
//         },
//         onAdClicked: () {},
//         onAdImpression: (_) {},
//       ),
//     );

//     await openAd!.show();
//     await openAd!.waitForDismiss();
//   }

//   // ================= CLEANUP =================

//   static void _clearAd() {
//     openAd?.destroy();
//     openAd = null;
//     _isShowingAd = false;
//   }

//   static InterstitialAd? _interstitialAd;

//   static int _numLoadAttempts = 0;
//   static const int _maxFailedLoadAttempts = 3;

//   static VoidCallback? _onAdShowedCallback;
//   static VoidCallback? _onAdDismissedCallback;
//   static Function(AdError)? _onAdFailedCallback;

//   // Call once (e.g. app start)
//   static Future<void> initialize() async {
//     await YandexAds.initialize();
//     createInterstitialAd();
//     createRewardedAd();
//   }

//   // ================= LOAD =================

//   static Future<void> createInterstitialAd() async {
//     if (_interstitialAd != null) return;

//     try {
//       final loader = InterstitialAdLoader();
//       final ad = await loader.loadAd(
//         adRequest: const AdRequest(
//           adUnitId: "R-M-18306009-14",
//         ),
//       );
//       debugPrint('Yandex Interstitial loaded');
//       _interstitialAd = ad;
//       _numLoadAttempts = 0;
//     } catch (error) {
//       debugPrint('Yandex load failed: $error');
//       _interstitialAd = null;
//       _numLoadAttempts++;
//       if (_numLoadAttempts < _maxFailedLoadAttempts) {
//         createInterstitialAd();
//       }
//     }
//   }

//   // ================= SHOW =================

//   static Future<void> showInterstitialAd({
//     VoidCallback? onAdShowed,
//     VoidCallback? onAdDismissed,
//     Function(AdError)? onAdFailed,
//   }) async {
//     _onAdShowedCallback = onAdShowed;
//     _onAdDismissedCallback = onAdDismissed;
//     _onAdFailedCallback = onAdFailed;

//     if (_interstitialAd == null) {
//       _onAdDismissedCallback?.call();
//       return;
//     }

//     _interstitialAd!.setAdEventListener(
//       eventListener: InterstitialAdEventListener(
//         onAdShown: () {
//           _onAdShowedCallback?.call();
//         },
//         onAdFailedToShow: (error) {
//           _onAdFailedCallback?.call(error);
//           _destroyAndReload();
//         },
//         onAdDismissed: () {
//           _onAdDismissedCallback?.call();
//           _destroyAndReload();
//         },
//         onAdClicked: () {},
//         onAdImpression: (_) {},
//       ),
//     );

//     await _interstitialAd!.show();
//     await _interstitialAd!.waitForDismiss();
//   }

//   // ================= CLEANUP =================

//   static void _destroyAndReload() {
//     _interstitialAd?.destroy();
//     _interstitialAd = null;
//     createInterstitialAd();
//   }

//   // ================= REWARDED AD =================

//   static RewardedAd? _rewardedAd;
//   static int _numRewardedLoadAttempts = 0;

//   static void createRewardedAd({
//     Function(RewardedAd)? onAdLoaded,
//     Function(AdRequestError)? onAdFailedToLoad,
//   }) async {
//     if (_rewardedAd != null) {
//       onAdLoaded?.call(_rewardedAd!);
//       return;
//     }

//     try {
//       final loader = RewardedAdLoader();
//       final ad = await loader.loadAd(
//         adRequest: const AdRequest(
//           adUnitId: "R-M-18306009-15",
//         ),
//       );
//       debugPrint('Yandex Rewarded Ad loaded');
//       _rewardedAd = ad;
//       _numRewardedLoadAttempts = 0;
//       onAdLoaded?.call(ad);
//     } catch (e) {
//       debugPrint('Yandex Rewarded Ad failed to load: $e');
//       _rewardedAd = null;
//       _numRewardedLoadAttempts++;
//       final err = e is AdRequestError
//           ? e
//           : AdRequestError(0, e.toString(), "R-M-18306009-15");
//       onAdFailedToLoad?.call(err);
//       if (_numRewardedLoadAttempts < _maxFailedLoadAttempts) {
//         createRewardedAd(
//           onAdLoaded: onAdLoaded,
//           onAdFailedToLoad: onAdFailedToLoad,
//         );
//       }
//     }
//   }

//   static Future<void> showRewardedAd({
//     VoidCallback? onAdShowed,
//     VoidCallback? onAdDismissed,
//     Function(AdError)? onAdFailed,
//     Function(Reward)? onUserEarnedReward,
//   }) async {
//     if (_rewardedAd == null) {
//       debugPrint('Warning: attempt to show Yandex rewarded ad before loaded.');
//       onAdDismissed?.call();
//       return;
//     }

//     _rewardedAd!.setAdEventListener(
//       eventListener: RewardedAdEventListener(
//         onAdShown: () {
//           onAdShowed?.call();
//         },
//         onAdFailedToShow: (error) {
//           onAdFailed?.call(error);
//           _destroyAndReloadRewarded();
//         },
//         onAdDismissed: () {
//           onAdDismissed?.call();
//           _destroyAndReloadRewarded();
//         },
//         onRewarded: (Reward reward) {
//           onUserEarnedReward?.call(reward);
//         },
//         onAdClicked: () {},
//         onAdImpression: (_) {},
//       ),
//     );

//     await _rewardedAd!.show();
//     await _rewardedAd!.waitForDismiss();
//   }

//   static void _destroyAndReloadRewarded() {
//     _rewardedAd?.destroy();
//     _rewardedAd = null;
//     createRewardedAd();
//   }
// }

// class MyHomePage2 extends StatefulWidget {
//   const MyHomePage2({super.key});

//   @override
//   State<MyHomePage2> createState() => _MyHomePage2State();
// }

// class _MyHomePage2State extends State<MyHomePage2> {
//   BannerAd? banner;
//   bool isBannerAlreadyCreated = false;
//   bool _initialized = false;

//   static const double bannerHeight = 90;

//   BannerAdSize getAdSize() {
//     final screenWidth = MediaQuery.of(context).size.width.round();
//     return BannerAdSize.inline(
//       width: screenWidth,
//       maxHeight: bannerHeight.toInt(),
//     );
//   }

//   BannerAd _createBanner() {
//     final bannerAd = BannerAd(adSize: getAdSize());
//     bannerAd.loadStateStream.listen((state) {
//       if (state is BannerAdLoadStateLoaded) {
//         debugPrint('✅ Yandex banner loaded');
//       } else if (state is BannerAdLoadStateError) {
//         debugPrint('❌ Yandex banner failed: ${state.error.description}');
//       }
//     });
//     bannerAd.load(const AdRequest(adUnitId: 'demo-banner-yandex'));
//     return bannerAd;
//   }

//   @override
//   void initState() {
//     super.initState();
//     YandexAds.initialize();
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();

//     if (_initialized) return;
//     _initialized = true;

//     banner = _createBanner();

//     // Show banner immediately with fixed height
//     setState(() {
//       isBannerAlreadyCreated = true;
//     });
//   }

//   @override
//   void dispose() {
//     banner?.destroy();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           const Center(
//             child: Text(
//               'Main Screen Content',
//               style: TextStyle(fontSize: 18),
//             ),
//           ),
//           if (isBannerAlreadyCreated && banner != null)
//             Align(
//               alignment: Alignment.bottomCenter,
//               child: SizedBox(
//                 height: bannerHeight,
//                 width: double.infinity,
//                 child: AdWidget(bannerAd: banner!),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// // class YandexBannerWidget extends StatefulWidget {
// //   const YandexBannerWidget({super.key, this.isMedium = false, required this.adId});
// //
// //   final bool isMedium;
// //   final String adId;
// //
// //   @override
// //   State<YandexBannerWidget> createState() => _YandexBannerWidgetState();
// // }
// //
// // class _YandexBannerWidgetState extends State<YandexBannerWidget> {
// //   BannerAd? banner;
// //   bool isBannerAlreadyCreated = false;
// //   bool _initialized = false;
// //
// //   static const double smallHeight = 110;
// //   static const double mediumHeight = 360;
// //
// //   BannerAdSize _getAdSize() {
// //     // final screenWidth = MediaQuery.of(context).size.width.round();
// //     // return BannerAdSize.inline(
// //     //   width: screenWidth,
// //     //   maxHeight: widget.isMedium ? mediumHeight.toInt() : smallHeight.toInt(),
// //     // );
// //
// //     final screenWidth = MediaQuery.of(context).size.width.round();
// //     return BannerAdSize.sticky(width: screenWidth);
// //   }
// //
// //   BannerAd _createBanner() {
// //     return BannerAd(
// //       adUnitId: widget.adId, // demo-banner-yandex for testing
// //       adSize: _getAdSize(),
// //       adRequest: const AdRequest(),
// //       onAdLoaded: () {
// //         debugPrint('✅ Yandex banner loaded');
// //       },
// //       onAdFailedToLoad: (error) {
// //         debugPrint('❌ Yandex banner failed: ${error.description}');
// //       },
// //     );
// //   }
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     MobileAds.initialize();
// //   }
// //
// //   @override
// //   void didChangeDependencies() {
// //     super.didChangeDependencies();
// //     if (_initialized) return;
// //     _initialized = true;
// //
// //     banner = _createBanner();
// //
// //     setState(() {
// //       isBannerAlreadyCreated = true;
// //     });
// //   }
// //
// //   @override
// //   void dispose() {
// //     banner?.destroy();
// //     super.dispose();
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final height = widget.isMedium ? mediumHeight : smallHeight;
// //
// //     return SizedBox(
// //       width: double.infinity,
// //       height: height,
// //       child: isBannerAlreadyCreated && banner != null
// //           ? AdWidget(bannerAd: banner!)
// //           : Center(
// //         child: Text(
// //           'Advertisement',
// //           style: TextStyle(
// //             color: Theme.of(context).brightness == Brightness.light
// //                 ? Colors.black
// //                 : Colors.white,
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }

// class YandexBannerWidget extends StatefulWidget {
//   const YandexBannerWidget(
//       {super.key, this.isMedium = false, required this.adId});

//   final bool isMedium;
//   final String adId;

//   @override
//   State<YandexBannerWidget> createState() => _YandexBannerWidgetState();
// }

// class _YandexBannerWidgetState extends State<YandexBannerWidget> {
//   BannerAd? banner;
//   bool isBannerAlreadyCreated = false;
//   bool _initialized = false;

//   static const double smallHeight = 50; // small banner height
//   static const double mediumHeight = 110; // medium banner height

//   BannerAdSize _getAdSize() {
//     final screenWidth = MediaQuery.of(context).size.width.round();
//     return BannerAdSize.inline(
//       width: screenWidth,
//       maxHeight: widget.isMedium ? mediumHeight.toInt() : smallHeight.toInt(),
//     );
//   }

//   BannerAd _createBanner() {
//     final bannerAd = BannerAd(adSize: _getAdSize());
//     bannerAd.loadStateStream.listen((state) {
//       if (state is BannerAdLoadStateLoaded) {
//         debugPrint('✅ Yandex banner loaded');
//       } else if (state is BannerAdLoadStateError) {
//         debugPrint('❌ Yandex banner failed: ${state.error.description}');
//       }
//     });
//     bannerAd.load(AdRequest(adUnitId: widget.adId));
//     return bannerAd;
//   }

//   @override
//   void initState() {
//     super.initState();
//     YandexAds.initialize();
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     if (_initialized) return;
//     _initialized = true;

//     banner = _createBanner();

//     setState(() {
//       isBannerAlreadyCreated = true;
//     });
//   }

//   @override
//   void dispose() {
//     banner?.destroy();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final height = widget.isMedium ? mediumHeight : smallHeight;

//     return SizedBox(
//       width: double.infinity,
//       height: height,
//       child: isBannerAlreadyCreated && banner != null
//           ? AdWidget(bannerAd: banner!)
//           : Center(
//               child: Text(
//                 'Advertisement',
//                 style: TextStyle(
//                   color: Theme.of(context).brightness == Brightness.light
//                       ? Colors.black
//                       : Colors.white,
//                 ),
//               ),
//             ),
//     );
//   }
// }

// enum BannerType { small, medium, adaptive }

// class YandexCommonBannerWidget extends StatefulWidget {
//   const YandexCommonBannerWidget({
//     super.key,
//     required this.adId,
//     this.bannerType = BannerType.medium,
//   });

//   final String adId;
//   final BannerType bannerType;

//   @override
//   State<YandexCommonBannerWidget> createState() =>
//       _YandexCommonBannerWidgetState();
// }

// class _YandexCommonBannerWidgetState extends State<YandexCommonBannerWidget> {
//   BannerAd? banner;
//   bool _initialized = false;

//   // Heights
//   static const double _smallHeight = 50;
//   static const double _mediumHeight = 110;

//   BannerAdSize _getAdSize() {
//     final width = MediaQuery.of(context).size.width.round();

//     switch (widget.bannerType) {
//       case BannerType.small:
//         return BannerAdSize.inline(width: width, maxHeight: 50);
//       case BannerType.medium:
//         return BannerAdSize.inline(width: width, maxHeight: 110);
//       case BannerType.adaptive:
//         final height = width > 600 ? 90 : 50;
//         return BannerAdSize.inline(width: width, maxHeight: height);
//     }
//   }

//   double get _bannerHeight {
//     switch (widget.bannerType) {
//       case BannerType.small:
//         return _smallHeight;
//       case BannerType.medium:
//         return _mediumHeight;
//       case BannerType.adaptive:
//         return MediaQuery.of(context).size.width > 600 ? 90 : 50;
//     }
//   }

//   BannerAd _createBanner() {
//     final bannerAd = BannerAd(adSize: _getAdSize());
//     bannerAd.loadStateStream.listen((state) {
//       if (state is BannerAdLoadStateLoaded) {
//         debugPrint('✅ Yandex banner loaded');
//       } else if (state is BannerAdLoadStateError) {
//         debugPrint('❌ Yandex banner failed: ${state.error.description}');
//       }
//     });
//     bannerAd.load(AdRequest(adUnitId: widget.adId));
//     return bannerAd;
//   }

//   @override
//   void initState() {
//     super.initState();
//     YandexAds.initialize();
//   }

//   /// 🔑 THIS IS THE MOST IMPORTANT PART
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();

//     if (_initialized) return;
//     _initialized = true;

//     banner = _createBanner();

//     // 🔥 MUST call setState immediately
//     setState(() {});
//   }

//   @override
//   void dispose() {
//     banner?.destroy();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: double.infinity,
//       height: _bannerHeight,
//       child: banner != null
//           ? AdWidget(bannerAd: banner!)
//           : Center(
//               child: Text(
//                 'Advertisement',
//                 style: TextStyle(
//                   color: Theme.of(context).brightness == Brightness.light
//                       ? Colors.black
//                       : Colors.white,
//                 ),
//               ),
//             ),
//     );
//   }
// }
