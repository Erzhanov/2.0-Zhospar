import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../common/floating_motion.dart';

/// Floating Zero-G glass capsule bottom navigation bar with sliding luminous
/// active indicator and spring physics micro-interactions.
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
    final primary =
        isDark ? AppColors.darkPrimaryBright : AppColors.lightPrimary;
    final pillTint = isDark
        ? Colors.white.withValues(alpha: 0.11)
        : primary.withValues(alpha: 0.11);
    final inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.62)
        : const Color(0xFF5B6B7F);

    final totalCount = primaryItems.length + (hasMoreItem ? 1 : 0);
    final activeSlot = isMoreHighlighted && hasMoreItem
        ? primaryItems.length
        : currentIndex.clamp(0, totalCount - 1);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: AppColors.floatingShadows(
                  isDark: isDark,
                  glowColor: primary,
                  elevation: 1.25,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xBF0F172A)
                          : Colors.white.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppColors.rimBorder(isDark),
                        width: 1.2,
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final slotWidth = constraints.maxWidth / totalCount;
                        const inset = 3.0;
                        final pillWidth =
                            (slotWidth - inset * 2).clamp(44.0, double.infinity);

                        return Stack(
                          children: [
                            // Sliding luminous active glass capsule
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              left: activeSlot * slotWidth + inset,
                              top: 6,
                              bottom: 6,
                              width: pillWidth,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: pillTint,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: primary.withValues(
                                      alpha: isDark ? 0.35 : 0.18,
                                    ),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),

                            // Sliding glowing indicator pill at top of capsule
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 320),
                              curve: Curves.easeOutBack,
                              left: activeSlot * slotWidth +
                                  (slotWidth - 20) / 2,
                              top: 2,
                              width: 20,
                              height: 3,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: primary,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primary.withValues(alpha: 0.6),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Interactive slots (>= 44x44px)
                            Row(
                              children: [
                                for (int i = 0; i < primaryItems.length; i++)
                                  _NavBarSlot(
                                    icon: primaryItems[i].icon,
                                    activeIcon: primaryItems[i].activeIcon,
                                    label: lang.t(primaryItems[i].labelKey),
                                    active:
                                        !isMoreHighlighted && currentIndex == i,
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
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.active ? widget.activeColor : widget.inactiveColor;

    return Expanded(
      child: Semantics(
        button: true,
        selected: widget.active,
        label: widget.label,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
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
                scale: _pressed ? 0.93 : 1.0,
                duration: const Duration(milliseconds: 160),
                curve: AppMotion.spring,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: AppMotion.spring,
                      transform: Matrix4.translationValues(
                        0,
                        widget.active ? -2.0 : (_hovered ? -2.0 : 0.0),
                        0,
                      ),
                      child: AnimatedScale(
                        scale: widget.active ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 240),
                        curve: AppMotion.spring,
                        child: Icon(
                          widget.active ? widget.activeIcon : widget.icon,
                          size: 21,
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
                          fontSize: 10.5,
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
      ),
    );
  }
}
