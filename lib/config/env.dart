/// Build-time configuration.
///
/// The Supabase URL and publishable ("anon") key are injected at build time so
/// no credentials live in the repository:
///
/// ```bash
/// flutter run --dart-define-from-file=env.json
/// ```
///
/// `env.json` is git-ignored; `env.example.json` shows the shape. The
/// service-role key must never be placed here — the client only ever needs the
/// publishable key, and every privileged action is enforced by RLS.
class Env {
  const Env._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Deep link the auth emails return to. Must also be listed in the Supabase
  /// project's redirect allow list.
  static const String authRedirectUrl = 'com.suprememall.app://login-callback';

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
