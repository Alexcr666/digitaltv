// lib/firebase_options.dart
// ==============================================================
// Configuración Firebase actualizada a estilista-7a538
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
        return web;
      default:
        return web;
    }
  }

  // ── Web ───────────────────────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'AIzaSyDhzo0xL4ACH3tH7xWkXe9EqHQo9kcrMaM',
    authDomain:        'estilista-7a538.firebaseapp.com',
    databaseURL:       'https://estilista-7a538.firebaseio.com',
    projectId:         'estilista-7a538',
    storageBucket:     'estilista-7a538.appspot.com',
    messagingSenderId: '236180940295',
    appId:             '1:236180940295:web:14df2288a779fefcf2eca2',
    measurementId:     'G-2JMH6EDQEN',
  );

  // ── Android ───────────────────────────────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'AIzaSyDhzo0xL4ACH3tH7xWkXe9EqHQo9kcrMaM',
    authDomain:        'estilista-7a538.firebaseapp.com',
    databaseURL:       'https://estilista-7a538.firebaseio.com',
    projectId:         'estilista-7a538',
    storageBucket:     'estilista-7a538.appspot.com',
    messagingSenderId: '236180940295',
    appId:             '1:236180940295:web:14df2288a779fefcf2eca2',
  );

  // ── iOS ───────────────────────────────────────────────────
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:            'AIzaSyDhzo0xL4ACH3tH7xWkXe9EqHQo9kcrMaM',
    authDomain:        'estilista-7a538.firebaseapp.com',
    databaseURL:       'https://estilista-7a538.firebaseio.com',
    projectId:         'estilista-7a538',
    storageBucket:     'estilista-7a538.appspot.com',
    messagingSenderId: '236180940295',
    appId:             '1:236180940295:web:14df2288a779fefcf2eca2',
    iosClientId:       '',
    iosBundleId:       'com.example.digitaltv',
  );
}