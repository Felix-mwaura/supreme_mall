import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'dark_surface.dart';

/// Areas Supreme Mall delivers to at launch (Nyeri County).
///
/// Kept as a constant list for now; it becomes a `delivery_zones` table when
/// delivery fees land with checkout, so nothing here assumes a fee exists.
const List<String> serviceAreas = <String>[
  'Nyeri Town',
  'Karatina',
  'Othaya',
  'Mukurweini',
  'Kiganjo',
  'Chaka',
  'Mweiga',
  'Naromoru',
];

/// Lets the customer pick where they are shopping for.
///
/// Returns the chosen area, or null if dismissed. Persisting it is the caller's
/// job (see `AuthService.updateDeliveryArea`).
Future<String?> showAreaPicker(BuildContext context, {String? current}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      return SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
          decoration: darkSurface(radius: 22, raised: true),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Where should we deliver?',
                style: AppText.cardTitle.copyWith(fontSize: 15, color: AppColors.inkOnDark),
              ),
              const SizedBox(height: 4),
              Text(
                'This sets what you see near you. Change it any time.',
                style: AppText.caption.copyWith(fontSize: 10.5, color: AppColors.inkMutedOnDark),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: serviceAreas.length,
                  itemBuilder: (BuildContext context, int index) {
                    final String area = serviceAreas[index];
                    final bool selected = area == current;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: GestureDetector(
                        onTap: () => Navigator.of(sheetContext).pop(area),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 16),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.goldSoft : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? const Color(0x59D4A017)
                                  : AppColors.hairlineDark,
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                selected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                size: 16,
                                color: selected ? AppColors.gold : AppColors.inkMutedOnDark,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  area,
                                  style: AppText.bodyTight.copyWith(
                                    fontSize: 12.5,
                                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                    color: AppColors.inkOnDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
