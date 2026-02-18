import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../routes/presentation/providers/route_providers.dart';
import '../../data/services/direct_sms_service.dart';
import '../../data/services/forensic_snapshot_service.dart';
import '../../data/services/offline_sos_queue.dart';
import '../../data/services/shake_detector_service.dart';
import '../../data/services/sos_service.dart';

// ── Services ──

final forensicSnapshotServiceProvider = Provider<ForensicSnapshotService>(
  (ref) {
    final client = ref.watch(supabaseClientProvider);
    return ForensicSnapshotService(client: client);
  },
);

final directSMSServiceProvider = Provider<DirectSMSService>(
  (ref) => DirectSMSService(),
);

final offlineSOSQueueProvider = Provider<OfflineSOSQueue>(
  (ref) {
    final client = ref.watch(supabaseClientProvider);
    return OfflineSOSQueue(
      prefs: ref.watch(_sharedPrefsProvider),
      client: client,
    );
  },
);

/// Cached SharedPreferences instance — override in main.dart.
final _sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'SharedPreferences must be overridden before use.',
  ),
);

/// Expose for overriding in main.dart ProviderScope.
final sharedPrefsProvider = _sharedPrefsProvider;

final sosServiceProvider = Provider<SOSService>(
  (ref) {
    final client = ref.watch(supabaseClientProvider);
    return SOSService(
      client: client,
      forensicService: ref.watch(forensicSnapshotServiceProvider),
      directSMS: ref.watch(directSMSServiceProvider),
      offlineQueue: ref.watch(offlineSOSQueueProvider),
    );
  },
);

final shakeDetectorServiceProvider = Provider<ShakeDetectorService>(
  (ref) => ShakeDetectorService(),
);

// ── State ──

/// Whether an SOS is currently being processed.
final sosActiveProvider = StateProvider<bool>((ref) => false);

/// Current SOS event ID (if active).
final activeSosEventIdProvider = StateProvider<String?>((ref) => null);
