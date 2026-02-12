# 01 — Journey State Machine

## Objective
Implement the central journey state machine that governs all transitions during active travel monitoring.

---

## States

| State | Description | Active Services |
|-------|-------------|-----------------|
| `idle` | No journey active | None |
| `pre_trip` | Route selected, ready to start | None |
| `active` | Journey in progress | GPS, Voice, Deadman |
| `paused` | User paused journey | Minimal GPS |
| `stationary_warning` | User hasn't moved 20min | GPS, Vibration, Countdown |
| `sos` | Emergency triggered | High-freq GPS, Alerts |
| `completed` | Journey finished | None |
| `cancelled` | User cancelled mid-journey | None |

---

## Implementation

```dart
enum JourneyState { idle, preTrip, active, paused, stationaryWarning, sos, completed, cancelled }

class JourneyStateMachine {
  JourneyState _state = JourneyState.idle;
  final LocationService _locationService;
  final VoiceRecognitionService _voiceService;
  final DeadmanSwitchService _deadmanService;
  final EmergencyService _emergencyService;

  JourneyState get state => _state;

  void transition(JourneyState newState) {
    final oldState = _state;
    
    // Validate transition
    if (!_isValidTransition(oldState, newState)) {
      throw InvalidTransitionError('Cannot transition from $oldState to $newState');
    }

    _state = newState;
    _onEnterState(newState);
    _onExitState(oldState);
  }

  bool _isValidTransition(JourneyState from, JourneyState to) {
    final validTransitions = {
      JourneyState.idle: [JourneyState.preTrip],
      JourneyState.preTrip: [JourneyState.active, JourneyState.cancelled],
      JourneyState.active: [JourneyState.paused, JourneyState.stationaryWarning, 
                            JourneyState.sos, JourneyState.completed, JourneyState.cancelled],
      JourneyState.paused: [JourneyState.active, JourneyState.cancelled],
      JourneyState.stationaryWarning: [JourneyState.active, JourneyState.sos],
      JourneyState.sos: [JourneyState.completed],
      JourneyState.completed: [JourneyState.idle],
      JourneyState.cancelled: [JourneyState.idle],
    };
    return validTransitions[from]?.contains(to) ?? false;
  }

  void _onEnterState(JourneyState state) {
    switch (state) {
      case JourneyState.active:
        _locationService.startTracking(interval: Duration(seconds: 5));
        _voiceService.startListening();
        _deadmanService.start();
        break;
      case JourneyState.paused:
        _locationService.reduceFrequency(interval: Duration(seconds: 30));
        _voiceService.stopListening();
        _deadmanService.pause();
        break;
      case JourneyState.stationaryWarning:
        // Vibrate phone, show warning UI
        HapticFeedback.vibrate();
        _deadmanService.startCountdown(seconds: 60);
        break;
      case JourneyState.sos:
        _locationService.startTracking(interval: Duration(seconds: 20));
        _emergencyService.triggerSOS();
        break;
      case JourneyState.completed:
        _locationService.stopTracking();
        _voiceService.stopListening();
        _deadmanService.stop();
        break;
      default:
        break;
    }
  }

  void _onExitState(JourneyState state) {
    if (state == JourneyState.stationaryWarning) {
      _deadmanService.cancelCountdown();
    }
  }
}
```

---

## Supabase Realtime Integration

Journey state updates are broadcast via Supabase Realtime so emergency contacts can track:

```dart
// Broadcast state changes
Future<void> _broadcastState(JourneyState state, String journeyId) async {
  await Supabase.instance.client
      .from('journeys')
      .update({'status': state.name})
      .eq('id', journeyId);
}
```

---

## Verification
- [ ] All valid transitions work correctly
- [ ] Invalid transitions throw errors
- [ ] Services start/stop on state entry/exit
- [ ] State persisted to database
- [ ] Realtime broadcasts state changes
