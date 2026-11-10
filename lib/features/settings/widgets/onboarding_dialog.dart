import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/i18n/language_provider.dart';
import '../../../core/platform/platform_adaptive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/floating_motion.dart';
import '../../../shared/widgets/glass_surface.dart';
import '../../../shared/widgets/tap_scale.dart';

class OnboardingDialog extends StatefulWidget {
  const OnboardingDialog({super.key});

  static const String _prefKey = 'zhospar_onboarding_done';

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const OnboardingDialog(),
    );
  }

  static Future<void> showIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_prefKey) ?? false;
    if (!seen && context.mounted) {
      await show(context);
    }
  }

  @override
  State<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<OnboardingDialog> {
  int _step = 0;

  List<_OnboardingStep> _stepsFor(String locale) {
    switch (locale) {
      case 'ru':
        return const [
          _OnboardingStep(
            icon: Icons.calendar_month_rounded,
            color: AppColors.lightPrimary,
            title: 'Недельный план без хаоса',
            body:
                'Планируйте задачи по дням недели, задавайте приоритеты и добавляйте план через AI-помощника.',
          ),
          _OnboardingStep(
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.success,
            title: 'Фокус на каждом дне',
            body:
                'Отмечайте выполнение свайпом или тапом, поддерживайте ежедневную серию и фиксируйте рефлексию.',
          ),
          _OnboardingStep(
            icon: Icons.timer_outlined,
            color: AppColors.glowIndigo,
            title: 'Таймер и итоги недели',
            body:
                'Запускайте помодоро-сессии с фоновой музыкой и подводите итоги в конце каждой недели.',
          ),
        ];
      case 'en':
        return const [
          _OnboardingStep(
            icon: Icons.calendar_month_rounded,
            color: AppColors.lightPrimary,
            title: 'Effortless Weekly Planning',
            body:
                'Organize tasks across days, set clear priorities, and generate structured plans with the AI Assistant.',
          ),
          _OnboardingStep(
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.success,
            title: 'Stay Consistent Every Day',
            body:
                'Complete tasks with one tap, maintain your daily streak, and capture quick evening reflections.',
          ),
          _OnboardingStep(
            icon: Icons.timer_outlined,
            color: AppColors.glowIndigo,
            title: 'Focus Timer & Reviews',
            body:
                'Run deep-work Pomodoro sessions with ambient music and review your progress every Sunday.',
          ),
        ];
      default:
        return const [
          _OnboardingStep(
            icon: Icons.calendar_month_rounded,
            color: AppColors.lightPrimary,
            title: 'Апталық жоспарыңызды реттеңіз',
            body:
                'Тапсырмаларды апта күндеріне бөліп, приоритет қойыңыз немесе AI көмекшімен дайын жоспар құрыңыз.',
          ),
          _OnboardingStep(
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.success,
            title: 'Күн сайынғы тұрақтылық',
            body:
                'Орындалған істерді белгілеп, күндік серияны сақтаңыз және кешкі рефлексия жазып отырыңыз.',
          ),
          _OnboardingStep(
            icon: Icons.timer_outlined,
            color: AppColors.glowIndigo,
            title: 'Фокус таймері және қорытынды',
            body:
                'Фокус музыкасымен Помодоро таймерін қосып, апта соңында нәтижелеріңізді саралаңыз.',
          ),
        ];
    }
  }

  Future<void> _finish() async {
    PlatformAdaptive.hapticMedium();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingDialog._prefKey, true);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final steps = _stepsFor(lang.currentLocale);
    final current = steps[_step];
    final muted =
        isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final isLast = _step == steps.length - 1;

    final nextLabel = switch (lang.currentLocale) {
      'ru' => 'Далее',
      'en' => 'Next',
      _ => 'Келесі',
    };
    final doneLabel = lang.t('common.doneBtn');
    final skipLabel = switch (lang.currentLocale) {
      'ru' => 'Пропустить',
      'en' => 'Skip',
      _ => 'Өткізіп жіберу',
    };

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SpringPopIn(
          child: GlassSurface(
            enableBlur: true,
            borderRadius: 28,
            elevation: 1.4,
            glowColor: current.color,
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_step + 1} / ${steps.length}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: muted,
                      ),
                    ),
                    TapScale(
                      onTap: _finish,
                      minWidth: 44,
                      minHeight: 44,
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Text(
                          skipLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: muted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: Column(
                    key: ValueKey(_step),
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: current.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: current.color.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          current.icon,
                          size: 34,
                          color: current.color,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        current.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        current.body,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(steps.length, (i) {
                    final active = i == _step;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: AppMotion.smooth,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active
                            ? current.color
                            : muted.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (_step > 0) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            PlatformAdaptive.hapticSelection();
                            setState(() => _step--);
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(lang.t('nav.back')),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: isLast
                            ? _finish
                            : () {
                                PlatformAdaptive.hapticSelection();
                                setState(() => _step++);
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: current.color,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          isLast ? doneLabel : nextLabel,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
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

class _OnboardingStep {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _OnboardingStep({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}
