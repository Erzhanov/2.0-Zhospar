import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum TimerMode { work, shortBreak, longBreak }

/// Persistent focus timer state surviving navigation between tabs and sub-pages.
class TimerProvider extends ChangeNotifier {
  TimerMode _mode = TimerMode.work;
  int _workMinutes = 25;
  int _shortBreakMinutes = 5;
  int _longBreakMinutes = 15;

  late int _totalSeconds;
  late int _secondsLeft;
  Timer? _timer;
  bool _isRunning = false;
  int _completedCycles = 0;

  TimerMode get mode => _mode;
  int get workMinutes => _workMinutes;
  int get shortBreakMinutes => _shortBreakMinutes;
  int get longBreakMinutes => _longBreakMinutes;
  int get totalSeconds => _totalSeconds;
  int get secondsLeft => _secondsLeft;
  bool get isRunning => _isRunning;
  int get completedCycles => _completedCycles;

  double get progress =>
      _totalSeconds > 0 ? (_totalSeconds - _secondsLeft) / _totalSeconds : 0.0;

  String get formattedTime {
    final m = _secondsLeft ~/ 60;
    final sec = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  TimerProvider() {
    _totalSeconds = _workMinutes * 60;
    _secondsLeft = _totalSeconds;
  }

  void switchMode(TimerMode nextMode) {
    _timer?.cancel();
    _mode = nextMode;
    _isRunning = false;
    _totalSeconds = switch (nextMode) {
      TimerMode.work => _workMinutes * 60,
      TimerMode.shortBreak => _shortBreakMinutes * 60,
      TimerMode.longBreak => _longBreakMinutes * 60,
    };
    _secondsLeft = _totalSeconds;
    notifyListeners();
  }

  void applyPreset(int work, int shortBreak, int longBreak) {
    _workMinutes = work;
    _shortBreakMinutes = shortBreak;
    _longBreakMinutes = longBreak;
    switchMode(TimerMode.work);
  }

  void adjustWorkMinutes(int delta) {
    if (_isRunning || _mode != TimerMode.work) return;
    final next = (_workMinutes + delta).clamp(5, 90);
    if (next == _workMinutes) return;
    _workMinutes = next;
    _totalSeconds = _workMinutes * 60;
    _secondsLeft = _totalSeconds;
    notifyListeners();
  }

  void toggleStartPause({VoidCallback? onCycleComplete}) {
    if (_isRunning) {
      _timer?.cancel();
      _isRunning = false;
      notifyListeners();
      return;
    }

    _isRunning = true;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft > 0) {
        _secondsLeft--;
        notifyListeners();
      } else {
        _timer?.cancel();
        HapticFeedback.heavyImpact();
        onCycleComplete?.call();

        if (_mode == TimerMode.work) {
          _completedCycles++;
          if (_completedCycles % 4 == 0) {
            switchMode(TimerMode.longBreak);
          } else {
            switchMode(TimerMode.shortBreak);
          }
        } else {
          switchMode(TimerMode.work);
        }
      }
    });
  }

  void reset() {
    _timer?.cancel();
    _isRunning = false;
    _secondsLeft = _totalSeconds;
    notifyListeners();
  }

  void skip() {
    if (_mode == TimerMode.work) {
      switchMode(TimerMode.shortBreak);
    } else {
      switchMode(TimerMode.work);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
