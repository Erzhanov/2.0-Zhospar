import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/router/app_routes.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/platform/platform_adaptive.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/ambient_space_background.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/brand_logo.dart';
import '../../shared/widgets/floating_motion.dart';
import '../../shared/widgets/mobile_page_container.dart';
import '../../state/auth_provider.dart';
import '../shell/widgets/top_app_bar.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  List<_FeatureInfo> _featuresFor(String locale) {
    switch (locale) {
      case 'ru':
        return const [
          _FeatureInfo(
            icon: Icons.calendar_month_rounded,
            color: AppColors.lightPrimary,
            title: 'Недельный планировщик',
            desc:
                'Чёткий обзор недели по дням, быстрый перенос задач и отслеживание прогресса.',
          ),
          _FeatureInfo(
            icon: Icons.auto_awesome_rounded,
            color: AppColors.glowIndigo,
            title: 'AI Ассистент',
            desc:
                'Составит план обучения или работы и импортирует задачи прямо в календарь.',
          ),
          _FeatureInfo(
            icon: Icons.insights_rounded,
            color: AppColors.success,
            title: 'Аналитика и серия дней',
            desc:
                'Графики выполнения, распределение по категориям и мотивация каждый день.',
          ),
          _FeatureInfo(
            icon: Icons.timer_outlined,
            color: AppColors.teal,
            title: 'Фокус таймер и итоги',
            desc:
                'Помодоро-режимы с фоновой музыкой и структурированная рефлексия недели.',
          ),
        ];
      case 'en':
        return const [
          _FeatureInfo(
            icon: Icons.calendar_month_rounded,
            color: AppColors.lightPrimary,
            title: 'Weekly Planner',
            desc:
                'Organize daily tasks with priorities, time slots, and clear weekly visibility.',
          ),
          _FeatureInfo(
            icon: Icons.auto_awesome_rounded,
            color: AppColors.glowIndigo,
            title: 'AI Planning Assistant',
            desc:
                'Draft study or work schedules and import structured tasks in one tap.',
          ),
          _FeatureInfo(
            icon: Icons.insights_rounded,
            color: AppColors.success,
            title: 'Analytics & Streaks',
            desc:
                'Track completion rates, category balance, and daily momentum effortlessly.',
          ),
          _FeatureInfo(
            icon: Icons.timer_outlined,
            color: AppColors.teal,
            title: 'Focus Timer & Reviews',
            desc:
                'Stay in flow with Pomodoro cycles, ambient audio, and weekly reflections.',
          ),
        ];
      default:
        return const [
          _FeatureInfo(
            icon: Icons.calendar_month_rounded,
            color: AppColors.lightPrimary,
            title: 'Апталық жоспарлаушы',
            desc:
                'Күнделікті тапсырмаларды уақытымен және приоритетімен ыңғайлы реттеу.',
          ),
          _FeatureInfo(
            icon: Icons.auto_awesome_rounded,
            color: AppColors.glowIndigo,
            title: 'AI Көмекші',
            desc:
                'Оқу мен жұмыс кестесін жасап, тапсырмаларды күнтізбеге жылдам енгізеді.',
          ),
          _FeatureInfo(
            icon: Icons.insights_rounded,
            color: AppColors.success,
            title: 'Аналитика және серия',
            desc:
                'Орындалу графиктері, категория статистикасы және күндік тұрақтылық.',
          ),
          _FeatureInfo(
            icon: Icons.timer_outlined,
            color: AppColors.teal,
            title: 'Фокус таймер және қорытынды',
            desc:
                'Фокус музыкасымен Помодоро сессиялары және апталық рефлексия.',
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary =
        isDark ? AppColors.darkPrimaryBright : AppColors.lightPrimary;
    final muted =
        isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final features = _featuresFor(lang.currentLocale);

    final heroHeadline = switch (lang.currentLocale) {
      'ru' => 'Планируйте неделю легко и осознанно',
      'en' => 'Plan your week with clarity and flow',
      _ => 'Аптаңызды жеңіл әрі жүйелі жоспарлаңыз',
    };

    return AmbientSpaceBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: TopAppBar(
          title: lang.t('nav.about'),
          isSubPage: true,
        ),
        body: SingleChildScrollView(
          physics: PlatformAdaptive.scrollPhysics(context),
          child: MobilePageContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SpringPopIn(
                  child: AppCard(
                    glowColor: primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 26,
                    ),
                    child: Column(
                      children: [
                        const FloatingDrift(
                          amplitude: 4,
                          child: BrandLogo(
                            size: 74,
                            borderRadius: 22,
                            showShadow: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'ZHOSPAR',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          heroHeadline,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          lang.t('auth.subtitle'),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13.5, color: muted),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...features.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SpringPopIn(
                      child: AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: f.color.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(f.icon, color: f.color, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    f.title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    f.desc,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.45,
                                      color: muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    PlatformAdaptive.hapticMedium();
                    final nav = Navigator.of(context);
                    if (nav.canPop()) {
                      nav.pop();
                    } else {
                      nav.pushNamedAndRemoveUntil(
                        auth.isAuthenticated ? AppRoutes.home : AppRoutes.auth,
                        (_) => false,
                      );
                    }
                  },
                  icon: Icon(
                    auth.isAuthenticated
                        ? Icons.home_rounded
                        : Icons.login_rounded,
                  ),
                  label: Text(
                    auth.isAuthenticated
                        ? lang.t('nav.home')
                        : lang.t('auth.login'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureInfo {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;

  const _FeatureInfo({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
  });
}
