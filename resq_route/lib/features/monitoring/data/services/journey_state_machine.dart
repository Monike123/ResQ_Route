import 'dart:async';

import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// All possible journey states.
enum JourneyState {
  idle,
  preTrip,
  active,
  paused,
  stationaryWarning,
  sos,
  completed,
  cancelled,
}

/// Central state machine governing journey lifecycle.
///
/// State transitions are validated — only legal moves are allowed.
/// On enter/exit hooks delegate to GPS, voice, and deadman services.
class JourneyStateMachine {
  JourneyState _state = JourneyState.idle;
  String? _journeyId;
  final SupabaseClient _client;

  // Callbacks — wired by ActiveJourneyScreen / providers
  void Function(JourneyState state)? onStateChanged;
  void Function()? onStartTracking;
  void Function()? onStopTracking;
  void Function()? onReduceTracking;
  void Function()? onStartVoice;
  void Function()? onStopVoice;
  void Function()? onStartDeadman;
  void Function()? onPauseDeadman;
  void Function()? onStopDeadman;
  void Function()? onTriggerSOS;

  JourneyStateMachine({
    required SupabaseClient client,
    this.onStateChanged,
    this.onStartTracking,
    this.onStopTracking,
    this.onReduceTracking,
    this.onStartVoice,
    this.onStopVoice,
    this.onStartDeadman,
    this.onPauseDeadman,
    this.onStopDeadman,
    this.onTriggerSOS,
  }) : _client = client;

  JourneyState get state => _state;
  String? get journeyId => _journeyId;
  bool get isActive =>
      _state == JourneyState.active ||
      _state == JourneyState.stationaryWarning ||
      _state == JourneyState.sos;

  /// Valid transitions map.
  static const Map<JourneyState, List<JourneyState>> _validTransitions = {
    JourneyState.idle: [JourneyState.preTrip],
    JourneyState.preTrip: [JourneyState.active, JourneyState.cancelled],
    JourneyState.active: [
      JourneyState.paused,
      JourneyState.stationaryWarning,
      JourneyState.sos,
      JourneyState.completed,
      JourneyState.cancelled,
    ],
    JourneyState.paused: [JourneyState.active, JourneyState.cancelled],
    JourneyState.stationaryWarning: [JourneyState.active, JourneyState.sos],
    JourneyState.sos: [JourneyState.completed],
    JourneyState.completed: [JourneyState.idle],
    JourneyState.cancelled: [JourneyState.idle],
  };

  /// Attempt a state transition. Throws if invalid.
  void transition(JourneyState newState) {
    if (!_isValid(_state, newState)) {
      throw StateError('Invalid transition: $_state → $newState');
    }
    final old = _state;
    _state = newState;
    _onExit(old);
    _onEnter(newState);
    onStateChanged?.call(newState);
    _broadcastState();
  }

  bool _isValid(JourneyState from, JourneyState to) =>
      _validTransitions[from]?.contains(to) ?? false;

  /// Check if a transition is possible (for UI button enablement).
  bool canTransitionTo(JourneyState target) => _isValid(_state, target);

  // ── Lifecycle hooks ──

  void _onEnter(JourneyState s) {
    switch (s) {
      case JourneyState.active:
        onStartTracking?.call();
        onStartVoice?.call();
        onStartDeadman?.call();
        break;
      case JourneyState.paused:
        onReduceTracking?.call();
        onStopVoice?.call();
        onPauseDeadman?.call();
        break;
      case JourneyState.stationaryWarning:
        HapticFeedback.vibrate();
        break;
      case JourneyState.sos:
        onTriggerSOS?.call();
        break;
      case JourneyState.completed:
      case JourneyState.cancelled:
        onStopTracking?.call();
        onStopVoice?.call();
        onStopDeadman?.call();
        break;
      default:
        break;
    }
  }

  void _onExit(JourneyState s) {
    // Cleanup on exiting specific states
    if (s == JourneyState.stationaryWarning) {
      // Deadman countdown cancelled externally via userConfirmedOK
    }
  }

  // ── Database operations ──

  /// Create a journey row in Supabase and store ID.
  Future<String> createJourney({
    required String userId,
    required String routeId,
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    bool shareLiveLocation = false,
  }) async {
    final response = await _client.from('journeys').insert({
      'user_id': userId,
      'route_id': routeId,
      'origin_lat': originLat,
      'origin_lng': originLng,
      'dest_lat': destLat,
      'dest_lng': destLng,
      'status': 'active',
      'share_live_location': shareLiveLocation,
    }).select('id').single();

    _journeyId = response['id'] as String;
    return _journeyId!;
  }

  /// Broadcast current state to the journeys table for realtime listeners.
  Future<void> _broadcastState() async {
    if (_journeyId == null) return;
    try {
      final statusName = _state.name;
      final updates = <String, dynamic>{'status': statusName};
      if (_state == JourneyState.completed ||
          _state == JourneyState.cancelled) {
        updates['completed_at'] = DateTime.now().toIso8601String();
      }
      await _client
          .from('journeys')
          .update(updates)
          .eq('id', _journeyId!);
    } catch (_) {
      // Non-critical — UI state is still correct
    }
  }

  /// Reset to idle (e.g. after journey ends and user navigates away).
  void reset() {
    _state = JourneyState.idle;
    _journeyId = null;
  }
}
