import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

/// Detects rapid phone shaking to trigger SOS.
///
/// Requires 4 shakes exceeding ~2.5 G within a 2-second window.
class ShakeDetectorService {
  static const double _shakeThreshold = 25.0; // m/s² (~2.5G)
  static const int _shakeCountTrigger = 4;
  static const Duration _shakeWindow = Duration(seconds: 2);

  StreamSubscription<AccelerometerEvent>? _subscription;
  int _shakeCount = 0;
  DateTime? _firstShake;

  /// Called when shake SOS is triggered.
  void Function()? onShakeSOS;

  ShakeDetectorService({this.onShakeSOS});

  /// Start listening to accelerometer.
  void start() {
    _subscription = accelerometerEventStream().listen(_onAccelerometer);
  }

  void _onAccelerometer(AccelerometerEvent event) {
    final magnitude =
        sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

    if (magnitude > _shakeThreshold) {
      final now = DateTime.now();

      // Reset if outside the shake window
      if (_firstShake != null &&
          now.difference(_firstShake!) > _shakeWindow) {
        _shakeCount = 0;
        _firstShake = null;
      }

      _firstShake ??= now;
      _shakeCount++;

      if (_shakeCount >= _shakeCountTrigger) {
        onShakeSOS?.call();
        _reset();
      }
    }
  }

  void _reset() {
    _shakeCount = 0;
    _firstShake = null;
  }

  /// Stop listening.
  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _reset();
  }

  void dispose() {
    stop();
  }
}
