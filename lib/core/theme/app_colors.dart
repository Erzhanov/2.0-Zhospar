import 'package:flutter/material.dart';

class AppColors {
  // Light Theme Palette (Classic ZHOSPAR / iOS Light)
  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color lightBackgroundSecondary = Color(0xFFE8EEF8);
  static const Color lightCard = Color(0xEBFFFFFF); // Frosted pure white
  static const Color lightForeground = Color(0xFF1C1C1E);
  static const Color lightSecondaryText = Color(0xFF8E8E93);
  static const Color lightBorder = Color(0xFFE5E5EA);
  static const Color lightMuted = Color(0xFFE5E5EA);
  static const Color lightPrimary = Color(0xFF007AFF);
  static const Color lightPrimaryDark = Color(0xFF005EC4);

  // Dark Theme Palette (Classic ZHOSPAR / iOS OLED Dark)
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkBackgroundSecondary = Color(0xFF0A0C12);
  static const Color darkCard = Color(0xDE1C1C1E); // Translucent #1C1C1E
  static const Color darkForeground = Color(0xFFFFFFFF);
  static const Color darkSecondaryText = Color(0xFF98989D);
  static const Color darkBorder = Color(0xFF2C2C2E);
  static const Color darkMuted = Color(0xFF2C2C2E);
  static const Color darkPrimary = Color(0xFF0A84FF);
  static const Color darkPrimaryBright = Color(0xFF5AC8FA);

  // Ambient Accents
  static const Color glowTeal = Color(0xFF30B0C7);
  static const Color glowIndigo = Color(0xFF5856D6);
  static const Color glowAmber = Color(0xFFFF9500);

  // Status & Semantic Accents (Original iOS Palette)
  static const Color success = Color(0xFF34C759);
  static const Color destructive = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFF9500);
  static const Color purple = Color(0xFFAF52DE);
  static const Color teal = Color(0xFF30B0C7);
  static const Color indigo = Color(0xFF5856D6);

  // Priority Pill Colors
  static const Color priorityLowBg = Color(0xFFE5E5EA);
  static const Color priorityLowText = Color(0xFF636366);
  static const Color priorityMedBg = Color(0xFFE1F0FF);
  static const Color priorityMedText = Color(0xFF007AFF);
  static const Color priorityHighBg = Color(0xFFFFE5E5);
  static const Color priorityHighText = Color(0xFFFF3B30);

  /// Multi-layered diffuse floating shadow tuned for low-overhead GPU rendering.
  static List<BoxShadow> floatingShadows({
    required bool isDark,
    Color? glowColor,
    double elevation = 1.0,
  }) {
    final tint = glowColor ?? (isDark ? darkPrimary : lightPrimary);
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.50 * elevation),
          blurRadius: 24 * elevation,
          spreadRadius: -5,
          offset: Offset(0, 10 * elevation),
        ),
        BoxShadow(
          color: tint.withValues(alpha: 0.12 * elevation),
          blurRadius: 18 * elevation,
          spreadRadius: -4,
          offset: Offset(0, 3 * elevation),
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06 * elevation),
        blurRadius: 20 * elevation,
        spreadRadius: -4,
        offset: Offset(0, 8 * elevation),
      ),
      BoxShadow(
        color: tint.withValues(alpha: 0.08 * elevation),
        blurRadius: 12 * elevation,
        spreadRadius: -2,
        offset: Offset(0, 3 * elevation),
      ),
    ];
  }

  /// Luminous glass rim color matching the light/dark surface.
  static Color rimBorder(bool isDark, {bool highlighted = false}) {
    if (highlighted) {
      return isDark
          ? darkPrimary.withValues(alpha: 0.55)
          : lightPrimary.withValues(alpha: 0.45);
    }
    return isDark
        ? Colors.white.withValues(alpha: 0.13)
        : Colors.white.withValues(alpha: 0.90);
  }

  static Map<String, dynamic> getCategoryStyle(String category, bool isDark) {
    switch (category.toLowerCase()) {
      case 'оқу':
      case 'учёба':
      case 'study':
        return {
          'bg': isDark ? const Color(0xFF2C1E40) : const Color(0xFFF3E8FF),
          'text': isDark ? const Color(0xFFD8B4FE) : const Color(0xFF9333EA),
        };
      case 'жұмыс':
      case 'работа':
      case 'work':
        return {
          'bg': isDark ? const Color(0xFF1E2840) : const Color(0xFFE0E7FF),
          'text': isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5),
        };
      case 'жоба':
      case 'проект':
      case 'project':
        return {
          'bg': isDark ? const Color(0xFF3B2A18) : const Color(0xFFFFEDD5),
          'text': isDark ? const Color(0xFFFDBA74) : const Color(0xFFEA580C),
        };
      case 'денсаулық':
      case 'здоровье':
      case 'health':
        return {
          'bg': isDark ? const Color(0xFF143324) : const Color(0xFFDCFCE7),
          'text': isDark ? const Color(0xFF86EFAC) : const Color(0xFF16A34A),
        };
      case 'үй':
      case 'дом':
      case 'home':
        return {
          'bg': isDark ? const Color(0xFF173038) : const Color(0xFFCCFBF1),
          'text': isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0D9488),
        };
      case 'жеке':
      case 'личное':
      case 'personal':
      default:
        return {
          'bg': isDark ? const Color(0xFF381E2E) : const Color(0xFFFCE7F3),
          'text': isDark ? const Color(0xFFF472B6) : const Color(0xFFDB2777),
        };
    }
  }
}
