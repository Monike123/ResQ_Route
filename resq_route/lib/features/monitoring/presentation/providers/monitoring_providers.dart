import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../routes/presentation/providers/route_providers.dart';
import '../../data/services/journey_state_machine.dart';
import '../../data/services/gps_tracking_service.dart';
import '../../data/services/deadman_switch_service.dart';
import '../../data/services/voice_trigger_service.dart';
import '../../data/services/route_deviation_detector.dart';
import '../../data/services/battery_service.dart';

// ── Service providers ──

final journeyStateMachineProvider = Provider<JourneyStateMachine>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return JourneyStateMachine(client: client);
});

final gpsTrackingServiceProvider = Provider<GpsTrackingService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return GpsTrackingService(client: client);
});

final deadmanSwitchProvider = Provider<DeadmanSwitchService>((ref) {
  return DeadmanSwitchService(
    onStationaryWarning: () {
      ref.read(journeyStateMachineProvider).transition(JourneyState.stationaryWarning);
    },
    onAutoSOS: () {
      ref.read(journeyStateMachineProvider).transition(JourneyState.sos);
    },
    onCountdownTick: (remaining) {
      ref.read(deadmanCountdownProvider.notifier).state = remaining;
    },
  );
});

final voiceTriggerServiceProvider = Provider<VoiceTriggerService>((ref) {
  return VoiceTriggerService(
    onTriggerDetected: () {
      ref.read(voiceTriggerDetectedProvider.notifier).state = true;
    },
    onTriggerConfirmed: () {
      ref.read(journeyStateMachineProvider).transition(JourneyState.sos);
    },
    onTriggerCancelled: () {
      ref.read(voiceTriggerDetectedProvider.notifier).state = false;
    },
  );
});

final routeDeviationDetectorProvider = Provider<RouteDeviationDetector>((ref) {
  return RouteDeviationDetector();
});

final batteryServiceProvider = Provider<BatteryService>((ref) {
  return BatteryService();
});

// ── State providers ──

/// Current journey state (for UI reactivity).
final journeyStateProvider = StateProvider<JourneyState>((ref) {
  return JourneyState.idle;
});

/// Active journey ID.
final activeJourneyIdProvider = StateProvider<String?>((ref) => null);

/// Deadman countdown remaining seconds.
final deadmanCountdownProvider = StateProvider<int>((ref) => 60);

/// Whether voice trigger was just detected (grace period).
final voiceTriggerDetectedProvider = StateProvider<bool>((ref) => false);

/// Current battery level.
final batteryLevelProvider = StateProvider<int>((ref) => 100);

/// Whether the user wants to share live location.
final shareLiveLocationProvider = StateProvider<bool>((ref) => false);
