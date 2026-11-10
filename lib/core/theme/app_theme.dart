import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData light() {
    return _buildTheme(
      base: ThemeData.light(useMaterial3: true),
      brightness: Brightness.light,
      scaffoldBg: Colors.transparent,
      primary: AppColors.lightPrimary,
      surface: Colors.white,
      foreground: AppColors.lightForeground,
      border: const Color(0x330F172A),
    );
  }

  static ThemeData dark() {
    return _buildTheme(
      base: ThemeData.dark(useMaterial3: true),
      brightness: Brightness.dark,
      scaffoldBg: Colors.transparent,
      primary: AppColors.darkPrimary,
      surface: const Color(0xFF11182B),
      foreground: AppColors.darkForeground,
      border: const Color(0x24FFFFFF),
    );
  }

  static ThemeData _buildTheme({
    required ThemeData base,
    required Brightness brightness,
    required Color scaffoldBg,
    required Color primary,
    required Color surface,
    required Color foreground,
    required Color border,
  }) {
    final interFont = GoogleFonts.inter().fontFamily;
    final isDark = brightness == Brightness.dark;

    final baseText = base.textTheme.apply(
      fontFamily: interFont,
      bodyColor: foreground,
      displayColor: foreground,
    );

    return base.copyWith(
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: Colors.white,
        secondary: AppColors.glowIndigo,
        onSecondary: Colors.white,
        error: AppColors.destructive,
        onError: Colors.white,
        surface: surface,
        onSurface: foreground,
        outline: border,
      ),
      textTheme: baseText.copyWith(
        headlineMedium: baseText.headlineMedium?.copyWith(
          height: 1.2,
          letterSpacing: -0.6,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: baseText.titleLarge?.copyWith(
          height: 1.25,
          letterSpacing: -0.4,
          fontWeight: FontWeight.w800,
        ),
        bodyLarge: baseText.bodyLarge?.copyWith(height: 1.45),
        bodyMedium: baseText.bodyMedium?.copyWith(height: 1.45),
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: AppColors.rimBorder(isDark), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(44, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 46),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          side: BorderSide(color: AppColors.rimBorder(isDark)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.72),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.rimBorder(isDark)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.14)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? const Color(0xEB121A2E) : const Color(0xF5FFFFFF),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: BorderSide(color: AppColors.rimBorder(isDark), width: 1.2),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 60,
        iconTheme: IconThemeData(color: foreground),
        titleTextStyle: TextStyle(
          fontFamily: interFont,
          color: foreground,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05),
        thickness: 1,
      ),
    );
  }
}
