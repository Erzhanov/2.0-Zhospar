import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/i18n/language_provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/task_provider.dart';

class PlanReviewDialog extends StatefulWidget {
  final List<Map<String, dynamic>> initialTasks;

  const PlanReviewDialog({super.key, required this.initialTasks});

  @override
  State<PlanReviewDialog> createState() => _PlanReviewDialogState();
}

class _PlanReviewDialogState extends State<PlanReviewDialog> {
  late List<Map<String, dynamic>> _tasks;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tasks = List.from(widget.initialTasks);
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dayShort = lang.getDayShort();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      child: Container(
        padding: const EdgeInsets.all(22),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.purple, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      lang.t('assistant.planReady'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${_tasks.length} тапсырма табылды. Төмендегі тізімді тексеріп, апталық кестеңізге енгізіңіз:',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 14),

            // Tasks List
            Expanded(
              child: _tasks.isEmpty
                  ? Center(
                      child: Text(
                        'Тапсырмалар жоқ',
                        style: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _tasks.length,
                      itemBuilder: (context, i) {
                        final t = _tasks[i];
                        final dow = (t['day_of_week'] as int? ?? 1) - 1;
                        final dayLabel = (dow >= 0 && dow < 7) ? dayShort[dow] : 'Дс';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkPrimary.withValues(alpha: 0.2) : AppColors.lightPrimary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  dayLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t['title'] ?? '',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                    if (t['due_time'] != null && (t['due_time'] as String).isNotEmpty)
                                      Text(
                                        t['due_time'],
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? Colors.white54 : Colors.black54,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18),
                                onPressed: () {
                                  setState(() => _tasks.removeAt(i));
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),

            // Add to Plan Button
            ElevatedButton(
              onPressed: _isSaving || _tasks.isEmpty
                  ? null
                  : () async {
                      setState(() => _isSaving = true);
                      for (final t in _tasks) {
                        await taskProvider.addTask(
                          dayOfWeek: t['day_of_week'] ?? 1,
                          title: t['title'] ?? '',
                          description: t['description'],
                          category: t['category'],
                          priority: t['priority'] ?? 'med',
                          dueTime: t['due_time'],
                        );
                      }
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Тапсырмалар апта жоспарына қосылды!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      lang.t('assistant.addTasks'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
