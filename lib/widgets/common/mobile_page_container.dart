import 'package:flutter/material.dart';

/// Centers page content within a readable mobile-first max width while
/// preserving full-bleed mobile padding and bottom clearance.
class MobilePageContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final double bottomClearance;

  const MobilePageContainer({
    super.key,
    required this.child,
    this.maxWidth = 640,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.bottomClearance = 88,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding.add(EdgeInsets.only(bottom: bottomClearance)),
          child: child,
        ),
      ),
    );
  }
}
