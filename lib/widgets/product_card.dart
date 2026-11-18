import 'package:flutter/material.dart';

import '../models/catalogue.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../utils/money.dart';
import 'catalogue_image.dart';
import 'dark_surface.dart';

/// The single product card used by every storefront.
///
/// Deliberately sparse: photo, name (max two lines), merchant, price and — only
/// when the data supports it — a real previous price, a unit, or an
/// out-of-stock state. No badges are invented to fill space.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.accent,
    required this.onTap,
    this.icon = Icons.shopping_bag_outlined,
    this.showMerchant = true,
  });

  final CatalogueProduct product;
  final Color accent;
  final VoidCallback onTap;
  final IconData icon;
  final bool showMerchant;

  @override
  Widget build(BuildContext context) {
    final bool soldOut = !product.inStock;

    return Semantics(
      button: true,
      label: '${product.name}, ${ksh(product.price.round())}'
          '${soldOut ? ', out of stock' : ''}',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        // A grid tile has a fixed height, so unbounded text growth would clip
        // or overflow. 130 % still honours large-text settings while keeping
        // price and unit readable; the tile is sized for exactly this.
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: darkSurface(radius: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    CatalogueImage(product: product, accent: accent, icon: icon),
                    if (soldOut)
                      Positioned(
                        left: 6,
                        top: 6,
                        child: _Pill(
                          background: AppColors.canvasDeep,
                          label: 'OUT OF STOCK',
                          color: AppColors.inkMutedOnDark,
                          letterSpacing: 0.7,
                        ),
                      ),
                    if (product.hasDiscount && !soldOut)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: _Pill(
                          background: AppColors.gold,
                          label: '-${product.discountPercent}%',
                          color: AppColors.navy,
                          letterSpacing: 0.4,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyTight.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: soldOut ? AppColors.inkMutedOnDark : AppColors.inkOnDark,
                  ),
                ),
                if (showMerchant) ...<Widget>[
                  const SizedBox(height: 3),
                  Text(
                    product.businessName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(
                      fontSize: 9.5,
                      color: AppColors.inkMutedOnDark,
                    ),
                  ),
                ],
                const Spacer(),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        ksh(product.price.round()),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.cardTitle.copyWith(
                          fontSize: 13,
                          color: soldOut ? AppColors.inkMutedOnDark : AppColors.gold,
                        ),
                      ),
                    ),
                    if (product.hasDiscount) ...<Widget>[
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          ksh(product.compareAtPrice!.round()),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.caption.copyWith(
                            fontSize: 9.5,
                            color: AppColors.inkMutedOnDark,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (product.unitLabel != null)
                  Text(
                    product.unitLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(
                      fontSize: 9,
                      color: AppColors.inkMutedOnDark,
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

/// Small status pill over the photo. Only ever built from real data.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.background,
    required this.label,
    required this.color,
    required this.letterSpacing,
  });

  final Color background;
  final String label;
  final Color color;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: AppText.sectionLabel.copyWith(
          fontSize: 7,
          letterSpacing: letterSpacing,
          color: color,
        ),
      ),
    );
  }
}

/// Grey card shown while the first page loads. Same footprint as a real card,
/// so the grid does not reflow when data arrives.
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: darkSurface(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(height: 9, width: double.infinity, color: AppColors.surfaceRaised),
          const SizedBox(height: 6),
          Container(height: 9, width: 62, color: AppColors.surfaceRaised),
          const Spacer(),
        ],
      ),
    );
  }
}
