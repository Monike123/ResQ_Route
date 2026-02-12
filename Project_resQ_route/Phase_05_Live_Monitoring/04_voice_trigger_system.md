# 04 — Voice Trigger System

## Objective
Listen in the background for a safety keyword phrase (e.g., "HELP SAFE APP") to trigger SOS hands-free.

---

## Implementation

```dart
class VoiceRecognitionService {
  final SpeechToText _speech = SpeechToText();
  static const String triggerPhrase = 'help safe app';
  bool _isListening = false;

  Future<void> startListening({
    required Function() onTriggerDetected,
  }) async {
    bool available = await _speech.initialize(
      onError: (error) => _handleError(error),
    );
    
    if (!available) return;
    _isListening = true;

    _speech.listen(
      onResult: (result) {
        final text = result.recognizedWords.toLowerCase();
        if (text.contains(triggerPhrase)) {
          onTriggerDetected();
          stopListening();
        }
      },
      listenFor: Duration(hours: 2),    // Max listen duration
      pauseFor: Duration(seconds: 10),  // Auto-restart after pause
      partialResults: true,
      listenMode: ListenMode.dictation,
    );
  }

  void stopListening() {
    _speech.stop();
    _isListening = false;
  }
}
```

### False Positive Prevention
- Require EXACT phrase match (not partial words)
- Confirmation vibration when trigger detected
- 3-second grace period to cancel false trigger

### Battery Considerations
- Voice recognition is CPU-intensive
- Only active during `active` journey state
- Stops during `paused` state
- Consider adaptive listening intervals for battery savings

---

## Verification
- [ ] Voice recognition starts with journey
- [ ] Trigger phrase detected in quiet environment
- [ ] False positives minimized
- [ ] Works in background
- [ ] Battery impact acceptable
