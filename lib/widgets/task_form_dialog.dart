import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/i18n/language_provider.dart';
import '../core/theme/app_colors.dart';

/// Shared mobile-first Add/Edit task dialog content so both flows reuse the
/// exact same validation, touch targets, and responsive layout.
class TaskFormDialog extends StatefulWidget {
  final String heading;
  final String submitLabel;
  final int initialDay;
  final String initialTitle;
  final String initialDescription;
  final String initialTime;
  final String? initialCategory;
  final String initialPriority;
  final bool autofocusTitle;
  final Future<void> Function({
    required int dayOfWeek,
    required String title,
    String? description,
    String? category,
    required String priority,
    String? dueTime,
  }) onSubmit;

  const TaskFormDialog({
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
  });

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _timeController;

  late int _dayOfWeek;
  String? _category;
  late String _priority;
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
    _timeController = TextEditingController(text: widget.initialTime);
    _dayOfWeek = widget.initialDay;
    _category = widget.initialCategory;
    _priority = widget.initialPriority;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
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
        dueTime: _timeController.text.trim().isEmpty
            ? null
            : _timeController.text.trim(),
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
    final dayNames = lang.getDayNames();
    final isNarrow = MediaQuery.sizeOf(context).width < 380;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  const SizedBox(height: 14),
                  _label(lang.t('dlg.taskName'), isDark),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _titleController,
                    autofocus: widget.autofocusTitle,
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
                  const SizedBox(height: 14),
                  _label(lang.t('dlg.desc'), isDark),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _descController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: lang.t('dlg.desc'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (isNarrow) ...[
                    _dayDropdown(lang, dayNames, isDark),
                    const SizedBox(height: 12),
                    _timeField(lang, isDark),
                    const SizedBox(height: 12),
                    _categoryDropdown(lang, isDark),
                    const SizedBox(height: 12),
                    _priorityDropdown(lang, isDark),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _dayDropdown(lang, dayNames, isDark),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _timeField(lang, isDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _categoryDropdown(lang, isDark)),
                        const SizedBox(width: 12),
                        Expanded(child: _priorityDropdown(lang, isDark)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: _submitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.submitLabel,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ],
              ),
            ),
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

  Widget _dropdownContainer(bool isDark, Widget child) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: DropdownButtonHideUnderline(child: child),
    );
  }

  Widget _dayDropdown(
    LanguageProvider lang,
    List<String> dayNames,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(lang.t('dlg.day'), isDark),
        const SizedBox(height: 6),
        _dropdownContainer(
          isDark,
          DropdownButton<int>(
            value: _dayOfWeek,
            isExpanded: true,
            items: List.generate(7, (i) {
              return DropdownMenuItem(
                value: i + 1,
                child: Text(dayNames[i], style: const TextStyle(fontSize: 14)),
              );
            }),
            onChanged: (v) {
              if (v != null) setState(() => _dayOfWeek = v);
            },
          ),
        ),
      ],
    );
  }

  Widget _timeField(LanguageProvider lang, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(lang.t('dlg.time'), isDark),
        const SizedBox(height: 6),
        TextFormField(
          controller: _timeController,
          decoration: const InputDecoration(hintText: '14:00'),
        ),
      ],
    );
  }

  Widget _categoryDropdown(LanguageProvider lang, bool isDark) {
    final options = <String>[
      ...categories,
      if (_category != null &&
          _category!.isNotEmpty &&
          !categories.contains(_category))
        _category!,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(lang.t('dlg.category'), isDark),
        const SizedBox(height: 6),
        _dropdownContainer(
          isDark,
          DropdownButton<String>(
            value: _category,
            hint: const Text('—', style: TextStyle(fontSize: 13)),
            isExpanded: true,
            items: [
              const DropdownMenuItem(value: null, child: Text('—')),
              ...options.map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(c, style: const TextStyle(fontSize: 13)),
                ),
              ),
            ],
            onChanged: (v) => setState(() => _category = v),
          ),
        ),
      ],
    );
  }

  Widget _priorityDropdown(LanguageProvider lang, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(lang.t('dlg.priority'), isDark),
        const SizedBox(height: 6),
        _dropdownContainer(
          isDark,
          DropdownButton<String>(
            value: _priority,
            isExpanded: true,
            items: [
              DropdownMenuItem(
                value: 'low',
                child: Text(
                  lang.t('priority.low'),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              DropdownMenuItem(
                value: 'med',
                child: Text(
                  lang.t('priority.med'),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              DropdownMenuItem(
                value: 'high',
                child: Text(
                  lang.t('priority.high'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.destructive,
                  ),
                ),
              ),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _priority = v);
            },
          ),
        ),
      ],
    );
  }
}
