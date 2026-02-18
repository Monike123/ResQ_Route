import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile_model.dart';
import '../models/emergency_contact_model.dart';

/// Remote data source for user profiles and emergency contacts.
class ProfileRemoteDataSource {
  final SupabaseClient _client;

  ProfileRemoteDataSource(this._client);

  // ── USER PROFILE ──

  /// Get current user's profile.
  Future<UserProfileModel?> getProfile(String userId) async {
    final response = await _client
        .from('user_profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return UserProfileModel.fromJson(response);
  }

  /// Update user profile fields.
  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await _client.from('user_profiles').update(data).eq('id', userId);
  }

  /// Mark onboarding as completed.
  Future<void> completeOnboarding(String userId) async {
    await _client
        .from('user_profiles')
        .update({'onboarding_completed': true})
        .eq('id', userId);
  }

  // ── EMERGENCY CONTACTS ──

  /// Get all emergency contacts for a user (ordered by priority).
  Future<List<EmergencyContactModel>> getContacts(String userId) async {
    final response = await _client
        .from('emergency_contacts')
        .select()
        .eq('user_id', userId)
        .order('priority');

    return (response as List<dynamic>)
        .map((json) =>
            EmergencyContactModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Save or update a single emergency contact (upsert by user_id + priority).
  Future<void> upsertContact(EmergencyContactModel contact) async {
    await _client.from('emergency_contacts').upsert(
      contact.toJson(),
      onConflict: 'user_id,priority',
    );
  }

  /// Save all contacts at once (replaces existing).
  Future<void> saveAllContacts(List<EmergencyContactModel> contacts) async {
    final userId = contacts.first.userId;

    // Delete existing contacts for the user
    await _client
        .from('emergency_contacts')
        .delete()
        .eq('user_id', userId);

    // Insert new contacts
    for (final contact in contacts) {
      await _client.from('emergency_contacts').insert(contact.toJson());
    }
  }

  /// Delete a specific emergency contact.
  Future<void> deleteContact(String contactId) async {
    await _client.from('emergency_contacts').delete().eq('id', contactId);
  }
}
