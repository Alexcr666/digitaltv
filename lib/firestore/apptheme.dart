// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppColors {
  // Brand
  static const primary = Color(0xFF4F7DFF);
  static const primaryLight = Color(0xFF6B99FF);
  static const primaryDark = Color(0xFF3A62D9);

  // Status
  static const online = Color(0xFF22D07A);
  static const offline = Color(0xFF545C72);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFFF4F6B);

  // Dark theme surfaces
  static const dark900 = Color(0xFF0A0B0E);
  static const dark800 = Color(0xFF111318);
  static const dark700 = Color(0xFF181C24);
  static const dark600 = Color(0xFF1E2330);
  static const dark500 = Color(0xFF252C3D);

  // Light theme surfaces
  static const light50 = Color(0xFFF8F9FC);
  static const light100 = Color(0xFFF0F2F8);
  static const light200 = Color(0xFFE4E8F2);
  static const light300 = Color(0xFFCDD3E5);
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.dark900,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.primaryLight,
          surface: AppColors.dark800,
          error: AppColors.error,
        ),
        textTheme:
            GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme).copyWith(
          displayLarge: GoogleFonts.dmSans(
              fontSize: 32, fontWeight: FontWeight.w600, color: Colors.white),
          headlineMedium: GoogleFonts.dmSans(
              fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
          titleLarge: GoogleFonts.dmSans(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
          titleMedium: GoogleFonts.dmSans(
              fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
          bodyLarge: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFFE8EAF0)),
          bodyMedium: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF8B92A5)),
          labelSmall: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF545C72),
              letterSpacing: 0.5),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.dark700,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0x18FFFFFF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0x18FFFFFF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        cardTheme: CardTheme(
          color: AppColors.dark800,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0x0FFFFFFF)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle:
                GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0x0FFFFFFF),
          thickness: 1,
        ),
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.light50,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.primaryLight,
          surface: Colors.white,
          error: AppColors.error,
        ),
        textTheme:
            GoogleFonts.dmSansTextTheme(ThemeData.light().textTheme).copyWith(
          displayLarge: GoogleFonts.dmSans(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F1120)),
          headlineMedium: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F1120)),
          titleLarge: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F1120)),
          titleMedium: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1D2E)),
          bodyLarge: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF2D3146)),
          bodyMedium: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6B7290)),
          labelSmall: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF9BA3BA),
              letterSpacing: 0.5),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.light300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.light300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.light200),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle:
                GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.light200,
          thickness: 1,
        ),
      );
}

// ── THEME NOTIFIER (persisted preference) ─────────────────────────────────────
// lib/core/theme/theme_provider.dart

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark) {
    _loadTheme();
  }

  static const _key = 'theme_mode';

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == 'light')
      state = ThemeMode.light;
    else if (saved == 'system')
      state = ThemeMode.system;
    else
      state = ThemeMode.dark;
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  void toggle() =>
      setTheme(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (_) => ThemeNotifier(),
);
