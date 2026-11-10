import 'package:flutter/material.dart';

/// Centers page content within a readable mobile-first max width while
/// respecting top glass AppBar and bottom floating nav clearances.
class MobilePageContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;
  final double bottomClearance;

  const MobilePageContainer({
    super.key,
    required this.child,
    this.maxWidth = 640,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.bottomClearance = 32,
  });

  @override
  Widget build(BuildContext context) {
    final mediaPadding = MediaQuery.paddingOf(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            padding.left,
            padding.top + mediaPadding.top,
            padding.right,
            padding.bottom + mediaPadding.bottom + bottomClearance,
          ),
          child: child,
        ),
      ),
    );
  }
}
