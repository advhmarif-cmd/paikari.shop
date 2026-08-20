import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:paikari_shop/features/products/models/product.dart';

class ProductRepository {
  ProductRepository({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<List<Product>> getProducts() async {
    final response = await _supabase
        .from('catalog_products')
        .select()
        .eq('is_active', true)
        .order('updated_at', ascending: false);

    return (response as List)
        .map((json) => Product.fromJson(Map<String, dynamic>.from(json as Map)))
        .toList();
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

  Future<Product> createLocalProduct({
    required String name,
    required String description,
    required double retailPrice,
    required List<WholesaleTier> wholesaleTiers,
    required String imageUrl,
    required String category,
    String stockStatus = 'In Stock',
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('লগইন করা প্রয়োজন');

    final response = await _supabase
        .from('catalog_products')
        .insert({
          'source': 'paikari',
          'owner_id': user.id,
          'name': name.trim(),
          'description': description.trim(),
          'retail_price': retailPrice,
          'wholesale_tiers': wholesaleTiers.map((tier) => tier.toJson()).toList(),
          'image_url': imageUrl.trim(),
          'images': imageUrl.trim().isEmpty ? [] : [imageUrl.trim()],
          'category': category.trim(),
          'stock_status': stockStatus,
          'is_active': false,
        })
        .select()
        .single();

    return Product.fromJson(Map<String, dynamic>.from(response));
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});
