import 'package:flutter/material.dart';

import '../../services/account_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/signup_scaffold.dart';
import 'sign_in_screen.dart';
import 'signup_result_screen.dart';

/// Customer account creation — the first of the two paths offered on the home
/// screen. Fields follow the Phase 1 roadmap's shared customer platform:
/// profile, phone (for M-Pesa and SMS notifications) and optional email.
class CustomerSignupScreen extends StatefulWidget {
  const CustomerSignupScreen({super.key});

  @override
  State<CustomerSignupScreen> createState() => _CustomerSignupScreenState();
}

class _CustomerSignupScreenState extends State<CustomerSignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool _acceptedTerms = false;
  String? _termsError;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final bool formValid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _termsError = _acceptedTerms ? null : 'Please accept the Terms of Service to continue.';
    });

    if (!formValid || !_acceptedTerms) {
      return;
    }

    setState(() => _submitting = true);

    final AccountResult result = await AccountService.instance.createCustomerAccount(
      CustomerSignupRequest(
        fullName: _name.text.trim(),
        phone: '+254${Validators.normaliseKenyanPhone(_phone.text)}',
        email: _email.text.trim(),
        password: _password.text,
      ),
    );

    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext _) => SignupResultScreen.customer(
          firstName: _name.text.trim().split(' ').first,
          reference: result.referenceId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SignupScaffold(
      roleLabel: 'Customer account',
      title: 'Create your account',
      subtitle: 'One account for shopping, meals, fresh produce and deliveries.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const FormSectionLabel(label: 'Your details'),
            SupremeTextField(
              label: 'Full name',
              hint: 'e.g. Wanjiku Kamau',
              prefixIcon: Icons.person_outline,
              controller: _name,
              validator: Validators.personName,
              autofillHints: const <String>[AutofillHints.name],
            ),
            const SizedBox(height: 14),
            SupremePhoneField(
              controller: _phone,
              validator: Validators.phone,
              label: 'Phone number (M-Pesa)',
            ),
            const SizedBox(height: 14),
            SupremeTextField(
              label: 'Email (optional)',
              hint: 'you@example.com',
              prefixIcon: Icons.mail_outline,
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
              validator: (String? value) => Validators.email(value, required: false),
              autofillHints: const <String>[AutofillHints.email],
            ),
            const SizedBox(height: 22),
            const FormSectionLabel(label: 'Security'),
            SupremePasswordField(
              controller: _password,
              validator: Validators.password,
              label: 'Create password',
              hint: 'At least 8 characters',
              textInputAction: TextInputAction.done,
              onSubmitted: (String _) => _submit(),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.shield_outlined, size: 14, color: AppColors.slate),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Use 8+ characters with at least one letter and one number.',
                    style: AppText.caption.copyWith(fontSize: 11, color: AppColors.slate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TermsCheckRow(
              value: _acceptedTerms,
              errorText: _termsError,
              onChanged: (bool value) {
                setState(() {
                  _acceptedTerms = value;
                  if (value) {
                    _termsError = null;
                  }
                });
              },
              child: Text.rich(
                TextSpan(
                  style: AppText.caption.copyWith(color: AppColors.charcoal, height: 1.45),
                  children: const <TextSpan>[
                    TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Terms of Service',
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
                    ),
                    TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
                    ),
                    TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Create account',
              onPressed: _submit,
              loading: _submitting,
              icon: Icons.arrow_forward,
            ),
            const SizedBox(height: 14),
            const PreviewBuildNote(),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Already registered?',
                  style: AppText.caption.copyWith(color: AppColors.charcoal),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (BuildContext _) => const SignInScreen(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    foregroundColor: AppColors.navy,
                    textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
