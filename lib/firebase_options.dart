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
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDZ7-3GQ2vhNC4TgTdODj7xejskN1eZBB0',
    appId: '1:507927332163:android:eb42c63bbbcf9bc9029bf6',
    messagingSenderId: '507927332163',
    projectId: 'tech-truckers-abd65',
    databaseURL: 'https://tech-truckers-abd65-default-rtdb.firebaseio.com',
    storageBucket: 'tech-truckers-abd65.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAKN0VKhX-RtDgmAPpB2-DYvHqAVRBUJ_A',
    appId: '1:507927332163:ios:18ea503b8c8aa9fc029bf6',
    messagingSenderId: '507927332163',
    projectId: 'tech-truckers-abd65',
    databaseURL: 'https://tech-truckers-abd65-default-rtdb.firebaseio.com',
    storageBucket: 'tech-truckers-abd65.appspot.com',
    iosBundleId: 'com.example.techtruckers',
  );
}
