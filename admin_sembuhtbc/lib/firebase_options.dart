// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyDUNU-sjvkA80YTN6BHXFn5umG5EO7wbu4',
    appId: '1:118240719864:web:9dae05fe3425f6bcf59c0d',
    messagingSenderId: '118240719864',
    projectId: 'sembuhtbcuser',
    authDomain: 'sembuhtbcuser.firebaseapp.com',
    storageBucket: 'sembuhtbcuser.firebasestorage.app',
    measurementId: 'G-MRF2GN80S9',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDqpYlDr8qt5p4abhAyUHalY2byBLGJCNw',
    appId: '1:118240719864:android:d7d06b0c99e23a67f59c0d',
    messagingSenderId: '118240719864',
    projectId: 'sembuhtbcuser',
    storageBucket: 'sembuhtbcuser.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCz6INpCrY2CWZxCcXkXabC3A7GBwfZsWY',
    appId: '1:118240719864:ios:e5e788d66a905e3bf59c0d',
    messagingSenderId: '118240719864',
    projectId: 'sembuhtbcuser',
    storageBucket: 'sembuhtbcuser.firebasestorage.app',
    androidClientId: '118240719864-8qi5mvbeqfnnteq998qa4kmmmtnq8b7h.apps.googleusercontent.com',
    iosClientId: '118240719864-8govdosgm9diicsvs74urpfab92qt3s1.apps.googleusercontent.com',
    iosBundleId: 'com.example.adminSembuhtbc',
  );

}