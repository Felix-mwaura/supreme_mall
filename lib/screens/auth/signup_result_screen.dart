import 'package:flutter/material.dart';

import '../../models/account_role.dart';
import '../../services/account_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/app_button.dart';

class ResultStep {
  const ResultStep({required this.label, this.detail, this.done = false});

  final String label;
  final String? detail;
  final bool done;
}

/// Confirmation screen shown after a successful customer sign-up or after a
/// business application is submitted. Businesses land on a pending-verification
/// state because providers must be approved before they can accept paid orders
/// (brief, section 5).
class SignupResultScreen extends StatelessWidget {
  const SignupResultScreen({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.message,
    required this.steps,
    this.reference,
  });

  factory SignupResultScreen.customer({
    required String firstName,
    required String reference,
  }) {
    return SignupResultScreen(
      eyebrow: AccountRole.customer.label,
      title: 'Karibu, $firstName!',
      message:
          'Your account is ready. Add a delivery location and you can start '
          'ordering from Supreme Shopping, Supreme Food and Supreme Fresh.',
      reference: reference,
      steps: const <ResultStep>[
        ResultStep(label: 'Account created', done: true),
        ResultStep(label: 'Save your delivery location', detail: 'Nyeri Town and surrounding areas'),
        ResultStep(label: 'Start ordering', detail: 'Shopping, Food and Fresh are live'),
      ],
    );
  }

  factory SignupResultScreen.business({
    required String businessName,
    required String reference,
    required String departmentName,
  }) {
    return SignupResultScreen(
      eyebrow: 'Application received',
      title: 'Thank you,\n$businessName',
      message:
          'We have your $departmentName application. Our team reviews your '
          'documents and contacts you within ${AccountService.businessReviewWindow}.',
      reference: reference,
      steps: const <ResultStep>[
        ResultStep(label: 'Application submitted', done: true),
        ResultStep(
          label: 'Document review',
          detail: 'Business permit, owner ID and contact details',
        ),
        ResultStep(
          label: 'Approved — dashboard opens',
          detail: 'Add products, set prices and receive orders',
        ),
      ],
    );
  }

  final String eyebrow;
  final String title;
  final String message;
  final List<ResultStep> steps;
  final String? reference;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[Color(0xFFE8BF4A), AppColors.gold],
                      ),
                    ),
                    child: const Icon(Icons.check_rounded, size: 38, color: AppColors.navy),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  eyebrow.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: AppText.sectionLabel.copyWith(color: AppColors.goldInk),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppText.screenTitle.copyWith(color: AppColors.navy, height: 1.25),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(color: AppColors.charcoal),
                ),
                if (reference != null) ...<Widget>[
                  const SizedBox(height: 14),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.navySoft,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        'REF  $reference',
                        style: AppText.caption.copyWith(
                          fontSize: 10.5,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    children: <Widget>[
                      for (int i = 0; i < steps.length; i++)
                        _StepRow(
                          step: steps[i],
                          index: i + 1,
                          isLast: i == steps.length - 1,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Back to Supreme Mall',
                  onPressed: () => Navigator.of(context).popUntil(
                    (Route<dynamic> route) => route.isFirst,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.index, required this.isLast});

  final ResultStep step;
  final int index;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final Color markerColor = step.done ? AppColors.emerald : AppColors.line;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: step.done ? AppColors.emerald : AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: markerColor, width: 1.6),
                ),
                child: step.done
                    ? const Icon(Icons.check, size: 12, color: AppColors.white)
                    : Center(
                        child: Text(
                          '$index',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.slate,
                          ),
                        ),
                      ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 1.6, color: AppColors.line),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      step.label,
                      style: AppText.bodyTight.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (step.detail != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      step.detail!,
                      style: AppText.caption.copyWith(color: AppColors.slate, height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
