import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_bootstrap.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/signup_scaffold.dart';

/// Sign-in with the email and password held by Supabase Auth.
///
/// There is no customer/business toggle any more: the account's role lives in
/// `profiles.role`, and the auth gate routes people to the right home screen.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool _submitting = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _info = null;
    });

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _submitting = true);

    try {
      await SupabaseBootstrap.auth.signIn(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) {
        return;
      }
      setState(() => _submitting = false);

      // Back to the root, where AuthGate now renders the correct home screen.
      Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
    } on AuthFailure catch (failure) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _error = failure.message;
      });
    }
  }

  Future<void> _sendReset() async {
    setState(() {
      _error = null;
      _info = null;
    });

    final String? emailError = Validators.email(_email.text);
    if (emailError != null) {
      setState(() => _error = 'Enter your email address first, then tap "Forgot password?".');
      return;
    }

    final TextEditingController resetEmail = TextEditingController(text: _email.text.trim());
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Reset password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'We will send a reset link to this address. Until our own mail service is '
              'live, delivery is limited — if nothing arrives, contact support and we '
              'will reset it for you.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: resetEmail,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email address'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Send link')),
        ],
      ),
    );

    if (confirmed != true) {
      resetEmail.dispose();
      return;
    }

    setState(() => _submitting = true);
    try {
      await SupabaseBootstrap.auth.sendPasswordReset(resetEmail.text.trim());
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _info = 'If ${resetEmail.text.trim()} has an account, a reset link is on its way. '
            'Check the inbox and the spam folder; support is at '
            '${AppConfig.supportEmail} if it does not arrive.';
      });
    } on AuthFailure catch (failure) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _error = failure.message;
      });
    } finally {
      resetEmail.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SignupScaffold(
      roleLabel: 'Sign in',
      title: 'Welcome back',
      subtitle: 'Sign in with the email and password you registered with.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (_error != null)
              ErrorBanner(message: _error!, onDismiss: () => setState(() => _error = null)),
            if (_info != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.emeraldSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(Icons.mark_email_read_outlined, size: 16, color: AppColors.emerald),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        _info!,
                        style: AppText.caption.copyWith(
                          fontSize: 11.5,
                          height: 1.45,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SupremeTextField(
              label: 'Email address',
              hint: 'you@example.com',
              prefixIcon: Icons.mail_outline,
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
              validator: Validators.email,
              autofillHints: const <String>[AutofillHints.email],
            ),
            const SizedBox(height: 14),
            SupremePasswordField(
              controller: _password,
              validator: (String? value) =>
                  (value == null || value.isEmpty) ? 'Enter your password' : null,
              label: 'Password',
              textInputAction: TextInputAction.done,
              onSubmitted: (String _) => _submit(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: AppTextLink(
                label: 'Forgot password?',
                onPressed: _submitting ? () {} : _sendReset,
              ),
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Sign in',
              onPressed: _submit,
              loading: _submitting,
              icon: Icons.arrow_forward,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'New to Supreme Mall?',
                  style: AppText.caption.copyWith(color: AppColors.charcoal),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    foregroundColor: AppColors.navy,
                    textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Create an account'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
