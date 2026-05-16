import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:paikari_shop/features/products/models/product.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Product>> getProducts() async {
    final response = await _supabase
        .from('products')
        .select();
    
    return (response as List).map((json) => Product.fromJson(json)).toList();
  }

  Future<Product?> getProductById(String id) async {
    final response = await _supabase
        .from('products')
        .select()
        .eq('id', id)
        .maybeSingle();
    
    if (response == null) return null;
    return Product.fromJson(response);
  }

  Stream<List<Product>> watchProducts() {
    return _supabase
        .from('products')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((json) => Product.fromJson(json)).toList());
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});
