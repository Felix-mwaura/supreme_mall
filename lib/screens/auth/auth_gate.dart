import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/app_profile.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_bootstrap.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/app_button.dart';
import '../business/business_status_screen.dart';
import '../home/customer_home_screen.dart';
import '../welcome_screen.dart';

/// Decides what the app shows, from the real session.
///
/// signed out          → [WelcomeScreen]
/// customer signed in  → [CustomerHomeScreen]
/// business signed in  → [BusinessStatusScreen] (pending / approved / rejected)
///
/// There is no "skip login" path: every destination here requires a session,
/// and RLS rejects queries without one.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<dynamic>? _subscription;
  Future<AppProfile?>? _profileFuture;

  AuthService get _auth => SupabaseBootstrap.auth;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    _subscription?.cancel();
    _subscription = _auth.onAuthStateChange.listen((dynamic _) {
      if (mounted) {
        setState(_load);
      }
    });
    _load();
  }

  void _load() {
    final bool signedIn = _auth.session != null;
    _profileFuture = signedIn ? _auth.loadProfile() : Future<AppProfile?>.value(null);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
    } on AuthFailure catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: const Color(0xFF8E1B12)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_auth.session == null) {
      return const WelcomeScreen();
    }

    return FutureBuilder<AppProfile?>(
      future: _profileFuture,
      builder: (BuildContext context, AsyncSnapshot<AppProfile?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _GateScaffold(
            child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2.4),
          );
        }

        if (snapshot.hasError) {
          final Object error = snapshot.error!;
          final String message =
              error is AuthFailure ? error.message : 'We could not load your account.';
          return _GateScaffold(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.cloud_off_rounded, size: 34, color: AppColors.inkMutedOnDark),
                const SizedBox(height: 14),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppText.bodyTight.copyWith(color: AppColors.inkMutedOnDark),
                ),
                const SizedBox(height: 20),
                AppButton(label: 'Try again', onPressed: () => setState(_load)),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Sign out',
                  onPressed: _signOut,
                  background: AppColors.surface,
                  foreground: AppColors.gold,
                ),
              ],
            ),
          );
        }

        final AppProfile? profile = snapshot.data;
        if (profile == null) {
          return _GateScaffold(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.person_off_outlined, size: 34, color: AppColors.inkMutedOnDark),
                const SizedBox(height: 14),
                Text(
                  'Your profile is missing. Please sign out and register again.',
                  textAlign: TextAlign.center,
                  style: AppText.bodyTight.copyWith(color: AppColors.inkMutedOnDark),
                ),
                const SizedBox(height: 20),
                AppButton(label: 'Sign out', onPressed: _signOut),
              ],
            ),
          );
        }

        if (profile.isBusiness) {
          return BusinessStatusScreen(profile: profile, onSignOut: _signOut);
        }

        return CustomerHomeScreen(profile: profile, onSignOut: _signOut);
      },
    );
  }
}

class _GateScaffold extends StatelessWidget {
  const _GateScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: child,
        ),
      ),
    );
  }
}
