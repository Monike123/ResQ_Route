import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vibration/vibration.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../routes/presentation/providers/route_providers.dart';
import '../../data/services/journey_state_machine.dart';

import '../providers/monitoring_providers.dart';

/// Active journey screen — full-bleed map with live tracking, SOS button,
/// pause/resume, stationary warning overlay, and deviation alerts.
class ActiveJourneyScreen extends ConsumerStatefulWidget {
  const ActiveJourneyScreen({super.key});

  @override
  ConsumerState<ActiveJourneyScreen> createState() =>
      _ActiveJourneyScreenState();
}

class _ActiveJourneyScreenState extends ConsumerState<ActiveJourneyScreen> {
  GoogleMapController? _mapController;
  Timer? _vibrationTimer;

  @override
  void initState() {
    super.initState();
    _startJourney();
  }

  Future<void> _startJourney() async {
    final stateMachine = ref.read(journeyStateMachineProvider);
    final gps = ref.read(gpsTrackingServiceProvider);
    final deadman = ref.read(deadmanSwitchProvider);
    final voice = ref.read(voiceTriggerServiceProvider);
    final deviation = ref.read(routeDeviationDetectorProvider);
    final battery = ref.read(batteryServiceProvider);
    final route = ref.read(fetchedRoutesProvider).firstOrNull;
    final user = ref.read(supabaseClientProvider).auth.currentUser;

    if (route == null || user == null) return;

    // Wire callbacks on state machine
    stateMachine.onStateChanged = (state) {
      if (mounted) {
        ref.read(journeyStateProvider.notifier).state = state;
      }
    };
    stateMachine.onStartTracking = () {
      final jId = stateMachine.journeyId;
      if (jId != null) gps.startTracking(journeyId: jId);
    };
    stateMachine.onStopTracking = () { gps.stopTracking(); };
    stateMachine.onReduceTracking = () { gps.reduceFrequency(); };
    stateMachine.onStartVoice = () { voice.startListening(); };
    stateMachine.onStopVoice = () { voice.stopListening(); };
    stateMachine.onStartDeadman = () { deadman.start(); };
    stateMachine.onPauseDeadman = () { deadman.pause(); };
    stateMachine.onStopDeadman = () { deadman.stop(); };
    stateMachine.onTriggerSOS = () { _handleSOS(); };

    // Set route waypoints for deviation detector
    final waypoints = route.waypoints
        .map((w) => LatLng(w['lat']!, w['lng']!))
        .toList();
    deviation.setRoute(waypoints);

    // Wire battery service
    battery.onIntervalChange = (interval) { gps.changeInterval(interval); };
    battery.onVoiceToggle = (listen) {
      if (listen) {
        voice.startListening();
      } else {
        voice.stopListening();
      }
    };
    battery.onLowBattery = (level) {
      if (mounted) {
        ref.read(batteryLevelProvider.notifier).state = level;
      }
    };
    battery.onCriticalBattery = () {
      // Phase 6 will handle emergency contact SMS
    };
    battery.start();

    // Create journey in DB
    try {
      final journeyId = await stateMachine.createJourney(
        userId: user.id,
        routeId: route.id ?? '',
        originLat: route.originLat,
        originLng: route.originLng,
        destLat: route.destLat,
        destLng: route.destLng,
        shareLiveLocation: ref.read(shareLiveLocationProvider),
      );
      ref.read(activeJourneyIdProvider.notifier).state = journeyId;

      // Transition idle → preTrip → active
      stateMachine.transition(JourneyState.preTrip);
      stateMachine.transition(JourneyState.active);

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start journey: $e')),
        );
        context.pop();
      }
    }
  }

  void _handleSOS() {
    // Start vibration pattern
    _vibrationTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 500);
      }
    });
  }

  @override
  void dispose() {
    _vibrationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final journeyState = ref.watch(journeyStateProvider);
    final route = ref.watch(fetchedRoutesProvider).firstOrNull;
    final deadmanCountdown = ref.watch(deadmanCountdownProvider);
    final voiceTriggered = ref.watch(voiceTriggerDetectedProvider);
    final batteryLevel = ref.watch(batteryLevelProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: route != null
                  ? LatLng(route.originLat, route.originLng)
                  : const LatLng(0, 0),
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (c) => _mapController = c,
          ),

          // ── Top bar ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: _buildStatusBar(theme, journeyState, batteryLevel),
          ),

          // ── Bottom controls ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(theme, journeyState),
          ),

          // ── Stationary warning overlay ──
          if (journeyState == JourneyState.stationaryWarning)
            _buildStationaryOverlay(theme, deadmanCountdown),

          // ── Voice trigger grace overlay ──
          if (voiceTriggered)
            _buildVoiceGraceOverlay(theme),

          // ── Low battery warning ──
          if (batteryLevel <= 15 && journeyState == JourneyState.active)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 16,
              right: 16,
              child: _buildLowBatteryBanner(theme, batteryLevel),
            ),
        ],
      ),
    );
  }

  // ── UI Builders ──

  Widget _buildStatusBar(ThemeData theme, JourneyState state, int battery) {
    final color = state == JourneyState.sos
        ? AppColors.sosRed
        : state == JourneyState.stationaryWarning
            ? AppColors.safetyModerate
            : AppColors.safetySafe;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _stateLabel(state),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const Spacer(),
          Icon(Icons.battery_std, size: 16, color: battery <= 15 ? AppColors.error : null),
          const SizedBox(width: 4),
          Text('$battery%', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme, JourneyState state) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20, 16, 20, MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Pause / Resume
          if (state == JourneyState.active || state == JourneyState.paused)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  final sm = ref.read(journeyStateMachineProvider);
                  if (state == JourneyState.active) {
                    sm.transition(JourneyState.paused);
                  } else {
                    sm.transition(JourneyState.active);
                  }
                },
                icon: Icon(
                  state == JourneyState.paused ? Icons.play_arrow : Icons.pause,
                ),
                label: Text(state == JourneyState.paused ? 'Resume' : 'Pause'),
              ),
            ),
          if (state == JourneyState.active || state == JourneyState.paused)
            const SizedBox(width: 12),

          // SOS Button
          if (state == JourneyState.active ||
              state == JourneyState.paused ||
              state == JourneyState.stationaryWarning)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ref
                      .read(journeyStateMachineProvider)
                      .transition(JourneyState.sos);
                },
                icon: const Icon(Icons.sos, color: Colors.white),
                label: const Text('SOS',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sosRed,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

          // End Journey (SOS state)
          if (state == JourneyState.sos)
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  ref
                      .read(journeyStateMachineProvider)
                      .transition(JourneyState.completed);
                  _cleanup();
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.safetySafe,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('End Journey',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStationaryOverlay(ThemeData theme, int countdown) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.safetyModerate, size: 48),
              const SizedBox(height: 16),
              Text(
                'ARE YOU OKAY?',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "You haven't moved for 20 minutes.",
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Auto-SOS in: 0:${countdown.toString().padLeft(2, '0')}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: countdown <= 10 ? AppColors.error : null,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: countdown / 60,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  countdown <= 10 ? AppColors.error : AppColors.safetyModerate,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(deadmanSwitchProvider).userConfirmedOK();
                    ref
                        .read(journeyStateMachineProvider)
                        .transition(JourneyState.active);
                  },
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text("I'M OKAY",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.safetySafe,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'If you don\'t respond, emergency contacts will be alerted.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceGraceOverlay(ThemeData theme) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mic, color: AppColors.sosRed, size: 48),
              const SizedBox(height: 16),
              Text(
                'SOS Voice Detected!',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.sosRed,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Triggering SOS in 3 seconds...',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  ref.read(voiceTriggerServiceProvider).cancelTrigger();
                },
                child: const Text('CANCEL — False Alarm'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLowBatteryBanner(ThemeData theme, int level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.safetyModerate.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.battery_alert, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Low Battery ($level%) — safety monitoring may be affected',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _stateLabel(JourneyState state) {
    switch (state) {
      case JourneyState.active:
        return 'Journey Active';
      case JourneyState.paused:
        return 'Paused';
      case JourneyState.stationaryWarning:
        return 'Stationary Warning';
      case JourneyState.sos:
        return '🚨 SOS ACTIVE';
      case JourneyState.completed:
        return 'Completed';
      default:
        return 'Starting...';
    }
  }

  void _cleanup() {
    ref.read(gpsTrackingServiceProvider).stopTracking();
    ref.read(voiceTriggerServiceProvider).stopListening();
    ref.read(deadmanSwitchProvider).stop();
    ref.read(batteryServiceProvider).stop();
    ref.read(journeyStateMachineProvider).reset();
    _vibrationTimer?.cancel();
  }
}
