import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../routes/presentation/providers/route_providers.dart';
import '../../data/services/feedback_service.dart';
import '../../data/services/map_snapshot_service.dart';
import '../../data/services/report_share_service.dart';
import '../../data/services/srr_report_generator.dart';

// ── Services ──

final srrReportGeneratorProvider = Provider<SRRReportGenerator>(
  (ref) {
    final client = ref.watch(supabaseClientProvider);
    return SRRReportGenerator(client: client);
  },
);

final mapSnapshotServiceProvider = Provider<MapSnapshotService>(
  (ref) {
    final client = ref.watch(supabaseClientProvider);
    return MapSnapshotService(client: client);
  },
);

final reportShareServiceProvider = Provider<ReportShareService>(
  (ref) {
    final client = ref.watch(supabaseClientProvider);
    return ReportShareService(client: client);
  },
);

final feedbackServiceProvider = Provider<FeedbackService>(
  (ref) {
    final client = ref.watch(supabaseClientProvider);
    return FeedbackService(client: client);
  },
);

// ── State ──

/// ID of the last generated report.
final lastReportIdProvider = StateProvider<String?>((ref) => null);

/// Whether a report is currently being generated.
final reportGeneratingProvider = StateProvider<bool>((ref) => false);
