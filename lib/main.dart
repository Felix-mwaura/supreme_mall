import 'package:flutter/material.dart';

import 'config/env.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/config_missing_screen.dart';
import 'services/supabase_bootstrap.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fail loudly and safely if the build was made without Supabase config,
  // instead of throwing a socket error on the first tap.
  if (!Env.isConfigured) {
    runApp(const SupremeMallApp(home: ConfigMissingScreen()));
    return;
  }

  await SupabaseBootstrap.initialize();
  runApp(const SupremeMallApp());
}

/// Supreme Mall — one app, multiple services.
class SupremeMallApp extends StatelessWidget {
  const SupremeMallApp({super.key, this.home});

  /// Overridable for widget tests; production always starts at the auth gate.
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supreme Mall',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: home ?? const AuthGate(),
    );
  }
}
