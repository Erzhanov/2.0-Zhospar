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

/// Opens a frosted bottom sheet on phones (<600dp) or centered dialog on tablets.
Future<void> showTaskFormModal(
  BuildContext context, {
  int defaultDay = 1,
  TaskModel? taskToEdit,
}) {
  return showAdaptiveModal<void>(
    context,
    builder: (ctx) {
      final lang = Provider.of<LanguageProvider>(ctx);
      final taskProvider = Provider.of<TaskProvider>(ctx, listen: false);
      final isEditing = taskToEdit != null;

      return TaskFormModal(
        heading: isEditing ? lang.t('dlg.editTask') : lang.t('dlg.addTask'),
        submitLabel: isEditing ? lang.t('common.save') : lang.t('common.add'),
        initialDay: taskToEdit?.dayOfWeek ?? defaultDay,
        initialTitle: taskToEdit?.title ?? '',
        initialDescription: taskToEdit?.description ?? '',
        initialTime: taskToEdit?.dueTime ?? '',
        initialCategory: taskToEdit?.category,
        initialPriority: taskToEdit?.priority ?? 'med',
        autofocusTitle: !isEditing,
        requireEditConfirm: isEditing,
        onSubmit: ({
          required int dayOfWeek,
          required String title,
          String? description,
          String? category,
          required String priority,
          String? dueTime,
        }) async {
          if (isEditing) {
            await taskProvider.updateTask(taskToEdit.id, {
              'day_of_week': dayOfWeek,
              'title': title,
              'description': description,
              'category': category,
              'priority': priority,
              'due_time': dueTime,
            });
          } else {
            await taskProvider.addTask(
              dayOfWeek: dayOfWeek,
              title: title,
              description: description,
              category: category,
              priority: priority,
              dueTime: dueTime,
            );
          }
        },
      );
    },
  );
}

/// Platform-adaptive mobile-first Add/Edit task sheet & tablet dialog.
class TaskFormModal extends StatefulWidget {
  final String heading;
  final String submitLabel;
  final int initialDay;
  final String initialTitle;
  final String initialDescription;
  final String initialTime;
  final String? initialCategory;
  final String initialPriority;
  final bool autofocusTitle;
  final bool requireEditConfirm;
  final Future<void> Function({
    required int dayOfWeek,
    required String title,
    String? description,
    String? category,
    required String priority,
    String? dueTime,
  }) onSubmit;

  const TaskFormModal({
    super.key,
    required this.heading,
    required this.submitLabel,
    required this.onSubmit,
    this.initialDay = 1,
    this.initialTitle = '',
    this.initialDescription = '',
    this.initialTime = '',
    this.initialCategory,
    this.initialPriority = 'med',
    this.autofocusTitle = false,
    this.requireEditConfirm = false,
  });

  @override
  State<TaskFormModal> createState() => _TaskFormModalState();
}

