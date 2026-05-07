// lib/firebase_options.dart
// ==============================================================
// Generado manualmente con las credenciales de index.html
// NUNCA subas este archivo a un repositorio público
// ==============================================================

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return web; // reutiliza web para macOS desktop
      default:
        return web;
    }
  }

  // ── Web ───────────────────────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'AIzaSyAtNMdib_L9yjXDql87crKBCwlC-zSK3ic',
    authDomain:        'notes-4c618.firebaseapp.com',
    databaseURL:       'https://notes-4c618.firebaseio.com',
    projectId:         'notes-4c618',
    storageBucket:     'notes-4c618.firebasestorage.app',
    messagingSenderId: '659987129698',
    appId:             '1:659987129698:web:5dacdc20c2ffd1760cf83b',
    measurementId:     'G-MP4Z852SKS',
  );

  // ── Android ───────────────────────────────────────────────
  // Si tienes google-services.json, reemplaza estos valores
  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'AIzaSyAtNMdib_L9yjXDql87crKBCwlC-zSK3ic',
    authDomain:        'notes-4c618.firebaseapp.com',
    databaseURL:       'https://notes-4c618.firebaseio.com',
    projectId:         'notes-4c618',
    storageBucket:     'notes-4c618.firebasestorage.app',
    messagingSenderId: '659987129698',
    appId:             '1:659987129698:web:5dacdc20c2ffd1760cf83b',
  );

  // ── iOS ───────────────────────────────────────────────────
  // Si tienes GoogleService-Info.plist, reemplaza estos valores
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:            'AIzaSyAtNMdib_L9yjXDql87crKBCwlC-zSK3ic',
    authDomain:        'notes-4c618.firebaseapp.com',
    databaseURL:       'https://notes-4c618.firebaseio.com',
    projectId:         'notes-4c618',
    storageBucket:     'notes-4c618.firebasestorage.app',
    messagingSenderId: '659987129698',
    appId:             '1:659987129698:web:5dacdc20c2ffd1760cf83b',
    iosClientId:       '', // agregar si usas Google Sign-In en iOS
    iosBundleId:       'com.example.digitaltv',
  );
}