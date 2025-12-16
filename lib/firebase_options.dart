// File generated manually for Firebase configuration
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web; // ✅ Return web configuration
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
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCbipKjLKfyzpXwzPuiHqYeKoBoFFtWg9I',
    appId: '1:452199317060:web:43d9780e4b042492cb8611',
    messagingSenderId: '452199317060',
    projectId: 'zentra-41d8f',
    authDomain: 'zentra-41d8f.firebaseapp.com',
    storageBucket: 'zentra-41d8f.firebasestorage.app',
    measurementId: 'G-RXLECEHC22',
  );

  // -------- Web --------

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBXFWdgJYTX-ms777qQkRN3nPAWV4FMAec',
    appId: '1:452199317060:android:9d5a7b2a0c9cb493cb8611',
    messagingSenderId: '452199317060',
    projectId: 'zentra-41d8f',
    storageBucket: 'zentra-41d8f.firebasestorage.app',
  );

  // -------- Android --------

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAYWTi04_klYdFLJqMAXn2o8rof22w7ABU',
    appId: '1:452199317060:ios:45f33199939f31f6cb8611',
    messagingSenderId: '452199317060',
    projectId: 'zentra-41d8f',
    storageBucket: 'zentra-41d8f.firebasestorage.app',
    iosBundleId: 'com.example.zentra0',
  );

  // -------- iOS --------

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAYWTi04_klYdFLJqMAXn2o8rof22w7ABU',
    appId: '1:452199317060:ios:45f33199939f31f6cb8611',
    messagingSenderId: '452199317060',
    projectId: 'zentra-41d8f',
    storageBucket: 'zentra-41d8f.firebasestorage.app',
    iosBundleId: 'com.example.zentra0',
  );

  // -------- macOS --------

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCbipKjLKfyzpXwzPuiHqYeKoBoFFtWg9I',
    appId: '1:452199317060:web:36f00a425d97e308cb8611',
    messagingSenderId: '452199317060',
    projectId: 'zentra-41d8f',
    authDomain: 'zentra-41d8f.firebaseapp.com',
    storageBucket: 'zentra-41d8f.firebasestorage.app',
    measurementId: 'G-5NYKKM3MYN',
  );

  // -------- Windows --------

  // -------- Linux --------
  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'YourLinuxApiKey', // Optional, add if using Linux
    appId: 'YourLinuxAppId',
    messagingSenderId: '452199317060',
    projectId: 'zentra-41d8f',
    storageBucket: 'zentra-41d8f.appspot.com',
  );
}