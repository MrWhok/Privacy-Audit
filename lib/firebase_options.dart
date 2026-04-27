import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBLoEm2Aw5bnyQP93k9biQoSvc970gpOJA',
    appId: '1:846661260362:web:ddf993977c77bd2cf242b3',
    messagingSenderId: '846661260362',
    projectId: 'privacy-audit-11723',
    authDomain: 'privacy-audit-11723.firebaseapp.com',
    storageBucket: 'privacy-audit-11723.firebasestorage.app',
    measurementId: 'G-J4RDKRWJJ2',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC4u8tZASncYpnQdjQ7MauoZmoVc8g57X0',
    appId: '1:846661260362:android:77637db6a7febd12f242b3',
    messagingSenderId: '846661260362',
    projectId: 'privacy-audit-11723',
    storageBucket: 'privacy-audit-11723.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAXzUR6A6RePKRFdfYsuIXzCullQC-KxIY',
    appId: '1:846661260362:ios:393c55d24aa526a3f242b3',
    messagingSenderId: '846661260362',
    projectId: 'privacy-audit-11723',
    storageBucket: 'privacy-audit-11723.firebasestorage.app',
    iosBundleId: 'com.example.ppbPrivacyAudit',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAXzUR6A6RePKRFdfYsuIXzCullQC-KxIY',
    appId: '1:846661260362:ios:393c55d24aa526a3f242b3',
    messagingSenderId: '846661260362',
    projectId: 'privacy-audit-11723',
    storageBucket: 'privacy-audit-11723.firebasestorage.app',
    iosBundleId: 'com.example.ppbPrivacyAudit',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBLoEm2Aw5bnyQP93k9biQoSvc970gpOJA',
    appId: '1:846661260362:web:08a155e10d3d88f9f242b3',
    messagingSenderId: '846661260362',
    projectId: 'privacy-audit-11723',
    authDomain: 'privacy-audit-11723.firebaseapp.com',
    storageBucket: 'privacy-audit-11723.firebasestorage.app',
    measurementId: 'G-9NM4X62HT1',
  );
}
