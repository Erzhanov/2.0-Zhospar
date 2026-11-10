import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/i18n/language_provider.dart';
import '../providers/task_provider.dart';
import 'task_form_dialog.dart';

class AddTaskDialog extends StatelessWidget {
  final int defaultDay;

  const AddTaskDialog({super.key, this.defaultDay = 1});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    return TaskFormDialog(
      heading: lang.t('dlg.addTask'),
      submitLabel: lang.t('common.add'),
      initialDay: defaultDay,
      autofocusTitle: true,
      onSubmit: ({
        required int dayOfWeek,
        required String title,
        String? description,
        String? category,
        required String priority,
        String? dueTime,
      }) async {
        await taskProvider.addTask(
          dayOfWeek: dayOfWeek,
          title: title,
          description: description,
          category: category,
          priority: priority,
          dueTime: dueTime,
        );
      },
    );
  }
}
