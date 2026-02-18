import 'package:url_launcher/url_launcher.dart';

/// Fallback SMS service — sends SOS alerts directly from the device
/// when Twilio / Edge Functions / internet are unavailable.
///
/// Uses `url_launcher` sms: scheme, which opens the default SMS app
/// pre-filled with the message. No SEND_SMS permission required.
class DirectSMSService {
  /// Send SOS SMS to all contacts via the device SMS app.
  Future<void> sendDirectSMS({
    required List<Map<String, dynamic>> contacts,
    required double lat,
    required double lng,
    required String userName,
  }) async {
    final message = Uri.encodeComponent(
      '🚨 SOS from $userName via ResQ Route! '
      'Location: https://maps.google.com/?q=$lat,$lng '
      'Time: ${DateTime.now().toIso8601String()} '
      'CALL 112 IF CONCERNED',
    );

    for (final contact in contacts) {
      final phone = contact['phone'] as String? ?? '';
      if (phone.isEmpty) continue;

      final uri = Uri.parse('sms:+91$phone?body=$message');
      try {
        await launchUrl(uri);
      } catch (_) {
        // SMS launch failed — last resort exhausted
      }
    }
  }
}
