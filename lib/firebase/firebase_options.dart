import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get android => const FirebaseOptions(
    apiKey: 'AIzaSyAmNXXFiqPUH-SspNPRUG11cktszM6Ls7M',
    appId: '1:398858755798:android:08b91bf10b904b6b30b377',
    messagingSenderId: '398858755798',
    projectId: 'smartride-mobileapp001',
    storageBucket: 'smartride-mobileapp001.firebasestorage.app',
  );

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for $defaultTargetPlatform.',
        );
    }
  }
}
