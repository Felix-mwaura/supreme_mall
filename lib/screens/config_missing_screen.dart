import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Shown when the app is built without `SUPABASE_URL` / `SUPABASE_ANON_KEY`.
///
/// Without this screen the failure appears much later as an unexplained network
/// error, which is the kind of silent breakage the brief forbids.
class ConfigMissingScreen extends StatelessWidget {
  const ConfigMissingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 20),
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
                'Supabase is not configured',
                style: AppText.screenTitle.copyWith(fontSize: 22, color: AppColors.navy),
              ),
              const SizedBox(height: 10),
              Text(
                'This build has no Supabase URL or publishable key, so sign-up and '
                'sign-in cannot work. Add them with a local, git-ignored env file:',
                style: AppText.body.copyWith(color: AppColors.charcoal),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'env.json\n'
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
                'Use the publishable (anon) key only — never the service-role key. '
                'env.json is git-ignored; see env.example.json.',
                style: AppText.caption.copyWith(color: AppColors.slate, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
