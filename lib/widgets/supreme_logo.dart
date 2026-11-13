import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Gold "S" monogram beside the SUPREME MALL wordmark.
class SupremeLogo extends StatelessWidget {
  const SupremeLogo({
    super.key,
    this.markSize = 40,
    this.onDark = true,
    this.showCompany = true,
  });

  final double markSize;
  final bool onDark;
  final bool showCompany;

  @override
  Widget build(BuildContext context) {
    final Color wordColor = onDark ? AppColors.white : AppColors.navy;
    final Color subColor = onDark ? AppColors.whiteMuted : AppColors.slate;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: markSize,
          height: markSize,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFFE8BF4A), AppColors.gold],
            ),
            borderRadius: BorderRadius.circular(markSize * 0.3),
          ),
          alignment: Alignment.center,
          child: Text(
            'S',
            style: TextStyle(
              fontSize: markSize * 0.52,
              fontWeight: FontWeight.w900,
              height: 1,
              color: AppColors.navy,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('SUPREME MALL', style: AppText.brandWordmark.copyWith(color: wordColor)),
            if (showCompany) ...<Widget>[
              const SizedBox(height: 2),
              Text(
                'by Supreme Solutions Ltd',
                style: AppText.brandSub.copyWith(color: subColor),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
