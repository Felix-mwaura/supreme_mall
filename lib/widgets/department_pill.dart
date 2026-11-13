import 'package:flutter/material.dart';

import '../models/department.dart';
import '../theme/app_colors.dart';

/// Compact department chip used in the home screen hero to show the breadth of
/// the platform. Phase 1 departments read as live; later-phase ones are muted
/// and marked "soon" (brief, section 4 / roadmap, section 5).
class DepartmentPill extends StatelessWidget {
  const DepartmentPill({super.key, required this.department});

  final SupremeDepartment department;

  @override
  Widget build(BuildContext context) {
    final bool live = department.openForApplications;
    final Color content = live ? AppColors.white : AppColors.whiteMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: live ? AppColors.whiteGlass : AppColors.whiteFaint,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(department.icon, size: 13, color: content),
          const SizedBox(width: 6),
          Text(
            live ? department.shortName : '${department.shortName} · soon',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: content,
            ),
          ),
        ],
      ),
    );
  }
}
