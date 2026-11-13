import 'package:flutter/material.dart';

/// Clean, lightweight, slightly tilted Santa Claus hat icon
/// positioned on the top-left corner of the first letter in the greeting text.
class SantaHat extends StatelessWidget {
  final double size;

  const SantaHat({
    super.key,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.15, // Slightly tilted festive angle
      alignment: const Alignment(-0.5, 0.8),
      child: CustomPaint(
        size: Size(size * 1.25, size),
        painter: _SantaHatPainter(),
      ),
    );
  }
}

class _SantaHatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Red cone cap
    final capRect = Rect.fromLTWH(0, 0, w, h);
    final capGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFF3B30),
        Color(0xFFE53935),
        Color(0xFFC62828),
      ],
    ).createShader(capRect);

    final capPaint = Paint()
      ..shader = capGradient
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final capPath = Path();
    capPath.moveTo(w * 0.14, h * 0.72);
    // Smooth curve up to the bent tip
    capPath.quadraticBezierTo(w * 0.32, h * 0.16, w * 0.74, h * 0.14);
    // Bent tip curving down to the right
    capPath.quadraticBezierTo(w * 0.98, h * 0.22, w * 0.92, h * 0.46);
    capPath.quadraticBezierTo(w * 0.80, h * 0.34, w * 0.66, h * 0.36);
    // Downwards to right brim
    capPath.quadraticBezierTo(w * 0.74, h * 0.58, w * 0.86, h * 0.72);
    capPath.close();

    // Subtle drop shadow beneath cap
    final capShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    canvas.drawPath(capPath.shift(const Offset(0, 1.2)), capShadow);
    canvas.drawPath(capPath, capPaint);

    // 2. White fluffy brim
    final brimCenter = Offset(w * 0.50, h * 0.76);
    final brimRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: brimCenter,
        width: w * 0.82,
        height: h * 0.28,
      ),
      Radius.circular(h * 0.14),
    );

    final brimShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    canvas.drawRRect(brimRRect.shift(const Offset(0, 1.0)), brimShadow);

    final brimPaint = Paint()
      ..color = Colors.white
      ..isAntiAlias = true;
    canvas.drawRRect(brimRRect, brimPaint);

    // Fluffy cotton circles along the brim
    final fluffPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.fill;
    final fluffOffsets = [
      Offset(w * 0.18, h * 0.76),
      Offset(w * 0.34, h * 0.75),
      Offset(w * 0.50, h * 0.76),
      Offset(w * 0.66, h * 0.75),
      Offset(w * 0.82, h * 0.76),
    ];
    for (final pt in fluffOffsets) {
      canvas.drawCircle(pt, h * 0.11, fluffPaint);
    }

    // 3. Fluffy white pom-pom ball at the tip
    final pomCenter = Offset(w * 0.93, h * 0.48);
    final pomRadius = h * 0.19;

    canvas.drawCircle(pomCenter.translate(0, 1.0), pomRadius, brimShadow);
    canvas.drawCircle(pomCenter, pomRadius, brimPaint);
    canvas.drawCircle(
      pomCenter.translate(-1, -1),
      pomRadius * 0.45,
      Paint()..color = const Color(0xFFF8FAFC),
    );
  }

  @override
  bool shouldRepaint(covariant _SantaHatPainter oldDelegate) => false;
}
