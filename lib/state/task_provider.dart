import 'package:flutter/material.dart';
import '../core/utils/week_utils.dart';
import '../data/models/task.dart';
import '../data/models/week.dart';
import '../data/services/task_service.dart';
import '../data/services/week_service.dart';

class TaskProvider extends ChangeNotifier {
  final TaskService _taskService;
  final WeekService _weekService;

  String _weekStartDate = WeekUtils.getWeekStartDate();
  WeekModel? _currentWeek;
  List<TaskModel> _tasks = [];
  int _selectedDay = WeekUtils.getTodayDayOfWeek();
  String _reflectionText = '';
  bool _isLoading = false;
  int _streakCount = 0;
  String? _activeUserId;

  String get weekStartDate => _weekStartDate;
  WeekModel? get currentWeek => _currentWeek;
  List<TaskModel> get tasks => _tasks;
  int get selectedDay => _selectedDay;
  String get reflectionText => _reflectionText;
  bool get isLoading => _isLoading;
  int get streakCount => _streakCount;

  List<TaskModel> get selectedDayTasks =>
      _tasks.where((t) => t.dayOfWeek == _selectedDay).toList();

  int get doneCount => _tasks.where((t) => t.isDone).length;
  int get totalCount => _tasks.length;
  int get completionPct =>
      totalCount > 0 ? ((doneCount / totalCount) * 100).round() : 0;

  TaskProvider({
    TaskService? taskService,
    WeekService? weekService,
  })  : _taskService = taskService ?? TaskService(),
        _weekService = weekService ?? WeekService();

  void syncAuthUser(String? userId) {
    if (userId == _activeUserId) return;
    _activeUserId = userId;

    if (userId == null) {
      _currentWeek = null;
      _tasks = [];
      _reflectionText = '';
      _streakCount = 0;
      _isLoading = false;
      notifyListeners();
      return;
    }

    loadWeek(_weekStartDate);
  }

  void selectDay(int day) {
    if (day < 1 || day > 7 || day == _selectedDay) return;
    _selectedDay = day;
    notifyListeners();
    _loadReflectionForSelectedDay();
  }

  Future<void> shiftCurrentWeek(int deltaWeeks) async {
    final nextStartDate = WeekUtils.shiftWeek(_weekStartDate, deltaWeeks);
    await loadWeek(nextStartDate);
  }

  Future<void> resetToCurrentWeek() async {
    final todayStart = WeekUtils.getWeekStartDate();
    await loadWeek(todayStart);
  }

  Future<void> loadWeek(String wsd) async {
    _isLoading = true;
    _weekStartDate = wsd;
    notifyListeners();

    try {
      final week = await _weekService.getOrCreateWeek(wsd);
      _currentWeek = week;

      if (week != null) {
        _tasks = await _taskService.getTasksForWeek(week.id);
        await _loadReflectionForSelectedDay(notify: false);
        await _calculateStreak();
      } else {
        _tasks = [];
        _reflectionText = '';
      }
    } catch (_) {
      // Preserve current state cleanly on transient errors
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadReflectionForSelectedDay({bool notify = true}) async {
    if (_currentWeek == null) {
      _reflectionText = '';
      return;
    }
    final ref = await _weekService.getReflection(_currentWeek!.id, _selectedDay);
    _reflectionText = ref?.text ?? '';
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> _calculateStreak() async {
    try {
      final allWeeks = await _weekService.getAllWeeks();
      if (allWeeks.isEmpty) {
        _streakCount = 0;
        return;
      }
      final weekIds = allWeeks.map((w) => w.id).toList();
      final map = await _taskService.getTasksForWeeks(weekIds);

      final completedDates = <String>{};
      for (final w in allWeeks) {
        final wTasks = map[w.id] ?? [];
        for (final t in wTasks) {
          if (t.isDone) {
            final taskDate = WeekUtils.getDayDate(w.weekStartDate, t.dayOfWeek);
            final key =
                '${taskDate.year}-${taskDate.month.toString().padLeft(2, '0')}-${taskDate.day.toString().padLeft(2, '0')}';
            completedDates.add(key);
          }
        }
      }

      int s = 0;
      var cur = DateTime.now();
      String curKey =
          '${cur.year}-${cur.month.toString().padLeft(2, '0')}-${cur.day.toString().padLeft(2, '0')}';

      if (!completedDates.contains(curKey)) {
        cur = cur.subtract(const Duration(days: 1));
        curKey =
            '${cur.year}-${cur.month.toString().padLeft(2, '0')}-${cur.day.toString().padLeft(2, '0')}';
      }

      while (completedDates.contains(curKey)) {
        s++;
        cur = cur.subtract(const Duration(days: 1));
        curKey =
            '${cur.year}-${cur.month.toString().padLeft(2, '0')}-${cur.day.toString().padLeft(2, '0')}';
      }
      _streakCount = s;
    } catch (_) {
      _streakCount = 0;
    }
  }

  Future<void> toggleTaskStatus(String taskId) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;

    final currentStatus = _tasks[idx].status;
    final newStatus = currentStatus == 'done' ? 'todo' : 'done';

    _tasks[idx] = _tasks[idx].copyWith(status: newStatus);
    notifyListeners();

    try {
      await _taskService.updateTask(taskId, {'status': newStatus});
    } catch (_) {
      _tasks[idx] = _tasks[idx].copyWith(status: currentStatus);
      notifyListeners();
    }
  }

  Future<void> addTask({
    required int dayOfWeek,
    required String title,
    String? description,
    String? category,
    String priority = 'med',
    String? dueTime,
  }) async {
    if (_currentWeek == null) return;

    final newTask = await _taskService.addTask(
      weekId: _currentWeek!.id,
      dayOfWeek: dayOfWeek,
      title: title,
      description: description,
      category: category,
      priority: priority,
      dueTime: dueTime,
    );

    if (newTask != null) {
      _tasks.add(newTask);
      notifyListeners();
    }
  }

  Future<void> updateTask(String id, Map<String, dynamic> updates) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      await _taskService.updateTask(id, updates);
      if (_currentWeek != null) {
        _tasks = await _taskService.getTasksForWeek(_currentWeek!.id);
        notifyListeners();
      }
    }
  }

  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
    await _taskService.deleteTask(id);
  }

  Future<void> restoreTask(TaskModel task) async {
    await addTask(
      dayOfWeek: task.dayOfWeek,
      title: task.title,
      description: task.description,
      category: task.category,
      priority: task.priority,
      dueTime: task.dueTime,
    );
  }

  Future<void> saveQuote(String quote) async {
    if (_currentWeek == null) return;
    _currentWeek = _currentWeek!.copyWith(quote: quote);
    notifyListeners();
    await _weekService.updateWeekQuote(_currentWeek!.id, quote);
  }

  Future<void> saveReflection(String text) async {
    if (_currentWeek == null) return;
    _reflectionText = text;
    notifyListeners();
    await _weekService.saveReflection(_currentWeek!.id, _selectedDay, text);
  }

  Future<int> copyIncompleteTasks() async {
    if (_currentWeek == null) return 0;
    return await _taskService.copyIncompleteTasks(
      _currentWeek!.id,
      _weekStartDate,
    );
  }
}
