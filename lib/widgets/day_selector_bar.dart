import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/i18n/language_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/week_utils.dart';
import '../models/task.dart';

/// Shared horizontal 7-day selector used by Dashboard and WeekPlan screens.
class DaySelectorBar extends StatelessWidget {
  final String weekStartDate;
  final int selectedDay;
  final List<TaskModel> tasks;
  final LanguageProvider lang;
  final ValueChanged<int> onSelectDay;

  const DaySelectorBar({
    super.key,
    required this.weekStartDate,
    required this.selectedDay,
    required this.tasks,
    required this.lang,
    required this.onSelectDay,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final dayShort = lang.getDayShort();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(7, (i) {
          final dayNum = i + 1;
          final isSelected = selectedDay == dayNum;
          final isToday = WeekUtils.isDayToday(weekStartDate, dayNum);
          final dayDate = WeekUtils.getDayDate(weekStartDate, dayNum);
          final dayTasksList =
              tasks.where((t) => t.dayOfWeek == dayNum).toList();
          final dayDoneCount = dayTasksList.where((t) => t.isDone).length;

          return Padding(
            padding: EdgeInsets.only(right: i == 6 ? 0 : 8),
            child: Semantics(
              button: true,
              selected: isSelected,
              label: '${dayShort[i]} ${dayDate.day}',
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelectDay(dayNum);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  constraints: const BoxConstraints(
                    minWidth: 52,
                    minHeight: 72,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primary
                        : (isDark ? AppColors.darkCard : AppColors.lightCard),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : (isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
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
                            color: isSelected
                                ? Colors.white
                                : AppColors.destructive,
                            shape: BoxShape.circle,
                          ),
                        )
                      else if (dayTasksList.isNotEmpty)
                        Text(
                          '$dayDoneCount/${dayTasksList.length}',
                          style: TextStyle(
                            fontSize: 10,
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
              ),
            ),
          );
        }),
      ),
    );
  }
}
