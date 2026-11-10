import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/i18n/language_provider.dart';
import '../../../core/platform/platform_adaptive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/floating_motion.dart';
import '../../../shared/widgets/tap_scale.dart';

/// Floating frosted glass bottom sheet for secondary navigation and confirmed sign-out.
class MobileMoreSheet extends StatelessWidget {
  final List<AppNavItem> items;
  final LanguageProvider lang;
  final ValueChanged<AppNavItem> onSelectItem;
  final Future<void> Function() onSignOut;

  const MobileMoreSheet({
    super.key,
    required this.items,
    required this.lang,
    required this.onSelectItem,
    required this.onSignOut,
  });

  static Future<void> show(
    BuildContext context, {
    required List<AppNavItem> items,
    required LanguageProvider lang,
    required ValueChanged<AppNavItem> onSelectItem,
    required Future<void> Function() onSignOut,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MobileMoreSheet(
        items: items,
        lang: lang,
        onSelectItem: (item) {
          Navigator.of(ctx).pop();
          onSelectItem(item);
        },
        onSignOut: () async {
          final confirmed = await showAdaptiveConfirmDialog(
            ctx,
            title: lang.t('auth.logoutConfirmTitle'),
            body: lang.t('auth.logoutConfirmBody'),
            confirmLabel: lang.t('nav.logout'),
            cancelLabel: lang.t('common.cancel'),
            destructive: true,
          );
          if (confirmed && ctx.mounted) {
            Navigator.of(ctx).pop();
            await onSignOut();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width < 360 ? 2 : 3;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: AppColors.floatingShadows(isDark: isDark, elevation: 1.4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xE01C1C1E)
                      : Colors.white.withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColors.rimBorder(isDark),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          lang.t('nav.menu'),
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 22),
                          tooltip: lang.t('nav.close'),
                          onPressed: () {
                            PlatformAdaptive.hapticLight();
                            Navigator.of(context).pop();
                          },
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: crossAxisCount == 2 ? 1.35 : 1.05,
                      ),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final accent = item.accentColor ??
                            (isDark
                                ? AppColors.darkPrimaryBright
                                : AppColors.lightPrimary);

                        return SpringPopIn(
                          duration: Duration(milliseconds: 260 + (index * 50)),
                          beginOffsetY: 16,
                          child: TapScale(
                            onTap: () => onSelectItem(item),
                            semanticLabel: lang.t(item.labelKey),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.white.withValues(alpha: 0.72),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.rimBorder(isDark),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      item.icon,
                                      color: accent,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    lang.t(item.labelKey),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onSignOut,
                            icon: const Icon(
                              Icons.logout_rounded,
                              size: 18,
                              color: AppColors.destructive,
                            ),
                            label: Text(
                              lang.t('nav.logout'),
                              style: const TextStyle(
                                color: AppColors.destructive,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(44, 48),
                              side: BorderSide(
                                color: AppColors.destructive
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.tonal(
                          onPressed: () => Navigator.of(context).pop(),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(84, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            lang.t('nav.close'),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
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
