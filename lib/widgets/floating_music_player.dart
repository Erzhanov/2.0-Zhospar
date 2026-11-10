import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/music_provider.dart';
import 'common/floating_motion.dart';
import 'common/glass_surface.dart';
import 'common/tap_scale.dart';

class FloatingMusicPlayer extends StatelessWidget {
  final double bottomOffset;

  const FloatingMusicPlayer({
    super.key,
    this.bottomOffset = 16,
  });

  @override
  Widget build(BuildContext context) {
    final music = Provider.of<MusicProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    if (!music.showPlayer || music.currentTrack == null) {
      return const SizedBox.shrink();
    }

    final track = music.currentTrack!;
    final primary =
        isDark ? AppColors.darkPrimaryBright : AppColors.lightPrimary;

    if (music.isMinimized) {
      return Positioned(
        bottom: bottomOffset + safeBottom,
        left: 16,
        child: FloatingDrift(
          amplitude: 3.5,
          child: TapScale(
            onTap: () => music.setMinimized(false),
            minWidth: 52,
            minHeight: 52,
            borderRadius: BorderRadius.circular(26),
            child: GlassSurface(
              enableBlur: true,
              borderRadius: 26,
              glowColor: AppColors.purple,
              padding: const EdgeInsets.all(12),
              child: Text(track.icon, style: const TextStyle(fontSize: 22)),
            ),
          ),
        ),
      );
    }

    return Positioned(
      bottom: bottomOffset + safeBottom,
      left: 16,
      right: 16,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: GlassSurface(
            enableBlur: true,
            borderRadius: 24,
            glowColor: AppColors.purple,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Text(track.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.label,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        track.artist,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    music.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 32,
                    color: primary,
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    music.togglePlay();
                  },
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 22),
                  onPressed: () => music.setMinimized(true),
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => music.stop(),
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
