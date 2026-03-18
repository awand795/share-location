// File ini akan di-generate otomatis oleh Firebase CLI
// Jalankan 'flutterfire configure' untuk generate file ini
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

// Tempatkan konfigurasi Firebase Anda di sini
// Setelah membuat project di Firebase Console, ganti nilai-nilai di bawah ini
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  // Ganti dengan konfigurasi dari Firebase Console Anda
  // Contoh konfigurasi Android - update dengan nilai dari project Firebase Anda
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAXyzN0ZVlVBz3HpNZOlq7fFVLzUPUwMlQ',
    appId: '1:563469755786:android:7c14f2e0a1370b9fea5473',
    messagingSenderId: '563469755786',
    projectId: 'share-location-app-39ce3',
    storageBucket: 'share-location-app-39ce3.firebasestorage.app',
  );
}
