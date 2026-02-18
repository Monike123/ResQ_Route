import 'package:supabase_flutter/supabase_flutter.dart';

/// Submits post-journey feedback (safety rating, score accuracy,
/// optional comment) to the `feedback` table.
class FeedbackService {
  final SupabaseClient _client;

  FeedbackService({required SupabaseClient client}) : _client = client;

  /// Submit feedback for a completed journey.
  Future<void> submitFeedback({
    required String journeyId,
    required String userId,
    required int safetyRating,
    String? scoreAccuracy,
    String? comment,
  }) async {
    await _client.from('feedback').insert({
      'journey_id': journeyId,
      'user_id': userId,
      'safety_rating': safetyRating,
      'score_accuracy': scoreAccuracy,
      'comment': comment,
    });
  }

  /// Check if feedback has already been submitted for this journey.
  Future<bool> hasFeedback(String journeyId) async {
    try {
      final result = await _client
          .from('feedback')
          .select('id')
          .eq('journey_id', journeyId)
          .maybeSingle();
      return result != null;
    } catch (_) {
      return false;
    }
  }
}
