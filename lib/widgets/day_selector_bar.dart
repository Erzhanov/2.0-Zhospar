import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/i18n/language_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/week_utils.dart';
import '../models/task.dart';
import 'common/floating_motion.dart';

/// Weightless floating 7-day selector pills.
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
    final accent =
        isDark ? AppColors.darkPrimaryBright : AppColors.lightPrimary;
    final dayShort = lang.getDayShort();

    return SizedBox(
      height: 82,
      child: ListView.separated(
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (_, _) => const SizedBox(width: 9),
        itemBuilder: (context, i) {
          final dayNum = i + 1;
          final isSelected = selectedDay == dayNum;
          final isToday = WeekUtils.isDayToday(weekStartDate, dayNum);
          final dayDate = WeekUtils.getDayDate(weekStartDate, dayNum);
          final dayTasksList =
              tasks.where((t) => t.dayOfWeek == dayNum).toList();
          final hasPending = dayTasksList.any((t) => !t.isDone);
          final allDone = dayTasksList.isNotEmpty && !hasPending;

          return Semantics(
            button: true,
            selected: isSelected,
            label: '${dayShort[i]} ${dayDate.day}',
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onSelectDay(dayNum);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: AppMotion.spring,
                transform: Matrix4.translationValues(
                  0,
                  isSelected ? -3.0 : 0.0,
                  0,
                ),
                constraints: const BoxConstraints(minWidth: 52),
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: isDark
                              ? [AppColors.darkPrimary, AppColors.glowTeal]
                              : [AppColors.lightPrimary, const Color(0xFF14B8A6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected
                      ? null
                      : (isDark ? AppColors.darkCard : AppColors.lightCard),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.35)
                        : isToday
                            ? accent.withValues(alpha: 0.55)
                            : AppColors.rimBorder(isDark),
                    width: isToday && !isSelected ? 1.5 : 1.1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.38),
                            blurRadius: 16,
                            spreadRadius: -2,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : AppColors.floatingShadows(
                          isDark: isDark,
                          elevation: 0.5,
                        ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayShort[i],
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.85)
                            : (isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.lightSecondaryText),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dayDate.day}',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? AppColors.darkForeground
                                : AppColors.lightForeground),
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (isToday)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : AppColors.warning,
                          shape: BoxShape.circle,
                        ),
                      )
                    else if (allDone)
                      Icon(
                        Icons.check_rounded,
                        size: 11,
                        color: isSelected ? Colors.white : AppColors.success,
                      )
                    else if (hasPending)
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white70
                              : accent.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
