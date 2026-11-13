import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/router/app_routes.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/platform/platform_adaptive.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/ambient_space_background.dart';
import '../../shared/widgets/confetti_celebration.dart';
import '../../shared/widgets/floating_motion.dart';
import '../../shared/widgets/floating_music_player.dart';
import '../../shared/widgets/tap_scale.dart';
import '../../shared/widgets/winter_snow_overlay.dart';
import '../../state/auth_provider.dart';
import '../../state/gamification_provider.dart';
import '../../state/music_provider.dart';
import '../../state/task_provider.dart';
import '../../state/timer_provider.dart';
import '../ai_assistant/ai_assistant_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../dashboard/widgets/task_form_sheet.dart';
import '../settings/settings_screen.dart';
import '../week_plan/week_plan_screen.dart';
import 'widgets/animated_bottom_nav_bar.dart';
import 'widgets/desktop_sidebar.dart';
import 'widgets/mobile_more_sheet.dart';

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
    final taskProvider = Provider.of<TaskProvider>(context);
    final gamification = Provider.of<GamificationProvider>(context);
    final celebration = gamification.currentCelebration;

    taskProvider.onTaskToggled = (task, isNowDone, allDayTasksDone) {
      gamification.onTaskToggled(
        task: task,
        isNowDone: isNowDone,
        allDayTasksDone: allDayTasksDone,
      );
    };
    taskProvider.onReflectionSaved = gamification.onReflectionSaved;

    final hasTimerRunning = context.select<TimerProvider, bool>(
      (t) => t.isRunning,
    );
    final hasMusicPlaying = context.select<MusicProvider, bool>(
      (m) => m.isPlaying,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final showSidebar = !PlatformAdaptive.isCompactPhone(context);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 100;

    final primaryItems = AppNavConfig.primaryItems;
    final secondaryItems =
        AppNavConfig.visibleSecondaryItems(isAdmin: auth.isAdmin);

    final pages = [
      DashboardScreen(
        onNavigateTab: _selectTab,
        onOpenAnalytics: () =>
            Navigator.of(context).pushNamed(AppRoutes.analytics),
      ),
      const WeekPlanScreen(),
      const AIAssistantScreen(),
      const SettingsScreen(embedded: true),
    ];

    final showAddTaskFab = _currentIndex == 0 || _currentIndex == 1;

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentIndex != 0) {
          _selectTab(0);
        }
      },
      child: AmbientSpaceBackground(
        child: WinterSnowOverlay(
          child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: Stack(
            children: [
              Row(
                children: [
                  if (showSidebar)
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
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey<int>(_currentIndex),
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 240),
                      curve: AppMotion.smooth,
                      builder: (context, t, child) => Opacity(
                        opacity: t.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, (1 - t) * 8),
                          child: child,
                        ),
                      ),
                      child: IndexedStack(
                        index: _currentIndex,
                        children: pages,
                      ),
                    ),
                  ),
                ],
              ),
              FloatingMusicPlayer(
                bottomOffset: showAddTaskFab ? 82 : 16,
              ),
              if (taskProvider.isOffline)
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 8,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 14, color: AppColors.warning),
                        const SizedBox(width: 6),
                        Text(
                          lang.t('offline.title'),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (celebration != null)
                ConfettiCelebrationOverlay(
                  event: celebration,
                  onDismiss: gamification.clearCelebration,
                ),
            ],
          ),
          floatingActionButton: (showAddTaskFab && !keyboardOpen)
              ? FloatingDrift(
                  amplitude: 4.0,
                  child: TapScale(
                    onTap: () {
                      PlatformAdaptive.hapticMedium();
                      showTaskFormModal(
                        context,
                        defaultDay: taskProvider.selectedDay,
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
                              ? [AppColors.darkPrimary, AppColors.indigo]
                              : [AppColors.lightPrimary, AppColors.teal],
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
          bottomNavigationBar: (showSidebar || keyboardOpen)
              ? null
              : AnimatedBottomNavBar(
                  currentIndex: _currentIndex,
                  primaryItems: primaryItems,
                  lang: lang,
                  isMoreHighlighted: _moreOpen,
                  showMoreBadge: hasTimerRunning || hasMusicPlaying,
                  onTabSelected: _selectTab,
                  onMoreTapped: _openMoreSheet,
                ),
          ),
        ),
      ),
    );
  }
}
