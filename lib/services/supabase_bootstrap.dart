import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import 'auth_service.dart';

/// Initialises Supabase once and exposes the shared [AuthService].
///
/// `Supabase.initialize` also restores any persisted session, which is what
/// makes "stay signed in after restart" work without extra code.
class SupabaseBootstrap {
  const SupabaseBootstrap._();

  static bool _initialized = false;
  static late final AuthService auth;

  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
      debug: false,
    );
    auth = AuthService(Supabase.instance.client);
    _initialized = true;
  }
}
