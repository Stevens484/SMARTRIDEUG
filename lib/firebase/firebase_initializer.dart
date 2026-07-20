import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseInitializer {
  static Future<FirebaseApp?> initialize({FirebaseOptions? options}) async {
    try {
      return await Firebase.initializeApp(options: options);
    } catch (error, stackTrace) {
      debugPrint('Firebase initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }
}
