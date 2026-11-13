import 'package:flutter/material.dart';
import '../../../core/i18n/language_provider.dart';
import '../../../core/platform/platform_adaptive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/tap_scale.dart';
import '../../../data/services/reminder_service.dart';

class RemindersCard extends StatelessWidget {
  final LanguageProvider lang;
  final ReminderService reminderService;

  const RemindersCard({
    super.key,
    required this.lang,
    required this.reminderService,
  });

  Future<void> _pickTime(
    BuildContext context,
    String initialTime,
    ValueChanged<String> onSelected,
  ) async {
    final parts = initialTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: int.tryParse(parts[1]) ?? 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null) {
      final hour = picked.hour.toString().padLeft(2, '0');
      final min = picked.minute.toString().padLeft(2, '0');
      onSelected('$hour:$min');
      PlatformAdaptive.hapticSelection();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.glowIndigo.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: AppColors.glowIndigo,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.t('reminders.title'),
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      lang.t('reminders.desc'),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.lightSecondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: reminderService.remindersEnabled,
                activeThumbColor: primary,
                onChanged: reminderService.toggleReminders,
              ),
            ],
          ),

          if (reminderService.remindersEnabled) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Task Due Time Alerts
            _ReminderRow(
              icon: Icons.alarm_rounded,
              title: lang.t('reminders.taskDue'),
              value: reminderService.taskDueAlerts,
              isDark: isDark,
              onChanged: reminderService.toggleTaskDueAlerts,
            ),

            // Morning Reminder
            _ReminderRowWithTime(
              icon: Icons.wb_sunny_outlined,
              title: lang.t('reminders.morning'),
              enabled: reminderService.morningReminder,
              time: reminderService.morningTime,
              isDark: isDark,
              onToggle: reminderService.toggleMorningReminder,
              onPickTime: () => _pickTime(
                context,
                reminderService.morningTime,
                reminderService.setMorningTime,
              ),
            ),

            // Evening Reflection Reminder
            _ReminderRowWithTime(
              icon: Icons.nightlight_outlined,
              title: lang.t('reminders.evening'),
              enabled: reminderService.eveningReminder,
              time: reminderService.eveningTime,
              isDark: isDark,
              onToggle: reminderService.toggleEveningReminder,
              onPickTime: () => _pickTime(
                context,
                reminderService.eveningTime,
                reminderService.setEveningTime,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _ReminderRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDark ? Colors.white70 : Colors.black54),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ReminderRowWithTime extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool enabled;
  final String time;
  final bool isDark;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickTime;

  const _ReminderRowWithTime({
    required this.icon,
    required this.title,
    required this.enabled,
    required this.time,
    required this.isDark,
    required this.onToggle,
    required this.onPickTime,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDark ? Colors.white70 : Colors.black54),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          if (enabled)
            TapScale(
              onTap: onPickTime,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.glowIndigo,
                  ),
                ),
              ),
            ),
          Switch.adaptive(
            value: enabled,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }
}
