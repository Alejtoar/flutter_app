import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => const FirebaseOptions(
    apiKey: 'AIzaSyDummyKeyForDevelopment',
    appId: '1:123456789012:windows:abcdef123456',
    messagingSenderId: '123456789012',
    projectId: 'golo-app-dev',
    storageBucket: 'golo-app-dev.appspot.com',
  );
}
