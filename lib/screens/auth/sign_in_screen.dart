import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/signup_scaffold.dart';

/// Sign-in for existing customers and businesses.
///
/// UI-only for now: authentication is the next step once Supabase is connected,
/// so the button validates the form and explains what happens next instead of
/// pretending to log the user in.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool _isBusiness = false;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontSize: 13)),
          backgroundColor: AppColors.navy,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final bool valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }
    _showMessage(
      'Sign-in is not connected yet — the next step is Supabase authentication.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return SignupScaffold(
      roleLabel: 'Sign in',
      title: 'Welcome back',
      subtitle: 'Sign in to your customer or business account.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Wrap(
              spacing: 8,
              children: <Widget>[
                ChoicePill(
                  label: 'Customer',
                  icon: Icons.shopping_bag_outlined,
                  selected: !_isBusiness,
                  onTap: () => setState(() => _isBusiness = false),
                ),
                ChoicePill(
                  label: 'Business',
                  icon: Icons.storefront_outlined,
                  selected: _isBusiness,
                  onTap: () => setState(() => _isBusiness = true),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SupremePhoneField(
              controller: _phone,
              validator: Validators.phone,
              label: 'Phone number',
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
                onPressed: () => _showMessage(
                  'Password reset by SMS will be enabled with the authentication build.',
                ),
              ),
            ),
            const SizedBox(height: 10),
            AppButton(
              label: _isBusiness ? 'Sign in to business account' : 'Sign in',
              onPressed: _submit,
              icon: Icons.arrow_forward,
            ),
            const SizedBox(height: 16),
            const PreviewBuildNote(),
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
