import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/catalogue.dart';
import '../../models/department.dart';
import '../../repositories/catalogue_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/app_button.dart';
import '../../widgets/dark_surface.dart';
import '../../widgets/product_card.dart';
import 'product_detail_screen.dart';

/// One storefront implementation for every department.
///
/// Shopping, Food and Fresh differ by data (categories, units, accent, glyph)
/// rather than by screen: the same widget renders groceries and produce, so the
/// next department never means a second copy of this file. Passing [merchant]
/// narrows it to a single approved merchant's listings.
class StorefrontScreen extends StatefulWidget {
  const StorefrontScreen({
    super.key,
    required this.department,
    this.merchant,
    this.initialCategoryId,
  });

  final SupremeDepartment department;
  final MerchantSummary? merchant;
  final String? initialCategoryId;

  @override
  State<StorefrontScreen> createState() => _StorefrontScreenState();
}

class _StorefrontScreenState extends State<StorefrontScreen> {
  static const CatalogueRepository _repository = CatalogueRepository();

  final TextEditingController _search = TextEditingController();
  Timer? _debounce;

  String _query = '';
  late String? _categoryId = widget.initialCategoryId;
  late Future<List<CatalogueProduct>> _products = _load();
  late Future<List<ProductCategory>> _categories =
      _repository.categories(widget.department.id);

  Future<List<CatalogueProduct>> _load() {
    return _repository.products(
      departmentId: widget.department.id,
      categoryId: _categoryId,
      businessId: widget.merchant?.id,
      query: _query,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    // 320 ms: long enough to avoid a query per keystroke on a slow connection,
    // short enough that the grid keeps up with typing.
    _debounce = Timer(const Duration(milliseconds: 320), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _query = value;
        _products = _load();
      });
    });
  }

  void _selectCategory(String? id) {
    if (_categoryId == id) {
      return;
    }
    setState(() {
      _categoryId = id;
      _products = _load();
    });
  }

  void _reload() {
    setState(() {
      _products = _load();
      _categories = _repository.categories(widget.department.id);
    });
  }

  void _openProduct(CatalogueProduct product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext _) => ProductDetailScreen(
          product: product,
          accent: widget.department.accent,
          icon: widget.department.icon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.merchant?.name ?? widget.department.name;
    final String subtitle = widget.merchant?.area.isNotEmpty == true
        ? widget.merchant!.area
        : 'Approved ${widget.department.shortName.toLowerCase()} merchants';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 16, 0),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppColors.inkOnDark,
                      tooltip: 'Back',
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.screenTitle.copyWith(
                              fontSize: 17,
                              color: AppColors.inkOnDark,
                            ),
                          ),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.caption.copyWith(
                              fontSize: 10.5,
                              color: widget.department.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: DarkSearchField(
                  controller: _search,
                  onChanged: _onSearchChanged,
                  hint: 'Search ${widget.department.shortName.toLowerCase()}',
                ),
              ),
              const SizedBox(height: 12),
              _CategoryBar(
                categories: _categories,
                selectedId: _categoryId,
                onSelected: _selectCategory,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.gold,
                  backgroundColor: AppColors.surface,
                  onRefresh: () async {
                    _reload();
                    try {
                      await _products;
                    } catch (_) {
                      // The FutureBuilder below renders the failure state; an
                      // error escaping the refresh indicator would be unhandled.
                    }
                  },
                  child: FutureBuilder<List<CatalogueProduct>>(
                    future: _products,
                    builder: (
                      BuildContext context,
                      AsyncSnapshot<List<CatalogueProduct>> snapshot,
                    ) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const _SkeletonGrid();
                      }

                      if (snapshot.hasError) {
                        final Object error = snapshot.error!;
                        return ListView(
                          padding: const EdgeInsets.fromLTRB(16, 30, 16, 120),
                          children: <Widget>[
                            DarkEmptyState(
                              icon: Icons.cloud_off_rounded,
                              title: 'Could not load listings',
                              message: error is CatalogueFailure
                                  ? error.message
                                  : 'Check your connection and pull down to retry.',
                            ),
                            AppButton(
                              label: 'Try again',
                              onPressed: _reload,
                              background: AppColors.surface,
                              foreground: AppColors.gold,
                            ),
                          ],
                        );
                      }

                      final List<CatalogueProduct> products =
                          snapshot.data ?? const <CatalogueProduct>[];

                      if (products.isEmpty) {
                        return ListView(
                          padding: const EdgeInsets.fromLTRB(16, 30, 16, 120),
                          children: <Widget>[
                            DarkEmptyState(
                              icon: _query.isNotEmpty
                                  ? Icons.search_off_rounded
                                  : Icons.inventory_2_outlined,
                              title: _query.isNotEmpty
                                  ? 'Nothing matches "$_query"'
                                  : 'No listings here yet',
                              message: _query.isNotEmpty
                                  ? 'Try a shorter word, or clear the search to see everything.'
                                  : 'Approved merchants have not listed ${widget.department.shortName.toLowerCase()} items yet. '
                                      'Pull down to check again.',
                            ),
                          ],
                        );
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        physics: const AlwaysScrollableScrollPhysics(),
                        gridDelegate: _grid,
                        itemCount: products.length,
                        itemBuilder: (BuildContext context, int index) {
                          final CatalogueProduct product = products[index];
                          return ProductCard(
                            product: product,
                            accent: widget.department.accent,
                            icon: widget.department.icon,
                            showMerchant: widget.merchant == null,
                            onTap: () => _openProduct(product),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final Future<List<ProductCategory>> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProductCategory>>(
      future: categories,
      builder: (
        BuildContext context,
        AsyncSnapshot<List<ProductCategory>> snapshot,
      ) {
        final List<ProductCategory> items =
            snapshot.data ?? const <ProductCategory>[];
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }
        // Horizontal scroll with intrinsic height: a fixed-height box would
        // clip the chips once the customer raises their text size.
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: <Widget>[
              DarkChip(
                label: 'All',
                selected: selectedId == null,
                onTap: () => onSelected(null),
              ),
              for (final ProductCategory category in items) ...<Widget>[
                const SizedBox(width: 8),
                DarkChip(
                  label: category.name,
                  selected: selectedId == category.id,
                  onTap: () => onSelected(category.id),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Fixed tile height rather than a fixed aspect ratio.
///
/// The card's image is always square (so proportions match across listings);
/// what varies with screen width is the space left for text. Giving the tile an
/// explicit height — sized for the worst case (a two-line name at 130 % text
/// scale) — keeps the grid uniform and stops the column from overflowing on a
/// 320 dp phone, which a `childAspectRatio` cannot guarantee.
const SliverGridDelegateWithMaxCrossAxisExtent _grid =
    SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 190,
  mainAxisSpacing: 12,
  crossAxisSpacing: 12,
  mainAxisExtent: 300,
);

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: _grid,
      itemCount: 6,
      itemBuilder: (BuildContext context, int index) => const ProductCardSkeleton(),
    );
  }
}
