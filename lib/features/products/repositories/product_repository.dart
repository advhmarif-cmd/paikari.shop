import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:paikari_shop/features/products/models/product.dart';

class ProductRepository {
  ProductRepository({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<List<Product>> getProducts({bool businessMode = false}) async {
    final response = await _supabase
        .from(businessMode ? 'b2b_products' : 'b2c_products')
        .select()
        .order('updated_at', ascending: false);

    return (response as List)
        .map((json) => Product.fromJson(Map<String, dynamic>.from(json as Map)))
        .toList();
  }

  Future<Product?> getProductBySlug(String slug, {bool businessMode = false}) async {
    final response = await _supabase
        .from(businessMode ? 'b2b_products' : 'b2c_products')
        .select()
        .eq('slug', slug.trim())
        .maybeSingle();

    if (response == null) return null;
    return Product.fromJson(Map<String, dynamic>.from(response));
  }

  Future<Product?> getProductById(String id) async {
    final response = await _supabase
        .from('catalog_products')
        .select()
        .eq('id', id)
        .eq('is_active', true)
        .maybeSingle();

    if (response == null) return null;
    return Product.fromJson(Map<String, dynamic>.from(response));
  }

  Stream<List<Product>> watchProducts() {
    return _supabase
        .from('catalog_products')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('updated_at', ascending: false)
        .map((data) => data
            .map((json) => Product.fromJson(Map<String, dynamic>.from(json)))
            .toList());
  }

  Future<List<Product>> getMyLocalProducts() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('লগইন করা প্রয়োজন');

    final response = await _supabase
        .from('catalog_products')
        .select()
        .eq('source', 'paikari')
        .eq('owner_id', user.id)
        .order('updated_at', ascending: false);

    return (response as List)
        .map((json) => Product.fromJson(Map<String, dynamic>.from(json as Map)))
        .toList();
  }

  Future<Product> createLocalProduct({
    required String name,
    required String description,
    required double retailPrice,
    required List<WholesaleTier> wholesaleTiers,
    required String imageUrl,
    List<String> imageUrls = const [],
    required String category,
    String? slug,
    String stockStatus = 'In Stock',
    String? sku,
    String unitLabel = 'unit',
    int moq = 1,
    int? stockQuantity,
    bool isNegotiable = false,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('লগইন করা প্রয়োজন');
    final images = <String>{
      imageUrl.trim(),
      ...imageUrls.map((image) => image.trim()),
    }.where((image) => image.isNotEmpty).toList();
    final normalizedSlug = _normalizeSlug(slug);

    final response = await _supabase
        .from('catalog_products')
        .insert({
          'source': 'paikari',
          'owner_id': user.id,
          'slug': normalizedSlug ?? _makeSlug(name),
          'name': name.trim(),
          'description': description.trim(),
          'retail_price': retailPrice,
          'wholesale_tiers': wholesaleTiers.map((tier) => tier.toJson()).toList(),
          'image_url': images.isEmpty ? '' : images.first,
          'images': images,
          'category': category.trim(),
          'stock_status': stockStatus,
          'sku': sku?.trim().isEmpty == true ? null : sku?.trim(),
          'unit_label': unitLabel.trim().isEmpty ? 'unit' : unitLabel.trim(),
          'moq': moq < 1 ? 1 : moq,
          'stock_quantity': stockQuantity,
          'reserved_quantity': 0,
          'is_negotiable': isNegotiable,
          'approval_status': 'pending',
          'is_active': false,
        })
        .select()
        .single();

    return Product.fromJson(Map<String, dynamic>.from(response));
  }
}

String? _normalizeSlug(String? value) {
  final input = value?.trim().toLowerCase() ?? '';
  if (input.isEmpty) return null;
  final normalized = input
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return normalized.isEmpty ? null : normalized;
}

String _makeSlug(String value) {
  final base = value
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final suffix = DateTime.now().millisecondsSinceEpoch.toString();
  return '${base.isEmpty ? 'product' : base}-$suffix';
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});
