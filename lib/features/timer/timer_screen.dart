import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/language_provider.dart';
import '../../core/platform/platform_adaptive.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/ambient_space_background.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/floating_motion.dart';
import '../../shared/widgets/floating_music_player.dart';
import '../../shared/widgets/glass_surface.dart';
import '../../shared/widgets/mobile_page_container.dart';
import '../../shared/widgets/tap_scale.dart';
import '../../state/music_provider.dart';
import '../../state/timer_provider.dart';
import '../shell/widgets/top_app_bar.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final music = Provider.of<MusicProvider>(context);
    final timer = Provider.of<TimerProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialSize = math.min(
      248.0,
      math.max(196.0, MediaQuery.sizeOf(context).width * 0.58),
    );

    final (modeColor, modeLabel) = switch (timer.mode) {
      TimerMode.work => (
          isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          lang.t('timer.focus'),
        ),
      TimerMode.shortBreak => (
          AppColors.success,
          lang.t('timer.shortBreak'),
        ),
      TimerMode.longBreak => (
          AppColors.teal,
          lang.t('timer.longBreak'),
        ),
    };

    return AmbientSpaceBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: TopAppBar(
          title: lang.t('timer.title'),
          isSubPage: true,
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              physics: PlatformAdaptive.scrollPhysics(context),
              child: MobilePageContainer(
                bottomClearance: music.showPlayer ? 104 : 36,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppCard(
                      padding: const EdgeInsets.all(4),
                      borderRadius: 20,
                      child: Row(
                        children: [
                          _modeTab(
                            timer,
                            TimerMode.work,
                            lang.t('timer.focus'),
                            isDark,
                          ),
                          _modeTab(
                            timer,
                            TimerMode.shortBreak,
                            lang.t('timer.shortBreak'),
                            isDark,
                          ),
                          _modeTab(
                            timer,
                            TimerMode.longBreak,
                            lang.t('timer.longBreak'),
                            isDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    FloatingDrift(
                      amplitude: 4.5,
                      child: GlassSurface(
                        borderRadius: dialSize,
                        glowColor: modeColor,
                        elevation: 1.3,
                        padding: const EdgeInsets.all(14),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: dialSize,
                              height: dialSize,
                              child: CircularProgressIndicator(
                                value: timer.progress,
                                strokeWidth: 11,
                                strokeCap: StrokeCap.round,
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
                                  timer.formattedTime,
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
                                if (timer.completedCycles > 0) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    '🔥 ${timer.completedCycles} ${lang.t('timer.cycles')}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, size: 28),
                          onPressed: timer.reset,
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.sizeOf(context).width < 360 ? 10 : 18,
                        ),
                        Flexible(
                          child: TapScale(
                            onTap: () {
                              PlatformAdaptive.hapticMedium();
                              timer.toggleStartPause(
                                onCycleComplete: music.playChime,
                              );
                            },
                            minWidth: 112,
                            minHeight: 56,
                            borderRadius: BorderRadius.circular(28),
                            child: Container(
                              height: 56,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: modeColor,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: modeColor.withValues(alpha: 0.35),
                                    blurRadius: 18,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    timer.isRunning
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      timer.isRunning
                                          ? lang.t('timer.pause')
                                          : lang.t('timer.start'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.sizeOf(context).width < 360 ? 10 : 18,
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded, size: 28),
                          onPressed: timer.skip,
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                        ),
                      ],
                    ),
                    if (!timer.isRunning && timer.mode == TimerMode.work) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TapScale(
                            key: const ValueKey('timer-minus-5'),
                            onTap: () {
                              PlatformAdaptive.hapticSelection();
                              timer.adjustWorkMinutes(-5);
                            },
                            minHeight: 44,
                            minWidth: 68,
                            borderRadius: BorderRadius.circular(14),
                            child: GlassSurface(
                              borderRadius: 14,
                              elevation: 0.4,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              child: Text(
                                '-5 ${lang.t('timer.adjustMin')}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          TapScale(
                            key: const ValueKey('timer-plus-5'),
                            onTap: () {
                              PlatformAdaptive.hapticSelection();
                              timer.adjustWorkMinutes(5);
                            },
                            minHeight: 44,
                            minWidth: 68,
                            borderRadius: BorderRadius.circular(14),
                            child: GlassSurface(
                              borderRadius: 14,
                              elevation: 0.4,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              child: Text(
                                '+5 ${lang.t('timer.adjustMin')}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _presetPill(
                          timer,
                          lang.t('timer.pomodoro'),
                          25,
                          5,
                          15,
                          isDark,
                        ),
                        _presetPill(
                          timer,
                          lang.t('timer.deepWork'),
                          50,
                          10,
                          20,
                          isDark,
                        ),
                        _presetPill(
                          timer,
                          lang.t('timer.study'),
                          45,
                          10,
                          20,
                          isDark,
                        ),
                        _presetPill(
                          timer,
                          lang.t('timer.quick'),
                          15,
                          3,
                          10,
                          isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

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
                              Expanded(
                                child: Text(
                                  lang.t('timer.ambientBeats'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                          : AppColors.rimBorder(isDark),
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

  Widget _modeTab(
    TimerProvider timer,
    TimerMode mode,
    String label,
    bool isDark,
  ) {
    final active = timer.mode == mode;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    return Expanded(
      child: TapScale(
        onTap: () => timer.switchMode(mode),
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

  Widget _presetPill(
    TimerProvider timer,
    String name,
    int w,
    int s,
    int l,
    bool isDark,
  ) {
    final active = timer.workMinutes == w;
    return TapScale(
      onTap: () => timer.applyPreset(w, s, l),
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
          border: Border.all(color: AppColors.rimBorder(isDark)),
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
