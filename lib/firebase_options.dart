import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
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
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAE6IAnvRID8hfZIoIzvoZIJ396fApEU40',
    appId: '1:141599289824:android:a11e737fba99580c023b85',
    messagingSenderId: '141599289824',
    projectId: 'digiluk',
    storageBucket: 'digiluk.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAE6IAnvRID8hfZIoIzvoZIJ396fApEU40',
    appId: '1:141599289824:ios:0000000000000000000000',
    messagingSenderId: '141599289824',
    projectId: 'digiluk',
    storageBucket: 'digiluk.firebasestorage.app',
    iosBundleId: 'com.digiluk.app',
  );
}
