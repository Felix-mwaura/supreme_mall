import 'package:flutter/material.dart';

import '../models/department.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/department_pill.dart';
import '../widgets/role_option_card.dart';
import '../widgets/supreme_logo.dart';
import 'auth/business_signup_screen.dart';
import 'auth/customer_signup_screen.dart';
import 'auth/sign_in_screen.dart';

/// Supreme Mall home screen.
///
/// The entry point of the app. Per the Developer Brief (section 3) it makes the
/// main action obvious — here that action is choosing how to use the platform:
/// a customer account or a business account. The department pills preview the
/// seven services (Phase 1 departments first) so the breadth of the marketplace
/// is visible before sign-up.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (BuildContext _) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const _WelcomeHero(),
            Transform.translate(
              offset: const Offset(0, -34),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _AccountCard(
                      onCustomer: () => _open(context, const CustomerSignupScreen()),
                      onBusiness: () => _open(context, const BusinessSignupScreen()),
                    ),
                    const SizedBox(height: 14),
                    const _VerificationNote(),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'Already have an account?',
                          style: AppText.caption.copyWith(color: AppColors.charcoal),
                        ),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: () => _open(context, const SignInScreen()),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            foregroundColor: AppColors.navy,
                            textStyle: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('Sign in'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'By continuing you agree to our Terms of Service\nand Privacy Policy.',
                      textAlign: TextAlign.center,
                      style: AppText.caption.copyWith(
                        color: AppColors.slate,
                        height: 1.5,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'SUPREME SOLUTIONS LTD · NYERI, KENYA',
                      textAlign: TextAlign.center,
                      style: AppText.caption.copyWith(
                        color: AppColors.slate,
                        fontSize: 9.5,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 26),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.navyDeep, AppColors.navy, AppColors.navyLift],
          stops: <double>[0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: <Widget>[
            // Soft gold glow to lift the navy without adding noise.
            Positioned(
              top: -70,
              right: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[Color(0x33D4A017), Color(0x00D4A017)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 74),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const SupremeLogo(),
                      const Spacer(),
                      const _SignInChip(),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text.rich(
                    TextSpan(
                      style: AppText.display.copyWith(color: AppColors.white),
                      children: const <TextSpan>[
                        TextSpan(text: 'One app.\nMultiple services.\n'),
                        TextSpan(
                          text: 'Endless solutions.',
                          style: TextStyle(color: AppColors.gold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Text(
                      'Shop, eat, buy fresh produce and get deliveries across Nyeri '
                      '— all from one account.',
                      style: AppText.body.copyWith(
                        color: AppColors.whiteMuted,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: supremeDepartments
                        .map((SupremeDepartment d) => DepartmentPill(department: d))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignInChip extends StatelessWidget {
  const _SignInChip();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (BuildContext _) => const SignInScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0x40FFFFFF)),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.login, size: 13, color: AppColors.white),
              const SizedBox(width: 6),
              Text(
                'Sign in',
                style: AppText.caption.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.onCustomer, required this.onBusiness});

  final VoidCallback onCustomer;
  final VoidCallback onBusiness;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x140B2D5B),
            blurRadius: 26,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Create your account',
                  style: AppText.screenTitle.copyWith(fontSize: 20, color: AppColors.navy),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'FREE',
                  style: AppText.sectionLabel.copyWith(
                    fontSize: 9.5,
                    letterSpacing: 1.0,
                    color: AppColors.goldInk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Choose how you want to use Supreme Mall.',
            style: AppText.bodyTight.copyWith(color: AppColors.charcoal),
          ),
          const SizedBox(height: 18),
          RoleOptionCard(
            title: 'Sign up as a customer',
            description: 'Order groceries, meals and fresh produce, and follow every delivery.',
            icon: Icons.shopping_bag_outlined,
            accent: AppColors.navySoft,
            buttonLabel: 'Create customer account',
            buttonBackground: AppColors.navy,
            buttonForeground: AppColors.white,
            onPressed: onCustomer,
          ),
          const SizedBox(height: 14),
          RoleOptionCard(
            title: 'Sign up as a business',
            description: 'List your shop, restaurant or produce stall and start receiving orders.',
            icon: Icons.storefront_outlined,
            accent: AppColors.goldSoft,
            buttonLabel: 'Register my business',
            buttonBackground: AppColors.gold,
            buttonForeground: AppColors.navy,
            onPressed: onBusiness,
          ),
        ],
      ),
    );
  }
}

class _VerificationNote extends StatelessWidget {
  const _VerificationNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.emeraldSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.verified_user_outlined, size: 16, color: AppColors.emerald),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Every business is verified by Supreme Solutions Ltd before it can accept orders.',
              style: AppText.caption.copyWith(color: AppColors.charcoal, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
