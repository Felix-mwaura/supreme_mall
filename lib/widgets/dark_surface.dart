import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Surface recipe for the dark dashboard: one card colour, one hairline, one
/// radius family. Tabs must not invent their own borders or the app starts to
/// look like four different products.
BoxDecoration darkSurface({double radius = 18, bool raised = false, Color? border}) {
  return BoxDecoration(
    color: raised ? AppColors.surfaceRaised : AppColors.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: border ?? AppColors.hairlineDark),
  );
}

/// Uppercase section label with an optional trailing action ("See all").
class DarkSectionLabel extends StatelessWidget {
  const DarkSectionLabel({
    super.key,
    required this.label,
    this.action,
    this.onAction,
    this.actionColor = AppColors.sky,
  });

  final String label;
  final String? action;
  final VoidCallback? onAction;
  final Color actionColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: AppText.sectionLabel.copyWith(fontSize: 10, color: AppColors.inkMutedOnDark),
          ),
          const Spacer(),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Text(
                action!,
                style: AppText.caption.copyWith(fontSize: 10.5, color: actionColor),
              ),
            ),
        ],
      ),
    );
  }
}

/// Selectable filter pill on a dark surface.
class DarkChip extends StatelessWidget {
  const DarkChip({
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
    final Color ink = selected ? AppColors.gold : AppColors.inkMutedOnDark;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.goldSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? const Color(0x59D4A017) : AppColors.hairlineDark,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 13, color: ink),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared dark search field (Home and Categories use the same one).
class DarkSearchField extends StatelessWidget {
  const DarkSearchField({
    super.key,
    this.hint = 'Search shops, food, produce',
    this.controller,
    this.onChanged,
    this.onFilterTap,
    this.autofocus = false,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: darkSurface(radius: 16),
      child: Row(
        children: <Widget>[
          const Icon(Icons.search_rounded, size: 19, color: AppColors.inkMutedOnDark),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              autofocus: autofocus,
              cursorColor: AppColors.gold,
              style: AppText.bodyTight.copyWith(
                color: AppColors.inkOnDark,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: AppText.bodyTight.copyWith(color: AppColors.inkMutedOnDark),
              ),
            ),
          ),
          GestureDetector(
            onTap: onFilterTap,
            behavior: HitTestBehavior.opaque,
            child: const Icon(Icons.tune_rounded, size: 17, color: AppColors.inkMutedOnDark),
          ),
        ],
      ),
    );
  }
}

/// Neutral empty state used by search results, order history and so on.
class DarkEmptyState extends StatelessWidget {
  const DarkEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 34),
      child: Column(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: darkSurface(radius: 100, raised: true),
            child: Icon(icon, size: 24, color: AppColors.inkMutedOnDark),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppText.cardTitle.copyWith(fontSize: 14, color: AppColors.inkOnDark),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppText.caption.copyWith(color: AppColors.inkMutedOnDark, height: 1.5),
          ),
        ],
      ),
    );
  }
}
