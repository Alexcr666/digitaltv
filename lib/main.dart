// lib/main.dart
import 'package:digitaltv/firestore/apptheme.dart';

import 'package:digitaltv/route/route.dart';
import 'package:digitaltv/ui/dashboard.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // ← DESCOMENTADO
  );

  runApp(const ProviderScope(child: DigitalSignageApp()));
}

class DigitalSignageApp extends ConsumerWidget {
  const DigitalSignageApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final router    = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SignageOS',
      debugShowCheckedModeBanner: false,
      theme:        buildLightTheme(),
      darkTheme:    buildDarkTheme(),
      themeMode:    themeMode,
      routerConfig: router,
    );
  }
}