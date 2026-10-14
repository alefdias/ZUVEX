// File generated and configured for ZUVEX Firebase project (zuvex-4710f).
// Do NOT commit this file to public repositories — it contains API keys.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        // Desktop platforms: use Android config as fallback for local dev.
        return android;
    }
  }

  // ── Android ────────────────────────────────────────────────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBMWmo621ABqMIAHDyH_I_LdQoTDjyH8Vk',
    appId: '1:322803029275:android:4e8dabc0370aa56d79efbe',
    messagingSenderId: '322803029275',
    projectId: 'zuvex-4710f',
    storageBucket: 'zuvex-4710f.firebasestorage.app',
  );

  // ── iOS (adicione quando registrar o app iOS no Firebase Console) ──────────
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBMWmo621ABqMIAHDyH_I_LdQoTDjyH8Vk',
    appId: '1:322803029275:ios:0000000000000000000000', // substituir
    messagingSenderId: '322803029275',
    projectId: 'zuvex-4710f',
    storageBucket: 'zuvex-4710f.firebasestorage.app',
    iosBundleId: 'com.zuvex.app',
  );

  // ── macOS ──────────────────────────────────────────────────────────────────
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBMWmo621ABqMIAHDyH_I_LdQoTDjyH8Vk',
    appId: '1:322803029275:ios:0000000000000000000000', // substituir
    messagingSenderId: '322803029275',
    projectId: 'zuvex-4710f',
    storageBucket: 'zuvex-4710f.firebasestorage.app',
    iosBundleId: 'com.zuvex.app',
  );

  // ── Web (adicione quando registrar o app Web no Firebase Console) ──────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBMWmo621ABqMIAHDyH_I_LdQoTDjyH8Vk',
    appId: '1:322803029275:web:0000000000000000000000', // substituir
    messagingSenderId: '322803029275',
    projectId: 'zuvex-4710f',
    storageBucket: 'zuvex-4710f.firebasestorage.app',
    authDomain: 'zuvex-4710f.firebaseapp.com',
  );
}
