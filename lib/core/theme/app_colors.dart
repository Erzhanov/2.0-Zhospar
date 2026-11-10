import 'package:flutter/material.dart';

class AppColors {
  // Light Mode: Ultra-Clean Prism Mist
  static const Color lightBackground = Color(0xFFF6F9FC);
  static const Color lightBackgroundSecondary = Color(0xFFEEF4FA);
  static const Color lightCard = Color(0xD9FFFFFF); // 85% frosted white
  static const Color lightForeground = Color(0xFF0F172A);
  static const Color lightSecondaryText = Color(0xFF5B6B7F);
  static const Color lightBorder = Color(0xCCFFFFFF); // Luminous white prism rim
  static const Color lightMuted = Color(0x99E8EFF7);
  static const Color lightPrimary = Color(0xFF0D736B);
  static const Color lightPrimaryDark = Color(0xFF0A524D);

  // Dark Mode: Deep Space Zero-G
  static const Color darkBackground = Color(0xFF060913);
  static const Color darkBackgroundSecondary = Color(0xFF0B1222);
  static const Color darkCard = Color(0xA6121A2E); // Translucent obsidian glass
  static const Color darkForeground = Color(0xFFF8FAFC);
  static const Color darkSecondaryText = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0x26FFFFFF); // ~15% luminous white rim
  static const Color darkMuted = Color(0x7318233C);
  static const Color darkPrimary = Color(0xFF14B8A6);
  static const Color darkPrimaryBright = Color(0xFF5EEAD4);

  // Ambient Neon / Prism Glow Accents
  static const Color glowTeal = Color(0xFF2DD4BF);
  static const Color glowIndigo = Color(0xFF818CF8);
  static const Color glowAmber = Color(0xFFFBBF24);

  // Status & Semantic Accents
  static const Color success = Color(0xFF22C55E);
  static const Color destructive = Color(0xFFF43F5E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color purple = Color(0xFFA78BFA);
  static const Color teal = Color(0xFF14B8A6);
  static const Color indigo = Color(0xFF6366F1);

  // Priority Pill Colors
  static const Color priorityLowBg = Color(0x1F64748B);
  static const Color priorityLowText = Color(0xFF475569);
  static const Color priorityMedBg = Color(0x1F0D9488);
  static const Color priorityMedText = Color(0xFF0D736B);
  static const Color priorityHighBg = Color(0x1FF43F5E);
  static const Color priorityHighText = Color(0xFFE11D48);

  /// Multi-layered diffuse floating shadow giving components levitating depth.
  static List<BoxShadow> floatingShadows({
    required bool isDark,
    Color? glowColor,
    double elevation = 1.0,
  }) {
    final tint = glowColor ?? (isDark ? glowTeal : lightPrimary);
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.48 * elevation),
          blurRadius: 32 * elevation,
          spreadRadius: -6,
          offset: Offset(0, 14 * elevation),
        ),
        BoxShadow(
          color: tint.withValues(alpha: 0.10 * elevation),
          blurRadius: 24 * elevation,
          spreadRadius: -4,
          offset: Offset(0, 4 * elevation),
        ),
      ];
    }
    return [
      BoxShadow(
        color: const Color(0xFF0F2942).withValues(alpha: 0.08 * elevation),
        blurRadius: 28 * elevation,
        spreadRadius: -6,
        offset: Offset(0, 12 * elevation),
      ),
      BoxShadow(
        color: tint.withValues(alpha: 0.07 * elevation),
        blurRadius: 12 * elevation,
        spreadRadius: -2,
        offset: Offset(0, 4 * elevation),
      ),
    ];
  }

  /// Luminous glass rim color.
  static Color rimBorder(bool isDark, {bool highlighted = false}) {
    if (highlighted) {
      return isDark
          ? glowTeal.withValues(alpha: 0.55)
          : lightPrimary.withValues(alpha: 0.45);
    }
    return isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.white.withValues(alpha: 0.85);
  }

  static Map<String, dynamic> getCategoryStyle(String category, bool isDark) {
    switch (category.toLowerCase()) {
      case 'оқу':
      case 'учёба':
      case 'study':
        return {
          'bg': isDark ? const Color(0x33A78BFA) : const Color(0xFFF3E8FF),
          'text': isDark ? const Color(0xFFD8B4FE) : const Color(0xFF7C3AED),
        };
      case 'жұмыс':
      case 'работа':
      case 'work':
        return {
          'bg': isDark ? const Color(0x33818CF8) : const Color(0xFFE0E7FF),
          'text': isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA),
        };
      case 'жоба':
      case 'проект':
      case 'project':
        return {
          'bg': isDark ? const Color(0x33FB923C) : const Color(0xFFFFEDD5),
          'text': isDark ? const Color(0xFFFDBA74) : const Color(0xFFEA580C),
        };
      case 'денсаулық':
      case 'здоровье':
      case 'health':
        return {
          'bg': isDark ? const Color(0x334ADE80) : const Color(0xFFDCFCE7),
          'text': isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
        };
      case 'үй':
      case 'дом':
      case 'home':
        return {
          'bg': isDark ? const Color(0x332DD4BF) : const Color(0xFFCCFBF1),
          'text': isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E),
        };
      case 'жеке':
      case 'личное':
      case 'personal':
      default:
        return {
          'bg': isDark ? const Color(0x33F472B6) : const Color(0xFFFCE7F3),
          'text': isDark ? const Color(0xFFF9A8D4) : const Color(0xFFBE185D),
        };
    }
  }
}
