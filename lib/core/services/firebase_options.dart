import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
/// Updated from google-services.json (project: clipax-f0f02).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCrm5rW_aKcGoz07m9C3mCXfwWXEGhaPJs',
    appId: '1:584393370046:android:f0131a7cbffae025bfb1ef',
    messagingSenderId: '584393370046',
    projectId: 'clipax-f0f02',
    storageBucket: 'clipax-f0f02.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCn4grHW5-95fXp4sXJTenU6mEbk55OGAc',
    appId: '1:584393370046:ios:46da14843d83b514bfb1ef',
    messagingSenderId: '584393370046',
    projectId: 'clipax-f0f02',
    storageBucket: 'clipax-f0f02.firebasestorage.app',
    iosBundleId: 'com.flipbook.draw.animation.maker',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCrm5rW_aKcGoz07m9C3mCXfwWXEGhaPJs',
    appId: '1:584393370046:web:f0131a7cbffae025bfb1ef',
    messagingSenderId: '584393370046',
    projectId: 'clipax-f0f02',
    storageBucket: 'clipax-f0f02.firebasestorage.app',
  );
}
