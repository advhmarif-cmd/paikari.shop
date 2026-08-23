import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paikari_shop/features/products/models/product.dart';
import 'package:paikari_shop/features/products/repositories/product_repository.dart';

final productListProvider = FutureProvider.family<List<Product>, bool>((ref, businessMode) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getProducts(businessMode: businessMode);
});