class _TaskFormModalState extends State<TaskFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;

  late int _dayOfWeek;
  String? _category;
  late String _priority;
  String? _dueTime;
  bool _submitting = false;

  static const List<String> categories = [
    'Оқу',
    'Жоба',
    'Денсаулық',
    'Үй',
    'Жеке',
    'Жұмыс',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _descController = TextEditingController(text: widget.initialDescription);
    _dayOfWeek = widget.initialDay;
    _category = widget.initialCategory;
    _priority = widget.initialPriority;
    _dueTime = widget.initialTime.trim().isEmpty
        ? null
        : widget.initialTime.trim();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(LanguageProvider lang) async {
    final picked = await showAdaptiveTimePicker(
      context,
      initialTime: _dueTime,
      doneLabel: lang.t('common.doneBtn'),
      cancelLabel: lang.t('common.cancel'),
    );
    if (picked != null && mounted) {
      setState(() => _dueTime = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    if (widget.requireEditConfirm) {
      final lang = Provider.of<LanguageProvider>(context, listen: false);
      final confirmed = await showAdaptiveConfirmDialog(
        context,
        title: lang.t('task.editConfirmTitle'),
        body: lang.t('task.editConfirmBody'),
        confirmLabel: lang.t('common.confirm'),
        cancelLabel: lang.t('common.cancel'),
      );
      if (!confirmed || !mounted) return;
    }
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(
        dayOfWeek: _dayOfWeek,
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        category: _category,
        priority: _priority,
        dueTime: _dueTime,
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final accent = isDark ? AppColors.darkPrimaryBright : primary;
    final isPhone = PlatformAdaptive.isCompactPhone(context);
    final dayShort = lang.getDayShort();

    final categoryOptions = <String>[
      ...categories,
      if (_category != null &&
          _category!.isNotEmpty &&
          !categories.contains(_category))
        _category!,
    ];

    final formBody = Form(
      key: _formKey,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.heading,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  tooltip: lang.t('nav.close'),
                  onPressed: () => Navigator.of(context).pop(),
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _label(lang.t('dlg.taskName'), isDark),
            const SizedBox(height: 6),
            TextFormField(
              controller: _titleController,
              autofocus: widget.autofocusTitle,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: lang.t('dlg.taskHint'),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return lang.t('dlg.taskHint');
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            _label(lang.t('dlg.desc'), isDark),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descController,
              maxLines: 2,
              decoration: InputDecoration(hintText: lang.t('dlg.desc')),
            ),
            const SizedBox(height: 14),

            // 1-tap Day selector pills
            _label(lang.t('dlg.day'), isDark),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final d = i + 1;
                  final active = _dayOfWeek == d;
                  return TapScale(
                    onTap: () {
                      PlatformAdaptive.hapticSelection();
                      setState(() => _dayOfWeek = d);
                    },
                    minWidth: 44,
                    minHeight: 44,
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active
                            ? primary
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: active
                              ? Colors.transparent
                              : AppColors.rimBorder(isDark),
                        ),
                      ),
                      child: Text(
                        dayShort[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: active
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // Native iOS/Android Time Picker
            _label(lang.t('dlg.time'), isDark),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TapScale(
                    onTap: () => _pickTime(lang),
                    minHeight: 46,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.rimBorder(isDark)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 18,
                            color: accent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _dueTime ?? lang.t('common.selectTime'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _dueTime != null
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _dueTime != null
                                  ? null
                                  : (isDark ? Colors.white54 : Colors.black45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_dueTime != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 19),
                    tooltip: lang.t('common.cancel'),
                    onPressed: () => setState(() => _dueTime = null),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // 1-tap Priority segmented pills
            _label(lang.t('dlg.priority'), isDark),
            const SizedBox(height: 8),
            Row(
              children: [
                _priorityChip('low', lang.t('priority.low'), AppColors.teal, isDark),
                const SizedBox(width: 8),
                _priorityChip('med', lang.t('priority.med'), primary, isDark),
                const SizedBox(width: 8),
                _priorityChip(
                  'high',
                  lang.t('priority.high'),
                  AppColors.destructive,
                  isDark,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 1-tap Category pills
            _label(lang.t('dlg.category'), isDark),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categoryOptions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final c = categoryOptions[i];
                  final selected = _category == c;
                  final style = AppColors.getCategoryStyle(c, isDark);
                  final catColor = style['text'] as Color;
                  return TapScale(
                    onTap: () {
                      PlatformAdaptive.hapticSelection();
                      setState(() => _category = selected ? null : c);
                    },
                    minHeight: 44,
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? catColor.withValues(alpha: 0.18)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.04)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? catColor
                              : AppColors.rimBorder(isDark),
                        ),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? catColor : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _submitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
              ),
              child: _submitting
                  ? const AdaptiveLoadingIndicator(color: Colors.white)
                  : Text(
                      widget.submitLabel,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );

    if (isPhone) {
      return Padding(
        padding: EdgeInsets.only(
          left: 10,
          right: 10,
          bottom: MediaQuery.of(context).viewInsets.bottom + 10,
        ),
        child: GlassSurface(
          enableBlur: true,
          borderRadius: 28,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: formBody,
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
            child: formBody,
          ),
        ),
      ),
    );
  }

  Widget _label(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white70 : Colors.black87,
      ),
    );
  }

  Widget _priorityChip(String id, String label, Color color, bool isDark) {
    final active = _priority == id;
    return Expanded(
      child: TapScale(
        onTap: () {
          PlatformAdaptive.hapticSelection();
          setState(() => _priority = id);
        },
        minHeight: 44,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? color.withValues(alpha: isDark ? 0.25 : 0.14)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? color : AppColors.rimBorder(isDark),
              width: active ? 1.4 : 1.0,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? color : null,
            ),
          ),
        ),
      ),
    );
  }
}
