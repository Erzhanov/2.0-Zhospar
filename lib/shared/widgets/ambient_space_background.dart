import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Atmospheric Zero-G backdrop matching the classic ZHOSPAR iOS palette.
/// Wrapped in [RepaintBoundary] so the gradient and ambient halos rasterize
/// once into a static GPU layer without repainting during foreground scroll.
class AmbientSpaceBackground extends StatelessWidget {
  final Widget child;

  const AmbientSpaceBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: IgnorePointer(
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? const [
                              AppColors.darkBackground,
                              AppColors.darkBackgroundSecondary,
                              Color(0xFF060810),
                            ]
                          : const [
                              AppColors.lightBackground,
                              AppColors.lightBackgroundSecondary,
                              Color(0xFFF5F6FA),
                            ],
                    ),
                  ),
                ),

                // Top-left systemBlue ambient glow
                Positioned(
                  top: -90,
                  left: -70,
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          (isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.lightPrimary)
                              .withValues(alpha: isDark ? 0.14 : 0.12),
                          (isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.lightPrimary)
                              .withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),

                // Mid-right systemIndigo subtle accent
                Positioned(
                  top: 190,
                  right: -100,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.indigo
                              .withValues(alpha: isDark ? 0.12 : 0.08),
                          AppColors.indigo.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom-right systemTeal soft halo
                Positioned(
                  bottom: -100,
                  right: -60,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.teal
                              .withValues(alpha: isDark ? 0.10 : 0.08),
                          AppColors.teal.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}
