import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/i18n/language_provider.dart';
import '../core/theme/app_colors.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class TaskItemWidget extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onEdit;
  final bool compact;

  const TaskItemWidget({
    super.key,
    required this.task,
    this.onEdit,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color priorityBg;
    Color priorityFg;
    String priorityLabel;

    switch (task.priority) {
      case 'high':
        priorityBg = isDark
            ? AppColors.destructive.withValues(alpha: 0.2)
            : AppColors.priorityHighBg;
        priorityFg = AppColors.destructive;
        priorityLabel = lang.t('priority.high');
        break;
      case 'low':
        priorityBg = isDark ? Colors.white10 : AppColors.priorityLowBg;
        priorityFg = isDark ? Colors.white70 : AppColors.priorityLowText;
        priorityLabel = lang.t('priority.low');
        break;
      default:
        priorityBg = isDark
            ? AppColors.darkPrimary.withValues(alpha: 0.2)
            : AppColors.priorityMedBg;
        priorityFg = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
        priorityLabel = lang.t('priority.med');
    }

    final catStyle = task.category != null && task.category!.isNotEmpty
        ? AppColors.getCategoryStyle(task.category!, isDark)
        : null;

    final itemWidget = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: compact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: task.isDone
            ? (isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.025))
            : (isDark ? AppColors.darkCard : AppColors.lightCard),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: task.isDone
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 44x44px hit target around 24x24 visual checkbox
          Semantics(
            checked: task.isDone,
            label: task.title,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.lightImpact();
                taskProvider.toggleTaskStatus(task.id);
              },
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: task.isDone ? AppColors.success : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: task.isDone
                            ? AppColors.success
                            : (isDark ? Colors.white38 : Colors.black26),
                        width: 2,
                      ),
                    ),
                    child: task.isDone
                        ? const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Title & Details
          Expanded(
            child: GestureDetector(
              onTap: onEdit,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        decoration: task.isDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: task.isDone
                            ? (isDark ? Colors.white38 : Colors.black38)
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    if ((task.description != null &&
                            task.description!.isNotEmpty) ||
                        (task.dueTime != null && task.dueTime!.isNotEmpty) ||
                        (task.category != null && task.category!.isNotEmpty))
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (task.dueTime != null &&
                                task.dueTime!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 12,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.black54,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      task.dueTime!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.white60
                                            : Colors.black54,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (task.category != null &&
                                task.category!.isNotEmpty &&
                                catStyle != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: catStyle['bg'] as Color,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  task.category!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: catStyle['text'] as Color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: priorityBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                priorityLabel,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: priorityFg,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Touch-friendly Action Buttons (>= 44x44px)
          if (onEdit != null)
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                size: 19,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
              tooltip: lang.t('common.edit'),
              onPressed: onEdit,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 19,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
            tooltip: lang.t('common.delete'),
            onPressed: () {
              HapticFeedback.mediumImpact();
              taskProvider.deleteTask(task.id);
            },
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ],
      ),
    );

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerLeft,
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 24),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.destructive,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          HapticFeedback.mediumImpact();
          taskProvider.toggleTaskStatus(task.id);
          return false;
        } else {
          HapticFeedback.heavyImpact();
          taskProvider.deleteTask(task.id);
          return true;
        }
      },
      child: itemWidget,
    );
  }
}
