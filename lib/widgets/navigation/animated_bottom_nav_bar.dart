import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';

/// Mobile-first bottom navigation bar with a sliding active indicator pill,
/// top accent line, and spring/ease micro-interactions on tap.
class AnimatedBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final List<AppNavItem> primaryItems;
  final bool hasMoreItem;
  final bool isMoreHighlighted;
  final ValueChanged<int> onTabSelected;
  final VoidCallback? onMoreTapped;
  final LanguageProvider lang;

  const AnimatedBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.primaryItems,
    required this.onTabSelected,
    required this.lang,
    this.hasMoreItem = true,
    this.isMoreHighlighted = false,
    this.onMoreTapped,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final cardColor = isDark
        ? AppColors.darkCard.withValues(alpha: 0.96)
        : AppColors.lightCard.withValues(alpha: 0.96);
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final inactiveColor = isDark ? Colors.white60 : Colors.black54;

    final totalCount = primaryItems.length + (hasMoreItem ? 1 : 0);
    final activeSlot = isMoreHighlighted && hasMoreItem
        ? primaryItems.length
        : currentIndex.clamp(0, totalCount - 1);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, -4),
                ),
              ],
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SizedBox(
              height: 68,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final slotWidth = constraints.maxWidth / totalCount;
                  final pillHorizontalInset = 4.0;
                  final pillWidth = (slotWidth - pillHorizontalInset * 2)
                      .clamp(44.0, double.infinity);

                  return Stack(
                    children: [
                      // Sliding active background pill
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        left: activeSlot * slotWidth + pillHorizontalInset,
                        top: 7,
                        bottom: 7,
                        width: pillWidth,
                        child: Container(
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: isDark ? 0.18 : 0.11),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),

                      // Sliding top accent indicator
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutBack,
                        left: activeSlot * slotWidth + (slotWidth - 22) / 2,
                        top: 0,
                        width: 22,
                        height: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(3),
                            ),
                          ),
                        ),
                      ),

                      // Interactive nav slots (>= 44x44px)
                      Row(
                        children: [
                          for (int i = 0; i < primaryItems.length; i++)
                            _NavBarSlot(
                              icon: primaryItems[i].icon,
                              activeIcon: primaryItems[i].activeIcon,
                              label: lang.t(primaryItems[i].labelKey),
                              active: !isMoreHighlighted && currentIndex == i,
                              activeColor: primary,
                              inactiveColor: inactiveColor,
                              onTap: () => onTabSelected(i),
                            ),
                          if (hasMoreItem)
                            _NavBarSlot(
                              icon: Icons.grid_view_rounded,
                              activeIcon: Icons.grid_view_rounded,
                              label: lang.t('nav.more'),
                              active: isMoreHighlighted,
                              activeColor: primary,
                              inactiveColor: inactiveColor,
                              onTap: () => onMoreTapped?.call(),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarSlot extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavBarSlot({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  State<_NavBarSlot> createState() => _NavBarSlotState();
}

class _NavBarSlotState extends State<_NavBarSlot> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.active ? widget.activeColor : widget.inactiveColor;

    return Expanded(
      child: Semantics(
        button: true,
        selected: widget.active,
        label: widget.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onTap();
          },
          child: SizedBox(
            height: 68,
            child: AnimatedScale(
              scale: _pressed ? 0.88 : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutCubic,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutBack,
                    transform: Matrix4.translationValues(
                      0,
                      widget.active ? -1.5 : 0,
                      0,
                    ),
                    child: AnimatedScale(
                      scale: widget.active ? 1.08 : 1.0,
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutBack,
                      child: Icon(
                        widget.active ? widget.activeIcon : widget.icon,
                        size: 22,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            widget.active ? FontWeight.w700 : FontWeight.w500,
                        color: color,
                        letterSpacing: -0.2,
                      ),
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
