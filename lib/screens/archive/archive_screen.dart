import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/week_utils.dart';
import '../../models/task.dart';
import '../../models/week.dart';
import '../../services/task_service.dart';
import '../../services/week_service.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/mobile_page_container.dart';
import '../../widgets/navigation/top_app_bar.dart';
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
    try {
      final weeks = await _weekService.getAllWeeks();
      final weekIds = weeks.map((w) => w.id).toList();
      final tasksMap = await _taskService.getTasksForWeeks(weekIds);

      if (!mounted) return;
      setState(() {
        _weeks = weeks;
        _weekTasks.addAll(tasksMap);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleExpand(String weekId) async {
    if (_expandedWeekId == weekId) {
      setState(() => _expandedWeekId = null);
      return;
    }

    setState(() => _expandedWeekId = weekId);
    if (!_weekTasks.containsKey(weekId) || _weekTasks[weekId]!.isEmpty) {
      final tasks = await _taskService.getTasksForWeek(weekId);
      if (mounted) {
        setState(() => _weekTasks[weekId] = tasks);
      }
    }
  }

  Future<void> _copyIncomplete(WeekModel week) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final count =
        await _taskService.copyIncompleteTasks(week.id, week.weekStartDate);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count — ${lang.t('archive.copied')}'),
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
      final label = WeekUtils.formatWeekRange(
        w.weekStartDate,
        lang.currentLocale,
      ).toLowerCase();
      final quote = w.quote.toLowerCase();
      return label.contains(q) || quote.contains(q);
    }).toList();

    return Scaffold(
      appBar: TopAppBar(
        title: lang.t('archive.title'),
        isSubPage: true,
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: MobilePageContainer(
                  bottomClearance: 36,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        lang.t('archive.desc'),
                        style: TextStyle(
                          fontSize: 13.5,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: lang.t('common.search'),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (filteredWeeks.isEmpty)
                        AppCard(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              lang.t('common.empty'),
                              style: TextStyle(
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          ),
                        )
                      else
                        ...filteredWeeks.map((week) {
                          final isExpanded = _expandedWeekId == week.id;
                          final tasks = _weekTasks[week.id] ?? [];
                          final total = tasks.length;
                          final done = tasks.where((t) => t.isDone).length;
                          final pct =
                              total > 0 ? ((done / total) * 100).round() : 0;
                          final label = WeekUtils.formatWeekRange(
                            week.weekStartDate,
                            lang.currentLocale,
                          );

                          return AppCard(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: EdgeInsets.zero,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                InkWell(
                                  onTap: () => _toggleExpand(week.id),
                                  borderRadius: BorderRadius.circular(18),
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(minHeight: 72),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 46,
                                            height: 46,
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.white10
                                                  : Colors.black
                                                      .withValues(alpha: 0.04),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              '$pct%',
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  label,
                                                  style: const TextStyle(
                                                    fontSize: 15.5,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  '$total ${lang.t('common.tasks')} · $done ${lang.t('common.done')}',
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    color: isDark
                                                        ? Colors.white54
                                                        : Colors.black54,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            isExpanded
                                                ? Icons.expand_less_rounded
                                                : Icons.expand_more_rounded,
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.black54,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  child: !isExpanded
                                      ? const SizedBox.shrink()
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Divider(height: 1),
                                            Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  if (week.quote.isNotEmpty) ...[
                                                    Text(
                                                      '«${week.quote}»',
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                  ],
                                                  if (tasks.isNotEmpty) ...[
                                                    ...tasks.map(
                                                      (t) => TaskItemWidget(
                                                        task: t,
                                                        compact: true,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                  ],
                                                  OutlinedButton.icon(
                                                    onPressed: () =>
                                                        _copyIncomplete(week),
                                                    icon: const Icon(
                                                      Icons.copy_rounded,
                                                      size: 16,
                                                    ),
                                                    label: Text(
                                                      lang.t(
                                                        'archive.copyToNext',
                                                      ),
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
