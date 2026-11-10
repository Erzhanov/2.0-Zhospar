import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/admin/admin_screen.dart';
import '../../screens/archive/archive_screen.dart';
import '../../screens/auth/auth_gate.dart';
import '../../screens/auth/auth_screen.dart';
import '../../screens/landing/landing_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/timer/timer_screen.dart';
import '../../screens/weekly_review/weekly_review_screen.dart';
import 'app_routes.dart';

/// Centralized route generator with auth guarding and smooth transitions.
class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name ?? AppRoutes.root;

    switch (routeName) {
      case AppRoutes.root:
        return _fadeRoute(const AuthGate(), settings);

      case AppRoutes.auth:
        return _fadeRoute(const AuthGate(), settings);

      case AppRoutes.welcome:
        return _slideFadeRoute(const LandingScreen(), settings);

      case AppRoutes.home:
      case AppRoutes.week:
      case AppRoutes.analytics:
      case AppRoutes.assistant:
        return _fadeRoute(
          _ProtectedRoute(
            child: AuthGate(
              initialTabIndex: AppRoutes.tabIndexForRoute(routeName),
            ),
          ),
          settings,
        );

      case AppRoutes.timer:
        return _slideFadeRoute(
          const _ProtectedRoute(child: TimerScreen()),
          settings,
        );

      case AppRoutes.weeklyReview:
        return _slideFadeRoute(
          const _ProtectedRoute(child: WeeklyReviewScreen()),
          settings,
        );

      case AppRoutes.archive:
        return _slideFadeRoute(
          const _ProtectedRoute(child: ArchiveScreen()),
          settings,
        );

      case AppRoutes.settings:
        return _slideFadeRoute(
          const _ProtectedRoute(child: SettingsScreen()),
          settings,
        );

      case AppRoutes.admin:
        return _slideFadeRoute(
          const _ProtectedRoute(child: AdminScreen()),
          settings,
        );

      default:
        return _fadeRoute(const AuthGate(), settings);
    }
  }

  static PageRoute<T> _fadeRoute<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, anim, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
        child: child,
      ),
    );
  }

  static PageRoute<T> _slideFadeRoute<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, anim, _, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.06, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

class _ProtectedRoute extends StatelessWidget {
  final Widget child;

  const _ProtectedRoute({required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (auth.initializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }
    if (!auth.isAuthenticated) {
      return const AuthScreen();
    }
    return child;
  }
}
