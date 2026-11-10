import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';

/// Responsive wide-screen sidebar displaying primary tabs and secondary routes.
class DesktopSidebar extends StatelessWidget {
  final int currentIndex;
  final List<AppNavItem> primaryItems;
  final List<AppNavItem> secondaryItems;
  final LanguageProvider lang;
  final ValueChanged<int> onTabSelected;
  final ValueChanged<AppNavItem> onSubPageSelected;
  final VoidCallback onSignOut;

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
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      width: 224,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: Border(right: BorderSide(color: border, width: 1)),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              children: [
                for (int i = 0; i < primaryItems.length; i++)
                  _SidebarTile(
                    icon: currentIndex == i
                        ? primaryItems[i].activeIcon
                        : primaryItems[i].icon,
                    label: lang.t(primaryItems[i].labelKey),
                    active: currentIndex == i,
                    activeColor: primary,
                    isDark: isDark,
                    onTap: () => onTabSelected(i),
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1),
                ),
                for (final item in secondaryItems)
                  _SidebarTile(
                    icon: item.icon,
                    label: lang.t(item.labelKey),
                    active: false,
                    activeColor: item.accentColor ?? primary,
                    isDark: isDark,
                    onTap: () => onSubPageSelected(item),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
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
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                side: BorderSide(
                  color: AppColors.destructive.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final bool isDark;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.icon,
    required this.label,
    required this.active,
    required this.activeColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: active
                  ? activeColor.withValues(alpha: isDark ? 0.2 : 0.11)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: active
                      ? activeColor
                      : (isDark ? Colors.white60 : Colors.black54),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active
                          ? activeColor
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
