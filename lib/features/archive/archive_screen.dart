import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/router/app_routes.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/platform/platform_adaptive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/week_utils.dart';
import '../../data/models/task.dart';
import '../../data/models/week.dart';
import '../../data/services/task_service.dart';
import '../../data/services/week_service.dart';
import '../../shared/widgets/ambient_space_background.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/floating_motion.dart';
import '../../shared/widgets/glass_surface.dart';
import '../../shared/widgets/mobile_page_container.dart';
import '../../shared/widgets/tap_scale.dart';
import '../../state/task_provider.dart';
import '../dashboard/widgets/task_item_widget.dart';
import '../shell/widgets/top_app_bar.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({
    super.key,
    this.weekService,
    this.taskService,
  });

  final WeekService? weekService;
  final TaskService? taskService;

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  late final WeekService _weekService;
  late final TaskService _taskService;
  final _searchController = TextEditingController();

  List<WeekModel> _weeks = [];
  Map<String, List<TaskModel>> _tasksByWeek = {};
  final Set<String> _expandedWeekIds = {};
  bool _isLoading = true;
  String? _copyingWeekId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _weekService = widget.weekService ?? WeekService();
    _taskService = widget.taskService ?? TaskService();
    _loadArchive();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadArchive() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final weeks = await _weekService.getAllWeeks();
      final tasksMap = weeks.isEmpty
          ? <String, List<TaskModel>>{}
          : await _taskService.getTasksForWeeks(
              weeks.map((w) => w.id).toList(),
            );

      final nonEmptyWeeks = weeks
          .where((w) => (tasksMap[w.id] ?? const <TaskModel>[]).isNotEmpty)
          .toList();

      if (!mounted) return;
      setState(() {
        _weeks = nonEmptyWeeks;
        _tasksByWeek = tasksMap;
        if (_expandedWeekIds.isEmpty && nonEmptyWeeks.isNotEmpty) {
          _expandedWeekIds.add(nonEmptyWeeks.first.id);
        }
      });
    } catch (_) {
      // Preserve clean fallback UI
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _copyIncomplete(WeekModel week) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    PlatformAdaptive.hapticMedium();
    setState(() => _copyingWeekId = week.id);
    try {
      final copied = await _taskService.copyIncompleteTasks(
        week.id,
        week.weekStartDate,
      );
      await taskProvider.loadWeek(taskProvider.weekStartDate);
      await _loadArchive();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('${lang.t('archive.copied')} ($copied)'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _copyingWeekId = null);
      }
    }
  }

  void _toggleWeek(String weekId) {
    PlatformAdaptive.hapticSelection();
    setState(() {
      if (_expandedWeekIds.contains(weekId)) {
        _expandedWeekIds.remove(weekId);
      } else {
        _expandedWeekIds.add(weekId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary =
        isDark ? AppColors.darkPrimaryBright : AppColors.lightPrimary;
    final muted =
        isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final query = _searchQuery.trim().toLowerCase();
    final totalAllTasks = _tasksByWeek.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );
    final doneAllTasks = _tasksByWeek.values.fold<int>(
      0,
      (sum, list) => sum + list.where((t) => t.isDone).length,
    );
    final avgRate = totalAllTasks > 0
        ? ((doneAllTasks / totalAllTasks) * 100).round()
        : 0;

    final filteredWeeks = _weeks.where((week) {
      if (query.isEmpty) return true;
      final rangeLabel = WeekUtils.formatWeekRange(
        week.weekStartDate,
        lang.currentLocale,
      ).toLowerCase();
      if (rangeLabel.contains(query) ||
          week.weekStartDate.toLowerCase().contains(query) ||
          week.quote.toLowerCase().contains(query)) {
        return true;
      }
      final tasks = _tasksByWeek[week.id] ?? const <TaskModel>[];
      return tasks.any(
        (t) =>
            t.title.toLowerCase().contains(query) ||
            (t.category?.toLowerCase().contains(query) ?? false) ||
            (t.description?.toLowerCase().contains(query) ?? false),
      );
    }).toList();

    return AmbientSpaceBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: TopAppBar(
          title: lang.t('archive.title'),
          isSubPage: true,
        ),
        body: _isLoading
            ? Center(child: AdaptiveLoadingIndicator(color: primary))
            : RefreshIndicator.adaptive(
                onRefresh: _loadArchive,
                child: SingleChildScrollView(
                  physics: PlatformAdaptive.scrollPhysics(context),
                  child: MobilePageContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          lang.t('archive.desc'),
                          style: TextStyle(fontSize: 13.5, color: muted),
                        ),
                        if (_weeks.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _ArchiveMetricPill(
                                  value: '${_weeks.length}',
                                  label: lang.t('archive.weeksCount'),
                                  color: primary,
                                  muted: muted,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _ArchiveMetricPill(
                                  value: '$avgRate%',
                                  label: lang.t('archive.avgRate'),
                                  color: AppColors.glowIndigo,
                                  muted: muted,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _ArchiveMetricPill(
                                  value: '$doneAllTasks',
                                  label: lang.t('common.done'),
                                  color: AppColors.success,
                                  muted: muted,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 14),
                        GlassSurface(
                          borderRadius: 18,
                          elevation: 0.7,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) => setState(() => _searchQuery = v),
                            decoration: InputDecoration(
                              hintText: lang.t('common.search'),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              icon: Icon(
                                Icons.search_rounded,
                                size: 20,
                                color: muted,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close_rounded,
                                          size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (filteredWeeks.isEmpty)
                          SpringPopIn(
                            child: AppCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 34,
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: primary.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.inventory_2_outlined,
                                      size: 28,
                                      color: primary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    lang.t('common.empty'),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...filteredWeeks.map((week) {
                            final allTasks =
                                _tasksByWeek[week.id] ?? const <TaskModel>[];
                            final visibleTasks = query.isEmpty
                                ? allTasks
                                : allTasks.where((t) {
                                    return t.title
                                            .toLowerCase()
                                            .contains(query) ||
                                        (t.category
                                                ?.toLowerCase()
                                                .contains(query) ??
                                            false) ||
                                        (t.description
                                                ?.toLowerCase()
                                                .contains(query) ??
                                            false);
                                  }).toList();
                            final tasksToShow =
                                visibleTasks.isEmpty && query.isNotEmpty
                                    ? allTasks
                                    : visibleTasks;
                            final doneCount =
                                allTasks.where((t) => t.isDone).length;
                            final totalCount = allTasks.length;
                            final pct = totalCount > 0
                                ? ((doneCount / totalCount) * 100).round()
                                : 0;
                            final incompleteCount = totalCount - doneCount;
                            final isExpanded = query.isNotEmpty ||
                                _expandedWeekIds.contains(week.id);
                            final weekLabel = WeekUtils.formatWeekRange(
                              week.weekStartDate,
                              lang.currentLocale,
                            );

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: SpringPopIn(
                                child: AppCard(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      TapScale(
                                        onTap: () => _toggleWeek(week.id),
                                        borderRadius: BorderRadius.circular(14),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: primary.withValues(
                                                    alpha: 0.14),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Icons.calendar_month_rounded,
                                                color: primary,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    weekLabel,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '$doneCount/$totalCount ${lang.t('common.done')}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: muted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: (pct >= 75
                                                        ? AppColors.success
                                                        : primary)
                                                    .withValues(alpha: 0.14),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '$pct%',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                  color: pct >= 75
                                                      ? AppColors.success
                                                      : primary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            AnimatedRotation(
                                              turns: isExpanded ? 0.5 : 0.0,
                                              duration: const Duration(
                                                  milliseconds: 220),
                                              curve: AppMotion.smooth,
                                              child: Icon(
                                                Icons.expand_more_rounded,
                                                color: muted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isExpanded) ...[
                                        if (week.quote.isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          GlassSurface(
                                            borderRadius: 14,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.format_quote_rounded,
                                                  size: 16,
                                                  color: primary,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    week.quote,
                                                    style: TextStyle(
                                                      fontSize: 12.5,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                      color: muted,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 12),
                                        if (tasksToShow.isEmpty)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10),
                                            child: Text(
                                              lang.t('week.noTasks'),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: muted,
                                              ),
                                            ),
                                          )
                                        else
                                          ...tasksToShow.map(
                                            (task) => TaskItemWidget(
                                              key: ValueKey<String>(task.id),
                                              task: task,
                                              compact: true,
                                            ),
                                          ),
                                        if (incompleteCount > 0) ...[
                                          const SizedBox(height: 6),
                                          OutlinedButton.icon(
                                            onPressed: _copyingWeekId == week.id
                                                ? null
                                                : () => _copyIncomplete(week),
                                            icon: _copyingWeekId == week.id
                                                ? AdaptiveLoadingIndicator(
                                                    radius: 9,
                                                    color: primary,
                                                  )
                                                : const Icon(
                                                    Icons.forward_to_inbox_rounded,
                                                    size: 18,
                                                  ),
                                            label: Text(
                                              '${lang.t('archive.copyToNext')} ($incompleteCount)',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              minimumSize: const Size(0, 44),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 6),
                                        TextButton.icon(
                                          onPressed: () async {
                                            final tp = Provider.of<TaskProvider>(
                                              context,
                                              listen: false,
                                            );
                                            PlatformAdaptive.hapticSelection();
                                            await tp.loadWeek(
                                              week.weekStartDate,
                                            );
                                            if (context.mounted) {
                                              Navigator.of(context)
                                                  .pushNamedAndRemoveUntil(
                                                AppRoutes.week,
                                                (_) => false,
                                              );
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.open_in_new_rounded,
                                            size: 17,
                                          ),
                                          label: Text(
                                            lang.t('archive.openInPlanner'),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _ArchiveMetricPill extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final Color muted;

  const _ArchiveMetricPill({
    required this.value,
    required this.label,
    required this.color,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: 16,
      elevation: 0.6,
      glowColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }
}
