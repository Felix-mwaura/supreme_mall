import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Shown when the app is built without `SUPABASE_URL` / `SUPABASE_ANON_KEY`.
///
/// These are compile-time defines, so a build made without them stays broken
/// however many times it is restarted. The screen therefore reports *which*
/// value is missing: both missing means the flag never reached the compiler,
/// one missing usually means a typo in `env.json`.
class ConfigMissingScreen extends StatelessWidget {
  const ConfigMissingScreen({
    super.key,
    this.hasUrl = false,
    this.hasKey = false,
  });

  final bool hasUrl;
  final bool hasKey;

  String get _headline {
    if (!hasUrl && !hasKey) {
      return 'No Supabase credentials in this build';
    }
    return hasUrl ? 'The anon key is missing' : 'The project URL is missing';
  }

  String get _advice {
    if (!hasUrl && !hasKey) {
      return 'Neither value reached the compiler. The most common cause is '
          'starting the app without the flag — the Run button in Android '
          'Studio or VS Code does not pass it. Start from a terminal:';
    }
    if (hasUrl) {
      return '`SUPABASE_URL` was found but `SUPABASE_ANON_KEY` was not. Check '
          'the exact spelling in env.json — names are case-sensitive and must '
          'match exactly:';
    }
    return '`SUPABASE_ANON_KEY` was found but `SUPABASE_URL` was not. Check '
        'the exact spelling in env.json — names are case-sensitive and must '
        'match exactly:';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.navySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.settings_suggest_outlined, color: AppColors.navy),
            ),
            const SizedBox(height: 18),
            Text(
              _headline,
              style: AppText.screenTitle.copyWith(fontSize: 22, color: AppColors.navy),
            ),
            const SizedBox(height: 10),
            Text(
              _advice,
              style: AppText.body.copyWith(color: AppColors.charcoal, height: 1.5),
            ),
            const SizedBox(height: 14),
            _StatusRow(label: 'SUPABASE_URL', present: hasUrl),
            const SizedBox(height: 6),
            _StatusRow(label: 'SUPABASE_ANON_KEY', present: hasKey),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'env.json  (project root, next to pubspec.yaml)\n'
                '{\n'
                '  "SUPABASE_URL": "https://<project-ref>.supabase.co",\n'
                '  "SUPABASE_ANON_KEY": "<publishable key>"\n'
                '}\n\n'
                'flutter run --dart-define-from-file=env.json',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11.5,
                  height: 1.6,
                  color: AppColors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Already ran that? These values are baked in when the app is '
              'compiled, so a build made before env.json existed keeps the old '
              'state. Run `flutter clean` and start again.',
              style: AppText.caption.copyWith(color: AppColors.slate, height: 1.6),
            ),
            const SizedBox(height: 12),
            Text(
              'Use the publishable (anon) key only — never the service-role key. '
              'env.json is git-ignored; env.example.json shows the shape.',
              style: AppText.caption.copyWith(color: AppColors.slate, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.present});

  final String label;
  final bool present;

  @override
  Widget build(BuildContext context) {
    final Color accent = present ? AppColors.emerald : const Color(0xFFB3261E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: present ? AppColors.emeraldSoft : const Color(0x14B3261E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            present ? Icons.check_circle_outline : Icons.error_outline,
            size: 15,
            color: accent,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
          ),
          Text(
            present ? 'found' : 'missing',
            style: AppText.caption.copyWith(fontSize: 10.5, color: accent),
          ),
        ],
      ),
    );
  }
}
