import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/platform/platform_adaptive.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/mobile_page_container.dart';
import '../../state/task_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final dayShort = lang.getDayShort();

    final total = taskProvider.totalCount;
    final done = taskProvider.doneCount;
    final left = total - done;
    final pct = taskProvider.completionPct;
    final streak = taskProvider.streakCount;

    final Map<String, int> categoryCounts = {};
    for (final t in taskProvider.tasks) {
      final cat = (t.category != null && t.category!.isNotEmpty)
          ? t.category!
          : lang.t('analytics.other');
      categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
    }

    int maxPerDay = 4;
    for (int dayNum = 1; dayNum <= 7; dayNum++) {
      final dayTasks =
          taskProvider.tasks.where((t) => t.dayOfWeek == dayNum).toList();
      final dDone = dayTasks.where((t) => t.isDone).length;
      final dLeft = dayTasks.length - dDone;
      maxPerDay = math.max(maxPerDay, math.max(dDone, dLeft));
    }
    final chartMaxY = (maxPerDay + 2).toDouble();

    final stats = [
      _StatData(
        title: lang.t('analytics.doneRatio'),
        value: '$pct%',
        icon: Icons.pie_chart_outline_rounded,
        color: primary,
      ),
      _StatData(
        title: lang.t('analytics.streak'),
        value: '$streak ${lang.t('common.streakDays')}',
        icon: Icons.local_fire_department_rounded,
        color: AppColors.warning,
      ),
      _StatData(
        title: lang.t('analytics.done'),
        value: '$done',
        icon: Icons.check_circle_outline_rounded,
        color: AppColors.success,
      ),
      _StatData(
        title: lang.t('analytics.left'),
        value: '$left',
        icon: Icons.pending_actions_rounded,
        color: AppColors.purple,
      ),
    ];

    return SingleChildScrollView(
      physics: PlatformAdaptive.scrollPhysics(context),
      child: MobilePageContainer(
        bottomClearance: 100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              lang.t('analytics.title'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 16),

            LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth < 340 ? 1 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: stats.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    mainAxisExtent: 106,
                  ),
                  itemBuilder: (_, i) => _statCard(stats[i], isDark),
                );
              },
            ),
            const SizedBox(height: 18),

            AppCard(
              padding: const EdgeInsets.all(18),
              borderRadius: 22,
              glowColor: primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        lang.t('analytics.weeklyTrend'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _legendDot(primary, lang.t('analytics.done')),
                          const SizedBox(width: 12),
                          _legendDot(
                            isDark ? Colors.white24 : Colors.black12,
                            lang.t('analytics.left'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: RepaintBoundary(
                      child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: chartMaxY,
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                final i = val.toInt();
                                if (i >= 0 && i < 7) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      dayShort[i],
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black54,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 2,
                          getDrawingHorizontalLine: (val) => FlLine(
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.06),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(7, (i) {
                          final dayNum = i + 1;
                          final dayTasks = taskProvider.tasks
                              .where((t) => t.dayOfWeek == dayNum)
                              .toList();
                          final dDone =
                              dayTasks.where((t) => t.isDone).length.toDouble();
                          final dLeft =
                              (dayTasks.length - dDone.toInt()).toDouble();

                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: dDone > 0 ? dDone : 0.2,
                                color: primary,
                                width: 10,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              BarChartRodData(
                                toY: dLeft > 0 ? dLeft : 0.2,
                                color: isDark ? Colors.white24 : Colors.black12,
                                width: 10,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            if (categoryCounts.isNotEmpty)
              AppCard(
                padding: const EdgeInsets.all(18),
                borderRadius: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.t('analytics.byCategory'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...categoryCounts.entries.map((entry) {
                      final cat = entry.key;
                      final count = entry.value;
                      final ratio = total > 0 ? (count / total) : 0.0;
                      final style = AppColors.getCategoryStyle(cat, isDark);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: style['text'] as Color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          cat,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '$count (${(ratio * 100).round()}%)',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ratio,
                                backgroundColor: isDark
                                    ? Colors.white10
                                    : Colors.black.withValues(alpha: 0.05),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  style['text'] as Color,
                                ),
                                minHeight: 7,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(_StatData data, bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 20,
      glowColor: data.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(data.icon, size: 19, color: data.color),
            ],
          ),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _StatData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}
