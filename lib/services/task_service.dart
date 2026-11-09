import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';
import '../core/utils/week_utils.dart';
import 'week_service.dart';

class TaskService {
  final SupabaseClient _client = Supabase.instance.client;
  final WeekService _weekService = WeekService();

  String? get _userId => _client.auth.currentUser?.id;

  /// Fetch all tasks for a specific week
  Future<List<TaskModel>> getTasksForWeek(String weekId) async {
    final data = await _client
        .from('tasks')
        .select('*')
        .eq('week_id', weekId)
        .order('created_at', ascending: true);

    return (data as List).map((e) => TaskModel.fromJson(e)).toList();
  }

  /// Batch fetch tasks for multiple weeks (avoid N+1)
  Future<Map<String, List<TaskModel>>> getTasksForWeeks(
      List<String> weekIds) async {
    final Map<String, List<TaskModel>> result = {};
    for (final id in weekIds) {
      result[id] = [];
    }
    if (weekIds.isEmpty) return result;

    final data = await _client
        .from('tasks')
        .select('*')
        .inFilter('week_id', weekIds)
        .order('created_at', ascending: true);

    for (final item in data as List) {
      final task = TaskModel.fromJson(item);
      result[task.weekId]?.add(task);
    }
    return result;
  }

  /// Add a new task
  Future<TaskModel?> addTask({
    required String weekId,
    required int dayOfWeek,
    required String title,
    String? description,
    String? category,
    String priority = 'med',
    String? dueTime,
  }) async {
    final uid = _userId;
    if (uid == null) return null;

    final data = await _client
        .from('tasks')
        .insert({
          'user_id': uid,
          'week_id': weekId,
          'day_of_week': dayOfWeek,
          'title': title.trim(),
          'description': description?.trim(),
          'category': category?.trim(),
          'priority': priority,
          'due_time': dueTime?.trim(),
          'status': 'todo',
        })
        .select()
        .single();

    return TaskModel.fromJson(data);
  }

  /// Update task (status, title, due_time, etc.)
  Future<void> updateTask(String id, Map<String, dynamic> updates) async {
    await _client.from('tasks').update(updates).eq('id', id);
  }

  /// Delete a task
  Future<void> deleteTask(String id) async {
    await _client.from('tasks').delete().eq('id', id);
  }

  /// Replace all tasks for a week with new list (used when AI extracts a plan)
  Future<int> replaceTasksForWeek(
    String weekId,
    List<Map<String, dynamic>> tasks,
  ) async {
    final uid = _userId;
    if (uid == null) return 0;

    // Delete existing
    await _client.from('tasks').delete().eq('week_id', weekId);

    // Insert new
    final newTasks = tasks.map((t) => {
          'week_id': weekId,
          'user_id': uid,
          'day_of_week': t['day_of_week'] ?? 1,
          'title': t['title'] ?? '',
          'description': t['description'],
          'category': t['category'],
          'priority': t['priority'] ?? 'med',
          'due_time': t['due_time'],
          'status': 'todo',
        }).toList();

    if (newTasks.isEmpty) return 0;

    final res = await _client.from('tasks').insert(newTasks).select('id');
    return (res as List).length;
  }

  /// Copy incomplete tasks to next week
  Future<int> copyIncompleteTasks(
      String currentWeekId, String currentWeekStartDate) async {
    final uid = _userId;
    if (uid == null) return 0;

    final nextWeekStartDate = WeekUtils.shiftWeek(currentWeekStartDate, 1);
    final nextWeek = await _weekService.getOrCreateWeek(nextWeekStartDate);
    if (nextWeek == null) return 0;

    // Fetch incomplete tasks
    final data = await _client
        .from('tasks')
        .select('*')
        .eq('week_id', currentWeekId)
        .neq('status', 'done');

    final tasks = (data as List).map((e) => TaskModel.fromJson(e)).toList();
    if (tasks.isEmpty) return 0;

    final newTasks = tasks.map((t) => {
          'user_id': uid,
          'week_id': nextWeek.id,
          'day_of_week': t.dayOfWeek,
          'title': t.title,
          'description': t.description,
          'category': t.category,
          'priority': t.priority,
          'due_time': t.dueTime,
          'status': 'todo',
        }).toList();

    await _client.from('tasks').insert(newTasks);
    return newTasks.length;
  }
}
