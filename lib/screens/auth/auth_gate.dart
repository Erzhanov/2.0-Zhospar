import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../app_shell.dart';
import 'auth_screen.dart';

/// Root authentication gate.
///
/// Renders [AuthScreen] as the default initial view for unauthenticated users
/// and switches to [AppShell] (main dashboard/home) only after authentication.
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
      duration: const Duration(milliseconds: 260),
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
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}
