import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paikari_shop/features/products/models/product.dart';
import 'package:paikari_shop/features/products/repositories/product_repository.dart';

final myLocalProductsProvider = FutureProvider<List<Product>>((ref) async {
  return ref.watch(productRepositoryProvider).getMyLocalProducts();
});
