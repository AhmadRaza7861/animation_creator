import 'dart:io';

class AdHelper {

  static String get openAdUnitId {
    if (Platform.isAndroid) {
      return
          'ca-app-pub-5030382499330999/1650919559';
         //'ca-app-pub-3940256099942544/9257395921';   //test ad
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    } else {
      throw new UnsupportedError('Unsupported platform');
    }
  }

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return
        'ca-app-pub-5030382499330999/9777967415';
       // 'ca-app-pub-3940256099942544/6300978111';  //test id
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    } else {
      throw new UnsupportedError('Unsupported platform');
    }

  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return
           "ca-app-pub-5030382499330999/2480769583";
       // "ca-app-pub-3940256099942544/1033173712";      //TestID
    } else if (Platform.isIOS) {
      return "ca-app-pub-3940256099942544/4411468910";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-5030382499330999/5038438138";  // real id
        //"ca-app-pub-8987404798086121/9552333295";
    } else if (Platform.isIOS) {
      return "ca-app-pub-3940256099942544/1712485313";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  static String get nativeAdUnitId {
    if (Platform.isAndroid) {
      return
        "ca-app-pub-5030382499330999/3448568021";
      //"ca-app-pub-3940256099942544/2247696110"; //test ad
    } else if (Platform.isIOS) {
      return "ca-app-pub-7155931151667823/4589073852";
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }

  static String get resumeOpenAdUnitId {
    if (Platform.isAndroid) {
      return
        'ca-app-pub-5030382499330999/5981681269';
      //'ca-app-pub-3940256099942544/9257395921';   //test ad
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    } else {
      throw new UnsupportedError('Unsupported platform');
    }
  }


  static String get rewardedInterstitialAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-5030382499330999/2399604412";  // real id
      //"ca-app-pub-8987404798086121/9552333295";
    } else if (Platform.isIOS) {
      return "ca-app-pub-3940256099942544/1712485313";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }
}



