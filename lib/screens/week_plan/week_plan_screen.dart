import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/week_utils.dart';
import '../../providers/task_provider.dart';
import '../../widgets/add_task_dialog.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/mobile_page_container.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/day_selector_bar.dart';
import '../../widgets/edit_task_dialog.dart';
import '../../widgets/task_item_widget.dart';

class WeekPlanScreen extends StatefulWidget {
  const WeekPlanScreen({super.key});

  @override
  State<WeekPlanScreen> createState() => _WeekPlanScreenState();
}

class _WeekPlanScreenState extends State<WeekPlanScreen> {
  bool _isAllDaysView = false;

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    final weekRange = WeekUtils.formatWeekRange(
      taskProvider.weekStartDate,
      lang.currentLocale,
    );
    final dayNames = lang.getDayNames();
    final selectedDayTasks = taskProvider.selectedDayTasks;

    return RefreshIndicator(
      onRefresh: () => taskProvider.loadWeek(taskProvider.weekStartDate),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: MobilePageContainer(
          bottomClearance: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Top Week Switcher (>= 44x44px) ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 26),
                    onPressed: () => taskProvider.shiftCurrentWeek(-1),
                    tooltip: lang.t('common.prevWeek'),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  ),
                  Flexible(
                    child: TapScale(
                      onTap: () => taskProvider.resetToCurrentWeek(),
                      minHeight: 44,
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 15),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                weekRange,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 26),
                    onPressed: () => taskProvider.shiftCurrentWeek(1),
                    tooltip: lang.t('common.nextWeek'),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Hero Banner with Responsive View Mode Toggle ──
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
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : Colors.transparent,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        Text(
                          lang.t('week.title'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _viewToggleButton(
                                icon: Icons.view_day_outlined,
                                label: lang.t('week.byDay'),
                                active: !_isAllDaysView,
                                onTap: () =>
                                    setState(() => _isAllDaysView = false),
                              ),
                              _viewToggleButton(
                                icon: Icons.view_week_outlined,
                                label: lang.t('week.allWeek'),
                                active: _isAllDaysView,
                                onTap: () =>
                                    setState(() => _isAllDaysView = true),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (!_isAllDaysView) ...[
                DaySelectorBar(
                  weekStartDate: taskProvider.weekStartDate,
                  selectedDay: taskProvider.selectedDay,
                  tasks: taskProvider.tasks,
                  lang: lang,
                  onSelectDay: taskProvider.selectDay,
                ),
                const SizedBox(height: 18),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${dayNames[taskProvider.selectedDay - 1]} (${selectedDayTasks.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AddTaskDialog(
                            defaultDay: taskProvider.selectedDay,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(lang.t('common.add')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(44, 44),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (selectedDayTasks.isEmpty)
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      vertical: 38,
                      horizontal: 20,
                    ),
                    child: Center(
                      child: Text(
                        lang.t('week.dayEmpty'),
                        textAlign: TextAlign.center,
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
                ...List.generate(7, (i) {
                  final dayNum = i + 1;
                  final dayDate =
                      WeekUtils.getDayDate(taskProvider.weekStartDate, dayNum);
                  final dayTasks = taskProvider.tasks
                      .where((t) => t.dayOfWeek == dayNum)
                      .toList();
                  final isToday =
                      WeekUtils.isDayToday(taskProvider.weekStartDate, dayNum);

                  return AppCard(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.fromLTRB(16, 10, 8, 14),
                    borderColor: isToday ? primary : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      '${dayNames[i]} · ${dayDate.day}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (isToday) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.destructive,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        lang.t('common.today'),
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_rounded, size: 22),
                              tooltip: lang.t('common.addTask'),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) =>
                                      AddTaskDialog(defaultDay: dayNum),
                                );
                              },
                              constraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                              ),
                            ),
                          ],
                        ),
                        if (dayTasks.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              lang.t('week.noTasks'),
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(top: 6, right: 8),
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
    return TapScale(
      onTap: onTap,
      minWidth: 44,
      minHeight: 40,
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: active ? Colors.black87 : Colors.white,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
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
