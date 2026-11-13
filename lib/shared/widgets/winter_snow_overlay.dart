import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snow_fall_animation/snow_fall_animation.dart';
import '../../state/winter_theme_provider.dart';
import 'floating_motion.dart';

/// Clean, lightweight Winter Snowfall overlay powered by the pub.dev package `snow_fall_animation`.
///
/// Features:
/// - Gentle, subtle, semi-transparent falling snow at 60 FPS.
/// - Wrapped in a [Stack] with [IgnorePointer] so that no user clicks, scrolls,
///   or taps on the underlying UI are ever blocked.
/// - Zero complex accumulation, touch-erasing, or accelerometer tilt physics.
/// - Completely unmounts/disposes the animation when disabled in Settings.
class WinterSnowOverlay extends StatelessWidget {
  final Widget child;

  const WinterSnowOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final winter = Provider.of<WinterThemeProvider>(context);

    // When disabled in Settings, completely remove/dispose the snowfall widget
    if (!winter.isWinterEnabled) {
      return child;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Underlying application UI (fully accessible, 100% interactive)
        child,

        // 2. Lightweight, subtle, non-blocking 60 FPS snowfall overlay
        if (AppMotion.enableContinuousDrift)
          const Positioned.fill(
            child: IgnorePointer(
              ignoring: true, // Never intercepts or blocks user taps/scrolls
              child: SnowFallAnimation(
                config: SnowfallConfig(
                  numberOfSnowflakes: 65,
                  speed: 0.65,
                  useEmoji: false,
                  holdSnowAtBottom: false, // Clean snowfall without accumulation
                  minSnowflakeSize: 1.5,
                  maxSnowflakeSize: 4.0,
                  snowColor: Color(0xB3FFFFFF), // Subtle semi-transparent white (70% opacity)
                  minOpacity: 0.25,
                  maxOpacity: 0.75,
                  swingRange: 0.5,
                  rotationSpeed: 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
