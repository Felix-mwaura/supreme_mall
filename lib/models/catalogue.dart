/// Catalogue models: the shape the storefronts actually read.
///
/// Kept free of Flutter imports so they stay unit testable, and tolerant of
/// PostgREST's habit of returning `numeric` either as a number or as a string.

/// A category inside a department (Groceries, Breakfast, Vegetables…).
class ProductCategory {
  const ProductCategory({
    required this.id,
    required this.departmentId,
    required this.name,
    this.sortOrder = 0,
  });

  factory ProductCategory.fromMap(Map<String, dynamic> map) {
    return ProductCategory(
      id: map['id'] as String,
      departmentId: (map['department_id'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String departmentId;
  final String name;
  final int sortOrder;
}

/// One listing, joined with the merchant that sells it and its category.
class CatalogueProduct {
  const CatalogueProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    required this.categoryName,
    required this.departmentId,
    required this.businessId,
    required this.businessName,
    required this.businessArea,
    required this.stockQuantity,
    this.description,
    this.compareAtPrice,
    this.unit,
    this.imageUrl,
  });

  factory CatalogueProduct.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic> business =
        (map['businesses'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final Map<String, dynamic> category =
        (map['product_categories'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final String image = (map['image_url'] as String? ?? '').trim();

    return CatalogueProduct(
      id: map['id'] as String,
      name: (map['name'] as String?) ?? 'Unnamed item',
      description: map['description'] as String?,
      price: _toDouble(map['price_kes']),
      compareAtPrice: map['compare_at_price'] == null
          ? null
          : _toDouble(map['compare_at_price']),
      unit: map['unit'] as String?,
      stockQuantity: (map['stock_quantity'] as num?)?.toInt() ?? 0,
      imageUrl: image.isEmpty ? null : image,
      categoryId: (map['category_id'] as String?) ?? '',
      categoryName: (category['name'] as String?) ?? '',
      departmentId: (category['department_id'] as String?) ?? '',
      businessId: (map['business_id'] as String?) ?? '',
      businessName: (business['name'] as String?) ?? 'Merchant',
      businessArea: (business['area'] as String?) ?? '',
    );
  }

  final String id;
  final String name;
  final String? description;
  final double price;
  final double? compareAtPrice;
  final String? unit;
  final int stockQuantity;
  final String? imageUrl;
  final String categoryId;
  final String categoryName;
  final String departmentId;
  final String businessId;
  final String businessName;
  final String businessArea;

  bool get inStock => stockQuantity > 0;

  /// Discounts are shown only when a real previous price exists.
  bool get hasDiscount => compareAtPrice != null && compareAtPrice! > price;

  int get discountPercent {
    if (!hasDiscount) {
      return 0;
    }
    return (((compareAtPrice! - price) / compareAtPrice!) * 100).round();
  }

  /// "per kg", "each", or nothing for plain retail items.
  String? get unitLabel {
    switch (unit) {
      case null:
        return null;
      case 'piece':
        return 'each';
      case 'bunch':
        return 'per bunch';
      case 'crate':
        return 'per crate';
      case 'litre':
        return 'per litre';
      case 'pack':
        return 'per pack';
      case 'dozen':
        return 'per dozen';
      default:
        return 'per $unit';
    }
  }

  static double _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse('${value ?? ''}') ?? 0;
  }
}

/// An approved merchant, for the directory and storefront headers.
class MerchantSummary {
  const MerchantSummary({
    required this.id,
    required this.name,
    required this.area,
    required this.departmentIds,
    required this.departmentNames,
  });

  final String id;
  final String name;
  final String area;
  final List<String> departmentIds;
  final List<String> departmentNames;

  bool sellsIn(String departmentId) => departmentIds.contains(departmentId);

  String get departmentsLabel => departmentNames.join(' · ');
}
