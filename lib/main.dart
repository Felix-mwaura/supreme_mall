import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const SupremeMallApp());
}

/// Supreme Mall — one app, multiple services.
///
/// Phase 1 starts with the home screen (account paths for customers and
/// businesses). Department storefronts and the merchant dashboard follow.
class SupremeMallApp extends StatelessWidget {
  const SupremeMallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supreme Mall',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const WelcomeScreen(),
    );
  }
}
