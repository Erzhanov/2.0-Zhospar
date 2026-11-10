import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../common/tap_scale.dart';

/// Sticky/fixed top app bar shared across primary shell tabs and sub-pages.
///
/// On sub-pages ([isSubPage] == true), displays a prominent Back button
/// (arrow icon, >=44x44px) that pops the navigation stack or falls back to
/// [AppRoutes.home], alongside an animated dynamic page title.
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
  Size get preferredSize => const Size.fromHeight(58);

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

  Future<void> _handleSignOut(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.auth,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final surface = isDark
        ? AppColors.darkCard.withValues(alpha: 0.94)
        : AppColors.lightCard.withValues(alpha: 0.94);
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Material(
      color: surface,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: border, width: 1)),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 58,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  if (isSubPage) ...[
                    TapScale(
                      onTap: () => _handleBack(context),
                      semanticLabel: lang.t('nav.back'),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_back_rounded, size: 22),
                            if (MediaQuery.sizeOf(context).width >= 380) ...[
                              const SizedBox(width: 4),
                              Text(
                                lang.t('nav.back'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.14),
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
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
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
                                  fontSize: 17,
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
                                    fontSize: 11,
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

                  // Right-side touch-friendly action buttons (>= 44x44px)
                  ...?actions,
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
                  if (!isSubPage)
                    IconButton(
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      color: AppColors.destructive,
                      tooltip: lang.t('nav.logout'),
                      onPressed: () => _handleSignOut(context),
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
    );
  }
}
