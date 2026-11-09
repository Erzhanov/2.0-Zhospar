import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/week_utils.dart';
import '../../providers/task_provider.dart';
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
  final _quoteController = TextEditingController();
  final _reflectionController = TextEditingController();
  bool _isEditingQuote = false;

  @override
  void dispose() {
    _quoteController.dispose();
    _reflectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final weekRange = WeekUtils.formatWeekRange(
      taskProvider.weekStartDate,
      lang.currentLocale,
    );

    // Sync quote controller
    if (!_isEditingQuote && taskProvider.currentWeek != null) {
      _quoteController.text = taskProvider.currentWeek!.quote;
    }

    _reflectionController.text = taskProvider.reflectionText;

    final dayShort = lang.getDayShort();
    final dayNames = lang.getDayNames();
    final selectedDayTasks = taskProvider.selectedDayTasks;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => taskProvider.loadWeek(taskProvider.weekStartDate),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Week Progress Hero ──
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
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : Colors.transparent,
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
                              const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white70),
                              const SizedBox(width: 6),
                              Text(
                                weekRange.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white70,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Text('🔥 ', style: TextStyle(fontSize: 12)),
                                Text(
                                  '${taskProvider.streakCount} күн',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        lang.t('nav.appName'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${taskProvider.totalCount} ${lang.t('common.tasks')} · ${taskProvider.doneCount} ${lang.t('common.done')} · ${taskProvider.completionPct}%',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: taskProvider.totalCount > 0
                              ? taskProvider.doneCount / taskProvider.totalCount
                              : 0.0,
                          backgroundColor: Colors.white.withOpacity(0.25),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Weekly Quote Card ──
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
                              const Icon(Icons.format_quote_rounded, size: 20, color: AppColors.purple),
                              const SizedBox(width: 6),
                              Text(
                                lang.t('dashboard.quote'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          if (_isEditingQuote)
                            GestureDetector(
                              onTap: () async {
                                await taskProvider.saveQuote(_quoteController.text.trim());
                                setState(() => _isEditingQuote = false);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
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
                            )
                          else
                            GestureDetector(
                              onTap: () => setState(() => _isEditingQuote = true),
                              child: const Icon(Icons.edit_outlined, size: 16),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_isEditingQuote)
                        TextField(
                          controller: _quoteController,
                          autofocus: true,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: lang.t('dashboard.quoteHint'),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        )
                      else
                        Text(
                          taskProvider.currentWeek?.quote.isNotEmpty == true
                              ? '«${taskProvider.currentWeek!.quote}»'
                              : lang.t('dashboard.quoteHint'),
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: taskProvider.currentWeek?.quote.isNotEmpty == true
                                ? (isDark ? Colors.white70 : Colors.black87)
                                : (isDark ? Colors.white38 : Colors.black38),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Day Selector (Mon..Sun) ──
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(7, (i) {
                      final dayNum = i + 1;
                      final isSelected = taskProvider.selectedDay == dayNum;
                      final isToday = WeekUtils.isDayToday(taskProvider.weekStartDate, dayNum);
                      final dayDate = WeekUtils.getDayDate(taskProvider.weekStartDate, dayNum);

                      final dayTasks = taskProvider.tasks.where((t) => t.dayOfWeek == dayNum).toList();
                      final dayDone = dayTasks.where((t) => t.isDone).length;

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
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : AppColors.destructive,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              else if (dayTasks.isNotEmpty)
                                Text(
                                  '$dayDone/${dayTasks.length}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white70
                                        : (isDark ? Colors.white38 : Colors.black38),
                                  ),
                                )
                              else
                                const SizedBox(height: 5),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 18),

                // ── Day Header & Add Button ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${dayNames[taskProvider.selectedDay - 1]} (${selectedDayTasks.length})',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AddTaskDialog(defaultDay: taskProvider.selectedDay),
                        );
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(lang.t('common.add')),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Tasks List ──
                if (selectedDayTasks.isEmpty)
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
                        OutlinedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AddTaskDialog(defaultDay: taskProvider.selectedDay),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(lang.t('common.addTask')),
                        ),
                      ],
                    ),
                  )
                else
                  ...selectedDayTasks.map((task) {
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
                const SizedBox(height: 20),

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
                        maxLines: 3,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: lang.t('dashboard.reflectionHint'),
                          filled: true,
                          fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
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
                const SizedBox(height: 24),

                // ── Quick Actions Grid ──
                Text(
                  lang.t('dashboard.quickActions'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.1,
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
                const SizedBox(height: 60),
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
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
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
