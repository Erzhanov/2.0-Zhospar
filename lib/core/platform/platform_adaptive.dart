import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

/// Platform adaptation helpers for native iOS (Cupertino) and Android (Material 3)
/// behavior across scroll physics, dialogs, time pickers, modals, and haptics.
class PlatformAdaptive {
  static const String _hapticsPrefKey = 'zhospar_haptics';
  static final ValueNotifier<bool> hapticsNotifier = ValueNotifier<bool>(true);

  static bool get hapticsEnabled => hapticsNotifier.value;

  static Future<void> loadHapticsPref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(_hapticsPrefKey);
      if (saved != null) {
        hapticsNotifier.value = saved;
      }
    } catch (_) {}
  }

  static Future<void> setHapticsEnabled(bool enabled) async {
    hapticsNotifier.value = enabled;
    if (enabled) {
      HapticFeedback.selectionClick();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hapticsPrefKey, enabled);
    } catch (_) {}
  }

  static bool isApple(BuildContext context) {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  }

  static bool isCompactPhone(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 600;
  }

  static ScrollPhysics scrollPhysics(BuildContext context) {
    if (isApple(context)) {
      return const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      );
    }
    return const ClampingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }

  static void hapticSelection() {
    if (!hapticsNotifier.value) return;
    HapticFeedback.selectionClick();
  }

  static void hapticLight() {
    if (!hapticsNotifier.value) return;
    HapticFeedback.lightImpact();
  }

  static void hapticMedium() {
    if (!hapticsNotifier.value) return;
    HapticFeedback.mediumImpact();
  }

  static void hapticHeavy() {
    if (!hapticsNotifier.value) return;
    HapticFeedback.heavyImpact();
  }
}

/// Platform-aware scroll behavior applying Cupertino bounce on iOS/macOS
/// and Android Material 3 stretching overscroll on Android.
class AdaptiveScrollBehavior extends MaterialScrollBehavior {
  const AdaptiveScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    final platform = getPlatform(context);
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      );
    }
    return const ClampingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}

/// Native Cupertino spinner on iOS/macOS, crisp Material spinner on Android/Web.
class AdaptiveLoadingIndicator extends StatelessWidget {
  final double radius;
  final Color? color;

  const AdaptiveLoadingIndicator({
    super.key,
    this.radius = 12,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformAdaptive.isApple(context)) {
      return CupertinoActivityIndicator(
        radius: radius,
        color: color,
      );
    }
    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: color,
      ),
    );
  }
}

/// Shows a native Cupertino confirmation dialog on iOS and a Material dialog on Android.
Future<bool> showAdaptiveConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  required String cancelLabel,
  bool destructive = false,
}) async {
  final isApple = PlatformAdaptive.isApple(context);
  if (isApple) {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(body),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelLabel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: destructive,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  final isDark = Theme.of(context).brightness == Brightness.dark;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: destructive
                ? AppColors.destructive
                : (isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
            foregroundColor: Colors.white,
            minimumSize: const Size(72, 44),
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Shows a native iOS Cupertino wheel time picker or Android Material time picker.
Future<String?> showAdaptiveTimePicker(
  BuildContext context, {
  String? initialTime,
  required String doneLabel,
  required String cancelLabel,
}) async {
  TimeOfDay initial = TimeOfDay.now();
  if (initialTime != null && initialTime.contains(':')) {
    final parts = initialTime.split(':');
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h != null && m != null && h >= 0 && h < 24 && m >= 0 && m < 60) {
      initial = TimeOfDay(hour: h, minute: m);
    }
  }

  if (PlatformAdaptive.isApple(context)) {
    final now = DateTime.now();
    DateTime picked = DateTime(
      now.year,
      now.month,
      now.day,
      initial.hour,
      initial.minute,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) => Container(
        height: 290,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(cancelLabel),
                    ),
                    CupertinoButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(
                        doneLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  initialDateTime: picked,
                  onDateTimeChanged: (dt) => picked = dt,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true) {
      final hh = picked.hour.toString().padLeft(2, '0');
      final mm = picked.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }
    return null;
  }

  final picked = await showTimePicker(
    context: context,
    initialTime: initial,
  );
  if (picked == null) return null;
  final hh = picked.hour.toString().padLeft(2, '0');
  final mm = picked.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

/// Presents a bottom sheet on phones (< 600dp) and a centered dialog on tablets.
Future<T?> showAdaptiveModal<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  if (PlatformAdaptive.isCompactPhone(context)) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: builder,
    );
  }
  return showDialog<T>(
    context: context,
    builder: builder,
  );
}
