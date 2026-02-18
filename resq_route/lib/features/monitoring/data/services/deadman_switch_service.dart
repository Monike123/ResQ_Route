import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Detects when a user has been stationary for too long.
///
/// If the user doesn't move > 10 m in 20 minutes, a warning fires.
/// A 60-second countdown then begins — if the user doesn't tap
/// "I'm OK", SOS is auto-triggered.
class DeadmanSwitchService {
  static const int stationaryThresholdMinutes = 20;
  static const int countdownSeconds = 60;
  static const double movementThresholdMeters = 10;

  Timer? _stationaryTimer;
  Timer? _countdownTimer;
  int _countdownRemaining = countdownSeconds;
  Position? _lastKnownPosition;
  bool _isPaused = false;

  /// Fires when 20 min stationary threshold is reached.
  final void Function() onStationaryWarning;

  /// Fires when 60 s countdown expires without user response.
  final void Function() onAutoSOS;

  /// Fires every second during countdown.
  final void Function(int secondsRemaining) onCountdownTick;

  DeadmanSwitchService({
    required this.onStationaryWarning,
    required this.onAutoSOS,
    required this.onCountdownTick,
  });

  int get countdownRemaining => _countdownRemaining;
  bool get isCountingDown => _countdownTimer != null;

  /// Start the deadman switch monitoring.
  void start() {
    _isPaused = false;
    _resetStationaryTimer();
  }

  /// Feed position updates from GPS.
  void onPositionUpdate(Position position) {
    if (_isPaused) return;

    if (_lastKnownPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastKnownPosition!.latitude,
        _lastKnownPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      if (distance > movementThresholdMeters) {
        // Movement detected — reset everything
        _cancelCountdown();
        _resetStationaryTimer();
      }
    }
    _lastKnownPosition = position;
  }

  /// User dismisses warning — "I'm OK".
  void userConfirmedOK() {
    _cancelCountdown();
    _resetStationaryTimer();
  }

  /// Pause monitoring (e.g. when journey paused).
  void pause() {
    _isPaused = true;
    _stationaryTimer?.cancel();
    _cancelCountdown();
  }

  /// Full stop.
  void stop() {
    _stationaryTimer?.cancel();
    _cancelCountdown();
    _lastKnownPosition = null;
    _isPaused = false;
  }

  // ── Internal ──

  void _resetStationaryTimer() {
    _stationaryTimer?.cancel();
    _stationaryTimer = Timer(
      const Duration(minutes: stationaryThresholdMinutes),
      _onStationaryTimeout,
    );
  }

  void _onStationaryTimeout() {
    onStationaryWarning();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownRemaining = countdownSeconds;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdownRemaining--;
      onCountdownTick(_countdownRemaining);

      if (_countdownRemaining <= 0) {
        timer.cancel();
        _countdownTimer = null;
        onAutoSOS();
      }
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _countdownRemaining = countdownSeconds;
  }
}
