import 'package:flutter/material.dart';
import '../../../core/i18n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../state/winter_theme_provider.dart';

/// Lightweight Settings toggle card for Winter Atmosphere.
/// Controls snowfall animation and festive Santa hat visibility.
class WinterCard extends StatelessWidget {
  final LanguageProvider lang;
  final WinterThemeProvider winter;

  const WinterCard({
    super.key,
    required this.lang,
    required this.winter,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.glowCyan.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.glowCyan.withValues(alpha: 0.30),
              ),
            ),
            child: const Icon(
              Icons.ac_unit_rounded,
              color: AppColors.glowCyan,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.t('winter.title'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lang.t('winter.desc'),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: winter.isWinterEnabled,
            activeThumbColor: primary,
            onChanged: winter.toggleWinter,
          ),
        ],
      ),
    );
  }
}
