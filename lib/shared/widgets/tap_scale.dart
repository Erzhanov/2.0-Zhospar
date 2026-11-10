import 'package:flutter/material.dart';
import '../../core/platform/platform_adaptive.dart';
import 'floating_motion.dart';

/// Tactile Anti-Gravity interaction wrapper with spring compression on press
/// (`scale: 0.97`) and gentle levitation lift on pointer hover (`-4px`).
class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final double hoverLiftY;
  final double minWidth;
  final double minHeight;
  final bool haptic;
  final String? semanticLabel;
  final BorderRadius? borderRadius;

  const TapScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.97,
    this.hoverLiftY = -4.0,
    this.minWidth = 44,
    this.minHeight = 44,
    this.haptic = true,
    this.semanticLabel,
    this.borderRadius,
  });

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _pressed = false;
  bool _hovered = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final targetScale = _pressed ? widget.pressedScale : 1.0;
    final targetY = (!enabled || _pressed || !_hovered) ? 0.0 : widget.hoverLiftY;

    return Semantics(
      button: enabled,
      enabled: enabled,
      label: widget.semanticLabel,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: widget.minWidth,
          minHeight: widget.minHeight,
        ),
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
          onEnter: enabled ? (_) => _setHovered(true) : null,
          onExit: enabled ? (_) => _setHovered(false) : null,
          child: Material(
            color: Colors.transparent,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(20),
            child: InkWell(
              onTap: enabled
                  ? () {
                      if (widget.haptic) {
                        PlatformAdaptive.hapticLight();
                      }
                      widget.onTap?.call();
                    }
                  : null,
              onHighlightChanged: enabled ? _setPressed : null,
              borderRadius: widget.borderRadius ?? BorderRadius.circular(20),
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: AppMotion.spring,
                transform: Matrix4.translationValues(0, targetY, 0),
                child: AnimatedScale(
                  scale: targetScale,
                  duration: const Duration(milliseconds: 180),
                  curve: AppMotion.spring,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
