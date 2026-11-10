import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Displays the official ZHOSPAR app icon inside a crisp rounded frame.
class BrandLogo extends StatelessWidget {
  final double size;
  final double borderRadius;
  final bool showShadow;

  const BrandLogo({
    super.key,
    this.size = 40,
    this.borderRadius = 12,
    this.showShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: border, width: 1),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: primary.withValues(alpha: 0.16),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(size * 0.025),
        child: Image.asset(
          'assets/app-icon.png',
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Icon(
            Icons.calendar_month_rounded,
            color: primary,
            size: size * 0.54,
          ),
        ),
      ),
    );
  }
}
