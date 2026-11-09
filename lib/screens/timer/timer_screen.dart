import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/music_provider.dart';

enum TimerMode { work, shortBreak, longBreak }

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  TimerMode _mode = TimerMode.work;
  int _workMinutes = 25;
  int _shortBreakMinutes = 5;
  int _longBreakMinutes = 15;

  late int _totalSeconds;
  late int _secondsLeft;
  Timer? _timer;
  bool _isRunning = false;
  int _completedCycles = 0;

  @override
  void initState() {
    super.initState();
    _totalSeconds = _workMinutes * 60;
    _secondsLeft = _totalSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _switchMode(TimerMode mode) {
    _timer?.cancel();
    setState(() {
      _mode = mode;
      _isRunning = false;
      if (mode == TimerMode.work) {
        _totalSeconds = _workMinutes * 60;
      } else if (mode == TimerMode.shortBreak) {
        _totalSeconds = _shortBreakMinutes * 60;
      } else {
        _totalSeconds = _longBreakMinutes * 60;
      }
      _secondsLeft = _totalSeconds;
    });
  }

  void _applyPreset(int work, int shortBreak, int longBreak) {
    _timer?.cancel();
    setState(() {
      _workMinutes = work;
      _shortBreakMinutes = shortBreak;
      _longBreakMinutes = longBreak;
      _switchMode(TimerMode.work);
    });
  }

  void _toggleStartPause() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsLeft > 0) {
          setState(() => _secondsLeft--);
        } else {
          _timer?.cancel();
          HapticFeedback.heavyImpact();
          Provider.of<MusicProvider>(context, listen: false).playChime();

          if (_mode == TimerMode.work) {
            _completedCycles++;
            if (_completedCycles % 4 == 0) {
              _switchMode(TimerMode.longBreak);
            } else {
              _switchMode(TimerMode.shortBreak);
            }
          } else {
            _switchMode(TimerMode.work);
          }
        }
      });
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _secondsLeft = _totalSeconds;
    });
  }

  String _formatTime(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final music = Provider.of<MusicProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final progress = _totalSeconds > 0 ? (_totalSeconds - _secondsLeft) / _totalSeconds : 0.0;

    Color modeColor;
    String modeLabel;
    switch (_mode) {
      case TimerMode.work:
        modeColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
        modeLabel = lang.t('timer.focus');
        break;
      case TimerMode.shortBreak:
        modeColor = AppColors.success;
        modeLabel = lang.t('timer.shortBreak');
        break;
      case TimerMode.longBreak:
        modeColor = AppColors.teal;
        modeLabel = lang.t('timer.longBreak');
        break;
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                lang.t('timer.title'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 18),

              // Mode Tabs: Work | Short Break | Long Break
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    _modeTab(TimerMode.work, lang.t('timer.focus'), isDark),
                    _modeTab(TimerMode.shortBreak, lang.t('timer.shortBreak'), isDark),
                    _modeTab(TimerMode.longBreak, lang.t('timer.longBreak'), isDark),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Circular Countdown Timer
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                      valueColor: AlwaysStoppedAnimation<Color>(modeColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(_secondsLeft),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: modeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          modeLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: modeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Control Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 28),
                    onPressed: _reset,
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _toggleStartPause();
                    },
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: modeColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: modeColor.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded, size: 28),
                    onPressed: () {
                      if (_mode == TimerMode.work) {
                        _switchMode(TimerMode.shortBreak);
                      } else {
                        _switchMode(TimerMode.work);
                      }
                    },
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Presets
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _presetPill(lang.t('timer.pomodoro'), 25, 5, 15, isDark),
                  const SizedBox(width: 8),
                  _presetPill(lang.t('timer.deepWork'), 50, 10, 20, isDark),
                  const SizedBox(width: 8),
                  _presetPill(lang.t('timer.study'), 45, 10, 20, isDark),
                  const SizedBox(width: 8),
                  _presetPill(lang.t('timer.quick'), 15, 3, 10, isDark),
                ],
              ),
              const SizedBox(height: 28),

              // Ambient Focus Music Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.music_note_rounded, size: 20, color: AppColors.purple),
                        const SizedBox(width: 8),
                        Text(
                          lang.t('timer.ambientBeats'),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: MusicProvider.presetTracks.map((track) {
                        final isCurrent = music.currentTrack?.id == track.id;
                        return GestureDetector(
                          onTap: () {
                            if (isCurrent && music.isPlaying) {
                              music.togglePlay();
                            } else {
                              music.playTrack(track);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? AppColors.purple.withOpacity(0.15)
                                  : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isCurrent
                                    ? AppColors.purple
                                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(track.icon, style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Text(
                                  track.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                    color: isCurrent ? AppColors.purple : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeTab(TimerMode mode, String label, bool isDark) {
    final active = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: active
                  ? Colors.white
                  : (isDark ? Colors.white60 : Colors.black54),
            ),
          ),
        ),
      ),
    );
  }

  Widget _presetPill(String name, int w, int s, int l, bool isDark) {
    final active = _workMinutes == w;
    return GestureDetector(
      onTap: () => _applyPreset(w, s, l),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? (isDark ? Colors.white24 : Colors.black12)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Text(
          name,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
