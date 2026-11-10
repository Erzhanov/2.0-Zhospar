import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/i18n/language_provider.dart';
import '../../../core/platform/platform_adaptive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/task.dart';
import '../../../shared/widgets/floating_motion.dart';
import '../../../shared/widgets/glass_surface.dart';
import '../../../shared/widgets/tap_scale.dart';
import '../../../state/task_provider.dart';

/// Opens the adaptive Task Detail View modal (bottom sheet on phones, dialog on tablets)
/// with bottom Edit and Delete actions guarded by user confirmation.
Future<void> showTaskDetailModal(
  BuildContext context, {
  required TaskModel task,
  VoidCallback? onEdit,
  VoidCallback? onDeleteConfirmed,
}) {
  return showAdaptiveModal<void>(
    context,
    builder: (_) => TaskDetailModal(
      task: task,
      onEdit: onEdit,
      onDeleteConfirmed: onDeleteConfirmed,
    ),
  );
}

class TaskDetailModal extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onEdit;
  final VoidCallback? onDeleteConfirmed;

  const TaskDetailModal({
    super.key,
    required this.task,
    this.onEdit,
    this.onDeleteConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final currentTask = taskProvider.tasks.cast<TaskModel?>().firstWhere(
          (t) => t?.id == task.id,
          orElse: () => task,
        ) ??
        task;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final isPhone = PlatformAdaptive.isCompactPhone(context);
    final dayNames = lang.getDayNames();
    final dayLabel = (currentTask.dayOfWeek >= 1 && currentTask.dayOfWeek <= 7)
        ? dayNames[currentTask.dayOfWeek - 1]
        : '';

    final (priorityBg, priorityFg, priorityLabel) = switch (currentTask.priority) {
      'high' => (
          isDark
              ? AppColors.destructive.withValues(alpha: 0.18)
              : AppColors.priorityHighBg,
          isDark ? const Color(0xFFFF6961) : AppColors.priorityHighText,
          lang.t('priority.high'),
        ),
      'low' => (
          isDark ? Colors.white10 : AppColors.priorityLowBg,
          isDark ? Colors.white70 : AppColors.priorityLowText,
          lang.t('priority.low'),
        ),
      _ => (
          isDark
              ? AppColors.darkPrimary.withValues(alpha: 0.18)
              : AppColors.priorityMedBg,
          isDark ? AppColors.darkPrimaryBright : AppColors.lightPrimary,
          lang.t('priority.med'),
        ),
    };

    final catStyle = currentTask.category != null &&
            currentTask.category!.isNotEmpty
        ? AppColors.getCategoryStyle(currentTask.category!, isDark)
        : null;
    final muted =
        isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;

    final body = SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isPhone)
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          Row(
            children: [
              TapScale(
                onTap: () {
                  PlatformAdaptive.hapticMedium();
                  taskProvider.toggleTaskStatus(currentTask.id);
                },
                minHeight: 36,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: (currentTask.isDone ? AppColors.success : primary)
                        .withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (currentTask.isDone ? AppColors.success : primary)
                          .withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        currentTask.isDone
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 16,
                        color: currentTask.isDone ? AppColors.success : primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        currentTask.isDone
                            ? lang.t('task.statusDone')
                            : lang.t('task.statusTodo'),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color:
                              currentTask.isDone ? AppColors.success : primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 22),
                tooltip: lang.t('nav.close'),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            currentTask.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              decoration:
                  currentTask.isDone ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (dayLabel.isNotEmpty)
                _metaChip(
                  icon: Icons.calendar_today_rounded,
                  label: dayLabel,
                  bg: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  fg: isDark ? Colors.white : Colors.black87,
                ),
              if (currentTask.dueTime != null &&
                  currentTask.dueTime!.isNotEmpty)
                _metaChip(
                  icon: Icons.access_time_rounded,
                  label: currentTask.dueTime!,
                  bg: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  fg: isDark ? Colors.white : Colors.black87,
                ),
              if (catStyle != null)
                _metaChip(
                  icon: Icons.label_outline_rounded,
                  label: currentTask.category!,
                  bg: catStyle['bg'] as Color,
                  fg: catStyle['text'] as Color,
                ),
              _metaChip(
                icon: Icons.flag_outlined,
                label: priorityLabel,
                bg: priorityBg,
                fg: priorityFg,
              ),
            ],
          ),
          const SizedBox(height: 16),

          GlassSurface(
            borderRadius: 16,
            elevation: 0,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.t('task.view'),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  currentTask.description != null &&
                          currentTask.description!.trim().isNotEmpty
                      ? currentTask.description!.trim()
                      : lang.t('task.noDesc'),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: currentTask.description != null &&
                            currentTask.description!.trim().isNotEmpty
                        ? (isDark
                            ? AppColors.darkForeground
                            : AppColors.lightForeground)
                        : muted,
                    fontStyle: currentTask.description != null &&
                            currentTask.description!.trim().isNotEmpty
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Bottom Edit & Delete action bar (both guarded with confirmation)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('task-detail-delete'),
                  onPressed: () async {
                    PlatformAdaptive.hapticMedium();
                    final confirmed = await showAdaptiveConfirmDialog(
                      context,
                      title: lang.t('task.deleteConfirmTitle'),
                      body: lang.t('task.deleteConfirmBody'),
                      confirmLabel: lang.t('common.delete'),
                      cancelLabel: lang.t('common.cancel'),
                      destructive: true,
                    );
                    if (!confirmed || !context.mounted) return;
                    Navigator.of(context).pop();
                    onDeleteConfirmed?.call();
                  },
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: AppColors.destructive,
                  ),
                  label: Text(
                    lang.t('common.delete'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.destructive,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    side: BorderSide(
                      color: AppColors.destructive.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              if (onEdit != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey('task-detail-edit'),
                    onPressed: () {
                      PlatformAdaptive.hapticSelection();
                      Navigator.of(context).pop();
                      onEdit!.call();
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(
                      lang.t('common.edit'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (isPhone) {
      return Padding(
        padding: EdgeInsets.only(
          left: 10,
          right: 10,
          bottom: MediaQuery.of(context).padding.bottom + 10,
        ),
        child: GlassSurface(
          enableBlur: true,
          borderRadius: 28,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: body,
        ),
      );
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: SpringPopIn(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: GlassSurface(
            enableBlur: true,
            borderRadius: 28,
            padding: const EdgeInsets.all(22),
            child: body,
          ),
        ),
      ),
    );
  }

  Widget _metaChip({
    required IconData icon,
    required String label,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
