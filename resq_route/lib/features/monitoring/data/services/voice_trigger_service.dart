import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart';

/// Listens for a safety keyword ("help safe app") to trigger SOS hands-free.
///
/// Only active during `active` journey state. A 3-second grace period
/// lets the user cancel false triggers.
class VoiceTriggerService {
  final SpeechToText _speech = SpeechToText();
  static const String triggerPhrase = 'help safe app';
  static const int gracePeriodSeconds = 3;

  bool _isListening = false;
  bool _isAvailable = false;
  Timer? _graceTimer;

  /// Called when trigger phrase is confirmed (after grace period).
  final void Function() onTriggerConfirmed;

  /// Called when trigger is initially detected (before grace period).
  final void Function() onTriggerDetected;

  /// Called when user cancels during grace period.
  final void Function() onTriggerCancelled;

  VoiceTriggerService({
    required this.onTriggerConfirmed,
    required this.onTriggerDetected,
    required this.onTriggerCancelled,
  });

  bool get isListening => _isListening;

  /// Initialise and start continuous listening.
  Future<void> startListening() async {
    if (_isListening) return;

    _isAvailable = await _speech.initialize(
      onError: (_) => _restartListening(),
    );

    if (!_isAvailable) return;
    _isListening = true;
    _beginListenSession();
  }

  void _beginListenSession() {
    if (!_isListening || !_isAvailable) return;

    _speech.listen(
      onResult: (result) {
        final text = result.recognizedWords.toLowerCase();
        if (text.contains(triggerPhrase)) {
          _handleTrigger();
        }
      },
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 10),
      partialResults: true,
      listenMode: ListenMode.dictation,
      onSoundLevelChange: null,
    );
  }

  void _handleTrigger() {
    // Notify UI immediately
    onTriggerDetected();

    // 3-second grace period before confirming
    _graceTimer?.cancel();
    _graceTimer = Timer(const Duration(seconds: gracePeriodSeconds), () {
      onTriggerConfirmed();
      stopListening();
    });
  }

  /// User cancels during grace period.
  void cancelTrigger() {
    _graceTimer?.cancel();
    _graceTimer = null;
    onTriggerCancelled();
    // Restart listening
    _restartListening();
  }

  void _restartListening() {
    if (!_isListening) return;
    // Brief delay then re-listen
    Future.delayed(const Duration(seconds: 1), _beginListenSession);
  }

  /// Stop listening entirely.
  void stopListening() {
    _isListening = false;
    _graceTimer?.cancel();
    _graceTimer = null;
    _speech.stop();
  }

  void dispose() {
    stopListening();
  }
}
