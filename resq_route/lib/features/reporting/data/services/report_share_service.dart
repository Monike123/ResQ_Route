import 'dart:math';

import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Generates time-limited share links for SRR reports and
/// provides OS-level sharing (clipboard / share sheet).
class ReportShareService {
  final SupabaseClient _client;

  ReportShareService({required SupabaseClient client}) : _client = client;

  /// Generate a share link for the given report. Returns the full URL.
  Future<String?> generateShareLink(String reportId) async {
    final linkId = _generateLinkId();
    final expiresAt =
        DateTime.now().add(const Duration(days: 7)).toIso8601String();

    try {
      await _client.from('reports').update({
        'share_link_id': linkId,
        'share_link_expires_at': expiresAt,
      }).eq('id', reportId);

      return 'https://resqroute.app/report/$linkId';
    } catch (_) {
      return null;
    }
  }

  /// Share the report link via the OS share sheet.
  Future<void> shareReport({
    required String reportUrl,
    String? subject,
  }) async {
    await Share.share(
      reportUrl,
      subject: subject ?? 'My ResQ Route Safety Report',
    );
  }

  String _generateLinkId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rng = Random.secure();
    return List.generate(24, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
