import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
/// Generated from google-services.json (project: drawclipax).
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
    apiKey: 'AIzaSyAQVWmpYlB1ZVBBM_ILcfuNm3noJH49KkI',
    appId: '1:437409731351:android:ddc80ca0ed600518b39d52',
    messagingSenderId: '437409731351',
    projectId: 'drawclipax',
    storageBucket: 'drawclipax.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAQVWmpYlB1ZVBBM_ILcfuNm3noJH49KkI',
    appId: '1:437409731351:ios:ddc80ca0ed600518b39d52',
    messagingSenderId: '437409731351',
    projectId: 'drawclipax',
    storageBucket: 'drawclipax.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAQVWmpYlB1ZVBBM_ILcfuNm3noJH49KkI',
    appId: '1:437409731351:web:ddc80ca0ed600518b39d52',
    messagingSenderId: '437409731351',
    projectId: 'drawclipax',
    storageBucket: 'drawclipax.firebasestorage.app',
  );
}
