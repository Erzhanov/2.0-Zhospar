import 'package:flutter/material.dart';

/// Centralized route constants for ZHOSPAR across iOS, Android, and Web.
class AppRoutes {
  static const String root = '/';
  static const String auth = '/auth';
  static const String welcome = '/welcome';

  // Primary shell tabs
  static const String home = '/app';
  static const String week = '/app/week';
  static const String analytics = '/app/analytics';
  static const String assistant = '/app/assistant';

  // Secondary sub-pages (render sticky TopAppBar with Back button)
  static const String timer = '/app/timer';
  static const String weeklyReview = '/app/weekly-review';
  static const String archive = '/app/archive';
  static const String settings = '/app/settings';
  static const String admin = '/app/admin';

  static const Set<String> primaryTabRoutes = {
    home,
    week,
    assistant,
    settings,
  };

  static const Set<String> subPageRoutes = {
    timer,
    analytics,
    weeklyReview,
    archive,
    admin,
    welcome,
  };

  static bool isProtectedRoute(String? routeName) {
    if (routeName == null) return false;
    return routeName == home || routeName.startsWith('/app/');
  }

  static bool isSubPageRoute(String? routeName) {
    if (routeName == null) return false;
    return subPageRoutes.contains(routeName);
  }

  static int tabIndexForRoute(String? routeName) {
    switch (routeName) {
      case week:
        return 1;
      case assistant:
        return 2;
      case settings:
        return 3;
      case home:
      default:
        return 0;
    }
  }

  static String titleKeyForRoute(String? routeName) {
    switch (routeName) {
      case week:
        return 'nav.week';
      case analytics:
        return 'nav.analytics';
      case assistant:
        return 'nav.assistant';
      case timer:
        return 'timer.title';
      case weeklyReview:
        return 'review.title';
      case archive:
        return 'archive.title';
      case settings:
        return 'settings.title';
      case admin:
        return 'nav.admin';
      case welcome:
        return 'nav.about';
      case home:
      default:
        return 'nav.home';
    }
  }
}

class AppNavItem {
  final String route;
  final String labelKey;
  final IconData icon;
  final IconData activeIcon;
  final Color? accentColor;
  final bool adminOnly;

  const AppNavItem({
    required this.route,
    required this.labelKey,
    required this.icon,
    required this.activeIcon,
    this.accentColor,
    this.adminOnly = false,
  });
}

class AppNavConfig {
  static const List<AppNavItem> primaryItems = [
    AppNavItem(
      route: AppRoutes.home,
      labelKey: 'nav.home',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
    ),
    AppNavItem(
      route: AppRoutes.week,
      labelKey: 'nav.week',
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month_rounded,
    ),
    AppNavItem(
      route: AppRoutes.assistant,
      labelKey: 'nav.assistant',
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome,
    ),
    AppNavItem(
      route: AppRoutes.settings,
      labelKey: 'nav.settings',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
    ),
  ];

  static const List<AppNavItem> secondaryItems = [
    AppNavItem(
      route: AppRoutes.timer,
      labelKey: 'nav.timer',
      icon: Icons.timer_outlined,
      activeIcon: Icons.timer_rounded,
      accentColor: Color(0xFF30B0C7),
    ),
    AppNavItem(
      route: AppRoutes.analytics,
      labelKey: 'nav.analytics',
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      accentColor: Color(0xFF007AFF),
    ),
    AppNavItem(
      route: AppRoutes.weeklyReview,
      labelKey: 'nav.review',
      icon: Icons.rate_review_outlined,
      activeIcon: Icons.rate_review_rounded,
      accentColor: Color(0xFFAF52DE),
    ),
    AppNavItem(
      route: AppRoutes.archive,
      labelKey: 'nav.archive',
      icon: Icons.archive_outlined,
      activeIcon: Icons.archive_rounded,
      accentColor: Color(0xFFFF9500),
    ),
    AppNavItem(
      route: AppRoutes.admin,
      labelKey: 'nav.admin',
      icon: Icons.shield_outlined,
      activeIcon: Icons.shield_rounded,
      accentColor: Color(0xFFFF3B30),
      adminOnly: true,
    ),
  ];

  static List<AppNavItem> visibleSecondaryItems({required bool isAdmin}) {
    return secondaryItems
        .where((item) => !item.adminOnly || isAdmin)
        .toList();
  }
}
