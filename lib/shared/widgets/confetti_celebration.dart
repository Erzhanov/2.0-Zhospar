import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_surface.dart';
import '../../shared/widgets/tap_scale.dart';
import '../../state/gamification_provider.dart';

class ConfettiCelebrationOverlay extends StatefulWidget {
  final CelebrationEvent event;
  final VoidCallback onDismiss;

  const ConfettiCelebrationOverlay({
    super.key,
    required this.event,
    required this.onDismiss,
  });

  @override
  State<ConfettiCelebrationOverlay> createState() =>
      _ConfettiCelebrationOverlayState();
}

class _ConfettiCelebrationOverlayState extends State<ConfettiCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _particles = List.generate(45, (_) => _Particle.random(_random));
    _controller.forward();

    // Auto dismiss after animation completes
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: GestureDetector(
          onTap: widget.onDismiss,
          behavior: HitTestBehavior.translucent,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // Confetti canvas
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: _ConfettiPainter(
                      progress: _controller.value,
                      particles: _particles,
                    ),
                  );
                },
              ),

              // Floating celebration banner
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: TapScale(
                          onTap: widget.onDismiss,
                          borderRadius: BorderRadius.circular(28),
                          child: GlassSurface(
                            borderRadius: 28,
                            elevation: 1.4,
                            glowColor: AppColors.warning,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.event.emoji,
                                  style: const TextStyle(fontSize: 32),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.event.title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.event.subtitle,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.warning.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Text(
                                    '+${widget.event.xpEarned} XP',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.warning,
                                    ),
                                  ),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _Particle {
  final double x;
  final double speed;
  final double angle;
  final double size;
  final Color color;
  final double rotationSpeed;

  _Particle({
    required this.x,
    required this.speed,
    required this.angle,
    required this.size,
    required this.color,
    required this.rotationSpeed,
  });

  factory _Particle.random(math.Random rand) {
    const palette = [
      Color(0xFF007AFF),
      Color(0xFF5856D6),
      Color(0xFFFF9500),
      Color(0xFF34C759),
      Color(0xFFFF2D55),
      Color(0xFF30D158),
      Color(0xFFFFD60A),
    ];
    return _Particle(
      x: rand.nextDouble(),
      speed: 350 + rand.nextDouble() * 450,
      angle: (rand.nextDouble() - 0.5) * 1.2,
      size: 5 + rand.nextDouble() * 7,
      color: palette[rand.nextInt(palette.length)],
      rotationSpeed: (rand.nextDouble() - 0.5) * 12,
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;

  _ConfettiPainter({
    required this.progress,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final y = progress * p.speed;
      final x = (p.x * size.width) + math.sin(progress * 4 + p.angle) * 45;

      if (y > size.height + 20) continue;

      paint.color = p.color.withValues(alpha: opacity * 0.9);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * p.rotationSpeed);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 1.6,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
