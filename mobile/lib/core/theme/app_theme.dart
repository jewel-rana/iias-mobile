import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_fonts.dart';

class AppTheme {
  static ThemeData light([Locale locale = const Locale('en')]) {
    final bangla = locale.languageCode == 'bn';
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
    );

    final manrope = GoogleFonts.manropeTextTheme(base.textTheme);
    final textTheme = _withFallback(
      (bangla ? manrope.apply(fontFamily: AppFonts.kalpurush) : manrope).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      bangla ? const ['Manrope'] : const [AppFonts.kalpurush],
    );

    final titleStyle = bangla
        ? AppFonts.bangla(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)
        : GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: titleStyle,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: bangla
              ? AppFonts.bangla(fontSize: 16, fontWeight: FontWeight.w700)
              : GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: bangla ? AppFonts.bangla(fontSize: 16, fontWeight: FontWeight.w700) : null,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return Colors.transparent;
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static TextTheme _withFallback(TextTheme theme, List<String> fallback) {
    TextStyle? wrap(TextStyle? style) =>
        style?.copyWith(fontFamilyFallback: fallback);
    return theme.copyWith(
      displayLarge: wrap(theme.displayLarge),
      displayMedium: wrap(theme.displayMedium),
      displaySmall: wrap(theme.displaySmall),
      headlineLarge: wrap(theme.headlineLarge),
      headlineMedium: wrap(theme.headlineMedium),
      headlineSmall: wrap(theme.headlineSmall),
      titleLarge: wrap(theme.titleLarge),
      titleMedium: wrap(theme.titleMedium),
      titleSmall: wrap(theme.titleSmall),
      bodyLarge: wrap(theme.bodyLarge),
      bodyMedium: wrap(theme.bodyMedium),
      bodySmall: wrap(theme.bodySmall),
      labelLarge: wrap(theme.labelLarge),
      labelMedium: wrap(theme.labelMedium),
      labelSmall: wrap(theme.labelSmall),
    );
  }
}
