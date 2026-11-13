import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/platform/platform_adaptive.dart';
import '../data/models/task.dart';

class GamificationBadge {
  final String id;
  final String icon;
  final String titleKey;
  final String descKey;

  const GamificationBadge({
    required this.id,
    required this.icon,
    required this.titleKey,
    required this.descKey,
  });
}

class CelebrationEvent {
  final String title;
  final String subtitle;
  final String emoji;
  final int xpEarned;

  const CelebrationEvent({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.xpEarned,
  });
}

class GamificationProvider extends ChangeNotifier {
  static const String _xpKey = 'zhospar_gamification_xp';
  static const String _badgesKey = 'zhospar_gamification_badges';
  static const String _tasksDoneKey = 'zhospar_gamification_tasks_done_total';

  int _xp = 0;
  int _totalTasksDone = 0;
  Set<String> _unlockedBadgeIds = {};
  CelebrationEvent? _currentCelebration;

  int get xp => _xp;
  int get totalTasksDone => _totalTasksDone;
  Set<String> get unlockedBadgeIds => _unlockedBadgeIds;
  CelebrationEvent? get currentCelebration => _currentCelebration;

  /// Level calculation: 100 XP per level
  int get level => (_xp ~/ 100) + 1;
  double get levelProgress => (_xp % 100) / 100.0;
  int get xpToNextLevel => 100 - (_xp % 100);

  static const List<GamificationBadge> allBadges = [
    GamificationBadge(
      id: 'first_step',
      icon: '🎯',
      titleKey: 'gamification.badgeFirstStep',
      descKey: 'gamification.badgeFirstStepDesc',
    ),
    GamificationBadge(
      id: 'streak_3',
      icon: '🔥',
      titleKey: 'gamification.badgeStreak3',
      descKey: 'gamification.badgeStreak3Desc',
    ),
    GamificationBadge(
      id: 'streak_7',
      icon: '⚡',
      titleKey: 'gamification.badgeStreak7',
      descKey: 'gamification.badgeStreak7Desc',
    ),
    GamificationBadge(
      id: 'daily_clear',
      icon: '🌟',
      titleKey: 'gamification.badgeDailyClear',
      descKey: 'gamification.badgeDailyClearDesc',
    ),
    GamificationBadge(
      id: 'task_champ_10',
      icon: '🚀',
      titleKey: 'gamification.badgeTask10',
      descKey: 'gamification.badgeTask10Desc',
    ),
    GamificationBadge(
      id: 'reflection_master',
      icon: '🧘',
      titleKey: 'gamification.badgeReflection',
      descKey: 'gamification.badgeReflectionDesc',
    ),
    GamificationBadge(
      id: 'legend_50',
      icon: '🏆',
      titleKey: 'gamification.badgeTask50',
      descKey: 'gamification.badgeTask50Desc',
    ),
  ];

  Future<void>? _initFuture;

  GamificationProvider() {
    _initFuture = _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _xp = prefs.getInt(_xpKey) ?? 0;
      _totalTasksDone = prefs.getInt(_tasksDoneKey) ?? 0;
      final badgeList = prefs.getStringList(_badgesKey) ?? [];
      _unlockedBadgeIds = badgeList.toSet();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_xpKey, _xp);
      await prefs.setInt(_tasksDoneKey, _totalTasksDone);
      await prefs.setStringList(_badgesKey, _unlockedBadgeIds.toList());
    } catch (_) {}
  }

  void clearCelebration() {
    _currentCelebration = null;
    notifyListeners();
  }

  /// Award XP when a task is completed
  Future<void> onTaskToggled({
    required TaskModel task,
    required bool isNowDone,
    required bool allDayTasksDone,
  }) async {
    if (_initFuture != null) {
      await _initFuture;
    }
    if (!isNowDone) return;

    final oldLevel = level;
    _totalTasksDone++;

    // Base XP by priority
    int earned = switch (task.priority) {
      'high' => 40,
      'low' => 15,
      _ => 25,
    };

    // Bonus for clearing the whole day
    if (allDayTasksDone) {
      earned += 80;
    }

    _xp += earned;

    // Check badges
    bool newBadge = false;
    if (!_unlockedBadgeIds.contains('first_step')) {
      _unlockedBadgeIds.add('first_step');
      newBadge = true;
    }
    if (_totalTasksDone >= 10 && !_unlockedBadgeIds.contains('task_champ_10')) {
      _unlockedBadgeIds.add('task_champ_10');
      newBadge = true;
    }
    if (_totalTasksDone >= 50 && !_unlockedBadgeIds.contains('legend_50')) {
      _unlockedBadgeIds.add('legend_50');
      newBadge = true;
    }
    if (allDayTasksDone && !_unlockedBadgeIds.contains('daily_clear')) {
      _unlockedBadgeIds.add('daily_clear');
      newBadge = true;
    }

    await _saveToStorage();

    // Trigger celebration if leveled up, cleared day, or new badge unlocked
    if (level > oldLevel) {
      PlatformAdaptive.hapticSuccess();
      _currentCelebration = CelebrationEvent(
        title: 'Жаңа $level-деңгей!',
        subtitle: 'Өнімділік дәрежеңіз жоғарылады!',
        emoji: '⭐',
        xpEarned: earned,
      );
    } else if (allDayTasksDone) {
      PlatformAdaptive.hapticSuccess();
      _currentCelebration = CelebrationEvent(
        title: 'Мінсіз күн!',
        subtitle: 'Бүгінгі барлық жоспар орындалды!',
        emoji: '🎉',
        xpEarned: earned,
      );
    } else if (newBadge) {
      PlatformAdaptive.hapticSuccess();
      _currentCelebration = CelebrationEvent(
        title: 'Жаңа жетістік!',
        subtitle: 'Арнайы бейдж ашылды!',
        emoji: '🏆',
        xpEarned: earned,
      );
    }

    notifyListeners();
  }

  /// Award XP when reflection is recorded
  Future<void> onReflectionSaved() async {
    if (_initFuture != null) await _initFuture;
    _xp += 30;
    if (!_unlockedBadgeIds.contains('reflection_master')) {
      _unlockedBadgeIds.add('reflection_master');
    }
    await _saveToStorage();
    notifyListeners();
  }

  /// Check streak-based badges
  Future<void> checkStreakBadges(int streak) async {
    if (_initFuture != null) await _initFuture;
    bool updated = false;
    if (streak >= 3 && !_unlockedBadgeIds.contains('streak_3')) {
      _unlockedBadgeIds.add('streak_3');
      _xp += 50;
      updated = true;
    }
    if (streak >= 7 && !_unlockedBadgeIds.contains('streak_7')) {
      _unlockedBadgeIds.add('streak_7');
      _xp += 100;
      updated = true;
    }
    if (updated) {
      await _saveToStorage();
      notifyListeners();
    }
  }
}
