import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/week_utils.dart';
import '../../providers/task_provider.dart';
import '../../widgets/task_item_widget.dart';
import '../../widgets/add_task_dialog.dart';
import '../../widgets/edit_task_dialog.dart';

class WeekPlanScreen extends StatefulWidget {
  const WeekPlanScreen({super.key});

  @override
  State<WeekPlanScreen> createState() => _WeekPlanScreenState();
}

class _WeekPlanScreenState extends State<WeekPlanScreen> {
  bool _isAllDaysView = false; // false = by day, true = all 7 days

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final weekRange = WeekUtils.formatWeekRange(
      taskProvider.weekStartDate,
      lang.currentLocale,
    );

    final dayShort = lang.getDayShort();
    final dayNames = lang.getDayNames();
    final selectedDayTasks = taskProvider.selectedDayTasks;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Top Week Switcher ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () => taskProvider.shiftCurrentWeek(-1),
                    tooltip: lang.t('common.prevWeek'),
                  ),
                  GestureDetector(
                    onTap: () => taskProvider.resetToCurrentWeek(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            weekRange,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () => taskProvider.shiftCurrentWeek(1),
                    tooltip: lang.t('common.nextWeek'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Hero Banner with View Mode Toggle ──
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightPrimary,
                  borderRadius: BorderRadius.circular(22),
                  gradient: isDark
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFF007AFF), Color(0xFF0A57C7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          lang.t('week.title'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        // View Toggle Button (By Day vs All Days)
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              _viewToggleButton(
                                icon: Icons.view_day_outlined,
                                label: 'Күн',
                                active: !_isAllDaysView,
                                onTap: () => setState(() => _isAllDaysView = false),
                              ),
                              _viewToggleButton(
                                icon: Icons.view_week_outlined,
                                label: 'Апта',
                                active: _isAllDaysView,
                                onTap: () => setState(() => _isAllDaysView = true),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${taskProvider.totalCount} ${lang.t('common.tasks')} · ${taskProvider.doneCount} ${lang.t('common.done')} · ${taskProvider.completionPct}%',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: taskProvider.totalCount > 0
                            ? taskProvider.doneCount / taskProvider.totalCount
                            : 0.0,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Day Selector (if single day mode) ──
              if (!_isAllDaysView) ...[
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

                // Day Tasks Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${dayNames[taskProvider.selectedDay - 1]} (${selectedDayTasks.length})',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AddTaskDialog(defaultDay: taskProvider.selectedDay),
                        );
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(lang.t('common.addTask')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (selectedDayTasks.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        lang.t('week.dayEmpty'),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
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
              ] else ...[
                // ── All 7 Days Overview List ──
                ...List.generate(7, (i) {
                  final dayNum = i + 1;
                  final dayDate = WeekUtils.getDayDate(taskProvider.weekStartDate, dayNum);
                  final dayTasks = taskProvider.tasks.where((t) => t.dayOfWeek == dayNum).toList();
                  final isToday = WeekUtils.isDayToday(taskProvider.weekStartDate, dayNum);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isToday
                            ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        width: isToday ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${dayNames[i]} · ${dayDate.day}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isToday) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.destructive,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Бүгін',
                                      style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AddTaskDialog(defaultDay: dayNum),
                                );
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        if (dayTasks.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Тапсырма жоқ',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              children: dayTasks.map((t) {
                                return TaskItemWidget(
                                  task: t,
                                  compact: true,
                                  onEdit: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => EditTaskDialog(task: t),
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _viewToggleButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: active ? Colors.black87 : Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: active ? Colors.black87 : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
