import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:resq_route/core/constants/env_config.dart';

/// Centralized Supabase configuration and access.
class SupabaseConfig {
  SupabaseConfig._();

  /// Initialize Supabase with compile-time env vars.
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
    );
  }

  /// The Supabase client instance.
  static SupabaseClient get client => Supabase.instance.client;

  /// Auth client shortcut.
  static GoTrueClient get auth => client.auth;

  /// Storage client shortcut.
  static SupabaseStorageClient get storage => client.storage;
}
