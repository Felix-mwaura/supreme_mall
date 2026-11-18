import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/catalogue.dart';
import '../services/supabase_bootstrap.dart';
import '../utils/auth_errors.dart';

/// Thrown when a catalogue query fails in a way the UI must show.
class CatalogueFailure implements Exception {
  const CatalogueFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Every catalogue read goes through here.
///
/// The storefront never talks to PostgREST directly, so the query shape (which
/// columns, which joins, which limits) lives in one place and the screens stay
/// presentational. Row visibility is decided by RLS: a customer can only see
/// active products of approved businesses, whatever this class asks for.
class CatalogueRepository {
  const CatalogueRepository();

  /// `null` when the app is running without Supabase (widget tests). Screens
  /// then render their empty state instead of throwing.
  SupabaseClient? get _client =>
      SupabaseBootstrap.isInitialized ? SupabaseBootstrap.client : null;

  static const int pageSize = 40;

  /// Columns the product card and detail screen need, joined once.
  static const String _productSelect =
      'id, name, description, price_kes, compare_at_price, unit, stock_quantity, '
      'image_url, category_id, business_id, '
      'businesses(name, area), product_categories!inner(name, department_id)';

  Future<List<ProductCategory>> categories(String departmentId) async {
    final SupabaseClient? client = _client;
    if (client == null) {
      return const <ProductCategory>[];
    }
    try {
      final List<Map<String, dynamic>> rows = await client
          .from('product_categories')
          .select('id, department_id, name, sort_order')
          .eq('department_id', departmentId)
          .eq('is_active', true)
          .order('sort_order');

      return rows.map(ProductCategory.fromMap).toList();
    } on PostgrestException catch (error) {
      throw CatalogueFailure(AuthErrorMapper.describe(pgCode: error.code, message: error.message));
    } catch (error) {
      throw CatalogueFailure(AuthErrorMapper.describe(message: error.toString()));
    }
  }

  /// Products for a department, a merchant, a category, or a search term.
  ///
  /// Any combination works; nothing here can widen what RLS allows.
  Future<List<CatalogueProduct>> products({
    String? departmentId,
    String? categoryId,
    String? businessId,
    String? query,
    int limit = pageSize,
    int offset = 0,
  }) async {
    final SupabaseClient? client = _client;
    if (client == null) {
      return const <CatalogueProduct>[];
    }
    try {
      PostgrestFilterBuilder<List<Map<String, dynamic>>> request =
          client.from('products').select(_productSelect).eq('is_active', true);

      if (departmentId != null) {
        // Filter on the embedded category's department without a second query.
        request = request.eq('product_categories.department_id', departmentId);
      }
      if (categoryId != null) {
        request = request.eq('category_id', categoryId);
      }
      if (businessId != null) {
        request = request.eq('business_id', businessId);
      }
      final String term = (query ?? '').trim();
      if (term.isNotEmpty) {
        request = request.ilike('name', '%$term%');
      }

      final List<Map<String, dynamic>> rows =
          await request.order('name').range(offset, offset + limit - 1);

      return rows.map(CatalogueProduct.fromMap).toList();
    } on PostgrestException catch (error) {
      throw CatalogueFailure(AuthErrorMapper.describe(pgCode: error.code, message: error.message));
    } catch (error) {
      throw CatalogueFailure(AuthErrorMapper.describe(message: error.toString()));
    }
  }

  Future<CatalogueProduct?> product(String id) async {
    final SupabaseClient? client = _client;
    if (client == null) {
      return null;
    }
    try {
      final Map<String, dynamic>? row = await client
          .from('products')
          .select(_productSelect)
          .eq('id', id)
          .maybeSingle();

      return row == null ? null : CatalogueProduct.fromMap(row);
    } on PostgrestException catch (error) {
      throw CatalogueFailure(AuthErrorMapper.describe(pgCode: error.code, message: error.message));
    } catch (error) {
      throw CatalogueFailure(AuthErrorMapper.describe(message: error.toString()));
    }
  }

  /// Approved merchants, optionally limited to one department.
  Future<List<MerchantSummary>> merchants({
    String? departmentId,
    String? query,
    int limit = 100,
  }) async {
    final SupabaseClient? client = _client;
    if (client == null) {
      return const <MerchantSummary>[];
    }
    try {
      PostgrestFilterBuilder<List<Map<String, dynamic>>> request = client
          .from('businesses')
          .select('id, name, area, '
              'business_departments!inner(department_id, departments(name))')
          .eq('status', 'approved');

      if (departmentId != null) {
        request = request.eq('business_departments.department_id', departmentId);
      }
      final String term = (query ?? '').trim();
      if (term.isNotEmpty) {
        request = request.ilike('name', '%$term%');
      }

      final List<Map<String, dynamic>> rows = await request.order('name').limit(limit);

      return rows.map((Map<String, dynamic> row) {
        final List<dynamic> links =
            (row['business_departments'] as List<dynamic>?) ?? const <dynamic>[];
        final List<String> ids = <String>[];
        final List<String> names = <String>[];

        for (final dynamic link in links) {
          final Map<String, dynamic> map = link as Map<String, dynamic>;
          final String id = (map['department_id'] as String?) ?? '';
          if (id.isNotEmpty && !ids.contains(id)) {
            ids.add(id);
          }
          final Map<String, dynamic>? dept = map['departments'] as Map<String, dynamic>?;
          final String name = (dept?['name'] as String?) ?? '';
          if (name.isNotEmpty && !names.contains(name)) {
            names.add(name);
          }
        }

        return MerchantSummary(
          id: row['id'] as String,
          name: (row['name'] as String?) ?? 'Merchant',
          area: (row['area'] as String?) ?? '',
          departmentIds: ids,
          departmentNames: names,
        );
      }).toList();
    } on PostgrestException catch (error) {
      throw CatalogueFailure(AuthErrorMapper.describe(pgCode: error.code, message: error.message));
    } catch (error) {
      throw CatalogueFailure(AuthErrorMapper.describe(message: error.toString()));
    }
  }
}
