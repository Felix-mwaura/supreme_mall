import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/catalogue.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../utils/money.dart';
import '../../widgets/catalogue_image.dart';
import '../../widgets/dark_surface.dart';

/// Product page: photo, name, merchant, price, availability, description.
///
/// It shows exactly what the database holds for this listing — no invented
/// ratings, calories, preparation times or variant options, because the product
/// model has none of those fields yet.
///
/// There is deliberately no "Add to cart" action: cart and checkout are the
/// next milestone, and a button that cannot add to a real cart would be the
/// fake control this project is avoiding.
class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.accent,
    this.icon = Icons.shopping_bag_outlined,
  });

  final CatalogueProduct product;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final bool soldOut = !product.inStock;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 28),
            children: <Widget>[
              Stack(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: CatalogueImage(
                      product: product,
                      accent: accent,
                      icon: icon,
                      borderRadius: 22,
                    ),
                  ),
                  Positioned(
                    left: 24,
                    top: 16,
                    child: _RoundButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.of(context).maybePop(),
                      label: 'Back',
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        if (product.categoryName.isNotEmpty) ...<Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: AppColors.hairlineDark),
                            ),
                            child: Text(
                              product.categoryName.toUpperCase(),
                              style: AppText.sectionLabel.copyWith(
                                fontSize: 8,
                                letterSpacing: 0.8,
                                color: accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: AppColors.hairlineDark),
                          ),
                          child: Text(
                            soldOut ? 'OUT OF STOCK' : 'IN STOCK',
                            style: AppText.sectionLabel.copyWith(
                              fontSize: 8,
                              letterSpacing: 0.8,
                              color: soldOut ? AppColors.inkMutedOnDark : AppColors.emerald,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      product.name,
                      style: AppText.screenTitle.copyWith(
                        fontSize: 22,
                        height: 1.22,
                        color: AppColors.inkOnDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        const Icon(Icons.storefront_outlined, size: 14, color: AppColors.inkMutedOnDark),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            product.businessArea.isEmpty
                                ? product.businessName
                                : '${product.businessName} · ${product.businessArea}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.caption.copyWith(
                              fontSize: 11,
                              color: AppColors.inkMutedOnDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          ksh(product.price.round()),
                          style: AppText.display.copyWith(fontSize: 26, color: AppColors.gold),
                        ),
                        if (product.unitLabel != null) ...<Widget>[
                          const SizedBox(width: 7),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              product.unitLabel!,
                              style: AppText.caption.copyWith(
                                fontSize: 11,
                                color: AppColors.inkMutedOnDark,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (product.hasDiscount)
                          Text(
                            ksh(product.compareAtPrice!.round()),
                            style: AppText.caption.copyWith(
                              fontSize: 12,
                              color: AppColors.inkMutedOnDark,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                    if (product.hasDiscount)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${product.discountPercent}% off the previous price',
                          style: AppText.caption.copyWith(
                            fontSize: 10.5,
                            color: AppColors.emerald,
                          ),
                        ),
                      ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: darkSurface(radius: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'About this item',
                            style: AppText.sectionLabel.copyWith(
                              fontSize: 9,
                              letterSpacing: 1,
                              color: AppColors.inkMutedOnDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            (product.description ?? '').trim().isEmpty
                                ? 'The merchant has not added a description for this item yet.'
                                : product.description!.trim(),
                            style: AppText.bodyTight.copyWith(
                              fontSize: 12.5,
                              height: 1.55,
                              color: AppColors.inkOnDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: darkSurface(radius: 18),
                      child: Column(
                        children: <Widget>[
                          _MetaRow(label: 'Sold by', value: product.businessName),
                          if (product.businessArea.isNotEmpty)
                            _MetaRow(label: 'Area', value: product.businessArea),
                          if (product.categoryName.isNotEmpty)
                            _MetaRow(label: 'Category', value: product.categoryName),
                          _MetaRow(
                            label: 'Availability',
                            value: soldOut
                                ? 'Out of stock — check back soon'
                                : 'Available to order',
                            valueColor: soldOut ? AppColors.inkMutedOnDark : AppColors.emerald,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Checkout is not open yet. Browsing is live; ordering arrives with the '
                      'cart and checkout milestone.',
                      textAlign: TextAlign.center,
                      style: AppText.caption.copyWith(
                        fontSize: 10,
                        height: 1.6,
                        color: AppColors.inkMutedOnDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    this.valueColor = AppColors.inkOnDark,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: AppText.caption.copyWith(fontSize: 10.5, color: AppColors.inkMutedOnDark),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppText.bodyTight.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap, required this.label});

  final IconData icon;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.glassFillDeep,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.glassEdge),
          ),
          child: Icon(icon, size: 20, color: AppColors.inkOnDark),
        ),
      ),
    );
  }
}
