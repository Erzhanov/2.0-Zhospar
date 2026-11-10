import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Frosted glassmorphic surface with luminous rim border and diffuse floating shadows.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;
  final bool enableBlur;
  final Color? tintColor;
  final Color? borderColor;
  final Color? glowColor;
  final double elevation;
  final Gradient? gradient;

  const GlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 22,
    this.blurSigma = 18,
    this.enableBlur = false,
    this.tintColor,
    this.borderColor,
    this.glowColor,
    this.elevation = 1.0,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultTint = isDark ? AppColors.darkCard : AppColors.lightCard;
    final rim = borderColor ?? AppColors.rimBorder(isDark);
    final radius = BorderRadius.circular(borderRadius);

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (tintColor ?? defaultTint) : null,
        gradient: gradient,
        borderRadius: radius,
        border: Border.all(color: rim, width: isDark ? 1.0 : 1.2),
      ),
      child: child,
    );

    if (enableBlur) {
      content = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: content,
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: elevation > 0
            ? AppColors.floatingShadows(
                isDark: isDark,
                glowColor: glowColor,
                elevation: elevation,
              )
            : null,
      ),
      child: content,
    );
  }
}
