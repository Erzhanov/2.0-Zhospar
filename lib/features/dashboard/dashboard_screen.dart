import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/router/app_routes.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/platform/platform_adaptive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/week_utils.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/floating_motion.dart';
import '../../shared/widgets/glass_surface.dart';
import '../../shared/widgets/mobile_page_container.dart';
import '../../shared/widgets/tap_scale.dart';
import '../../state/auth_provider.dart';
import '../../state/gamification_provider.dart';
import '../../state/task_provider.dart';
import 'widgets/day_selector_bar.dart';
import 'widgets/task_form_sheet.dart';
import 'widgets/task_item_widget.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final VoidCallback? onOpenAnalytics;

  const DashboardScreen({
    super.key,
    this.onNavigateTab,
    this.onOpenAnalytics,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _reflectionController = TextEditingController();
  final _scrollController = ScrollController();
  String _taskFilter = 'all'; // 'all' | 'todo' | 'done'
  String _lastSyncedReflection = '';

  @override
  void dispose() {
    _reflectionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showQuoteDialog(
    BuildContext context,
    TaskProvider taskProvider,
    LanguageProvider lang,
    bool isDark,
  ) {
    final quoteController =
        TextEditingController(text: taskProvider.currentWeek?.quote ?? '');
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
          ),
          child: GlassSurface(
            enableBlur: true,
            borderRadius: 28,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.format_quote_rounded,
                      color: AppColors.warning,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        lang.t('dashboard.quote'),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: quoteController,
                  autofocus: true,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: lang.t('dashboard.quoteHint'),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    await taskProvider.saveQuote(quoteController.text.trim());
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text(
                    lang.t('common.save'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final accent = isDark ? AppColors.darkPrimaryBright : primary;

    final weekRange = WeekUtils.formatWeekRange(
      taskProvider.weekStartDate,
      lang.currentLocale,
    );

    if (_lastSyncedReflection != taskProvider.reflectionText) {
      _lastSyncedReflection = taskProvider.reflectionText;
      _reflectionController.text = taskProvider.reflectionText;
    }

    final dayNames = lang.getDayNames();
    final allDayTasks = taskProvider.selectedDayTasks;
    final todoCount = allDayTasks.where((t) => !t.isDone).length;
    final doneCount = allDayTasks.where((t) => t.isDone).length;

    var visibleTasks = allDayTasks;
    if (_taskFilter == 'todo') {
      visibleTasks = allDayTasks.where((t) => !t.isDone).toList();
    } else if (_taskFilter == 'done') {
      visibleTasks = allDayTasks.where((t) => t.isDone).toList();
    }

    final userEmail = auth.user?.email ?? '';
    final userName = auth.user?.userMetadata?['display_name'] as String? ??
        (userEmail.isNotEmpty ? userEmail.split('@').first : 'ZHOSPAR');
    final progressRatio = taskProvider.totalCount > 0
        ? taskProvider.doneCount / taskProvider.totalCount
        : 0.0;
    final hour = DateTime.now().hour;
    final daySalutation = hour < 12
        ? lang.t('dashboard.morning')
        : (hour < 18
            ? lang.t('dashboard.afternoon')
            : lang.t('dashboard.evening'));

    return RefreshIndicator.adaptive(
      onRefresh: () => taskProvider.loadWeek(taskProvider.weekStartDate),
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: PlatformAdaptive.scrollPhysics(context),
        child: MobilePageContainer(
          bottomClearance: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          daySalutation.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.9,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${lang.t('dashboard.hello')}, $userName 👋',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          weekRange,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.lightSecondaryText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GlassSurface(
                        borderRadius: 14,
                        glowColor: AppColors.warning,
                        elevation: 0.7,
                        tintColor: AppColors.warning.withValues(alpha: 0.14),
                        borderColor: AppColors.warning.withValues(alpha: 0.35),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              '${taskProvider.streakCount} ${lang.t('common.streakDays')}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Consumer<GamificationProvider>(
                        builder: (context, gamification, _) {
                          return GlassSurface(
                            borderRadius: 14,
                            glowColor: AppColors.glowIndigo,
                            elevation: 0.7,
                            tintColor: AppColors.glowIndigo.withValues(alpha: 0.14),
                            borderColor: AppColors.glowIndigo.withValues(alpha: 0.35),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('⚡', style: TextStyle(fontSize: 11)),
                                const SizedBox(width: 4),
                                Text(
                                  '${gamification.level} lvl • ${gamification.xp} XP',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.glowIndigo,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Levitating Zero-G Hero Card (tap opens Analytics)
              TapScale(
                onTap: widget.onOpenAnalytics ??
                    () => Navigator.of(context).pushNamed(AppRoutes.analytics),
                borderRadius: BorderRadius.circular(26),
                child: GlassSurface(
                  borderRadius: 26,
                  glowColor: accent,
                  elevation: 1.3,
                  borderColor:
                      Colors.white.withValues(alpha: isDark ? 0.22 : 0.65),
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xE00A84FF),
                            const Color(0xE05856D6),
                          ]
                        : [
                            AppColors.lightPrimary,
                            AppColors.indigo,
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.t('common.weekProgress').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white70,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${taskProvider.doneCount} / ${taskProvider.totalCount} ${lang.t('common.tasks')}',
                            style: const TextStyle(
                              fontSize: 18.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 16,
                            runSpacing: 6,
                            children: [
                              _heroCounter(
                                lang.t('dashboard.total'),
                                '${taskProvider.totalCount}',
                              ),
                              _heroCounter(
                                lang.t('dashboard.done'),
                                '${taskProvider.doneCount}',
                              ),
                              _heroCounter(
                                lang.t('dashboard.left'),
                                '${taskProvider.totalCount - taskProvider.doneCount}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    FloatingDrift(
                      amplitude: 3.5,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: progressRatio),
                        duration: const Duration(milliseconds: 560),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return SizedBox(
                            width: 74,
                            height: 74,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 74,
                                  height: 74,
                                  child: CircularProgressIndicator(
                                    value: value,
                                    strokeWidth: 7,
                                    strokeCap: StrokeCap.round,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.2),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${taskProvider.completionPct}%',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                ),
              ),
              const SizedBox(height: 14),

              TapScale(
                onTap: () =>
                    _showQuoteDialog(context, taskProvider, lang, isDark),
                borderRadius: BorderRadius.circular(20),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  borderRadius: 20,
                  glowColor: AppColors.warning,
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.warning.withValues(alpha: 0.55),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          taskProvider.currentWeek?.quote.isNotEmpty == true
                              ? '«${taskProvider.currentWeek!.quote}»'
                              : lang.t('dashboard.quoteHint'),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                            color: taskProvider.currentWeek?.quote.isNotEmpty ==
                                    true
                                ? (isDark
                                    ? AppColors.darkForeground
                                    : AppColors.lightForeground)
                                : (isDark ? Colors.white38 : Colors.black38),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              DaySelectorBar(
                weekStartDate: taskProvider.weekStartDate,
                selectedDay: taskProvider.selectedDay,
                tasks: taskProvider.tasks,
                lang: lang,
                onSelectDay: taskProvider.selectDay,
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      dayNames[taskProvider.selectedDay - 1],
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  GlassSurface(
                    elevation: 0.4,
                    borderRadius: 12,
                    tintColor: accent.withValues(alpha: isDark ? 0.16 : 0.10),
                    borderColor: accent.withValues(alpha: 0.25),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Text(
                      '${visibleTasks.length} ${lang.t('common.tasks')}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _TaskFilterBar(
                activeFilter: _taskFilter,
                allLabel: '${lang.t('common.all')} (${allDayTasks.length})',
                todoLabel: '${lang.t('dashboard.filterTodo')} ($todoCount)',
                doneLabel: '${lang.t('dashboard.filterDone')} ($doneCount)',
                primary: primary,
                accent: accent,
                isDark: isDark,
                onChanged: (id) => setState(() => _taskFilter = id),
              ),
              const SizedBox(height: 14),

              if (allDayTasks.isNotEmpty && todoCount == 0) ...[
                SpringPopIn(
                  child: GlassSurface(
                    margin: const EdgeInsets.only(bottom: 12),
                    borderRadius: 18,
                    elevation: 0.7,
                    glowColor: AppColors.success,
                    tintColor: AppColors.success.withValues(alpha: 0.13),
                    borderColor: AppColors.success.withValues(alpha: 0.35),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            lang.t('dashboard.dayDone'),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              if (visibleTasks.isEmpty)
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    vertical: 32,
                    horizontal: 20,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.checklist_rounded,
                          size: 28,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        lang.t('week.dayEmpty'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.lightSecondaryText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => showTaskFormModal(
                          context,
                          defaultDay: taskProvider.selectedDay,
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(lang.t('common.addTask')),
                      ),
                    ],
                  ),
                )
              else
                ...visibleTasks.map((task) {
                  return TaskItemWidget(
                    key: ValueKey<String>(task.id),
                    task: task,
                    onEdit: () => showTaskFormModal(context, taskToEdit: task),
                  );
                }),
              const SizedBox(height: 14),

              AppCard(
                glowColor: AppColors.teal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.edit_note_rounded,
                          size: 22,
                          color: AppColors.teal,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${dayNames[taskProvider.selectedDay - 1]} — ${lang.t('dashboard.reflection')}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _reflectionController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: lang.t('dashboard.reflectionHint'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () async {
                          PlatformAdaptive.hapticLight();
                          await taskProvider.saveReflection(
                            _reflectionController.text.trim(),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content:
                                    Text(lang.t('dashboard.reflectionSaved')),
                                duration: const Duration(seconds: 1),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(112, 44),
                        ),
                        child: Text(
                          lang.t('common.save'),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              Text(
                lang.t('dashboard.quickActions'),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cols = constraints.maxWidth < 340 ? 1 : 2;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: cols,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 68,
                    children: [
                      _quickActionTile(
                        icon: Icons.timer_outlined,
                        label: lang.t('nav.timer'),
                        color: AppColors.teal,
                        onTap: () =>
                            Navigator.of(context).pushNamed(AppRoutes.timer),
                      ),
                      _quickActionTile(
                        icon: Icons.rate_review_outlined,
                        label: lang.t('nav.review'),
                        color: AppColors.purple,
                        onTap: () => Navigator.of(context)
                            .pushNamed(AppRoutes.weeklyReview),
                      ),
                      _quickActionTile(
                        icon: Icons.archive_outlined,
                        label: lang.t('nav.archive'),
                        color: AppColors.warning,
                        onTap: () =>
                            Navigator.of(context).pushNamed(AppRoutes.archive),
                      ),
                      _quickActionTile(
                        icon: Icons.auto_awesome_rounded,
                        label: lang.t('nav.assistant'),
                        color: accent,
                        onTap: () => widget.onNavigateTab?.call(2),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroCounter(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _quickActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return TapScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        borderRadius: 20,
        glowColor: color,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskFilterBar extends StatelessWidget {
  final String activeFilter;
  final String allLabel;
  final String todoLabel;
  final String doneLabel;
  final Color primary;
  final Color accent;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _TaskFilterBar({
    required this.activeFilter,
    required this.allLabel,
    required this.todoLabel,
    required this.doneLabel,
    required this.primary,
    required this.accent,
    required this.isDark,
    required this.onChanged,
  });

  int get _activeIndex {
    switch (activeFilter) {
      case 'todo':
        return 1;
      case 'done':
        return 2;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.55);
    final pillColor =
        isDark ? primary : Colors.white.withValues(alpha: 0.96);
    final items = [
      ('all', allLabel),
      ('todo', todoLabel),
      ('done', doneLabel),
    ];

    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.rimBorder(isDark)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slotWidth = constraints.maxWidth / 3;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                left: _activeIndex * slotWidth,
                top: 0,
                bottom: 0,
                width: slotWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: pillColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppColors.floatingShadows(
                      isDark: isDark,
                      glowColor: accent,
                      elevation: 0.45,
                    ),
                  ),
                ),
              ),
              Row(
                children: items.map((entry) {
                  final active = activeFilter == entry.$1;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        PlatformAdaptive.hapticSelection();
                        onChanged(entry.$1);
                      },
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            entry.$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  active ? FontWeight.w700 : FontWeight.w600,
                              color: active
                                  ? (isDark ? Colors.white : primary)
                                  : (isDark
                                      ? AppColors.darkSecondaryText
                                      : AppColors.lightSecondaryText),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
