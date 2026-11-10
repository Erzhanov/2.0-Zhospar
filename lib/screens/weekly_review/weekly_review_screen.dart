import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/task_provider.dart';
import '../../services/week_service.dart';
import '../../widgets/common/ambient_space_background.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/glass_surface.dart';
import '../../widgets/common/mobile_page_container.dart';
import '../../widgets/navigation/top_app_bar.dart';

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
    try {
      if (taskProvider.currentWeek != null) {
        final review =
            await _weekService.getWeeklyReview(taskProvider.currentWeek!.id);
        if (review != null && mounted) {
          _learnedController.text = review.learnedText;
          _goodController.text = review.goodText;
          _hardController.text = review.hardText;
          _changeController.text = review.changeText;
          if (review.nextGoals.isNotEmpty) {
            _goal1Controller.text = review.nextGoals[0];
          }
          if (review.nextGoals.length > 1) {
            _goal2Controller.text = review.nextGoals[1];
          }
          if (review.nextGoals.length > 2) {
            _goal3Controller.text = review.nextGoals[2];
          }
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return AmbientSpaceBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: TopAppBar(
          title: lang.t('review.title'),
          isSubPage: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: MobilePageContainer(
                  bottomClearance: 36,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GlassSurface(
                        enableBlur: true,
                        borderRadius: 24,
                        glowColor: primary,
                        elevation: 1.25,
                        borderColor:
                            Colors.white.withValues(alpha: isDark ? 0.22 : 0.65),
                        padding: const EdgeInsets.all(20),
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xCC0D4B45),
                                  const Color(0xCC1E1B4B),
                                ]
                              : [
                                  AppColors.lightPrimary.withValues(alpha: 0.92),
                                  const Color(0xE60D9488),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.t('review.title'),
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              lang.t('review.desc'),
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _questionCard(
                        lang.t('review.q1'),
                        'Жаңа дағды, білім, тәжірибе...',
                        _learnedController,
                        Icons.school_outlined,
                        primary,
                      ),
                      const SizedBox(height: 12),
                      _questionCard(
                        lang.t('review.q2'),
                        'Жетістіктер, орындалған ірі мақсаттар...',
                        _goodController,
                        Icons.thumb_up_alt_outlined,
                        primary,
                      ),
                      const SizedBox(height: 12),
                      _questionCard(
                        lang.t('review.q3'),
                        'Кедергілер, уақыт жетпеген сәттер...',
                        _hardController,
                        Icons.warning_amber_rounded,
                        primary,
                      ),
                      const SizedBox(height: 12),
                      _questionCard(
                        lang.t('review.q4'),
                        'Келесі аптада түзейтін әдеттер...',
                        _changeController,
                        Icons.sync_rounded,
                        primary,
                      ),
                      const SizedBox(height: 18),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.t('review.goals'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _goalField('1', _goal1Controller, isDark, lang),
                            const SizedBox(height: 10),
                            _goalField('2', _goal2Controller, isDark, lang),
                            const SizedBox(height: 10),
                            _goalField('3', _goal3Controller, isDark, lang),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_rounded, size: 19),
                        label: Text(
                          lang.t('common.save'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ],
                  ),
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
    Color primary,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: 2,
            style: const TextStyle(fontSize: 13.5),
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }

  Widget _goalField(
    String num,
    TextEditingController controller,
    bool isDark,
    LanguageProvider lang,
  ) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color:
                isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            num,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 13.5),
            decoration: InputDecoration(
              hintText: '${lang.t('review.goal')} $num',
            ),
          ),
        ),
      ],
    );
  }
}
