import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../../core/platform/platform_adaptive.dart';

/// Cross-platform Reminder and Notification service for ZHOSPAR.
/// Manages task due-time alerts, morning plan reminders, and evening reflections.
class ReminderService extends ChangeNotifier {
  static const String _keyRemindersEnabled = 'zhospar_reminders_enabled';
  static const String _keyTaskDueAlerts = 'zhospar_reminders_task_due';
  static const String _keyMorningReminder = 'zhospar_reminders_morning';
  static const String _keyMorningTime = 'zhospar_reminders_morning_time';
  static const String _keyEveningReminder = 'zhospar_reminders_evening';
  static const String _keyEveningTime = 'zhospar_reminders_evening_time';

  bool _remindersEnabled = true;
  bool _taskDueAlerts = true;
  bool _morningReminder = true;
  String _morningTime = '08:30';
  bool _eveningReminder = true;
  String _eveningTime = '21:00';
  bool _initialized = false;

  bool get remindersEnabled => _remindersEnabled;
  bool get taskDueAlerts => _taskDueAlerts;
  bool get morningReminder => _morningReminder;
  String get morningTime => _morningTime;
  bool get eveningReminder => _eveningReminder;
  String get eveningTime => _eveningTime;
  bool get isInitialized => _initialized;

  ReminderService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _remindersEnabled = prefs.getBool(_keyRemindersEnabled) ?? true;
      _taskDueAlerts = prefs.getBool(_keyTaskDueAlerts) ?? true;
      _morningReminder = prefs.getBool(_keyMorningReminder) ?? true;
      _morningTime = prefs.getString(_keyMorningTime) ?? '08:30';
      _eveningReminder = prefs.getBool(_keyEveningReminder) ?? true;
      _eveningTime = prefs.getString(_keyEveningTime) ?? '21:00';
      _initialized = true;
      notifyListeners();
    } catch (_) {
      _initialized = true;
    }
  }

  Future<void> toggleReminders(bool value) async {
    _remindersEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRemindersEnabled, value);
    PlatformAdaptive.hapticSelection();
  }

  Future<void> toggleTaskDueAlerts(bool value) async {
    _taskDueAlerts = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTaskDueAlerts, value);
    PlatformAdaptive.hapticSelection();
  }

  Future<void> toggleMorningReminder(bool value) async {
    _morningReminder = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMorningReminder, value);
    PlatformAdaptive.hapticSelection();
  }

  Future<void> setMorningTime(String time) async {
    _morningTime = time;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMorningTime, time);
  }

  Future<void> toggleEveningReminder(bool value) async {
    _eveningReminder = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEveningReminder, value);
    PlatformAdaptive.hapticSelection();
  }

  Future<void> setEveningTime(String time) async {
    _eveningTime = time;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEveningTime, time);
  }

  /// Check if any task is due at current time and alert the user
  List<TaskModel> getDueTasks(List<TaskModel> todayTasks) {
    if (!_remindersEnabled || !_taskDueAlerts) return [];
    final now = DateTime.now();
    final currentHourMin =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return todayTasks.where((t) {
      if (t.isDone || t.dueTime == null || t.dueTime!.isEmpty) return false;
      return t.dueTime == currentHourMin;
    }).toList();
  }
}
