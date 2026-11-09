import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/week_utils.dart';
import '../../models/week.dart';
import '../../models/task.dart';
import '../../services/week_service.dart';
import '../../services/task_service.dart';
import '../../widgets/task_item_widget.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  final _weekService = WeekService();
  final _taskService = TaskService();

  List<WeekModel> _weeks = [];
  final Map<String, List<TaskModel>> _weekTasks = {};
  String? _expandedWeekId;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadWeeks();
  }

  Future<void> _loadWeeks() async {
    setState(() => _isLoading = true);
    final weeks = await _weekService.getAllWeeks();
    final weekIds = weeks.map((w) => w.id).toList();
    final tasksMap = await _taskService.getTasksForWeeks(weekIds);

    setState(() {
      _weeks = weeks;
      _weekTasks.addAll(tasksMap);
      _isLoading = false;
    });
  }

  Future<void> _toggleExpand(String weekId) async {
    if (_expandedWeekId == weekId) {
      setState(() => _expandedWeekId = null);
      return;
    }

    setState(() => _expandedWeekId = weekId);
    if (!_weekTasks.containsKey(weekId) || _weekTasks[weekId]!.isEmpty) {
      final tasks = await _taskService.getTasksForWeek(weekId);
      setState(() => _weekTasks[weekId] = tasks);
    }
  }

  Future<void> _copyIncomplete(WeekModel week) async {
    final count = await _taskService.copyIncompleteTasks(week.id, week.weekStartDate);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count тапсырма келесі аптаға көшірілді!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredWeeks = _weeks.where((w) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final label = WeekUtils.formatWeekRange(w.weekStartDate, lang.currentLocale).toLowerCase();
      final quote = w.quote.toLowerCase();
      return label.contains(q) || quote.contains(q);
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      lang.t('archive.title'),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lang.t('archive.desc'),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Search Field
                    TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: lang.t('common.search'),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        filled: true,
                        fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Weeks List
                    if (filteredWeeks.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: Text(
                            lang.t('common.empty'),
                            style: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                          ),
                        ),
                      )
                    else
                      ...filteredWeeks.map((week) {
                        final isExpanded = _expandedWeekId == week.id;
                        final tasks = _weekTasks[week.id] ?? [];
                        final total = tasks.length;
                        final done = tasks.where((t) => t.isDone).length;
                        final pct = total > 0 ? ((done / total) * 100).round() : 0;
                        final label = WeekUtils.formatWeekRange(week.weekStartDate, lang.currentLocale);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : AppColors.lightCard,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Week Header Tile
                              InkWell(
                                onTap: () => _toggleExpand(week.id),
                                borderRadius: BorderRadius.circular(18),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$pct%',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              label,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '$total тапсырма · $done орындалды',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? Colors.white54 : Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        isExpanded ? Icons.expand_less : Icons.expand_more,
                                        color: isDark ? Colors.white54 : Colors.black54,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Expanded Details
                              if (isExpanded) ...[
                                const Divider(height: 1),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (week.quote.isNotEmpty) ...[
                                        Text(
                                          '«${week.quote}»',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                      if (tasks.isNotEmpty) ...[
                                        ...tasks.map((t) => TaskItemWidget(task: t, compact: true)),
                                        const SizedBox(height: 8),
                                      ],
                                      OutlinedButton.icon(
                                        onPressed: () => _copyIncomplete(week),
                                        icon: const Icon(Icons.copy_rounded, size: 15),
                                        label: Text(
                                          lang.t('archive.copyToNext'),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
      ),
    );
  }
}
