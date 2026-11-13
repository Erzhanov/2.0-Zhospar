import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

/// Service managing synchronization of ZHOSPAR data to iOS WidgetKit and Android AppWidget.
class WidgetDataService {
  static const String keyWidgetDate = 'zhospar_widget_date';
  static const String keyWidgetStreak = 'zhospar_widget_streak';
  static const String keyWidgetTotal = 'zhospar_widget_total';
  static const String keyWidgetDone = 'zhospar_widget_done';
  static const String keyWidgetPct = 'zhospar_widget_pct';
  static const String keyWidgetTasksJson = 'zhospar_widget_tasks_json';

  static const MethodChannel _platformChannel =
      MethodChannel('com.zhospar.zhospar_app/widget');

  /// Update widget data snapshot in persistent storage and trigger native widget refresh
  static Future<void> syncWidgetData({
    required String dateFormatted,
    required List<TaskModel> todayTasks,
    required int streak,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final total = todayTasks.length;
      final done = todayTasks.where((t) => t.isDone).length;
      final pct = total > 0 ? ((done / total) * 100).round() : 0;

      final taskListSummary = todayTasks.map((t) => {
        'id': t.id,
        'title': t.title,
        'time': t.dueTime ?? '',
        'category': t.category ?? '',
        'priority': t.priority,
        'isDone': t.isDone,
      }).toList();

      await prefs.setString(keyWidgetDate, dateFormatted);
      await prefs.setInt(keyWidgetStreak, streak);
      await prefs.setInt(keyWidgetTotal, total);
      await prefs.setInt(keyWidgetDone, done);
      await prefs.setInt(keyWidgetPct, pct);
      await prefs.setString(keyWidgetTasksJson, jsonEncode(taskListSummary));

      // Attempt to notify native Android/iOS widget host
      try {
        await _platformChannel
            .invokeMethod('updateWidget')
            .timeout(const Duration(milliseconds: 200));
      } catch (_) {
        // Platform channel may not be registered in tests or on web
      }
    } catch (_) {
      // Best-effort
    }
  }

  /// Read current widget snapshot for in-app preview
  static Future<Map<String, dynamic>> getWidgetSnapshot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final date = prefs.getString(keyWidgetDate) ?? 'Бүгін';
      final streak = prefs.getInt(keyWidgetStreak) ?? 0;
      final total = prefs.getInt(keyWidgetTotal) ?? 0;
      final done = prefs.getInt(keyWidgetDone) ?? 0;
      final pct = prefs.getInt(keyWidgetPct) ?? 0;
      final rawTasks = prefs.getString(keyWidgetTasksJson);
      List<dynamic> tasks = [];
      if (rawTasks != null && rawTasks.isNotEmpty) {
        tasks = jsonDecode(rawTasks) as List;
      }
      return {
        'date': date,
        'streak': streak,
        'total': total,
        'done': done,
        'pct': pct,
        'tasks': tasks,
      };
    } catch (_) {
      return {
        'date': 'Бүгін',
        'streak': 0,
        'total': 0,
        'done': 0,
        'pct': 0,
        'tasks': [],
      };
    }
  }

  /// Request native OS to pin widget directly to Home Screen (supported on Android 8.0+)
  static Future<bool> requestPinWidget({String size = 'medium'}) async {
    try {
      final res = await _platformChannel
          .invokeMethod<bool>('pinWidget', {'size': size})
          .timeout(const Duration(milliseconds: 500));
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}
