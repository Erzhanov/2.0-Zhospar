import 'package:flutter/material.dart';
import '../../../core/i18n/language_provider.dart';
import '../../../core/platform/platform_adaptive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/glass_surface.dart';
import '../../../shared/widgets/tap_scale.dart';
import '../../../state/task_provider.dart';
import '../../../data/services/widget_data_service.dart';

class HomeWidgetPreviewCard extends StatefulWidget {
  final LanguageProvider lang;
  final TaskProvider taskProvider;

  const HomeWidgetPreviewCard({
    super.key,
    required this.lang,
    required this.taskProvider,
  });

  @override
  State<HomeWidgetPreviewCard> createState() => _HomeWidgetPreviewCardState();
}

class _HomeWidgetPreviewCardState extends State<HomeWidgetPreviewCard> {
  bool _isMedium = true;
  bool _isSyncing = false;

  Future<void> _sync() async {
    setState(() => _isSyncing = true);
    PlatformAdaptive.hapticSelection();

    final todayTasks = widget.taskProvider.selectedDayTasks;
    final dateFormatted = widget.lang.getDayNames()[widget.taskProvider.selectedDay - 1];

    await WidgetDataService.syncWidgetData(
      dateFormatted: dateFormatted,
      todayTasks: todayTasks,
      streak: widget.taskProvider.streakCount,
    );

    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      setState(() => _isSyncing = false);
      PlatformAdaptive.hapticSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(widget.lang.t('widgets.syncSuccess')),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _addToHomeScreen() async {
    PlatformAdaptive.hapticMedium();
    final size = _isMedium ? 'medium' : 'small';
    final pinned = await WidgetDataService.requestPinWidget(size: size);
    if (pinned && mounted) {
      PlatformAdaptive.hapticSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(widget.lang.t('widgets.pinSent')),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (mounted) {
      _showGuideDialog();
    }
  }

  void _showGuideDialog() {
    PlatformAdaptive.hapticLight();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.widgets_rounded, color: AppColors.teal, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.lang.t('widgets.guideTitle'),
                style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // iOS Guide card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.apple, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'iOS (iPhone / iPad)',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.lang.t('widgets.guideIos'),
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Android Guide card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.android, size: 18, color: Colors.green),
                      SizedBox(width: 6),
                      Text(
                        'Android',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.lang.t('widgets.guideAndroid'),
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(widget.lang.t('common.done')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final todayTasks = widget.taskProvider.selectedDayTasks;
    final total = todayTasks.length;
    final done = todayTasks.where((t) => t.isDone).length;
    final pct = total > 0 ? ((done / total) * 100).round() : 0;
    final streak = widget.taskProvider.streakCount;
    final dayName = widget.lang.getDayNames()[widget.taskProvider.selectedDay - 1];

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.widgets_outlined,
                  color: AppColors.teal,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.lang.t('widgets.title'),
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      widget.lang.t('widgets.desc'),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.lightSecondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Size Toggle
          Row(
            children: [
              Expanded(
                child: _WidgetSizePill(
                  label: widget.lang.t('widgets.medium'),
                  selected: _isMedium,
                  isDark: isDark,
                  onTap: () {
                    setState(() => _isMedium = true);
                    PlatformAdaptive.hapticSelection();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _WidgetSizePill(
                  label: widget.lang.t('widgets.small'),
                  selected: !_isMedium,
                  isDark: isDark,
                  onTap: () {
                    setState(() => _isMedium = false);
                    PlatformAdaptive.hapticSelection();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Widget Preview Canvas
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: _isMedium ? double.infinity : 156,
              constraints: BoxConstraints(maxWidth: _isMedium ? 320 : 156),
              height: 156,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: _isMedium
                  ? _buildMediumPreview(isDark, dayName, streak, total, done, pct, todayTasks)
                  : _buildSmallPreview(isDark, streak, total, done, pct),
            ),
          ),
          const SizedBox(height: 14),

          // Actions Row: Primary "Add to Home Screen", Quick Sync, and Guide Help
          Row(
            children: [
              Expanded(
                child: TapScale(
                  onTap: _addToHomeScreen,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primary,
                          primary.withValues(alpha: 0.85),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_to_home_screen_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            widget.lang.t('widgets.addToHomeScreen'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TapScale(
                onTap: _isSyncing ? null : _sync,
                borderRadius: BorderRadius.circular(16),
                child: GlassSurface(
                  borderRadius: 16,
                  elevation: 0.6,
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    _isSyncing ? Icons.sync : Icons.refresh_rounded,
                    size: 18,
                    color: primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TapScale(
                onTap: _showGuideDialog,
                borderRadius: BorderRadius.circular(16),
                child: GlassSurface(
                  borderRadius: 16,
                  elevation: 0.6,
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.help_outline_rounded,
                    size: 18,
                    color: primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediumPreview(
    bool isDark,
    String dayName,
    int streak,
    int total,
    int done,
    int pct,
    List todayTasks,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'ZHOSPAR',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '• $dayName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '🔥 $streak күн',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.warning,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '$done/$total орындалды',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const Spacer(),
            Text(
              '$pct%',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: total > 0 ? (done / total).clamp(0.0, 1.0) : 0,
            minHeight: 5,
            backgroundColor: isDark ? Colors.white12 : Colors.black12,
            valueColor: const AlwaysStoppedAnimation(AppColors.glowIndigo),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: todayTasks.isEmpty
              ? Center(
                  child: Text(
                    '• Бүгінге тапсырмалар жоқ',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                )
              : ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: todayTasks.take(2).length,
                  itemBuilder: (context, idx) {
                    final t = todayTasks[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                          Icon(
                            t.isDone
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked,
                            size: 13,
                            color: t.isDone
                                ? AppColors.success
                                : (isDark ? Colors.white38 : Colors.black38),
                          ),
                          const SizedBox(width: 6),
                          if (t.dueTime != null && t.dueTime!.isNotEmpty) ...[
                            Text(
                              t.dueTime!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.glowIndigo,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              t.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                decoration: t.isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: t.isDone
                                    ? (isDark ? Colors.white38 : Colors.black38)
                                    : (isDark ? Colors.white : Colors.black87),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSmallPreview(
    bool isDark,
    int streak,
    int total,
    int done,
    int pct,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'ZHOSPAR',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$pct%',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppColors.glowIndigo,
          ),
        ),
        Text(
          '$done/$total орындалды',
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '🔥 $streak күн',
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: AppColors.warning,
            ),
          ),
        ),
      ],
    );
  }
}

class _WidgetSizePill extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _WidgetSizePill({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
              : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }
}
