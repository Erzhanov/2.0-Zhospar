import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/i18n/language_provider.dart';
import '../../../core/platform/platform_adaptive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/floating_motion.dart';
import '../../../shared/widgets/tap_scale.dart';

/// Platform-adaptive frosted glass Back header bar used strictly on pushed sub-pages.
class TopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isSubPage;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  const TopAppBar({
    super.key,
    required this.title,
    this.isSubPage = true,
    this.onBack,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(62);

  void _handleBack(BuildContext context) {
    PlatformAdaptive.hapticLight();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isApple = PlatformAdaptive.isApple(context);
    final glassTint = isDark
        ? const Color(0xBA141416)
        : Colors.white.withValues(alpha: 0.78);
    final rimColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.90);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
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
                        key: const ValueKey('top-app-bar-back'),
                        onTap: () => _handleBack(context),
                        semanticLabel: lang.t('nav.back'),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
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
                              Icon(
                                isApple
                                    ? Icons.arrow_back_ios_new_rounded
                                    : Icons.arrow_back_rounded,
                                size: 18,
                              ),
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
                    ],
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
                          alignment:
                              isApple ? Alignment.center : Alignment.centerLeft,
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                    ...?actions,
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
