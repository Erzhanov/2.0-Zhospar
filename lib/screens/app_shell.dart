import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/i18n/language_provider.dart';
import '../core/routing/app_routes.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/common/ambient_space_background.dart';
import '../widgets/common/floating_motion.dart';
import '../widgets/common/tap_scale.dart';
import '../widgets/floating_music_player.dart';
import '../widgets/navigation/animated_bottom_nav_bar.dart';
import '../widgets/navigation/desktop_sidebar.dart';
import '../widgets/navigation/mobile_more_sheet.dart';
import '../widgets/navigation/top_app_bar.dart';
import 'ai_assistant/ai_assistant_screen.dart';
import 'analytics/analytics_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'week_plan/week_plan_screen.dart';

class AppShell extends StatefulWidget {
  final int initialIndex;

  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;
  bool _moreOpen = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(
      0,
      AppNavConfig.primaryItems.length - 1,
    );
  }

  void _selectTab(int index) {
    if (index < 0 || index >= AppNavConfig.primaryItems.length) return;
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  Future<void> _openMoreSheet() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final items = AppNavConfig.visibleSecondaryItems(isAdmin: auth.isAdmin);

    setState(() => _moreOpen = true);
    await MobileMoreSheet.show(
      context,
      items: items,
      lang: lang,
      onSelectItem: _openSubPage,
      onSignOut: _signOut,
    );
    if (mounted) {
      setState(() => _moreOpen = false);
    }
  }

  void _openSubPage(AppNavItem item) {
    Navigator.of(context).pushNamed(item.route);
  }

  Future<void> _signOut() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.root,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final isWide = MediaQuery.sizeOf(context).width >= 840;

    final primaryItems = AppNavConfig.primaryItems;
    final secondaryItems =
        AppNavConfig.visibleSecondaryItems(isAdmin: auth.isAdmin);

    final pages = [
      DashboardScreen(onNavigateTab: _selectTab),
      const WeekPlanScreen(),
      const AnalyticsScreen(),
      const AIAssistantScreen(),
    ];

    final headerTitle =
        _currentIndex == 0 ? 'ZHOSPAR' : lang.t(primaryItems[_currentIndex].labelKey);
    final headerSubtitle = _currentIndex == 0 ? lang.t('nav.appName') : null;
    final showAddTaskFab = _currentIndex == 0 || _currentIndex == 1;

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentIndex != 0) {
          _selectTab(0);
        }
      },
      child: AmbientSpaceBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          extendBody: true,
          appBar: TopAppBar(
            title: headerTitle,
            subtitle: headerSubtitle,
            isSubPage: false,
            onOpenSettings: () =>
                Navigator.of(context).pushNamed(AppRoutes.settings),
          ),
          body: Stack(
            children: [
              Row(
                children: [
                  if (isWide)
                    DesktopSidebar(
                      currentIndex: _currentIndex,
                      primaryItems: primaryItems,
                      secondaryItems: secondaryItems,
                      lang: lang,
                      onTabSelected: _selectTab,
                      onSubPageSelected: _openSubPage,
                      onSignOut: _signOut,
                    ),
                  Expanded(
                    child: IndexedStack(
                      index: _currentIndex,
                      children: pages,
                    ),
                  ),
                ],
              ),
              FloatingMusicPlayer(
                bottomOffset: showAddTaskFab ? 82 : 16,
              ),
            ],
          ),
          floatingActionButton: showAddTaskFab
              ? FloatingDrift(
                  amplitude: 4.0,
                  child: TapScale(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      showDialog(
                        context: context,
                        builder: (_) =>
                            AddTaskDialog(defaultDay: taskProvider.selectedDay),
                      );
                    },
                    minWidth: 58,
                    minHeight: 58,
                    semanticLabel: lang.t('common.addTask'),
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [AppColors.darkPrimary, AppColors.glowTeal]
                              : [AppColors.lightPrimary, const Color(0xFF14B8A6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.42),
                            blurRadius: 22,
                            spreadRadius: -2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                )
              : null,
          bottomNavigationBar: isWide
              ? null
              : AnimatedBottomNavBar(
                  currentIndex: _currentIndex,
                  primaryItems: primaryItems,
                  lang: lang,
                  isMoreHighlighted: _moreOpen,
                  onTabSelected: _selectTab,
                  onMoreTapped: _openMoreSheet,
                ),
        ),
      ),
    );
  }
}
