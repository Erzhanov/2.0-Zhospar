import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/i18n/language_provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import 'task_form_dialog.dart';

class EditTaskDialog extends StatelessWidget {
  final TaskModel task;

  const EditTaskDialog({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    return TaskFormDialog(
      heading: lang.t('dlg.editTask'),
      submitLabel: lang.t('common.save'),
      initialDay: task.dayOfWeek,
      initialTitle: task.title,
      initialDescription: task.description ?? '',
      initialTime: task.dueTime ?? '',
      initialCategory: task.category,
      initialPriority: task.priority,
      onSubmit: ({
        required int dayOfWeek,
        required String title,
        String? description,
        String? category,
        required String priority,
        String? dueTime,
      }) async {
        await taskProvider.updateTask(
          task.id,
          {
            'day_of_week': dayOfWeek,
            'title': title,
            'description': description,
            'category': category,
            'priority': priority,
            'due_time': dueTime,
          },
        );
      },
    );
  }
}
