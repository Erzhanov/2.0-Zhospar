import 'package:flutter/material.dart';
import 'glass_surface.dart';

/// Weightless floating glass card used across all ZHOSPAR screens.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;
  final Color? glowColor;
  final bool elevated;
  final bool enableBlur;
  final Gradient? gradient;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.borderRadius = 22,
    this.borderColor,
    this.backgroundColor,
    this.glowColor,
    this.elevated = true,
    this.enableBlur = false,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      margin: margin,
      padding: padding,
      borderRadius: borderRadius,
      borderColor: borderColor,
      tintColor: backgroundColor,
      glowColor: glowColor,
      elevation: elevated ? 1.0 : 0.0,
      enableBlur: enableBlur,
      gradient: gradient,
      child: child,
    );
  }
}
