import 'package:flutter/material.dart';

import '../../models/department.dart';
import '../../services/account_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/signup_scaffold.dart';
import 'sign_in_screen.dart';
import 'signup_result_screen.dart';

/// Business (merchant / vendor / restaurant) application.
///
/// Phase 1 departments — Shopping, Food and Fresh — accept applications now.
/// The remaining departments are visible but waitlisted, so the platform reads
/// as one product while staying honest about the launch scope.
class BusinessSignupScreen extends StatefulWidget {
  const BusinessSignupScreen({super.key});

  @override
  State<BusinessSignupScreen> createState() => _BusinessSignupScreenState();
}

class _BusinessSignupScreenState extends State<BusinessSignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _businessName = TextEditingController();
  final TextEditingController _contactName = TextEditingController();
  final TextEditingController _area = TextEditingController(text: 'Nyeri Town');
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  String? _departmentId;
  String? _departmentError;
  bool _acceptedTerms = false;
  String? _termsError;
  bool _submitting = false;

  @override
  void dispose() {
    _businessName.dispose();
    _contactName.dispose();
    _area.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final bool formValid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _departmentError = _departmentId == null ? 'Choose what your business sells.' : null;
      _termsError = _acceptedTerms
          ? null
          : 'Please accept the partner terms to submit your application.';
    });

    if (!formValid || _departmentId == null || !_acceptedTerms) {
      return;
    }

    setState(() => _submitting = true);

    final AccountResult result = await AccountService.instance.submitBusinessApplication(
      BusinessSignupRequest(
        businessName: _businessName.text.trim(),
        contactName: _contactName.text.trim(),
        departmentId: _departmentId!,
        phone: '+254${Validators.normaliseKenyanPhone(_phone.text)}',
        email: _email.text.trim(),
        area: _area.text.trim(),
        password: _password.text,
      ),
    );

    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);

    final SupremeDepartment department = supremeDepartments.firstWhere(
      (SupremeDepartment d) => d.id == _departmentId,
      orElse: () => supremeDepartments.first,
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext _) => SignupResultScreen.business(
          businessName: _businessName.text.trim(),
          reference: result.referenceId,
          departmentName: department.shortName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SignupScaffold(
      roleLabel: 'Business account',
      title: 'Register your business',
      subtitle: 'Sell on Supreme Mall. We verify every business before it goes live.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const FormSectionLabel(label: 'Business details'),
            SupremeTextField(
              label: 'Business name',
              hint: 'e.g. Nyeri Fresh Mart',
              prefixIcon: Icons.storefront_outlined,
              controller: _businessName,
              validator: Validators.businessName,
            ),
            const SizedBox(height: 16),
            Text(
              'What does your business sell?',
              style: AppText.bodyTight.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: supremeDepartments.map((SupremeDepartment d) {
                return ChoicePill(
                  label: d.openForApplications ? d.shortName : '${d.shortName} · soon',
                  icon: d.icon,
                  selected: _departmentId == d.id,
                  onTap: () => setState(() {
                    _departmentId = d.id;
                    _departmentError = null;
                  }),
                );
              }).toList(),
            ),
            if (_departmentError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _departmentError!,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFFB3261E)),
                ),
              ),
            const SizedBox(height: 6),
            Text(
              'Shopping, Food and Fresh are open for applications today. '
              'Rides, Boda, Errands and Home open in a later phase — you can still '
              'register your interest.',
              style: AppText.caption.copyWith(fontSize: 11, color: AppColors.slate, height: 1.45),
            ),
            const SizedBox(height: 16),
            SupremeTextField(
              label: 'Town / area',
              hint: 'Nyeri Town',
              prefixIcon: Icons.place_outlined,
              controller: _area,
              validator: (String? value) =>
                  Validators.requiredText(value, label: 'your town or area'),
            ),
            const SizedBox(height: 14),
            SupremeTextField(
              label: 'Contact person',
              hint: 'Owner or manager',
              prefixIcon: Icons.badge_outlined,
              controller: _contactName,
              validator: Validators.personName,
            ),
            const SizedBox(height: 22),
            const FormSectionLabel(label: 'Account & contact'),
            SupremePhoneField(
              controller: _phone,
              validator: Validators.phone,
              label: 'Business phone (M-Pesa)',
            ),
            const SizedBox(height: 14),
            SupremeTextField(
              label: 'Business email',
              hint: 'orders@yourbusiness.co.ke',
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
              validator: Validators.password,
              label: 'Create password',
              hint: 'At least 8 characters',
              textInputAction: TextInputAction.done,
              onSubmitted: (String _) => _submit(),
            ),
            const SizedBox(height: 20),
            const _DocumentsNote(),
            const SizedBox(height: 16),
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
                    TextSpan(text: 'I confirm the details are accurate and accept the '),
                    TextSpan(
                      text: 'Partner Terms',
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
                    ),
                    TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Commission Schedule',
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
                    ),
                    TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Submit application',
              onPressed: _submit,
              loading: _submitting,
              background: AppColors.gold,
              foreground: AppColors.navy,
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

class _DocumentsNote extends StatelessWidget {
  const _DocumentsNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.folder_outlined, size: 15, color: AppColors.navy),
              const SizedBox(width: 8),
              Text(
                'Have these ready',
                style: AppText.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Business permit, national ID of the owner and — if you want card '
            'payments — a bank account or M-Pesa paybill. Review usually takes '
            '${AccountService.businessReviewWindow}.',
            style: AppText.caption.copyWith(fontSize: 11, color: AppColors.slate, height: 1.5),
          ),
        ],
      ),
    );
  }
}
