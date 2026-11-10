import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Atmospheric Zero-G backdrop providing soft radial ambient lighting orbs
/// behind translucent glass surfaces without heavy full-screen shaders.
class AmbientSpaceBackground extends StatelessWidget {
  final Widget child;

  const AmbientSpaceBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Base atmospheric gradient
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [
                      AppColors.darkBackground,
                      AppColors.darkBackgroundSecondary,
                      Color(0xFF080D1B),
                    ]
                  : const [
                      AppColors.lightBackground,
                      AppColors.lightBackgroundSecondary,
                      Color(0xFFF3F0FF),
                    ],
            ),
          ),
        ),

        // Top-left teal/aqua ambient light orb
        Positioned(
          top: -90,
          left: -70,
          child: IgnorePointer(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.glowTeal.withValues(alpha: isDark ? 0.16 : 0.18),
                    AppColors.glowTeal.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Mid-right indigo nebula/prism orb
        Positioned(
          top: 180,
          right: -100,
          child: IgnorePointer(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.glowIndigo.withValues(
                      alpha: isDark ? 0.14 : 0.13,
                    ),
                    AppColors.glowIndigo.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Bottom-left warm prism accent
        Positioned(
          bottom: -80,
          left: -40,
          child: IgnorePointer(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.glowAmber.withValues(
                      alpha: isDark ? 0.08 : 0.11,
                    ),
                    AppColors.glowAmber.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),

        child,
      ],
    );
  }
}
