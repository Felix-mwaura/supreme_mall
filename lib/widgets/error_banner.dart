import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Inline, dismissible error for a form. Errors the user must act on stay on
/// screen next to the form — never in a toast that disappears.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message, this.onDismiss});

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(12, 11, 8, 11),
      decoration: BoxDecoration(
        color: const Color(0x1FB3261E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x4DB3261E)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.error_outline, size: 16, color: Color(0xFFB3261E)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: AppText.caption.copyWith(
                fontSize: 11.5,
                height: 1.45,
                color: const Color(0xFF8E1B12),
              ),
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.only(left: 6, right: 2),
                child: Icon(Icons.close, size: 15, color: Color(0xFF8E1B12)),
              ),
            ),
        ],
      ),
    );
  }
}
