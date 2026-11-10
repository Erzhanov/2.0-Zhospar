import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/week_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/add_task_dialog.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/mobile_page_container.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/day_selector_bar.dart';
import '../../widgets/edit_task_dialog.dart';
import '../../widgets/task_item_widget.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

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
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
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
                    color: AppColors.purple,
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

    final weekRange = WeekUtils.formatWeekRange(
      taskProvider.weekStartDate,
      lang.currentLocale,
    );

    if (_lastSyncedReflection != taskProvider.reflectionText) {
      _lastSyncedReflection = taskProvider.reflectionText;
      _reflectionController.text = taskProvider.reflectionText;
    }

    final dayNames = lang.getDayNames();

    var dayTasks = taskProvider.selectedDayTasks;
    if (_taskFilter == 'todo') {
      dayTasks = dayTasks.where((t) => !t.isDone).toList();
    } else if (_taskFilter == 'done') {
      dayTasks = dayTasks.where((t) => t.isDone).toList();
    }

    final userEmail = auth.user?.email ?? '';
    final userName = auth.user?.userMetadata?['display_name'] as String? ??
        (userEmail.isNotEmpty ? userEmail.split('@').first : 'ZHOSPAR');

    return RefreshIndicator(
      onRefresh: () => taskProvider.loadWeek(taskProvider.weekStartDate),
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: MobilePageContainer(
          bottomClearance: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Top Greeting & Streak ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${lang.t('dashboard.hello')}, $userName 👋',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          weekRange,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white60 : Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥 ', style: TextStyle(fontSize: 14)),
                        Text(
                          '${taskProvider.streakCount} ${lang.t('common.streakDays')}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Week Progress Hero ──
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightPrimary,
                  borderRadius: BorderRadius.circular(22),
                  gradient: isDark
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFF007AFF), Color(0xFF0056D2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : Colors.transparent,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.black : AppColors.lightPrimary)
                          .withValues(alpha: 0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            lang.t('common.weekProgress').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white70,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        Text(
                          '${taskProvider.completionPct}%',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: taskProvider.totalCount > 0
                            ? taskProvider.doneCount / taskProvider.totalCount
                            : 0.0,
                        backgroundColor: Colors.white.withValues(alpha: 0.24),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              const SizedBox(height: 12),

              // ── Weekly Quote Card (>= 44px touch target) ──
              TapScale(
                onTap: () =>
                    _showQuoteDialog(context, taskProvider, lang, isDark),
                borderRadius: BorderRadius.circular(18),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.format_quote_rounded,
                        size: 22,
                        color: AppColors.purple,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          taskProvider.currentWeek?.quote.isNotEmpty == true
                              ? '«${taskProvider.currentWeek!.quote}»'
                              : lang.t('dashboard.quoteHint'),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontStyle: FontStyle.italic,
                            height: 1.35,
                            color: taskProvider.currentWeek?.quote.isNotEmpty ==
                                    true
                                ? (isDark ? Colors.white : Colors.black87)
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
              const SizedBox(height: 16),

              // ── Day Selector (Mon..Sun) ──
              DaySelectorBar(
                weekStartDate: taskProvider.weekStartDate,
                selectedDay: taskProvider.selectedDay,
                tasks: taskProvider.tasks,
                lang: lang,
                onSelectDay: taskProvider.selectDay,
              ),
              const SizedBox(height: 18),

              // ── Day Header & Mobile-Friendly Filter Bar ──
              Text(
                '${dayNames[taskProvider.selectedDay - 1]} (${dayTasks.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _filterPill(
                      'all',
                      lang.t('common.all'),
                      isDark,
                      primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _filterPill(
                      'todo',
                      lang.t('dashboard.filterTodo'),
                      isDark,
                      primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _filterPill(
                      'done',
                      lang.t('dashboard.filterDone'),
                      isDark,
                      primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Tasks List ──
              if (dayTasks.isEmpty)
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    vertical: 32,
                    horizontal: 20,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.checklist_rounded,
                        size: 40,
                        color: isDark ? Colors.white24 : Colors.black12,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        lang.t('week.dayEmpty'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white54 : Colors.black45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AddTaskDialog(
                              defaultDay: taskProvider.selectedDay,
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(lang.t('common.addTask')),
                      ),
                    ],
                  ),
                )
              else
                ...dayTasks.map((task) {
                  return TaskItemWidget(
                    task: task,
                    onEdit: () {
                      showDialog(
                        context: context,
                        builder: (_) => EditTaskDialog(task: task),
                      );
                    },
                  );
                }),
              const SizedBox(height: 16),

              // ── Daily Reflection Card ──
              AppCard(
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
                    const SizedBox(height: 10),
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
                          HapticFeedback.lightImpact();
                          await taskProvider.saveReflection(
                            _reflectionController.text.trim(),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
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
                          minimumSize: const Size(110, 44),
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
              const SizedBox(height: 20),

              // ── Quick Actions Grid (Mobile-First Responsive) ──
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
                  final cols = constraints.maxWidth < 340 ? 2 : 3;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: cols,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: cols == 2 ? 1.45 : 1.08,
                    children: [
                      _quickActionTile(
                        icon: Icons.calendar_month_rounded,
                        label: lang.t('nav.week'),
                        color: AppColors.lightPrimary,
                        onTap: () => widget.onNavigateTab?.call(1),
                      ),
                      _quickActionTile(
                        icon: Icons.auto_awesome_rounded,
                        label: lang.t('nav.assistant'),
                        color: AppColors.purple,
                        onTap: () => widget.onNavigateTab?.call(3),
                      ),
                      _quickActionTile(
                        icon: Icons.bar_chart_rounded,
                        label: lang.t('nav.analytics'),
                        color: AppColors.teal,
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
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _filterPill(
    String id,
    String label,
    bool isDark,
    Color primary,
  ) {
    final active = _taskFilter == id;
    return TapScale(
      onTap: () => setState(() => _taskFilter = id),
      minHeight: 44,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? primary
              : (isDark
                  ? AppColors.darkCard
                  : AppColors.lightCard),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? Colors.transparent
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w600,
            color: active
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
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
      borderRadius: BorderRadius.circular(18),
      child: AppCard(
        padding: const EdgeInsets.all(10),
        borderRadius: 18,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
