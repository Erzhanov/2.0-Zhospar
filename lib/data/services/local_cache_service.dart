import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/week.dart';

/// Offline-first cache and sync queue manager for ZHOSPAR.
/// Caches weeks and tasks locally, queues offline mutations,
/// and synchronizes when the network is available.
class LocalCacheService {
  static const String _tasksPrefix = 'zhospar_offline_tasks_';
  static const String _weeksPrefix = 'zhospar_offline_week_';
  static const String _pendingSyncKey = 'zhospar_pending_sync_queue';
  static const String _lastSyncKey = 'zhospar_last_sync_timestamp';

  /// Save tasks for a specific week to local storage
  static Future<void> cacheTasksForWeek(String weekId, List<TaskModel> tasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = tasks.map((t) => t.toJson()).toList();
      await prefs.setString('$_tasksPrefix$weekId', jsonEncode(jsonList));
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (_) {
      // Best-effort local caching
    }
  }

  /// Retrieve cached tasks for a week if offline
  static Future<List<TaskModel>?> getCachedTasksForWeek(String weekId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_tasksPrefix$weekId');
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => TaskModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return null;
    }
  }

  /// Cache a week record
  static Future<void> cacheWeek(WeekModel week) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_weeksPrefix${week.weekStartDate}', jsonEncode(week.toJson()));
    } catch (_) {
      // Best-effort
    }
  }

  /// Retrieve cached week
  static Future<WeekModel?> getCachedWeek(String weekStartDate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_weeksPrefix$weekStartDate');
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return WeekModel.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Queue an offline mutation (add, update, delete) to sync later
  static Future<void> queueMutation({
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = await getPendingMutations();
      queue.add({
        'action': action,
        'payload': payload,
        'timestamp': DateTime.now().toIso8601String(),
      });
      await prefs.setString(_pendingSyncKey, jsonEncode(queue));
    } catch (_) {}
  }

  /// Get pending offline mutations
  static Future<List<Map<String, dynamic>>> getPendingMutations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_pendingSyncKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Clear synced mutations
  static Future<void> clearPendingMutations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingSyncKey);
    } catch (_) {}
  }

  /// Count of pending offline operations
  static Future<int> pendingCount() async {
    final queue = await getPendingMutations();
    return queue.length;
  }
}
