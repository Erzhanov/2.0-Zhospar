import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/i18n/language_provider.dart';
import '../../../core/platform/platform_adaptive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/floating_motion.dart';

/// Floating frosted glass sidebar for tablets, foldables, and wide screens (>= 600dp).
class DesktopSidebar extends StatelessWidget {
  final int currentIndex;
  final List<AppNavItem> primaryItems;
  final List<AppNavItem> secondaryItems;
  final LanguageProvider lang;
  final ValueChanged<int> onTabSelected;
  final ValueChanged<AppNavItem> onSubPageSelected;
  final Future<void> Function() onSignOut;

  const DesktopSidebar({
    super.key,
    required this.currentIndex,
    required this.primaryItems,
    required this.secondaryItems,
    required this.lang,
    required this.onTabSelected,
    required this.onSubPageSelected,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary =
        isDark ? AppColors.darkPrimaryBright : AppColors.lightPrimary;
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isCompactRail = MediaQuery.sizeOf(context).width < 840;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, topInset + 12, 4, bottomInset + 14),
      child: Container(
        width: isCompactRail ? 76 : 222,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: AppColors.floatingShadows(isDark: isDark, elevation: 1.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xBF18181B)
                    : Colors.white.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColors.rimBorder(isDark)),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 14,
                      ),
                      children: [
                        for (int i = 0; i < primaryItems.length; i++)
                          _SidebarTile(
                            icon: currentIndex == i
                                ? primaryItems[i].activeIcon
                                : primaryItems[i].icon,
                            label: lang.t(primaryItems[i].labelKey),
                            compact: isCompactRail,
                            active: currentIndex == i,
                            activeColor: primary,
                            isDark: isDark,
                            onTap: () => onTabSelected(i),
                          ),
                        const SizedBox(height: 12),
                        for (final item in secondaryItems)
                          _SidebarTile(
                            icon: item.icon,
                            label: lang.t(item.labelKey),
                            compact: isCompactRail,
                            active: false,
                            activeColor: item.accentColor ?? primary,
                            isDark: isDark,
                            onTap: () => onSubPageSelected(item),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: isCompactRail
                        ? IconButton(
                            icon: const Icon(
                              Icons.logout_rounded,
                              color: AppColors.destructive,
                            ),
                            tooltip: lang.t('nav.logout'),
                            onPressed: () async {
                              final confirmed = await showAdaptiveConfirmDialog(
                                context,
                                title: lang.t('auth.logoutConfirmTitle'),
                                body: lang.t('auth.logoutConfirmBody'),
                                confirmLabel: lang.t('nav.logout'),
                                cancelLabel: lang.t('common.cancel'),
                                destructive: true,
                              );
                              if (confirmed) await onSignOut();
                            },
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                          )
                        : OutlinedButton.icon(
                            onPressed: () async {
                              final confirmed = await showAdaptiveConfirmDialog(
                                context,
                                title: lang.t('auth.logoutConfirmTitle'),
                                body: lang.t('auth.logoutConfirmBody'),
                                confirmLabel: lang.t('nav.logout'),
                                cancelLabel: lang.t('common.cancel'),
                                destructive: true,
                              );
                              if (confirmed) await onSignOut();
                            },
                            icon: const Icon(
                              Icons.logout_rounded,
                              size: 18,
                              color: AppColors.destructive,
                            ),
                            label: Text(
                              lang.t('nav.logout'),
                              style: const TextStyle(
                                color: AppColors.destructive,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 44),
                              side: BorderSide(
                                color: AppColors.destructive
                                    .withValues(alpha: 0.35),
                              ),
                            ),
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

class _SidebarTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool compact;
  final bool active;
  final Color activeColor;
  final bool isDark;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.icon,
    required this.label,
    required this.compact,
    required this.active,
    required this.activeColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_SidebarTile> createState() => _SidebarTileState();
}

class _SidebarTileState extends State<_SidebarTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Tooltip(
        message: widget.compact ? widget.label : '',
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                PlatformAdaptive.hapticSelection();
                widget.onTap();
              },
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: AppMotion.spring,
                transform: Matrix4.translationValues(
                  _hovered && !widget.active ? 3.0 : 0.0,
                  0,
                  0,
                ),
                constraints: const BoxConstraints(minHeight: 46),
                padding: EdgeInsets.symmetric(
                  horizontal: widget.compact ? 0 : 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: widget.active
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: widget.isDark
                              ? [
                                  Colors.white.withValues(alpha: 0.14),
                                  widget.activeColor.withValues(alpha: 0.22),
                                ]
                              : [
                                  Colors.white.withValues(alpha: 0.92),
                                  widget.activeColor.withValues(alpha: 0.14),
                                ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(14),
                  border: widget.active
                      ? Border.all(
                          color: widget.isDark
                              ? Colors.white.withValues(alpha: 0.22)
                              : widget.activeColor.withValues(alpha: 0.28),
                        )
                      : null,
                  boxShadow: widget.active
                      ? [
                          BoxShadow(
                            color: widget.activeColor.withValues(
                              alpha: widget.isDark ? 0.22 : 0.12,
                            ),
                            blurRadius: 12,
                            spreadRadius: -2,
                          ),
                        ]
                      : null,
                ),
                child: widget.compact
                    ? Center(
                        child: Icon(
                          widget.icon,
                          size: 22,
                          color: widget.active
                              ? widget.activeColor
                              : (widget.isDark
                                  ? Colors.white60
                                  : Colors.black54),
                        ),
                      )
                    : Row(
                        children: [
                          Icon(
                            widget.icon,
                            size: 20,
                            color: widget.active
                                ? widget.activeColor
                                : (widget.isDark
                                    ? Colors.white60
                                    : Colors.black54),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: widget.active
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: widget.active
                                    ? widget.activeColor
                                    : (widget.isDark
                                        ? Colors.white
                                        : Colors.black87),
                              ),
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
