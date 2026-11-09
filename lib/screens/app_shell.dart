import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/i18n/language_provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'week_plan/week_plan_screen.dart';
import 'analytics/analytics_screen.dart';
import 'ai_assistant/ai_assistant_screen.dart';
import 'timer/timer_screen.dart';
import 'weekly_review/weekly_review_screen.dart';
import 'archive/archive_screen.dart';
import 'settings/settings_screen.dart';
import 'admin/admin_screen.dart';
import '../widgets/floating_music_player.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    if (index == 4) {
      _showMoreBottomSheet();
    } else {
      setState(() => _currentIndex = index);
    }
  }

  void _showMoreBottomSheet() {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  lang.t('nav.menu'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Grid of More Items
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  children: [
                    _moreGridItem(
                      icon: Icons.timer_outlined,
                      label: lang.t('nav.timer'),
                      color: AppColors.teal,
                      onTap: () {
                        Navigator.pop(ctx);
                        _openScreen(const TimerScreen());
                      },
                      isDark: isDark,
                    ),
                    _moreGridItem(
                      icon: Icons.rate_review_outlined,
                      label: lang.t('nav.review'),
                      color: AppColors.purple,
                      onTap: () {
                        Navigator.pop(ctx);
                        _openScreen(const WeeklyReviewScreen());
                      },
                      isDark: isDark,
                    ),
                    _moreGridItem(
                      icon: Icons.archive_outlined,
                      label: lang.t('nav.archive'),
                      color: AppColors.warning,
                      onTap: () {
                        Navigator.pop(ctx);
                        _openScreen(const ArchiveScreen());
                      },
                      isDark: isDark,
                    ),
                    _moreGridItem(
                      icon: Icons.settings_outlined,
                      label: lang.t('nav.settings'),
                      color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                      onTap: () {
                        Navigator.pop(ctx);
                        _openScreen(const SettingsScreen());
                      },
                      isDark: isDark,
                    ),
                    if (auth.isAdmin)
                      _moreGridItem(
                        icon: Icons.shield_outlined,
                        label: lang.t('nav.admin'),
                        color: AppColors.destructive,
                        onTap: () {
                          Navigator.pop(ctx);
                          _openScreen(const AdminScreen());
                        },
                        isDark: isDark,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openScreen(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;

    final pages = [
      DashboardScreen(onNavigateTab: (idx) => setState(() => _currentIndex = idx)),
      const WeekPlanScreen(),
      const AnalyticsScreen(),
      const AIAssistantScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'ZHOSPAR',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
            ),
            onPressed: () => theme.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: () => _openScreen(const SettingsScreen()),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Row(
            children: [
              // Desktop Sidebar if wide screen
              if (isDesktop)
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _onTabTapped,
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                  selectedIconTheme: IconThemeData(
                    color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                  ),
                  unselectedIconTheme: IconThemeData(
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.dashboard_outlined),
                      selectedIcon: const Icon(Icons.dashboard_rounded),
                      label: Text(lang.t('nav.home')),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.calendar_month_outlined),
                      selectedIcon: const Icon(Icons.calendar_month_rounded),
                      label: Text(lang.t('nav.week')),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.bar_chart_rounded),
                      selectedIcon: const Icon(Icons.bar_chart_rounded),
                      label: Text(lang.t('nav.analytics')),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.auto_awesome_outlined),
                      selectedIcon: const Icon(Icons.auto_awesome),
                      label: Text(lang.t('nav.assistant')),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.more_horiz_rounded),
                      selectedIcon: const Icon(Icons.more_horiz_rounded),
                      label: Text(lang.t('nav.more')),
                    ),
                  ],
                ),

              // Main Page Body
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: pages,
                ),
              ),
            ],
          ),

          // Floating Ambient Audio Player Pill
          const FloatingMusicPlayer(),
        ],
      ),

      // Bottom Navigation Bar (for Mobile)
      bottomNavigationBar: isDesktop
          ? null
          : Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: _onTabTapped,
                type: BottomNavigationBarType.fixed,
                backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                selectedItemColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                unselectedItemColor: isDark ? Colors.white54 : Colors.black45,
                selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                elevation: 0,
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.dashboard_outlined),
                    activeIcon: const Icon(Icons.dashboard_rounded),
                    label: lang.t('nav.home'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.calendar_month_outlined),
                    activeIcon: const Icon(Icons.calendar_month_rounded),
                    label: lang.t('nav.week'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.bar_chart_rounded),
                    activeIcon: const Icon(Icons.bar_chart_rounded),
                    label: lang.t('nav.analytics'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.auto_awesome_outlined),
                    activeIcon: const Icon(Icons.auto_awesome),
                    label: lang.t('nav.assistant'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.more_horiz_rounded),
                    label: lang.t('nav.more'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _moreGridItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
