import 'package:flutter_test/flutter_test.dart';
import 'package:supreme_mall/models/catalogue.dart';

void main() {
  Map<String, dynamic> row({
    Object? price = 199.0,
    Object? compareAt,
    String? unit,
    int stock = 10,
    String? image,
    Map<String, dynamic>? category,
  }) {
    return <String, dynamic>{
      'id': 'p1',
      'name': 'Unga wa Dola 2kg',
      'description': 'Maize flour',
      'price_kes': price,
      'compare_at_price': compareAt,
      'unit': unit,
      'stock_quantity': stock,
      'image_url': image,
      'category_id': 'groceries',
      'business_id': 'b1',
      'businesses': <String, dynamic>{'name': 'Nyeri Fresh Mart', 'area': 'Nyeri Town'},
      'product_categories':
          category ?? <String, dynamic>{'name': 'Groceries', 'department_id': 'shopping'},
    };
  }

  group('CatalogueProduct parsing', () {
    test('reads the joined merchant and category', () {
      final CatalogueProduct product = CatalogueProduct.fromMap(row());

      expect(product.name, 'Unga wa Dola 2kg');
      expect(product.price, 199.0);
      expect(product.businessName, 'Nyeri Fresh Mart');
      expect(product.businessArea, 'Nyeri Town');
      expect(product.categoryName, 'Groceries');
      expect(product.departmentId, 'shopping');
    });

    test('accepts numeric sent as a string', () {
      // PostgREST may serialise `numeric` as text; both must parse.
      final CatalogueProduct product = CatalogueProduct.fromMap(row(price: '349.50'));

      expect(product.price, 349.5);
    });

    test('treats blank and missing images as no image', () {
      expect(CatalogueProduct.fromMap(row(image: '  ')).imageUrl, isNull);
      expect(CatalogueProduct.fromMap(row()).imageUrl, isNull);
      expect(CatalogueProduct.fromMap(row(image: ' https://x/y.jpg ')).imageUrl,
          'https://x/y.jpg');
    });

    test('missing relationships never crash the card', () {
      final CatalogueProduct product = CatalogueProduct.fromMap(<String, dynamic>{
        'id': 'p2',
        'name': 'Loose item',
        'price_kes': 10,
      });

      expect(product.businessName, 'Merchant');
      expect(product.categoryName, '');
      expect(product.price, 10.0);
    });
  });

  group('availability and pricing rules', () {
    test('discount only exists when a higher previous price is stored', () {
      expect(CatalogueProduct.fromMap(row(compareAt: 399.0)).hasDiscount, isTrue);
      expect(CatalogueProduct.fromMap(row(compareAt: 399.0)).discountPercent, 50);
      expect(CatalogueProduct.fromMap(row(compareAt: 150.0)).hasDiscount, isFalse);
      expect(CatalogueProduct.fromMap(row()).hasDiscount, isFalse);
    });

    test('stock decides availability', () {
      expect(CatalogueProduct.fromMap(row(stock: 0)).inStock, isFalse);
      expect(CatalogueProduct.fromMap(row(stock: 3)).inStock, isTrue);
    });

    test('units are written the way shoppers read them', () {
      expect(CatalogueProduct.fromMap(row(unit: 'kg')).unitLabel, 'per kg');
      expect(CatalogueProduct.fromMap(row(unit: 'piece')).unitLabel, 'each');
      expect(CatalogueProduct.fromMap(row(unit: 'bunch')).unitLabel, 'per bunch');
      expect(CatalogueProduct.fromMap(row()).unitLabel, isNull);
    });
  });

  group('MerchantSummary', () {
    test('knows which departments it sells in', () {
      const MerchantSummary merchant = MerchantSummary(
        id: 'b1',
        name: 'Nyeri Fresh Mart',
        area: 'Nyeri Town',
        departmentIds: <String>['shopping'],
        departmentNames: <String>['Supreme Shopping'],
      );

      expect(merchant.sellsIn('shopping'), isTrue);
      expect(merchant.sellsIn('food'), isFalse);
      expect(merchant.departmentsLabel, 'Supreme Shopping');
    });
  });
}
