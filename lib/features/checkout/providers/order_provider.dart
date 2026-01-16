import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:paikari_shop/features/checkout/models/order.dart';
import 'package:paikari_shop/features/checkout/repositories/firestore_order_repository.dart';

final orderRepositoryProvider = Provider((ref) => FirestoreOrderRepository());

class OrderNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreOrderRepository _repository;

  OrderNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> placeOrder(Order order) async {
    state = const AsyncValue.loading();
    try {
      await _repository.placeOrder(order);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, AsyncValue<void>>(
    (ref) => OrderNotifier(ref.read(orderRepositoryProvider)));
