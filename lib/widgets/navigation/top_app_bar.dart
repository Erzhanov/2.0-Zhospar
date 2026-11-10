import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../common/brand_logo.dart';
import '../common/floating_motion.dart';
import '../common/tap_scale.dart';

/// Frosted glass sticky top app bar shared across shell tabs and sub-pages.
class TopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool isSubPage;
  final VoidCallback? onBack;
  final VoidCallback? onOpenSettings;
  final List<Widget>? actions;

  const TopAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.isSubPage = false,
    this.onBack,
    this.onOpenSettings,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(62);

  void _handleBack(BuildContext context) {
    HapticFeedback.lightImpact();
    if (onBack != null) {
      onBack!();
      return;
    }
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacementNamed(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassTint = isDark
        ? const Color(0xA60B1222)
        : Colors.white.withValues(alpha: 0.72);
    final rimColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.90);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: glassTint,
            border: Border(bottom: BorderSide(color: rimColor, width: 1)),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 62,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    if (isSubPage) ...[
                      TapScale(
                        onTap: () => _handleBack(context),
                        semanticLabel: lang.t('nav.back'),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.rimBorder(isDark),
                            ),
                            boxShadow: AppColors.floatingShadows(
                              isDark: isDark,
                              elevation: 0.45,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.arrow_back_rounded, size: 19),
                              if (MediaQuery.sizeOf(context).width >= 360) ...[
                                const SizedBox(width: 5),
                                Text(
                                  lang.t('nav.back'),
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          switchInCurve: AppMotion.spring,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.16),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                          child: Align(
                            key: ValueKey<String>(title),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      const BrandLogo(size: 38, borderRadius: 12),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: child,
                          ),
                          child: Align(
                            key: ValueKey<String>('$title-$subtitle'),
                            alignment: Alignment.centerLeft,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 17.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                if (subtitle != null && subtitle!.isNotEmpty)
                                  Text(
                                    subtitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? AppColors.darkSecondaryText
                                          : AppColors.lightSecondaryText,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],

                    ...?actions,
                    IconButton(
                      icon: Icon(
                        isDark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        size: 21,
                      ),
                      tooltip: isDark
                          ? lang.t('settings.light')
                          : lang.t('settings.dark'),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        theme.toggleTheme();
                      },
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                    ),
                    if (!isSubPage && onOpenSettings != null)
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, size: 21),
                        tooltip: lang.t('nav.settings'),
                        onPressed: onOpenSettings,
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
