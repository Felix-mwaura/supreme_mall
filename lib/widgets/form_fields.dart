import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

OutlineInputBorder _border(Color color, double width) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color, width: width),
  );
}

InputDecoration supremeFieldDecoration({
  required String label,
  String? hint,
  IconData? prefixIcon,
  String? prefixText,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefixIcon == null
        ? null
        : Icon(prefixIcon, size: 20, color: AppColors.slate),
    prefixText: prefixText,
    prefixStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.navy,
    ),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppColors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
    labelStyle: const TextStyle(fontSize: 13.5, color: AppColors.slate),
    floatingLabelStyle: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.navy,
    ),
    hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.slate),
    errorStyle: const TextStyle(fontSize: 11.5, height: 1.3),
    border: _border(AppColors.line, 1),
    enabledBorder: _border(AppColors.line, 1),
    focusedBorder: _border(AppColors.navy, 1.6),
    errorBorder: _border(const Color(0xFFB3261E), 1),
    focusedErrorBorder: _border(const Color(0xFFB3261E), 1.6),
  );
}

/// Standard text input used by every form in the sign-up flow.
class SupremeTextField extends StatelessWidget {
  const SupremeTextField({
    super.key,
    required this.label,
    required this.validator,
    this.controller,
    this.hint,
    this.prefixIcon,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.words,
    this.autofillHints,
    this.onSubmitted,
  });

  final String label;
  final String? Function(String?) validator;
  final TextEditingController? controller;
  final String? hint;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final void Function(String)? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      autofillHints: autofillHints,
      onFieldSubmitted: onSubmitted,
      style: const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        color: AppColors.navy,
      ),
      decoration: supremeFieldDecoration(
        label: label,
        hint: hint,
        prefixIcon: prefixIcon,
      ),
    );
  }
}

/// Kenyan mobile number input, always rendered behind a fixed +254 prefix.
class SupremePhoneField extends StatelessWidget {
  const SupremePhoneField({
    super.key,
    required this.validator,
    this.controller,
    this.label = 'Phone number',
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  final String? Function(String?) validator;
  final TextEditingController? controller;
  final String label;
  final TextInputAction textInputAction;
  final void Function(String)? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: TextInputType.phone,
      textInputAction: textInputAction,
      autofillHints: const <String>[AutofillHints.telephoneNumber],
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
        LengthLimitingTextInputFormatter(12),
      ],
      onFieldSubmitted: onSubmitted,
      style: const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: AppColors.navy,
      ),
      decoration: supremeFieldDecoration(
        label: label,
        hint: '712 345 678',
        prefixIcon: Icons.phone_outlined,
        prefixText: '+254  ',
      ),
    );
  }
}

/// Password input with a show/hide toggle.
class SupremePasswordField extends StatefulWidget {
  const SupremePasswordField({
    super.key,
    required this.validator,
    required this.controller,
    this.label = 'Password',
    this.hint,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  final String? Function(String?) validator;
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputAction textInputAction;
  final void Function(String)? onSubmitted;

  @override
  State<SupremePasswordField> createState() => _SupremePasswordFieldState();
}

class _SupremePasswordFieldState extends State<SupremePasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      obscureText: _obscured,
      enableSuggestions: false,
      autocorrect: false,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      style: const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: AppColors.navy,
      ),
      decoration: supremeFieldDecoration(
        label: widget.label,
        hint: widget.hint,
        prefixIcon: Icons.lock_outline,
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscured = !_obscured),
          tooltip: _obscured ? 'Show password' : 'Hide password',
          icon: Icon(
            _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 20,
            color: AppColors.slate,
          ),
        ),
      ),
    );
  }
}

/// Terms acceptance row. Built by hand instead of using [Checkbox] so the
/// tick styling matches the brand and the widget API stays version-proof.
class TermsCheckRow extends StatelessWidget {
  const TermsCheckRow({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
    required this.child,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? errorText;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: value ? AppColors.navy : AppColors.white,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: value
                          ? AppColors.navy
                          : (hasError ? const Color(0xFFB3261E) : AppColors.line),
                      width: 1.6,
                    ),
                  ),
                  child: value
                      ? const Icon(Icons.check, size: 14, color: AppColors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(child: child),
              ],
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 2),
            child: Text(
              errorText!,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.3,
                color: Color(0xFFB3261E),
              ),
            ),
          ),
      ],
    );
  }
}

/// Small uppercase section divider used to break long forms into blocks.
class FormSectionLabel extends StatelessWidget {
  const FormSectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Row(
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: AppText.sectionLabel.copyWith(color: AppColors.navyLift),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Divider(color: AppColors.line, height: 1)),
        ],
      ),
    );
  }
}

/// Selectable pill (business category picker).
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final Color ink = selected ? AppColors.white : AppColors.navy;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : AppColors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? AppColors.navy : AppColors.line,
            width: 1.4,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 14, color: ink),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: ink,
              ),
            ),
            if (selected) ...<Widget>[
              const SizedBox(width: 6),
              const Icon(Icons.check, size: 13, color: AppColors.gold),
            ],
          ],
        ),
      ),
    );
  }
}
