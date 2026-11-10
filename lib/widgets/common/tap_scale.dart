import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Press-scale micro-interaction wrapper enforcing optional minimum touch target.
class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final double minWidth;
  final double minHeight;
  final bool haptic;
  final String? semanticLabel;
  final BorderRadius? borderRadius;

  const TapScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.95,
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

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: enabled,
      enabled: enabled,
      label: widget.semanticLabel,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: widget.minWidth,
          minHeight: widget.minHeight,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(14),
          child: InkWell(
            onTap: enabled
                ? () {
                    if (widget.haptic) {
                      HapticFeedback.lightImpact();
                    }
                    widget.onTap?.call();
                  }
                : null,
            onHighlightChanged: enabled ? _setPressed : null,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(14),
            child: AnimatedScale(
              scale: _pressed ? widget.pressedScale : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutCubic,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
