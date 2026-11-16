import 'package:flutter/material.dart';

import '../../../models/app_profile.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text.dart';
import '../../../widgets/dark_surface.dart';

/// Profile tab — the signed-in person, their permissions and support links.
///
/// Identity comes from the real `profiles` row supplied by [AuthGate]; nothing
/// here is hard-coded. Rows that need a backend (addresses, payment methods,
/// notifications) say so when tapped instead of pretending to save. Sign out
/// ends the Supabase session.
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key, this.profile, this.onSignOut});

  final AppProfile? profile;

  /// Wired to `SupabaseBootstrap.auth.signOut()` by the auth gate.
  final Future<void> Function()? onSignOut;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _signingOut = false;

  void _notYet(BuildContext context, String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$what arrives with the account milestone.',
            style: const TextStyle(fontSize: 12.5),
          ),
          backgroundColor: AppColors.surfaceRaised,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  Future<void> _signOut(BuildContext context) async {
    if (_signingOut) {
      return;
    }
    setState(() => _signingOut = true);
    if (widget.onSignOut != null) {
      await widget.onSignOut!();
    } else if (context.mounted) {
      // Without a gate (widget tests) return to the entry point.
      Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
    }
    if (mounted) {
      setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 130),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Profile',
              style: AppText.screenTitle.copyWith(fontSize: 24, color: AppColors.inkOnDark),
            ),
            const SizedBox(height: 16),
            _IdentityCard(profile: widget.profile),
            const SizedBox(height: 20),
            const DarkSectionLabel(label: 'Account'),
            _Row(
              icon: Icons.place_outlined,
              label: 'Saved addresses',
              trailing: '2',
              onTap: () => _notYet(context, 'Address editing'),
            ),
            const SizedBox(height: 8),
            _Row(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Payment methods',
              trailing: 'M-Pesa',
              onTap: () => _notYet(context, 'Payment methods'),
            ),
            const SizedBox(height: 8),
            _Row(
              icon: Icons.notifications_none_rounded,
              label: 'Notifications',
              onTap: () => _notYet(context, 'Notification preferences'),
            ),
            const SizedBox(height: 8),
            _Row(
              icon: Icons.translate_rounded,
              label: 'Language',
              trailing: 'English',
              onTap: () => _notYet(context, 'Kiswahili support'),
            ),
            const SizedBox(height: 20),
            const DarkSectionLabel(label: 'Support'),
            _Row(
              icon: Icons.support_agent_rounded,
              label: 'Help & support',
              onTap: () => _notYet(context, 'Live support'),
            ),
            const SizedBox(height: 8),
            _Row(
              icon: Icons.shield_outlined,
              label: 'Privacy & terms',
              onTap: () => _notYet(context, 'Policy documents'),
            ),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: _signingOut ? null : () => _signOut(context),
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x4DD4A017)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (_signingOut)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                      )
                    else
                      const Icon(Icons.logout_rounded, size: 16, color: AppColors.gold),
                    const SizedBox(width: 8),
                    Text(
                      _signingOut ? 'Signing out…' : 'Sign out',
                      style: AppText.button.copyWith(fontSize: 13, color: AppColors.gold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Supreme Mall · v0.4\nSupreme Solutions Ltd · Nyeri, Kenya',
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(
                fontSize: 9.5,
                height: 1.6,
                color: AppColors.inkMutedOnDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({this.profile});

  final AppProfile? profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: darkSurface(radius: 18),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xFFE8BF4A), AppColors.gold],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              profile?.initials ?? 'SM',
              style: AppText.cardTitle.copyWith(fontSize: 17, color: AppColors.navy),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  profile?.fullName.isNotEmpty == true ? profile!.fullName : 'Your account',
                  style: AppText.cardTitle.copyWith(fontSize: 14, color: AppColors.inkOnDark),
                ),
                const SizedBox(height: 3),
                Text(
                  profile?.phone ?? 'No phone saved yet',
                  style: AppText.caption.copyWith(fontSize: 10.5, color: AppColors.inkMutedOnDark),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    profile?.isBusiness == true ? 'BUSINESS ACCOUNT' : 'CUSTOMER ACCOUNT',
                    style: AppText.sectionLabel.copyWith(
                      fontSize: 7,
                      letterSpacing: 0.8,
                      color: AppColors.inkMutedOnDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        decoration: darkSurface(radius: 14),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 17, color: AppColors.inkMutedOnDark),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppText.bodyTight.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkOnDark,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: AppText.caption.copyWith(fontSize: 10.5, color: AppColors.inkMutedOnDark),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 17, color: AppColors.inkMutedOnDark),
          ],
        ),
      ),
    );
  }
}
