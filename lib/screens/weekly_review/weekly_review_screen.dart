import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/task_provider.dart';
import '../../services/week_service.dart';

class WeeklyReviewScreen extends StatefulWidget {
  const WeeklyReviewScreen({super.key});

  @override
  State<WeeklyReviewScreen> createState() => _WeeklyReviewScreenState();
}

class _WeeklyReviewScreenState extends State<WeeklyReviewScreen> {
  final _weekService = WeekService();
  final _learnedController = TextEditingController();
  final _goodController = TextEditingController();
  final _hardController = TextEditingController();
  final _changeController = TextEditingController();
  final _goal1Controller = TextEditingController();
  final _goal2Controller = TextEditingController();
  final _goal3Controller = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadReview();
  }

  @override
  void dispose() {
    _learnedController.dispose();
    _goodController.dispose();
    _hardController.dispose();
    _changeController.dispose();
    _goal1Controller.dispose();
    _goal2Controller.dispose();
    _goal3Controller.dispose();
    super.dispose();
  }

  Future<void> _loadReview() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    if (taskProvider.currentWeek != null) {
      final review = await _weekService.getWeeklyReview(taskProvider.currentWeek!.id);
      if (review != null) {
        _learnedController.text = review.learnedText;
        _goodController.text = review.goodText;
        _hardController.text = review.hardText;
        _changeController.text = review.changeText;
        if (review.nextGoals.isNotEmpty) _goal1Controller.text = review.nextGoals[0];
        if (review.nextGoals.length > 1) _goal2Controller.text = review.nextGoals[1];
        if (review.nextGoals.length > 2) _goal3Controller.text = review.nextGoals[2];
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    if (taskProvider.currentWeek == null) return;

    setState(() => _isSaving = true);
    try {
      final goals = [
        _goal1Controller.text.trim(),
        _goal2Controller.text.trim(),
        _goal3Controller.text.trim(),
      ].where((g) => g.isNotEmpty).toList();

      await _weekService.saveWeeklyReview(
        weekId: taskProvider.currentWeek!.id,
        learnedText: _learnedController.text.trim(),
        goodText: _goodController.text.trim(),
        hardText: _hardController.text.trim(),
        changeText: _changeController.text.trim(),
        nextGoals: goals,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang.t('review.saved')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightPrimary,
                  borderRadius: BorderRadius.circular(22),
                  gradient: isDark
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFF007AFF), Color(0xFF0051C6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.t('review.title'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lang.t('review.desc'),
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4 Questions
              _questionCard(
                lang.t('review.q1'),
                'Жаңа дағды, білім, тәжірибе...',
                _learnedController,
                Icons.school_outlined,
                isDark,
              ),
              const SizedBox(height: 12),
              _questionCard(
                lang.t('review.q2'),
                'Жетістіктер, орындалған ірі мақсаттар...',
                _goodController,
                Icons.thumb_up_alt_outlined,
                isDark,
              ),
              const SizedBox(height: 12),
              _questionCard(
                lang.t('review.q3'),
                'Кедергілер, уақыт жетпеген сәттер...',
                _hardController,
                Icons.warning_amber_rounded,
                isDark,
              ),
              const SizedBox(height: 12),
              _questionCard(
                lang.t('review.q4'),
                'Келесі аптада түзейтін әдеттер...',
                _changeController,
                Icons.sync_rounded,
                isDark,
              ),
              const SizedBox(height: 20),

              // 3 Next Goals
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.t('review.goals'),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _goalField('1', _goal1Controller, isDark),
                    const SizedBox(height: 8),
                    _goalField('2', _goal2Controller, isDark),
                    const SizedBox(height: 8),
                    _goalField('3', _goal3Controller, isDark),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(
                  lang.t('common.save'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _questionCard(
    String title,
    String hint,
    TextEditingController controller,
    IconData icon,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: 2,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _goalField(String num, TextEditingController controller, bool isDark) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            num,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Мақсат жазыңыз...',
              filled: true,
              fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}
