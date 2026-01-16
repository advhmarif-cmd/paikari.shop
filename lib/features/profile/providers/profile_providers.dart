import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paikari_shop/features/checkout/models/order.dart';
import 'package:paikari_shop/features/checkout/providers/order_provider.dart';

import 'package:paikari_shop/features/auth/repositories/auth_repository.dart';

final profileOrdersProvider = StreamProvider<List<Order>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  final repository = ref.read(orderRepositoryProvider);
  return repository.getOrders(user.uid);
});
