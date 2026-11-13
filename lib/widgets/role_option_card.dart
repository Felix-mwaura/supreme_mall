import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_button.dart';

/// One of the two account paths on the home screen
/// ("Sign up as a customer" / "Sign up as a business").
class RoleOptionCard extends StatelessWidget {
  const RoleOptionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.buttonLabel,
    required this.onPressed,
    required this.buttonBackground,
    required this.buttonForeground,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final String buttonLabel;
  final VoidCallback onPressed;
  final Color buttonBackground;
  final Color buttonForeground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A0B2D5B),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(icon, size: 22, color: AppColors.navy),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(title, style: AppText.cardTitle.copyWith(color: AppColors.navy)),
                          const SizedBox(height: 3),
                          Text(
                            description,
                            style: AppText.bodyTight.copyWith(color: AppColors.charcoal),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AppButton(
                  label: buttonLabel,
                  onPressed: onPressed,
                  background: buttonBackground,
                  foreground: buttonForeground,
                  height: 48,
                  icon: Icons.arrow_forward,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
