import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'secrets_service.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions currentPlatform(Secret secret) {
    if (kIsWeb) {
      return web(secret);
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android(secret);
      case TargetPlatform.iOS:
        return ios(secret);
      case TargetPlatform.macOS:
        return macos(secret);
      case TargetPlatform.windows:
        return windows(secret);
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

  static FirebaseOptions web(Secret secret) => FirebaseOptions(
    apiKey: secret.webApiKey,
    appId: '1:1036541708035:web:b15c2d0d1758793f72cb36',
    messagingSenderId: '1036541708035',
    projectId: 'nalliq',
    authDomain: 'nalliq.firebaseapp.com',
    storageBucket: 'nalliq.firebasestorage.app',
    measurementId: 'G-7YXEZWSFZX',
  );

  static FirebaseOptions android(Secret secret) => FirebaseOptions(
    apiKey: secret.androidApiKey,
    appId: '1:1036541708035:android:eba7983a7985ff9d72cb36',
    messagingSenderId: '1036541708035',
    projectId: 'nalliq',
    storageBucket: 'nalliq.firebasestorage.app',
  );

  static FirebaseOptions ios(Secret secret) => FirebaseOptions(
    apiKey: secret.iosApiKey,
    appId: '1:1036541708035:ios:757ee7d87142b64172cb36',
    messagingSenderId: '1036541708035',
    projectId: 'nalliq',
    storageBucket: 'nalliq.firebasestorage.app',
    iosBundleId: 'com.example.nalliq',
  );

  static FirebaseOptions macos(Secret secret) => FirebaseOptions(
    apiKey: secret.iosApiKey,
    appId: '1:1036541708035:ios:757ee7d87142b64172cb36',
    messagingSenderId: '1036541708035',
    projectId: 'nalliq',
    storageBucket: 'nalliq.firebasestorage.app',
    iosBundleId: 'com.example.nalliq',
  );

  static FirebaseOptions windows(Secret secret) => FirebaseOptions(
    apiKey: secret.webApiKey,
    appId: '1:1036541708035:web:8016fe08ca5c897472cb36',
    messagingSenderId: '1036541708035',
    projectId: 'nalliq',
    authDomain: 'nalliq.firebaseapp.com',
    storageBucket: 'nalliq.firebasestorage.app',
    measurementId: 'G-CCEE76X1CC',
  );
}
