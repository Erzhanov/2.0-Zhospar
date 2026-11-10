import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/i18n/language_provider.dart';
import '../core/theme/app_colors.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import 'common/floating_motion.dart';
import 'common/glass_surface.dart';

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
    Color priorityGlow;
    String priorityLabel;

    switch (task.priority) {
      case 'high':
        priorityGlow = AppColors.destructive;
        priorityBg = isDark
            ? AppColors.destructive.withValues(alpha: 0.18)
            : AppColors.priorityHighBg;
        priorityFg = isDark ? const Color(0xFFFDA4AF) : AppColors.priorityHighText;
        priorityLabel = lang.t('priority.high');
        break;
      case 'low':
        priorityGlow = isDark ? Colors.white38 : Colors.black26;
        priorityBg = isDark ? Colors.white10 : AppColors.priorityLowBg;
        priorityFg = isDark ? Colors.white70 : AppColors.priorityLowText;
        priorityLabel = lang.t('priority.low');
        break;
      default:
        priorityGlow = isDark ? AppColors.darkPrimaryBright : AppColors.lightPrimary;
        priorityBg = isDark
            ? AppColors.darkPrimary.withValues(alpha: 0.18)
            : AppColors.priorityMedBg;
        priorityFg =
            isDark ? AppColors.darkPrimaryBright : AppColors.lightPrimary;
        priorityLabel = lang.t('priority.med');
    }

    final catStyle = task.category != null && task.category!.isNotEmpty
        ? AppColors.getCategoryStyle(task.category!, isDark)
        : null;

    final itemWidget = AnimatedOpacity(
      opacity: task.isDone ? 0.65 : 1.0,
      duration: const Duration(milliseconds: 220),
      child: GlassSurface(
        margin: const EdgeInsets.only(bottom: 12),
        borderRadius: 20,
        elevation: task.isDone ? 0.35 : 0.9,
        glowColor: task.isDone ? null : priorityGlow,
        padding: EdgeInsets.symmetric(
          horizontal: 8,
          vertical: compact ? 6 : 10,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 44x44px hit target around buoyant spring checkbox
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
                      duration: const Duration(milliseconds: 240),
                      curve: AppMotion.spring,
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: task.isDone ? AppColors.success : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: task.isDone
                              ? AppColors.success
                              : priorityGlow.withValues(alpha: 0.65),
                          width: 2,
                        ),
                        boxShadow: task.isDone
                            ? [
                                BoxShadow(
                                  color: AppColors.success.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
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

            // Title & Luminous Chips
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
                          height: 1.35,
                          decoration: task.isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: task.isDone
                              ? (isDark ? Colors.white38 : Colors.black38)
                              : (isDark
                                  ? AppColors.darkForeground
                                  : AppColors.lightForeground),
                        ),
                      ),
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
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
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
                                    const SizedBox(width: 4),
                                    Text(
                                      task.dueTime!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.white70
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
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: catStyle['bg'] as Color,
                                  borderRadius: BorderRadius.circular(8),
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
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: priorityBg,
                                borderRadius: BorderRadius.circular(8),
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
      ),
    );

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerLeft,
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 24),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.destructive.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
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
