import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common/app_card.dart';

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

        if (!result.authenticated && result.requiresEmailConfirmation && mounted) {
          setState(() {
            _isLogin = true;
            _infoMessage = lang.t('auth.confirmEmail');
          });
          return;
        }
      }

      if (mounted && auth.isAuthenticated) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.root,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    }
  }

  void _switchMode(bool isLogin) {
    if (_isLogin == isLogin) return;
    HapticFeedback.selectionClick();
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
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Sticky utility top bar with >=44x44px touch targets
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 0.7,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (canPop)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
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
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Flexible(
                            child: Text(
                              'ZHOSPAR',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _languageMenuButton(lang, isDark, primary),
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
                          HapticFeedback.selectionClick();
                          theme.toggleTheme();
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

            // Scrollable vertical mobile-first auth form
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Brand badge & headline
                          Center(
                            child: Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: primary,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: primary.withValues(alpha: 0.28),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.calendar_month_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              _isLogin
                                  ? lang.t('auth.login')
                                  : lang.t('auth.register'),
                              key: ValueKey<bool>(_isLogin),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            lang.t('auth.subtitle'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Segmented Login / Sign Up Switcher
                          _AuthModeToggle(
                            isLogin: _isLogin,
                            loginLabel: lang.t('auth.login'),
                            registerLabel: lang.t('auth.register'),
                            primary: primary,
                            isDark: isDark,
                            onChanged: _switchMode,
                          ),
                          const SizedBox(height: 18),

                          AppCard(
                            padding: const EdgeInsets.all(18),
                            borderRadius: 22,
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

                                // Animated Name Field on registration
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 220),
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
                                              textInputAction:
                                                  TextInputAction.next,
                                              decoration: InputDecoration(
                                                hintText: lang.t('auth.name'),
                                                prefixIcon: const Icon(
                                                  Icons.person_outline_rounded,
                                                  size: 20,
                                                ),
                                              ),
                                              validator: (v) {
                                                if (!_isLogin &&
                                                    (v == null ||
                                                        v.trim().isEmpty)) {
                                                  return lang.t('auth.name');
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 16),
                                          ],
                                        ),
                                ),

                                _fieldLabel(lang.t('auth.email'), isDark),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  decoration: const InputDecoration(
                                    hintText: 'user@example.com',
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      size: 20,
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return lang.t('auth.email');
                                    }
                                    if (!v.contains('@') || !v.contains('.')) {
                                      return lang.t('auth.email');
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                _fieldLabel(lang.t('auth.password'), isDark),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
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
                                        () =>
                                            _obscurePassword = !_obscurePassword,
                                      ),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.length < 6) {
                                      return '${lang.t('auth.password')} (6+)';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 22),

                                ElevatedButton(
                                  onPressed: auth.loading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(double.infinity, 50),
                                  ),
                                  child: auth.loading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
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
                          const SizedBox(height: 14),

                          TextButton(
                            onPressed: () => _switchMode(!_isLogin),
                            child: Text(
                              _isLogin
                                  ? '${lang.t('auth.noAccount')} ${lang.t('auth.register')}'
                                  : '${lang.t('auth.haveAccount')} ${lang.t('auth.login')}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: primary,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushNamed(AppRoutes.welcome);
                            },
                            icon: const Icon(Icons.info_outline_rounded, size: 17),
                            label: Text(
                              lang.t('auth.welcomeLink'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white60 : Colors.black54,
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
          ],
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
    Color primary,
  ) {
    final codeLabel = lang.currentLocale.toUpperCase();
    return PopupMenuButton<String>(
      tooltip: lang.t('settings.language'),
      initialValue: lang.currentLocale,
      onSelected: (code) {
        HapticFeedback.selectionClick();
        lang.setLocale(code);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
            color: primary.withValues(alpha: isDark ? 0.18 : 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.language_rounded, size: 17, color: primary),
              const SizedBox(width: 5),
              Text(
                codeLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: primary,
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
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _AuthModeToggle({
    required this.isLogin,
    required this.loginLabel,
    required this.registerLabel,
    required this.primary,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? AppColors.darkCard
        : Colors.black.withValues(alpha: 0.05);

    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final halfWidth = constraints.maxWidth / 2;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                left: isLogin ? 0 : halfWidth,
                top: 0,
                bottom: 0,
                width: halfWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(12),
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
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black54),
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
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black54),
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
