import 'package:flutter/material.dart';
import '../../../core/i18n/language_provider.dart';
import '../../../core/platform/platform_adaptive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/week_utils.dart';
import '../../../data/models/task.dart';
import '../../../shared/widgets/floating_motion.dart';

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
      height: 84,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 500;
          if (isWide) {
            return Row(
              children: List.generate(7, (i) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 6 ? 8 : 0),
                    child: _buildPill(context, i, dayShort, isDark, primary, accent),
                  ),
                );
              }),
            );
          }
          return ListView.separated(
            clipBehavior: Clip.none,
            physics: PlatformAdaptive.scrollPhysics(context),
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            separatorBuilder: (_, _) => const SizedBox(width: 9),
            itemBuilder: (context, i) =>
                _buildPill(context, i, dayShort, isDark, primary, accent),
          );
        },
      ),
    );
  }

  Widget _buildPill(
    BuildContext context,
    int i,
    List<String> dayShort,
    bool isDark,
    Color primary,
    Color accent,
  ) {
    final dayNum = i + 1;
    final isSelected = selectedDay == dayNum;
    final isToday = WeekUtils.isDayToday(weekStartDate, dayNum);
    final dayDate = WeekUtils.getDayDate(weekStartDate, dayNum);
    final dayTasksList = tasks.where((t) => t.dayOfWeek == dayNum).toList();
    final doneCount = dayTasksList.where((t) => t.isDone).length;
    final pendingCount = dayTasksList.length - doneCount;
    final allDone = dayTasksList.isNotEmpty && pendingCount == 0;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${dayShort[i]} ${dayDate.day}',
      child: GestureDetector(
        onTap: () {
          PlatformAdaptive.hapticSelection();
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
            horizontal: 12,
            vertical: 9,
          ),
          decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: isDark
                              ? [AppColors.darkPrimary, AppColors.indigo]
                              : [AppColors.lightPrimary, AppColors.teal],
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
              if (allDone)
                Icon(
                  Icons.check_rounded,
                  size: 11,
                  color: isSelected ? Colors.white : AppColors.success,
                )
              else if (dayTasksList.isNotEmpty || isToday)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isToday)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : AppColors.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (isToday && (doneCount > 0 || pendingCount > 0))
                      const SizedBox(width: 3),
                    if (doneCount > 0)
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (doneCount > 0 && pendingCount > 0)
                      const SizedBox(width: 3),
                    if (pendingCount > 0)
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white70
                              : accent.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                )
              else
                const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}
