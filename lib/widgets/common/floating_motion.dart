import 'package:flutter/material.dart';

/// Shared Anti-Gravity spring & physics curves.
class AppMotion {
  /// Elastic overshoot spring matching `cubic-bezier(0.34, 1.56, 0.64, 1)`.
  static const Curve spring = Cubic(0.34, 1.56, 0.64, 1.0);
  static const Curve smooth = Curves.easeOutCubic;

  /// Allows deterministic widget tests to opt out of infinite levitation loops
  /// when calling `pumpAndSettle()` while preserving normal runtime float motion.
  static bool enableContinuousDrift = true;
}

/// Subtle Zero-G vertical levitation animation for primary floating elements.
class FloatingDrift extends StatefulWidget {
  final Widget child;
  final double amplitude;
  final Duration duration;

  const FloatingDrift({
    super.key,
    required this.child,
    this.amplitude = 4.0,
    this.duration = const Duration(milliseconds: 3000),
  });

  @override
  State<FloatingDrift> createState() => _FloatingDriftState();
}

class _FloatingDriftState extends State<FloatingDrift>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    if (AppMotion.enableContinuousDrift) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!AppMotion.enableContinuousDrift || disableAnimations) {
      if (_controller.isAnimating) _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AppMotion.enableContinuousDrift) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOutSine.transform(_controller.value);
        final dy = (t * 2 - 1) * widget.amplitude;
        return Transform.translate(
          offset: Offset(0, dy),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Buoyant spring entrance for cards, tiles, and dialogs.
class SpringPopIn extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final double beginOffsetY;

  const SpringPopIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 380),
    this.beginOffsetY = 14,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: AppMotion.spring,
      builder: (context, value, child) {
        final clampedOpacity = value.clamp(0.0, 1.0);
        return Opacity(
          opacity: clampedOpacity,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * beginOffsetY),
            child: Transform.scale(
              scale: 0.96 + (0.04 * value),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}
