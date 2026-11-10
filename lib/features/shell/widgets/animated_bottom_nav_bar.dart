import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/i18n/language_provider.dart';
import '../../../core/platform/platform_adaptive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/floating_motion.dart';

/// Floating Liquid Glass capsule navigation bar for phones & compact viewports.
/// Features a refractive morphing droplet indicator with velocity stretch-and-squash,
/// caustic light refraction, and interactive horizontal finger-scrubbing.
class AnimatedBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final List<AppNavItem> primaryItems;
  final bool hasMoreItem;
  final bool isMoreHighlighted;
  final bool showMoreBadge;
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
    this.showMoreBadge = false,
    this.onMoreTapped,
  });

  @override
  State<AnimatedBottomNavBar> createState() => _AnimatedBottomNavBarState();
}

class _AnimatedBottomNavBarState extends State<AnimatedBottomNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _springAnim;

  double _fromSlot = 0;
  double _toSlot = 0;
  double? _dragSlot;
  bool _isDragging = false;
  int _lastHapticSlot = -1;

  int _targetSlotFor(AnimatedBottomNavBar w) {
    final totalCount = w.primaryItems.length + (w.hasMoreItem ? 1 : 0);
    return (w.isMoreHighlighted && w.hasMoreItem)
        ? w.primaryItems.length
        : w.currentIndex.clamp(0, totalCount - 1);
  }

  double get _visualSlot {
    if (_dragSlot != null) return _dragSlot!;
    return lerpDouble(_fromSlot, _toSlot, _springAnim.value) ?? _toSlot;
  }

  @override
  void initState() {
    super.initState();
    final initial = _targetSlotFor(widget).toDouble();
    _fromSlot = initial;
    _toSlot = initial;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _springAnim = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.spring,
    );
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant AnimatedBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextTarget = _targetSlotFor(widget).toDouble();
    if (!_isDragging && nextTarget != _toSlot) {
      _fromSlot = _visualSlot;
      _toSlot = nextTarget;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details, double slotWidth, int total) {
    PlatformAdaptive.hapticLight();
    final slot = ((details.localPosition.dx / slotWidth) - 0.5)
        .clamp(0.0, total - 1.0);
    setState(() {
      _isDragging = true;
      _dragSlot = slot;
      _lastHapticSlot = slot.round();
    });
  }

  void _handleDragUpdate(
    DragUpdateDetails details,
    double slotWidth,
    int total,
  ) {
    final slot = ((details.localPosition.dx / slotWidth) - 0.5)
        .clamp(0.0, total - 1.0);
    final rounded = slot.round();
    if (rounded != _lastHapticSlot) {
      _lastHapticSlot = rounded;
      PlatformAdaptive.hapticSelection();
    }
    setState(() => _dragSlot = slot);
  }

  void _handleDragEnd(int total) {
    final snapped = (_dragSlot ?? _visualSlot).round().clamp(0, total - 1);
    final from = _dragSlot ?? _visualSlot;
    setState(() {
      _isDragging = false;
      _dragSlot = null;
      _fromSlot = from;
      _toSlot = snapped.toDouble();
    });
    _controller.forward(from: 0.0);

    if (snapped < widget.primaryItems.length) {
      widget.onTabSelected(snapped);
    } else if (widget.hasMoreItem) {
      widget.onMoreTapped?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final secondaryAccent = isDark ? AppColors.darkPrimaryBright : AppColors.teal;
    final inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.62)
        : AppColors.lightSecondaryText;

    final totalCount =
        widget.primaryItems.length + (widget.hasMoreItem ? 1 : 0);
    final activeSlot = _targetSlotFor(widget);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: AnimatedScale(
              scale: _isDragging ? 1.02 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: AppMotion.spring,
              child: Container(
                height: 68,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: AppColors.floatingShadows(
                    isDark: isDark,
                    glowColor: primary,
                    elevation: _isDragging ? 1.5 : 1.25,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isDark
                              ? [
                                  const Color(0xDB242428),
                                  const Color(0xCC161618),
                                ]
                              : [
                                  Colors.white.withValues(alpha: 0.90),
                                  Colors.white.withValues(alpha: 0.76),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.16)
                              : Colors.white.withValues(alpha: 0.94),
                          width: 1.2,
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final slotWidth = constraints.maxWidth / totalCount;
                          const inset = 3.0;
                          final basePillWidth = (slotWidth - inset * 2)
                              .clamp(44.0, double.infinity);

                          return GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onHorizontalDragStart: (d) =>
                                _handleDragStart(d, slotWidth, totalCount),
                            onHorizontalDragUpdate: (d) =>
                                _handleDragUpdate(d, slotWidth, totalCount),
                            onHorizontalDragEnd: (_) =>
                                _handleDragEnd(totalCount),
                            onHorizontalDragCancel: () =>
                                _handleDragEnd(totalCount),
                            child: RepaintBoundary(
                              child: AnimatedBuilder(
                                animation: _controller,
                                builder: (context, child) {
                                  final slot = _visualSlot;
                                  final t = _controller.value.clamp(0.0, 1.0);
                                  final midWave = math.sin(math.pi * t);
                                  final travel = (_toSlot - _fromSlot).abs();

                                  final stretchW = _isDragging
                                      ? 10.0
                                      : math.min(
                                            slotWidth * 0.44,
                                            travel * slotWidth * 0.28,
                                          ) *
                                          midWave;
                                  final expandV = _isDragging
                                      ? 2.0
                                      : 1.5 * midWave;

                                  final dropletWidth =
                                      (basePillWidth + stretchW).clamp(
                                    44.0,
                                    constraints.maxWidth - inset * 2,
                                  );
                                  final rawCenter = (slot + 0.5) * slotWidth;
                                  final dropletLeft =
                                      (rawCenter - dropletWidth / 2).clamp(
                                    inset,
                                    constraints.maxWidth -
                                        inset -
                                        dropletWidth,
                                  );
                                  final causticCenterX =
                                      ((dropletLeft + dropletWidth / 2) /
                                              constraints.maxWidth) *
                                          2 -
                                      1;
                                  final crestLeft =
                                      (dropletLeft + dropletWidth / 2 - 11)
                                          .clamp(
                                    inset + 6,
                                    constraints.maxWidth - inset - 28,
                                  );

                                  return Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      // Ambient caustic light refraction gliding inside glass capsule
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              gradient: RadialGradient(
                                                center: Alignment(
                                                  causticCenterX,
                                                  -0.35,
                                                ),
                                                radius: 1.15,
                                                colors: [
                                                  primary.withValues(
                                                    alpha: isDark ? 0.16 : 0.10,
                                                  ),
                                                  secondaryAccent.withValues(
                                                    alpha: isDark ? 0.05 : 0.04,
                                                  ),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Elastic Liquid Glass refractive droplet
                                      Positioned(
                                        left: dropletLeft,
                                        top: (6 - expandV).clamp(2.0, 6.0),
                                        bottom: (6 - expandV).clamp(2.0, 6.0),
                                        width: dropletWidth,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(23),
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: isDark
                                                  ? [
                                                      Colors.white.withValues(
                                                        alpha: _isDragging
                                                            ? 0.24
                                                            : 0.18,
                                                      ),
                                                      primary.withValues(
                                                        alpha: 0.20,
                                                      ),
                                                      Colors.white.withValues(
                                                        alpha: 0.06,
                                                      ),
                                                    ]
                                                  : [
                                                      Colors.white.withValues(
                                                        alpha: 0.94,
                                                      ),
                                                      primary.withValues(
                                                        alpha: _isDragging
                                                            ? 0.18
                                                            : 0.13,
                                                      ),
                                                      secondaryAccent
                                                          .withValues(
                                                        alpha: 0.10,
                                                      ),
                                                    ],
                                            ),
                                            border: Border.all(
                                              color: isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.26,
                                                    )
                                                  : primary.withValues(
                                                      alpha: 0.22,
                                                    ),
                                              width: 1.1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: primary.withValues(
                                                  alpha: isDark
                                                      ? (0.24 +
                                                          0.12 * midWave)
                                                      : (0.14 +
                                                          0.08 * midWave),
                                                ),
                                                blurRadius: 14 + 6 * midWave,
                                                spreadRadius: -2,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Align(
                                            alignment: Alignment.topCenter,
                                            child: Container(
                                              height: 1.5,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 14,
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.white
                                                        .withValues(alpha: 0),
                                                    Colors.white.withValues(
                                                      alpha:
                                                          isDark ? 0.55 : 0.95,
                                                    ),
                                                    Colors.white
                                                        .withValues(alpha: 0),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Luminous meniscus crest following droplet
                                      Positioned(
                                        left: crestLeft,
                                        top: 2,
                                        width: 22 + stretchW * 0.22,
                                        height: 3,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                primary,
                                                secondaryAccent,
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            boxShadow: [
                                              BoxShadow(
                                                color: primary.withValues(
                                                  alpha: 0.65,
                                                ),
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      ?child,
                                    ],
                                  );
                                },
                                child: Row(
                                  children: [
                                    for (int i = 0;
                                        i < widget.primaryItems.length;
                                        i++)
                                      _NavBarSlot(
                                        icon: widget.primaryItems[i].icon,
                                        activeIcon:
                                            widget.primaryItems[i].activeIcon,
                                        label: widget.lang
                                            .t(widget.primaryItems[i].labelKey),
                                        active: !_isDragging
                                            ? (!widget.isMoreHighlighted &&
                                                widget.currentIndex == i)
                                            : (_dragSlot?.round() == i),
                                        activeColor: primary,
                                        inactiveColor: inactiveColor,
                                        onTap: () => widget.onTabSelected(i),
                                      ),
                                    if (widget.hasMoreItem)
                                      _NavBarSlot(
                                        icon: Icons.grid_view_rounded,
                                        activeIcon: Icons.grid_view_rounded,
                                        label: widget.lang.t('nav.more'),
                                        active: !_isDragging
                                            ? activeSlot ==
                                                widget.primaryItems.length
                                            : (_dragSlot?.round() ==
                                                widget.primaryItems.length),
                                        showBadge: widget.showMoreBadge,
                                        activeColor: primary,
                                        inactiveColor: inactiveColor,
                                        onTap: () => widget.onMoreTapped?.call(),
                                      ),
                                  ],
                                ),
                              ),
                            ),
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
      ),
    );
  }
}

class _NavBarSlot extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final bool showBadge;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavBarSlot({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    this.showBadge = false,
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
              PlatformAdaptive.hapticSelection();
              widget.onTap();
            },
            child: SizedBox(
              height: 68,
              child: AnimatedScale(
                scale: _pressed ? 0.91 : 1.0,
                duration: const Duration(milliseconds: 160),
                curve: AppMotion.spring,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: AppMotion.spring,
                      transform: Matrix4.translationValues(
                        0,
                        widget.active ? -2.0 : (_hovered ? -2.0 : 0.0),
                        0,
                      ),
                      child: AnimatedScale(
                        scale: widget.active ? 1.12 : 1.0,
                        duration: const Duration(milliseconds: 260),
                        curve: AppMotion.spring,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              widget.active ? widget.activeIcon : widget.icon,
                              size: 21,
                              color: color,
                            ),
                            if (widget.showBadge)
                              Positioned(
                                right: -3,
                                top: -2,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.success
                                            .withValues(alpha: 0.65),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
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
