import 'dart:async';

import 'package:battery_plus/battery_plus.dart';

/// Battery-aware service that adapts GPS frequency and voice listening
/// based on current charge level.
///
/// | Battery   | GPS Interval | Voice |
/// |-----------|-------------|-------|
/// | > 50%     | 5 s         | On    |
/// | 30–50%    | 10 s        | On    |
/// | 15–30%    | 20 s        | Off   |
/// | 5–15%     | 30 s        | Off   |
/// | < 5%      | 60 s        | Off   |
class BatteryService {
  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _subscription;
  int _lastLevel = 100;
  Timer? _pollTimer;

  /// Called when GPS interval should change.
  void Function(Duration newInterval)? onIntervalChange;

  /// Called when voice listening should start/stop.
  void Function(bool shouldListen)? onVoiceToggle;

  /// Called when battery drops below 15%.
  void Function(int level)? onLowBattery;

  /// Called when battery drops below 5% — send location to contacts.
  void Function()? onCriticalBattery;

  BatteryService({
    this.onIntervalChange,
    this.onVoiceToggle,
    this.onLowBattery,
    this.onCriticalBattery,
  });

  int get lastLevel => _lastLevel;

  /// Start monitoring battery level.
  void start() {
    _checkLevel(); // Immediate check
    // Poll every 60 s since battery_plus state stream doesn't give level
    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _checkLevel();
    });
    // Also listen for charging state changes
    _subscription = _battery.onBatteryStateChanged.listen((_) {
      _checkLevel();
    });
  }

  Future<void> _checkLevel() async {
    try {
      _lastLevel = await _battery.batteryLevel;
    } catch (_) {
      return; // Battery info unavailable (e.g. emulator)
    }
    _applyPolicy(_lastLevel);
  }

  void _applyPolicy(int level) {
    if (level > 50) {
      onIntervalChange?.call(const Duration(seconds: 5));
      onVoiceToggle?.call(true);
    } else if (level > 30) {
      onIntervalChange?.call(const Duration(seconds: 10));
      onVoiceToggle?.call(true);
    } else if (level > 15) {
      onIntervalChange?.call(const Duration(seconds: 20));
      onVoiceToggle?.call(false);
      onLowBattery?.call(level);
    } else if (level > 5) {
      onIntervalChange?.call(const Duration(seconds: 30));
      onVoiceToggle?.call(false);
      onLowBattery?.call(level);
    } else {
      onIntervalChange?.call(const Duration(seconds: 60));
      onVoiceToggle?.call(false);
      onCriticalBattery?.call();
    }
  }

  /// Stop monitoring.
  void stop() {
    _pollTimer?.cancel();
    _subscription?.cancel();
    _pollTimer = null;
    _subscription = null;
  }

  void dispose() {
    stop();
  }
}
