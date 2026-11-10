import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/music_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/mobile_page_container.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/floating_music_player.dart';
import '../../widgets/navigation/top_app_bar.dart';

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
    final dialSize = math.min(
      248.0,
      math.max(196.0, MediaQuery.sizeOf(context).width * 0.58),
    );

    final progress =
        _totalSeconds > 0 ? (_totalSeconds - _secondsLeft) / _totalSeconds : 0.0;

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
      appBar: TopAppBar(
        title: lang.t('timer.title'),
        isSubPage: true,
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              child: MobilePageContainer(
                bottomClearance: music.showPlayer ? 104 : 32,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Mode Tabs (>= 44px height)
                    AppCard(
                      padding: const EdgeInsets.all(4),
                      borderRadius: 18,
                      child: Row(
                        children: [
                          _modeTab(
                            TimerMode.work,
                            lang.t('timer.focus'),
                            isDark,
                          ),
                          _modeTab(
                            TimerMode.shortBreak,
                            lang.t('timer.shortBreak'),
                            isDark,
                          ),
                          _modeTab(
                            TimerMode.longBreak,
                            lang.t('timer.longBreak'),
                            isDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Circular Countdown Timer
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: dialSize,
                          height: dialSize,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 10,
                            backgroundColor: isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.06),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(modeColor),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(_secondsLeft),
                              style: const TextStyle(
                                fontSize: 46,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: modeColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                modeLabel,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: modeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Thumb-friendly Control Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, size: 28),
                          onPressed: _reset,
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                        ),
                        const SizedBox(width: 18),
                        TapScale(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            _toggleStartPause();
                          },
                          minWidth: 72,
                          minHeight: 72,
                          borderRadius: BorderRadius.circular(36),
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: modeColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: modeColor.withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              _isRunning
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded, size: 28),
                          onPressed: () {
                            if (_mode == TimerMode.work) {
                              _switchMode(TimerMode.shortBreak);
                            } else {
                              _switchMode(TimerMode.work);
                            }
                          },
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Responsive Wrapping Presets (>= 44px height)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _presetPill(lang.t('timer.pomodoro'), 25, 5, 15, isDark),
                        _presetPill(
                          lang.t('timer.deepWork'),
                          50,
                          10,
                          20,
                          isDark,
                        ),
                        _presetPill(lang.t('timer.study'), 45, 10, 20, isDark),
                        _presetPill(lang.t('timer.quick'), 15, 3, 10, isDark),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Ambient Focus Music Card
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.music_note_rounded,
                                size: 20,
                                color: AppColors.purple,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                lang.t('timer.ambientBeats'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: MusicProvider.presetTracks.map((track) {
                              final isCurrent =
                                  music.currentTrack?.id == track.id;
                              return TapScale(
                                onTap: () {
                                  if (isCurrent && music.isPlaying) {
                                    music.togglePlay();
                                  } else {
                                    music.playTrack(track);
                                  }
                                },
                                minHeight: 44,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  constraints:
                                      const BoxConstraints(minHeight: 44),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? AppColors.purple
                                            .withValues(alpha: 0.15)
                                        : (isDark
                                            ? Colors.white
                                                .withValues(alpha: 0.04)
                                            : Colors.black
                                                .withValues(alpha: 0.03)),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isCurrent
                                          ? AppColors.purple
                                          : (isDark
                                              ? AppColors.darkBorder
                                              : AppColors.lightBorder),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        track.icon,
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          track.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: isCurrent
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            color: isCurrent
                                                ? AppColors.purple
                                                : null,
                                          ),
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
                  ],
                ),
              ),
            ),
            const FloatingMusicPlayer(bottomOffset: 16),
          ],
        ),
      ),
    );
  }

  Widget _modeTab(TimerMode mode, String label, bool isDark) {
    final active = _mode == mode;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    return Expanded(
      child: TapScale(
        onTap: () => _switchMode(mode),
        minHeight: 44,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: active ? primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
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
    return TapScale(
      onTap: () => _applyPreset(w, s, l),
      minHeight: 44,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? (isDark ? Colors.white24 : Colors.black12)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '$name · $w/$s',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
