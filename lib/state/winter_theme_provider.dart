import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/platform/platform_adaptive.dart';

/// Provider managing Winter Atmosphere state (falling snow & festive Santa hat).
/// Persists the boolean toggle in SharedPreferences.
class WinterThemeProvider extends ChangeNotifier {
  static const String _keyWinterEnabled = 'zhospar_winter_mode';

  bool _isWinterEnabled = true;
  double _tiltX = 0.0;
  Future<void>? _initFuture;

  bool get isWinterEnabled => _isWinterEnabled;
  double get tiltX => _tiltX;

  WinterThemeProvider() {
    _initFuture = _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isWinterEnabled = prefs.getBool(_keyWinterEnabled) ?? true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleWinter(bool enabled) async {
    if (_initFuture != null) await _initFuture;
    _isWinterEnabled = enabled;
    notifyListeners();
    PlatformAdaptive.hapticSelection();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyWinterEnabled, enabled);
    } catch (_) {}
  }

  /// Backward-compatible tilt setter (for test harness or simple tilt offset)
  void setTilt(double tilt) {
    _tiltX = tilt.clamp(-1.0, 1.0);
    notifyListeners();
  }
}
