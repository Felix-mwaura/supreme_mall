import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../models/app_profile.dart';
import '../../models/business_application.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_bootstrap.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/app_button.dart';
import '../../widgets/dark_surface.dart';

/// Where a business owner lands after signing in, until approval.
///
/// The status shown here comes from `businesses.status`, which only an
/// administrator can change. Nothing on this screen can approve the business —
/// the database would reject it.
class BusinessStatusScreen extends StatefulWidget {
  const BusinessStatusScreen({
    super.key,
    required this.profile,
    required this.onSignOut,
  });

  final AppProfile profile;
  final Future<void> Function() onSignOut;

  @override
  State<BusinessStatusScreen> createState() => _BusinessStatusScreenState();
}

class _BusinessStatusScreenState extends State<BusinessStatusScreen> {
  late Future<Map<String, dynamic>?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>?> _load() {
    if (!SupabaseBootstrap.isInitialized) {
      return Future<Map<String, dynamic>?>.value(null);
    }
    return SupabaseBootstrap.auth.loadOwnBusiness();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.gold,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            setState(() => _future = _load());
            await _future;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: <Widget>[
              Text(
                'Karibu, ${widget.profile.firstName}',
                style: AppText.screenTitle.copyWith(fontSize: 22, color: AppColors.inkOnDark),
              ),
              const SizedBox(height: 5),
              Text(
                'Business account',
                style: AppText.caption.copyWith(color: AppColors.inkMutedOnDark),
              ),
              const SizedBox(height: 22),
              FutureBuilder<Map<String, dynamic>?>(
                future: _future,
                builder: (
                  BuildContext context,
                  AsyncSnapshot<Map<String, dynamic>?> snapshot,
                ) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2.4),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    final Object error = snapshot.error!;
                    return _Message(
                      icon: Icons.cloud_off_rounded,
                      title: 'Could not load your application',
                      message: error is AuthFailure
                          ? error.message
                          : 'Check your connection and pull down to retry.',
                    );
                  }

                  final Map<String, dynamic>? row = snapshot.data;
                  if (row == null) {
                    return const _Message(
                      icon: Icons.folder_off_outlined,
                      title: 'No business details yet',
                      message:
                          'Your account exists but we have no application on file. '
                          'Sign out and submit the business form again.',
                    );
                  }

                  return _StatusCard(application: BusinessApplication.fromMap(row));
                },
              ),
              const SizedBox(height: 22),
              AppButton(
                label: 'Sign out',
                onPressed: () => widget.onSignOut(),
                background: AppColors.surface,
                foreground: AppColors.gold,
              ),
              const SizedBox(height: 16),
              Text(
                'Pull down to refresh your status. '
                'Approval is handled by the Supreme Mall team, not by this app.',
                textAlign: TextAlign.center,
                style: AppText.caption.copyWith(
                  fontSize: 10,
                  height: 1.6,
                  color: AppColors.inkMutedOnDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.application});

  final BusinessApplication application;

  @override
  Widget build(BuildContext context) {
    final Color accent = switch (application.status) {
      BusinessStatus.pending => AppColors.gold,
      BusinessStatus.approved => AppColors.emerald,
      BusinessStatus.rejected => const Color(0xFFE4572E),
      BusinessStatus.suspended => const Color(0xFFE4572E),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: darkSurface(radius: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      application.name,
                      style: AppText.cardTitle.copyWith(fontSize: 15, color: AppColors.inkOnDark),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppColors.hairlineDark),
                    ),
                    child: Text(
                      application.status.label.toUpperCase(),
                      style: AppText.sectionLabel.copyWith(
                        fontSize: 8,
                        letterSpacing: 0.9,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (application.departments.isNotEmpty)
                Text(
                  application.departments.join(' · '),
                  style: AppText.caption.copyWith(fontSize: 10.5, color: accent),
                ),
              if (application.area.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    application.area,
                    style: AppText.caption.copyWith(
                      fontSize: 10.5,
                      color: AppColors.inkMutedOnDark,
                    ),
                  ),
                ),
              if (application.status == BusinessStatus.rejected &&
                  (application.rejectionReason ?? '').isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  'Reason: ${application.rejectionReason}',
                  style: AppText.caption.copyWith(fontSize: 10.5, color: const Color(0xFFF3A28E)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: darkSurface(radius: 18),
          child: Column(
            children: <Widget>[
              _Step(
                label: 'Application received',
                detail: 'Your details are saved',
                done: true,
                isLast: false,
              ),
              _Step(
                label: 'Document review',
                detail: 'Permit, owner ID and contact details — ${AppConfig.businessReviewWindow}',
                done: application.status.canSell,
                isLast: false,
              ),
              _Step(
                label: 'Approved — start selling',
                detail: 'Your dashboard opens once approved',
                done: application.status == BusinessStatus.approved,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.detail,
    required this.done,
    required this.isLast,
  });

  final String label;
  final String detail;
  final bool done;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Column(
          children: <Widget>[
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: done ? AppColors.emerald : AppColors.surfaceRaised,
                shape: BoxShape.circle,
                border: Border.all(
                  color: done ? AppColors.emerald : AppColors.hairlineDark,
                  width: 1.4,
                ),
              ),
              child: done ? const Icon(Icons.check, size: 11, color: AppColors.white) : null,
            ),
            if (!isLast) Container(width: 1.4, height: 26, color: AppColors.hairlineDark),
          ],
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: AppText.bodyTight.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkOnDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: AppText.caption.copyWith(fontSize: 9.5, color: AppColors.inkMutedOnDark),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: darkSurface(radius: 18),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 28, color: AppColors.inkMutedOnDark),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppText.cardTitle.copyWith(fontSize: 13, color: AppColors.inkOnDark),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppText.caption.copyWith(color: AppColors.inkMutedOnDark, height: 1.6),
          ),
        ],
      ),
    );
  }
}
