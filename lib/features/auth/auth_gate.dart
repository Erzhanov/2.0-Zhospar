import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/platform/platform_adaptive.dart';
import '../../shared/widgets/ambient_space_background.dart';
import '../../shared/widgets/brand_logo.dart';
import '../../shared/widgets/floating_motion.dart';
import '../../state/auth_provider.dart';
import '../shell/app_shell.dart';
import 'auth_screen.dart';

/// Root authentication gate routing unauthenticated users to [AuthScreen]
/// and authenticated users to [AppShell].
class AuthGate extends StatelessWidget {
  final int initialTabIndex;

  const AuthGate({super.key, this.initialTabIndex = 0});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    Widget child;
    if (auth.initializing) {
      child = const _AuthSplash(key: ValueKey('auth-loading'));
    } else if (auth.isAuthenticated) {
      child = AppShell(
        key: const ValueKey('app-shell'),
        initialIndex: initialTabIndex,
      );
    } else {
      child = const AuthScreen(key: ValueKey('auth-screen'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: child,
    );
  }
}

class _AuthSplash extends StatelessWidget {
  const _AuthSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return const AmbientSpaceBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingDrift(
                amplitude: 5,
                child: BrandLogo(size: 80, borderRadius: 24, showShadow: true),
              ),
              SizedBox(height: 22),
              AdaptiveLoadingIndicator(radius: 14),
            ],
          ),
        ),
      ),
    );
  }
}
