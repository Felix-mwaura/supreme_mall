import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Shared chrome for the account-creation screens: a navy header carrying the
/// role badge, back navigation and the screen title, then a scrollable body.
class SignupScaffold extends StatelessWidget {
  const SignupScaffold({
    super.key,
    required this.roleLabel,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String roleLabel;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[AppColors.navyDeep, AppColors.navy, AppColors.navyLift],
                stops: <double>[0.0, 0.6, 1.0],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.of(context).maybePop(),
                            borderRadius: BorderRadius.circular(100),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.whiteFaint,
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(color: AppColors.hairline),
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                size: 18,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.whiteGlass,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: AppColors.hairline),
                          ),
                          child: Text(
                            roleLabel.toUpperCase(),
                            style: AppText.sectionLabel.copyWith(
                              fontSize: 9.5,
                              letterSpacing: 1.2,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(title, style: AppText.screenTitle.copyWith(color: AppColors.white)),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: AppText.bodyTight.copyWith(color: AppColors.whiteMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small muted line used to be honest about what this prototype does not do
/// yet (nothing is persisted until Supabase auth is connected).
class PreviewBuildNote extends StatelessWidget {
  const PreviewBuildNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Icon(Icons.info_outline, size: 13, color: AppColors.slate),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Preview build — details are not sent to a server yet.',
            style: AppText.caption.copyWith(fontSize: 11, color: AppColors.slate),
          ),
        ),
      ],
    );
  }
}
