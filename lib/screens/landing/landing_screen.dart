import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/mobile_page_container.dart';
import '../../widgets/navigation/top_app_bar.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: TopAppBar(
        title: lang.t('nav.about'),
        isSubPage: canPop,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: MobilePageContainer(
            maxWidth: 540,
            bottomClearance: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/hero-planner.png',
                      height: 190,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 170,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.lightPrimary.withValues(alpha: 0.85),
                              AppColors.purple.withValues(alpha: 0.85),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  lang.currentLocale == 'ru'
                      ? 'Умный еженедельный планировщик'
                      : lang.currentLocale == 'en'
                          ? 'Smart Weekly Planner'
                          : 'Апталық Жоспар — Өміріңді ретке келтір',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                    height: 1.18,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  lang.currentLocale == 'ru'
                      ? 'Планируйте дни, управляйте фокусом с помодоро таймером, анализируйте прогресс и достигайте целей с AI.'
                      : lang.currentLocale == 'en'
                          ? 'Plan your days, focus with pomodoro timer, track analytics and achieve goals with AI.'
                          : 'Апталық мақсаттар, фокус таймері, AI көмекшісі, аналитика және апталық рефлексия — барлығы бір жерде.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _metricCell('3 000+', 'Users', isDark),
                    const SizedBox(width: 10),
                    _metricCell('95%', 'Focus', isDark),
                    const SizedBox(width: 10),
                    _metricCell('0 ₸', 'Free', isDark),
                  ],
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () {
                    if (auth.isAuthenticated) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.root,
                        (route) => false,
                      );
                    } else if (canPop) {
                      Navigator.of(context).pop();
                    } else {
                      Navigator.of(context).pushReplacementNamed(AppRoutes.auth);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        auth.isAuthenticated
                            ? lang.t('nav.home')
                            : '${lang.t('auth.login')} / ${lang.t('auth.register')}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metricCell(String val, String label, bool isDark) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        borderRadius: 16,
        child: Column(
          children: [
            Text(
              val,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
