import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/i18n/language_provider.dart';
import '../core/theme/app_colors.dart';

class OnboardingDialog extends StatefulWidget {
  const OnboardingDialog({super.key});

  @override
  State<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<OnboardingDialog> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    final steps = [
      {
        'icon': Icons.calendar_today_rounded,
        'title': 'Аптаңызды жоспарлаңыз',
        'desc':
            '«Апта жоспары» бетінде апта күндерін көріп, әр күнге мақсаттарыңызды бөліп қойыңыз. Апта дүйсенбіден басталады.',
      },
      {
        'icon': Icons.add_task_rounded,
        'title': 'Тапсырма қосыңыз',
        'desc':
            '«Тапсырма қосу» батырмасын басып, атауын, күнін, категориясы мен приоритетін таңдаңыз. Орындалғанын белгілеп отырыңыз.',
      },
      {
        'icon': Icons.insights_rounded,
        'title': 'Прогресті бақылаңыз',
        'desc':
            'Аналитика мен мұрағат арқылы апта сайынғы жетістігіңізді көріп, рефлексия жазып, дамуыңызды қадағалаңыз.',
      },
    ];

    final step = steps[_currentStep];

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  tooltip: lang.t('nav.close'),
                  onPressed: () => Navigator.of(context).pop(),
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: isDark ? 0.2 : 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  step['icon'] as IconData,
                  size: 36,
                  color: primary,
                ),
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Column(
                  key: ValueKey<int>(_currentStep),
                  children: [
                    Text(
                      step['title'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      step['desc'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white60 : Colors.black54,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(steps.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _currentStep ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _currentStep
                          ? primary
                          : (isDark ? Colors.white24 : Colors.black12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (_currentStep > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _currentStep--),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(44, 48),
                        ),
                        child: Text(lang.t('nav.back')),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentStep < steps.length - 1) {
                          setState(() => _currentStep++);
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(44, 48),
                      ),
                      child: Text(
                        _currentStep == steps.length - 1 ? 'Бастау' : 'Келесі',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
