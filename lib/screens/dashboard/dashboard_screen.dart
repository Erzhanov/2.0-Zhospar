import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/week_utils.dart';
import '../../providers/task_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/task_item_widget.dart';
import '../../widgets/add_task_dialog.dart';
import '../../widgets/edit_task_dialog.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _reflectionController = TextEditingController();
  final _scrollController = ScrollController();
  String _taskFilter = 'all'; // 'all' | 'todo' | 'done'

  @override
  void dispose() {
    _reflectionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showQuoteDialog(BuildContext context, TaskProvider taskProvider, LanguageProvider lang, bool isDark) {
    final quoteController = TextEditingController(text: taskProvider.currentWeek?.quote ?? '');

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
            top: 20,
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
                  const Icon(Icons.format_quote_rounded, color: AppColors.purple, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    lang.t('dashboard.quote'),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await taskProvider.saveQuote(quoteController.text.trim());
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
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

    final weekRange = WeekUtils.formatWeekRange(
      taskProvider.weekStartDate,
      lang.currentLocale,
    );

    _reflectionController.text = taskProvider.reflectionText;

    final dayShort = lang.getDayShort();
    final dayNames = lang.getDayNames();

    // Filter tasks based on selected segment
    var dayTasks = taskProvider.selectedDayTasks;
    if (_taskFilter == 'todo') {
      dayTasks = dayTasks.where((t) => !t.isDone).toList();
    } else if (_taskFilter == 'done') {
      dayTasks = dayTasks.where((t) => t.isDone).toList();
    }

    final userEmail = auth.user?.email ?? '';
    final userName = auth.user?.userMetadata?['display_name'] as String? ??
        (userEmail.isNotEmpty ? userEmail.split('@').first : 'Дос');

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => taskProvider.loadWeek(taskProvider.weekStartDate),
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Top Greeting Bar ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Сәлем, $userName 👋',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          weekRange,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Text('🔥 ', style: TextStyle(fontSize: 14)),
                          Text(
                            '${taskProvider.streakCount} күн',
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
                const SizedBox(height: 14),

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
                        color: (isDark ? Colors.black : AppColors.lightPrimary).withValues(alpha: 0.25),
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
                          Text(
                            lang.t('common.weekProgress').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white70,
                              letterSpacing: 0.6,
                            ),
                          ),
                          Text(
                            '${taskProvider.completionPct}%',
                            style: const TextStyle(
                              fontSize: 16,
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
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 7,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _heroCounter('Жалпы', '${taskProvider.totalCount}'),
                          _heroCounter('Орындалды', '${taskProvider.doneCount}'),
                          _heroCounter('Қалды', '${taskProvider.totalCount - taskProvider.doneCount}'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Weekly Quote Card ──
                GestureDetector(
                  onTap: () => _showQuoteDialog(context, taskProvider, lang, isDark),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.format_quote_rounded, size: 20, color: AppColors.purple),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            taskProvider.currentWeek?.quote.isNotEmpty == true
                                ? '«${taskProvider.currentWeek!.quote}»'
                                : lang.t('dashboard.quoteHint'),
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: taskProvider.currentWeek?.quote.isNotEmpty == true
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
                          size: 16,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Day Selector (Mon..Sun) ──
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(7, (i) {
                      final dayNum = i + 1;
                      final isSelected = taskProvider.selectedDay == dayNum;
                      final isToday = WeekUtils.isDayToday(taskProvider.weekStartDate, dayNum);
                      final dayDate = WeekUtils.getDayDate(taskProvider.weekStartDate, dayNum);

                      final dayTasksList = taskProvider.tasks.where((t) => t.dayOfWeek == dayNum).toList();
                      final dayDoneCount = dayTasksList.where((t) => t.isDone).length;

                      return GestureDetector(
                        onTap: () => taskProvider.selectDay(dayNum),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                                : (isDark ? AppColors.darkCard : AppColors.lightCard),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            children: [
                              Text(
                                dayShort[i],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white70
                                      : (isDark ? Colors.white60 : Colors.black54),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${dayDate.day}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? Colors.white : Colors.black87),
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (isToday)
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : AppColors.destructive,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              else if (dayTasksList.isNotEmpty)
                                Text(
                                  '$dayDoneCount/${dayTasksList.length}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white70
                                        : (isDark ? Colors.white38 : Colors.black38),
                                  ),
                                )
                              else
                                const SizedBox(height: 6),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Day Header & Segmented Filter Bar ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${dayNames[taskProvider.selectedDay - 1]} (${dayTasks.length})',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    // Filter Pills
                    Row(
                      children: [
                        _filterPill('all', lang.t('common.all'), isDark),
                        const SizedBox(width: 4),
                        _filterPill('todo', 'Қалған', isDark),
                        const SizedBox(width: 4),
                        _filterPill('done', 'Дайын', isDark),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Tasks List ──
                if (dayTasks.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
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
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white54 : Colors.black45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AddTaskDialog(defaultDay: taskProvider.selectedDay),
                            );
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: Text(lang.t('common.addTask')),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.edit_note_rounded, size: 20, color: AppColors.teal),
                              const SizedBox(width: 6),
                              Text(
                                '${dayNames[taskProvider.selectedDay - 1]} — ${lang.t('dashboard.reflection')}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () async {
                              await taskProvider.saveReflection(_reflectionController.text.trim());
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Рефлексия сақталды!'),
                                    duration: Duration(seconds: 1),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                lang.t('common.save'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _reflectionController,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: lang.t('dashboard.reflectionHint'),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.black.withValues(alpha: 0.03),
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
                ),
                const SizedBox(height: 20),

                // ── Quick Actions Grid ──
                Text(
                  lang.t('dashboard.quickActions'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.15,
                  children: [
                    _quickActionTile(
                      icon: Icons.calendar_month_rounded,
                      label: lang.t('nav.week'),
                      color: AppColors.lightPrimary,
                      onTap: () => widget.onNavigateTab?.call(1),
                      isDark: isDark,
                    ),
                    _quickActionTile(
                      icon: Icons.auto_awesome_rounded,
                      label: lang.t('nav.assistant'),
                      color: AppColors.purple,
                      onTap: () => widget.onNavigateTab?.call(3),
                      isDark: isDark,
                    ),
                    _quickActionTile(
                      icon: Icons.bar_chart_rounded,
                      label: lang.t('nav.analytics'),
                      color: AppColors.teal,
                      onTap: () => widget.onNavigateTab?.call(2),
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 70),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AddTaskDialog(defaultDay: taskProvider.selectedDay),
          );
        },
        backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
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

  Widget _filterPill(String id, String label, bool isDark) {
    final active = _taskFilter == id;
    return GestureDetector(
      onTap: () => setState(() => _taskFilter = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
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
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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
