import 'dart:ui';
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
import '../../state/auth_provider.dart';
import '../../state/theme_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = null;
      _infoMessage = null;
    });
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    try {
      if (_isLogin) {
        await auth.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        final result = await auth.signUp(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
        );

        if (!result.authenticated &&
            result.requiresEmailConfirmation &&
            mounted) {
          setState(() {
            _isLogin = true;
            _infoMessage = lang.t('auth.confirmEmail');
          });
          return;
        }
      }

      if (mounted && auth.isAuthenticated) {
        PlatformAdaptive.hapticMedium();
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.root,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        PlatformAdaptive.hapticHeavy();
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    }
  }

  void _switchMode(bool isLogin) {
    if (_isLogin == isLogin) return;
    PlatformAdaptive.hapticSelection();
    setState(() {
      _isLogin = isLogin;
      _errorMessage = null;
      _infoMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final accent = isDark ? AppColors.darkPrimaryBright : primary;
    final canPop = Navigator.of(context).canPop();
    final isApple = PlatformAdaptive.isApple(context);

    return AmbientSpaceBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xB8141416)
                          : Colors.white.withValues(alpha: 0.72),
                      border: Border(
                        bottom: BorderSide(color: AppColors.rimBorder(isDark)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (canPop)
                          IconButton(
                            icon: Icon(
                              isApple
                                  ? Icons.arrow_back_ios_new_rounded
                                  : Icons.arrow_back_rounded,
                            ),
                            tooltip: lang.t('nav.back'),
                            onPressed: () => Navigator.of(context).pop(),
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                          )
                        else
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 4),
                                const BrandLogo(size: 34, borderRadius: 11),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'ZHOSPAR',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.4,
                                        ),
                                      ),
                                      Text(
                                        lang.t('nav.appName'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? AppColors.darkSecondaryText
                                              : AppColors.lightSecondaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _languageMenuButton(lang, isDark, accent),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: Icon(
                                isDark
                                    ? Icons.light_mode_outlined
                                    : Icons.dark_mode_outlined,
                                size: 20,
                              ),
                              tooltip: isDark
                                  ? lang.t('settings.light')
                                  : lang.t('settings.dark'),
                              onPressed: () {
                                PlatformAdaptive.hapticSelection();
                                theme.toggleTheme(Theme.of(context).brightness);
                              },
                              constraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: PlatformAdaptive.scrollPhysics(context),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: AutofillGroup(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: FloatingDrift(
                                  amplitude: 4.5,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: accent.withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: const BrandLogo(
                                      size: 58,
                                      borderRadius: 16,
                                      showShadow: true,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: Text(
                                  _isLogin
                                      ? lang.t('auth.login')
                                      : lang.t('auth.register'),
                                  key: ValueKey<bool>(_isLogin),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                lang.t('auth.subtitle'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  height: 1.35,
                                  color: isDark
                                      ? AppColors.darkSecondaryText
                                      : AppColors.lightSecondaryText,
                                ),
                              ),
                              const SizedBox(height: 16),

                              _AuthModeToggle(
                                isLogin: _isLogin,
                                loginLabel: lang.t('auth.login'),
                                registerLabel: lang.t('auth.register'),
                                primary: primary,
                                accent: accent,
                                isDark: isDark,
                                onChanged: _switchMode,
                              ),
                              const SizedBox(height: 14),

                              AppCard(
                                padding: const EdgeInsets.all(20),
                                borderRadius: 26,
                                glowColor: accent,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    if (_errorMessage != null)
                                      _statusBanner(
                                        message: _errorMessage!,
                                        color: AppColors.destructive,
                                        icon: Icons.error_outline_rounded,
                                      ),
                                    if (_infoMessage != null)
                                      _statusBanner(
                                        message: _infoMessage!,
                                        color: AppColors.success,
                                        icon: Icons.mark_email_read_outlined,
                                      ),

                                    AnimatedSize(
                                      duration:
                                          const Duration(milliseconds: 220),
                                      curve: Curves.easeOutCubic,
                                      child: _isLogin
                                          ? const SizedBox.shrink()
                                          : Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                _fieldLabel(
                                                  lang.t('auth.name'),
                                                  isDark,
                                                ),
                                                const SizedBox(height: 6),
                                                TextFormField(
                                                  controller: _nameController,
                                                  autofillHints: const [
                                                    AutofillHints.name,
                                                  ],
                                                  textInputAction:
                                                      TextInputAction.next,
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        lang.t('auth.name'),
                                                    prefixIcon: const Icon(
                                                      Icons
                                                          .person_outline_rounded,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  validator: (v) {
                                                    if (!_isLogin &&
                                                        (v == null ||
                                                            v.trim().isEmpty)) {
                                                      return lang.t(
                                                        'auth.nameRequired',
                                                      );
                                                    }
                                                    return null;
                                                  },
                                                ),
                                                const SizedBox(height: 14),
                                              ],
                                            ),
                                    ),

                                    _fieldLabel(lang.t('auth.email'), isDark),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.email,
                                        AutofillHints.username,
                                      ],
                                      decoration: const InputDecoration(
                                        hintText: 'user@example.com',
                                        prefixIcon: Icon(
                                          Icons.email_outlined,
                                          size: 20,
                                        ),
                                      ),
                                      validator: (v) {
                                        if (v == null ||
                                            v.trim().isEmpty ||
                                            !v.contains('@') ||
                                            !v.contains('.')) {
                                          return lang.t('auth.emailInvalid');
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),

                                    _fieldLabel(
                                      lang.t('auth.password'),
                                      isDark,
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      autofillHints: _isLogin
                                          ? const [AutofillHints.password]
                                          : const [AutofillHints.newPassword],
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) {
                                        if (!auth.loading) _submit();
                                      },
                                      decoration: InputDecoration(
                                        hintText: '••••••••',
                                        prefixIcon: const Icon(
                                          Icons.lock_outline_rounded,
                                          size: 20,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            size: 20,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 44,
                                            minHeight: 44,
                                          ),
                                          onPressed: () => setState(
                                            () => _obscurePassword =
                                                !_obscurePassword,
                                          ),
                                        ),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.length < 6) {
                                          return lang.t('auth.passwordShort');
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    ElevatedButton(
                                      onPressed: auth.loading ? null : _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primary,
                                        foregroundColor: Colors.white,
                                        minimumSize:
                                            const Size(double.infinity, 52),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(18),
                                        ),
                                      ),
                                      child: auth.loading
                                          ? const AdaptiveLoadingIndicator(
                                              color: Colors.white,
                                            )
                                          : Text(
                                              _isLogin
                                                  ? lang.t('auth.login')
                                                  : lang.t('auth.register'),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),

                              TextButton(
                                onPressed: () => _switchMode(!_isLogin),
                                child: Text(
                                  _isLogin
                                      ? '${lang.t('auth.noAccount')} ${lang.t('auth.register')}'
                                      : '${lang.t('auth.haveAccount')} ${lang.t('auth.login')}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: accent,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.of(context)
                                      .pushNamed(AppRoutes.welcome);
                                },
                                icon: const Icon(
                                  Icons.info_outline_rounded,
                                  size: 17,
                                ),
                                label: Text(
                                  lang.t('auth.welcomeLink'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.darkSecondaryText
                                        : AppColors.lightSecondaryText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white70 : Colors.black87,
      ),
    );
  }

  Widget _statusBanner({
    required String message,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _languageMenuButton(
    LanguageProvider lang,
    bool isDark,
    Color accent,
  ) {
    final codeLabel = lang.currentLocale.toUpperCase();
    return PopupMenuButton<String>(
      tooltip: lang.t('settings.language'),
      initialValue: lang.currentLocale,
      onSelected: (code) {
        PlatformAdaptive.hapticSelection();
        lang.setLocale(code);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'kk', child: Text('🇰🇿  Қазақша')),
        PopupMenuItem(value: 'ru', child: Text('🇷🇺  Русский')),
        PopupMenuItem(value: 'en', child: Text('🇬🇧  English')),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 56, minHeight: 44),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: isDark ? 0.16 : 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.language_rounded, size: 17, color: accent),
              const SizedBox(width: 5),
              Text(
                codeLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthModeToggle extends StatelessWidget {
  final bool isLogin;
  final String loginLabel;
  final String registerLabel;
  final Color primary;
  final Color accent;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _AuthModeToggle({
    required this.isLogin,
    required this.loginLabel,
    required this.registerLabel,
    required this.primary,
    required this.accent,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.55);
    final pillColor =
        isDark ? primary : Colors.white.withValues(alpha: 0.95);

    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.rimBorder(isDark)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final halfWidth = constraints.maxWidth / 2;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: isLogin ? 0 : halfWidth,
                top: 0,
                bottom: 0,
                width: halfWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: pillColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppColors.floatingShadows(
                      isDark: isDark,
                      glowColor: accent,
                      elevation: 0.5,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(true),
                      child: Center(
                        child: Text(
                          loginLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isLogin
                                ? (isDark ? Colors.white : primary)
                                : (isDark ? Colors.white60 : Colors.black54),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(false),
                      child: Center(
                        child: Text(
                          registerLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: !isLogin
                                ? (isDark ? Colors.white : primary)
                                : (isDark ? Colors.white60 : Colors.black54),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
