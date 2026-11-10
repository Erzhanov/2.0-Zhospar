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
import '../../shared/widgets/glass_surface.dart';
import '../../shared/widgets/mobile_page_container.dart';
import '../../shared/widgets/tap_scale.dart';
import '../../state/auth_provider.dart';
import '../../state/theme_provider.dart';
import '../shell/widgets/top_app_bar.dart';
import 'widgets/onboarding_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmSignOut(
    BuildContext context,
    AuthProvider auth,
    LanguageProvider lang,
  ) async {
    final confirmed = await showAdaptiveConfirmDialog(
      context,
      title: lang.t('auth.logoutConfirmTitle'),
      body: lang.t('auth.logoutConfirmBody'),
      confirmLabel: lang.t('nav.logout'),
      cancelLabel: lang.t('common.cancel'),
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.root,
        (route) => false,
      );
    }
  }

  Future<void> _editDisplayName(
    BuildContext context,
    AuthProvider auth,
    LanguageProvider lang,
    String currentName,
  ) async {
    await showAdaptiveModal<void>(
      context,
      builder: (_) => _EditNameModal(
        initialName: currentName,
        lang: lang,
        onSave: (name) async {
          await auth.updateDisplayName(name);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text(lang.t('settings.nameSaved')),
              ),
            );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary =
        isDark ? AppColors.darkPrimaryBright : AppColors.lightPrimary;
    final muted =
        isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final fg = isDark ? AppColors.darkForeground : AppColors.lightForeground;

    final user = auth.user;
    final displayName =
        user?.userMetadata?['display_name']?.toString().trim().isNotEmpty ==
                true
            ? user!.userMetadata!['display_name'].toString().trim()
            : (user?.email?.split('@').first ?? 'User');
    final email = user?.email ?? '';
    final initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'Z';

    return AmbientSpaceBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: TopAppBar(
          title: lang.t('settings.title'),
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
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primary, AppColors.glowIndigo],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: AppColors.floatingShadows(
                              isDark: isDark,
                              glowColor: primary,
                              elevation: 0.7,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
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
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: fg,
                                ),
                              ),
                              if (email.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: muted,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: (auth.isAdmin
                                          ? AppColors.warning
                                          : primary)
                                      .withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  auth.isAdmin
                                      ? lang.t('settings.roleAdmin')
                                      : lang.t('settings.roleUser'),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: auth.isAdmin
                                        ? AppColors.warning
                                        : primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (auth.isAdmin) ...[
                          TapScale(
                            onTap: () => Navigator.of(context)
                                .pushNamed(AppRoutes.admin),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings_rounded,
                                color: AppColors.warning,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        IconButton(
                          key: const ValueKey('settings-edit-name'),
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: muted,
                          ),
                          tooltip: lang.t('settings.editName'),
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                          onPressed: () {
                            PlatformAdaptive.hapticLight();
                            _editDisplayName(context, auth, lang, displayName);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Theme selector (System / Light / Dark)
                SpringPopIn(
                  child: AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.palette_outlined,
                              size: 18,
                              color: primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                lang.t('settings.theme'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: fg,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _ThemeOptionButton(
                                key: const ValueKey('theme-option-system'),
                                icon: Icons.brightness_auto_rounded,
                                label: lang.t('settings.system'),
                                selected: theme.themeMode == ThemeMode.system,
                                accent: primary,
                                isDark: isDark,
                                onTap: () {
                                  PlatformAdaptive.hapticSelection();
                                  theme.setTheme(ThemeMode.system);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ThemeOptionButton(
                                key: const ValueKey('theme-option-light'),
                                icon: Icons.light_mode_rounded,
                                label: lang.t('settings.light'),
                                selected: theme.themeMode == ThemeMode.light,
                                accent: primary,
                                isDark: isDark,
                                onTap: () {
                                  PlatformAdaptive.hapticSelection();
                                  theme.setTheme(ThemeMode.light);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ThemeOptionButton(
                                key: const ValueKey('theme-option-dark'),
                                icon: Icons.dark_mode_rounded,
                                label: lang.t('settings.dark'),
                                selected: theme.themeMode == ThemeMode.dark,
                                accent: primary,
                                isDark: isDark,
                                onTap: () {
                                  PlatformAdaptive.hapticSelection();
                                  theme.setTheme(ThemeMode.dark);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Language selector
                SpringPopIn(
                  child: AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.translate_rounded,
                              size: 18,
                              color: primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                lang.t('settings.language'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: fg,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _LanguageOptionButton(
                                flag: '🇰🇿',
                                label: 'Қаз',
                                selected: lang.currentLocale == 'kk',
                                accent: primary,
                                isDark: isDark,
                                onTap: () {
                                  PlatformAdaptive.hapticSelection();
                                  lang.setLocale('kk');
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _LanguageOptionButton(
                                flag: '🇷🇺',
                                label: 'Рус',
                                selected: lang.currentLocale == 'ru',
                                accent: primary,
                                isDark: isDark,
                                onTap: () {
                                  PlatformAdaptive.hapticSelection();
                                  lang.setLocale('ru');
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _LanguageOptionButton(
                                flag: '🇬🇧',
                                label: 'Eng',
                                selected: lang.currentLocale == 'en',
                                accent: primary,
                                isDark: isDark,
                                onTap: () {
                                  PlatformAdaptive.hapticSelection();
                                  lang.setLocale('en');
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Haptic feedback adaptive toggle
                SpringPopIn(
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: PlatformAdaptive.hapticsNotifier,
                      builder: (context, hapticsOn, _) {
                        return Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.13),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.vibration_rounded,
                                color: primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang.t('settings.haptics'),
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: fg,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    lang.t('settings.hapticsDesc'),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch.adaptive(
                              key: const ValueKey('settings-haptics-switch'),
                              value: hapticsOn,
                              activeTrackColor: primary,
                              onChanged: (val) =>
                                  PlatformAdaptive.setHapticsEnabled(val),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Onboarding guide card
                SpringPopIn(
                  child: TapScale(
                    onTap: () => OnboardingDialog.show(context),
                    borderRadius: BorderRadius.circular(22),
                    child: AppCard(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.glowIndigo.withValues(
                                alpha: 0.14,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.explore_outlined,
                              color: AppColors.glowIndigo,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.t('settings.onboarding'),
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: fg,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  lang.t('settings.onboardingDesc'),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: muted),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // About & Welcome link
                SpringPopIn(
                  child: TapScale(
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.welcome),
                    borderRadius: BorderRadius.circular(22),
                    child: AppCard(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          const BrandLogo(size: 44, borderRadius: 14),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.t('settings.about'),
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: fg,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  lang.t('settings.version'),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: muted),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Sign Out action with native confirmation dialog
                SpringPopIn(
                  child: TapScale(
                    onTap: () => _confirmSignOut(context, auth, lang),
                    minHeight: 52,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.destructive.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.destructive.withValues(alpha: 0.28),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.logout_rounded,
                            color: AppColors.destructive,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            lang.t('nav.logout'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.destructive,
                            ),
                          ),
                        ],
                      ),
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

class _ThemeOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _ThemeOptionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? accent.withValues(alpha: isDark ? 0.22 : 0.14)
        : (isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.60));
    final fg = selected
        ? accent
        : (isDark ? AppColors.darkForeground : AppColors.lightForeground);

    return TapScale(
      onTap: onTap,
      minHeight: 54,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: AppMotion.smooth,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.65)
                : AppColors.rimBorder(isDark),
            width: selected ? 1.4 : 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 19, color: fg),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditNameModal extends StatefulWidget {
  final String initialName;
  final LanguageProvider lang;
  final Future<void> Function(String name) onSave;

  const _EditNameModal({
    required this.initialName,
    required this.lang,
    required this.onSave,
  });

  @override
  State<_EditNameModal> createState() => _EditNameModalState();
}

class _EditNameModalState extends State<_EditNameModal> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final isPhone = PlatformAdaptive.isCompactPhone(context);

    return Padding(
      padding: EdgeInsets.only(
        left: isPhone ? 12 : 24,
        right: isPhone ? 12 : 24,
        bottom: isPhone ? MediaQuery.of(context).viewInsets.bottom + 12 : 24,
      ),
      child: Center(
        heightFactor: isPhone ? 1 : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: GlassSurface(
            enableBlur: true,
            borderRadius: 26,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.lang.t('settings.editName'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: widget.lang.t('auth.name'),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.of(context).pop(),
                      child: Text(widget.lang.t('common.cancel')),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _saving
                          ? null
                          : () async {
                              final trimmed = _controller.text.trim();
                              if (trimmed.isEmpty) return;
                              setState(() => _saving = true);
                              try {
                                await widget.onSave(trimmed);
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              } finally {
                                if (mounted) setState(() => _saving = false);
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(88, 44),
                      ),
                      child: _saving
                          ? const AdaptiveLoadingIndicator(
                              radius: 10,
                              color: Colors.white,
                            )
                          : Text(widget.lang.t('common.save')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageOptionButton extends StatelessWidget {
  final String flag;
  final String label;
  final bool selected;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _LanguageOptionButton({
    required this.flag,
    required this.label,
    required this.selected,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? accent.withValues(alpha: isDark ? 0.22 : 0.14)
        : (isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.60));
    final fg = selected
        ? accent
        : (isDark ? AppColors.darkForeground : AppColors.lightForeground);

    return TapScale(
      onTap: onTap,
      minHeight: 48,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: AppMotion.smooth,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.65)
                : AppColors.rimBorder(isDark),
            width: selected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
