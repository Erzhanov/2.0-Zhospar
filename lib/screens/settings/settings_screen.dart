import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/mobile_page_container.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/navigation/top_app_bar.dart';
import '../../widgets/onboarding_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    final userEmail = auth.user?.email ?? 'user@example.com';
    final initial = userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'U';

    return Scaffold(
      appBar: TopAppBar(
        title: lang.t('settings.title'),
        isSubPage: true,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: MobilePageContainer(
            bottomClearance: 36,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Card
                AppCard(
                  borderRadius: 20,
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userEmail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              auth.isAdmin
                                  ? lang.t('settings.roleAdmin')
                                  : lang.t('settings.roleUser'),
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Theme Selector
                AppCard(
                  borderRadius: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.t('settings.theme'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _themeOption(
                            label: lang.t('settings.light'),
                            icon: Icons.light_mode_rounded,
                            selected: !theme.isDarkMode,
                            onTap: () => theme.setTheme(ThemeMode.light),
                            isDark: isDark,
                            primary: primary,
                          ),
                          const SizedBox(width: 12),
                          _themeOption(
                            label: lang.t('settings.dark'),
                            icon: Icons.dark_mode_rounded,
                            selected: theme.isDarkMode,
                            onTap: () => theme.setTheme(ThemeMode.dark),
                            isDark: isDark,
                            primary: primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Language Selector (vertical thumb-friendly options)
                AppCard(
                  borderRadius: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.t('settings.language'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _langOption('kk', '🇰🇿  Қазақша', lang, isDark, primary),
                      const SizedBox(height: 8),
                      _langOption('ru', '🇷🇺  Русский', lang, isDark, primary),
                      const SizedBox(height: 8),
                      _langOption('en', '🇬🇧  English', lang, isDark, primary),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Onboarding Restart
                AppCard(
                  borderRadius: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.t('settings.onboarding'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lang.t('settings.onboardingDesc'),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.black54,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => const OnboardingDialog(),
                          );
                        },
                        icon: const Icon(Icons.help_outline_rounded, size: 18),
                        label: Text(lang.t('settings.onboarding')),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Sign Out Button -> redirects cleanly to AuthScreen via AppRoutes.root
                OutlinedButton.icon(
                  onPressed: () async {
                    await auth.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.root,
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.logout_rounded,
                    size: 19,
                    color: AppColors.destructive,
                  ),
                  label: Text(
                    lang.t('nav.logout'),
                    style: const TextStyle(
                      color: AppColors.destructive,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: BorderSide(
                      color: AppColors.destructive.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    lang.t('settings.version'),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black38,
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

  Widget _themeOption({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
    required Color primary,
  }) {
    return Expanded(
      child: TapScale(
        onTap: onTap,
        minHeight: 56,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: selected
                ? primary.withValues(alpha: isDark ? 0.18 : 0.12)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? primary
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: selected
                    ? primary
                    : (isDark ? Colors.white60 : Colors.black54),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? primary : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langOption(
    String code,
    String label,
    LanguageProvider lang,
    bool isDark,
    Color primary,
  ) {
    final selected = lang.currentLocale == code;
    return TapScale(
      onTap: () => lang.setLocale(code),
      minHeight: 48,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: isDark ? 0.18 : 0.12)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? primary : null,
              ),
            ),
            if (selected) Icon(Icons.check_circle_rounded, color: primary, size: 20),
          ],
        ),
      ),
    );
  }
}
