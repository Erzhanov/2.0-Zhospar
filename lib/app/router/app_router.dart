import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/platform/platform_adaptive.dart';
import '../../features/admin/admin_screen.dart';
import '../../features/archive/archive_screen.dart';
import '../../features/auth/auth_gate.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/landing/landing_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/timer/timer_screen.dart';
import '../../features/weekly_review/weekly_review_screen.dart';
import '../../shared/widgets/ambient_space_background.dart';
import '../../shared/widgets/floating_motion.dart';
import '../../state/auth_provider.dart';
import 'app_routes.dart';

/// Platform-adaptive route generator:
/// - Interactive Cupertino swipe-back route transitions on iOS & macOS
/// - Smooth spring slide+fade transitions on Android & Web
class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name ?? AppRoutes.root;

    switch (routeName) {
      case AppRoutes.root:
      case AppRoutes.auth:
        return _fadeRoute(const AuthGate(), settings);

      case AppRoutes.welcome:
        return _adaptiveSubRoute(const LandingScreen(), settings);

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
        return _adaptiveSubRoute(
          const _ProtectedRoute(child: TimerScreen()),
          settings,
        );

      case AppRoutes.weeklyReview:
        return _adaptiveSubRoute(
          const _ProtectedRoute(child: WeeklyReviewScreen()),
          settings,
        );

      case AppRoutes.archive:
        return _adaptiveSubRoute(
          const _ProtectedRoute(child: ArchiveScreen()),
          settings,
        );

      case AppRoutes.settings:
        return _adaptiveSubRoute(
          const _ProtectedRoute(child: SettingsScreen()),
          settings,
        );

      case AppRoutes.admin:
        return _adaptiveSubRoute(
          const _ProtectedRoute(child: AdminScreen()),
          settings,
        );

      default:
        return _fadeRoute(const AuthGate(), settings);
    }
  }

  static Route<T> _adaptiveSubRoute<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (context, anim, secondaryAnim) => page,
      transitionsBuilder: (context, anim, secondaryAnim, child) {
        if (PlatformAdaptive.isApple(context)) {
          return CupertinoPageTransition(
            primaryRouteAnimation: anim,
            secondaryRouteAnimation: secondaryAnim,
            linearTransition: false,
            child: child,
          );
        }
        final curved = CurvedAnimation(
          parent: anim,
          curve: AppMotion.spring,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
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
}

class _ProtectedRoute extends StatelessWidget {
  final Widget child;

  const _ProtectedRoute({required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (auth.initializing) {
      return const AmbientSpaceBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: AdaptiveLoadingIndicator(radius: 14)),
        ),
      );
    }
    if (!auth.isAuthenticated) {
      return const AuthScreen();
    }
    return child;
  }
}
