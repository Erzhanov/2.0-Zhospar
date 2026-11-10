import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/task_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dayShort = lang.getDayShort();

    final total = taskProvider.totalCount;
    final done = taskProvider.doneCount;
    final left = total - done;
    final pct = taskProvider.completionPct;
    final streak = taskProvider.streakCount;

    // Calculate category distribution
    final Map<String, int> categoryCounts = {};
    for (final t in taskProvider.tasks) {
      final cat = (t.category != null && t.category!.isNotEmpty) ? t.category! : 'Басқа';
      categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                lang.t('analytics.title'),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),

              // ── 4 Stat Cards ──
              Row(
                children: [
                  _statCard(
                    title: lang.t('analytics.doneRatio'),
                    value: '$pct%',
                    icon: Icons.pie_chart_outline_rounded,
                    color: AppColors.lightPrimary,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _statCard(
                    title: lang.t('analytics.streak'),
                    value: '$streak ${lang.t('common.streakDays')}',
                    icon: Icons.local_fire_department_rounded,
                    color: AppColors.warning,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _statCard(
                    title: lang.t('analytics.done'),
                    value: '$done',
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _statCard(
                    title: lang.t('analytics.left'),
                    value: '$left',
                    icon: Icons.pending_actions_rounded,
                    color: isDark ? Colors.white54 : Colors.black45,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ── Weekly Chart ──
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(20),
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
                        const Text(
                          'Апталық динамика',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        Row(
                          children: [
                            _legendDot(
                              isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                              lang.t('analytics.done'),
                            ),
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
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 8,
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
                                          color: isDark ? Colors.white54 : Colors.black54,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 2,
                            getDrawingHorizontalLine: (val) => FlLine(
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(7, (i) {
                            final dayNum = i + 1;
                            final dayTasks = taskProvider.tasks.where((t) => t.dayOfWeek == dayNum).toList();
                            final dDone = dayTasks.where((t) => t.isDone).length.toDouble();
                            final dLeft = (dayTasks.length - dDone.toInt()).toDouble();

                            return BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: dDone > 0 ? dDone : 0.2,
                                  color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                                  width: 10,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                BarChartRodData(
                                  toY: dLeft > 0 ? dLeft : 0.2,
                                  color: isDark ? Colors.white24 : Colors.black12,
                                  width: 10,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ── Category Breakdown ──
              if (categoryCounts.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Категориялар бойынша',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 14),
                      ...categoryCounts.entries.map((entry) {
                        final cat = entry.key;
                        final count = entry.value;
                        final pct = total > 0 ? (count / total) : 0.0;
                        final style = AppColors.getCategoryStyle(cat, isDark);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
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
                                      Text(
                                        cat,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '$count (${(pct * 100).round()}%)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white60 : Colors.black54,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                  valueColor: AlwaysStoppedAnimation<Color>(style['text'] as Color),
                                  minHeight: 6,
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
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
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
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                Icon(icon, size: 18, color: color),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
