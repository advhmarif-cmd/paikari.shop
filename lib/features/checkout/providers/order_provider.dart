import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paikari_shop/features/cart/models/cart_item.dart';
import 'package:paikari_shop/features/checkout/models/address.dart';
import 'package:paikari_shop/features/checkout/models/order.dart';
import 'package:paikari_shop/features/checkout/repositories/supabase_order_repository.dart';

final orderRepositoryProvider = Provider<SupabaseOrderRepository>((ref) {
  return SupabaseOrderRepository();
});

class OrderNotifier extends StateNotifier<AsyncValue<Order?>> {
  final SupabaseOrderRepository _repository;

  OrderNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<Order?> placeOrder({
    required List<CartItem> items,
    required Address shippingAddress,
    required String deliveryZone,
    required String paymentMethod,
  }) async {
    state = const AsyncValue.loading();
    try {
      final order = await _repository.placeOrder(
        items: items,
        shippingAddress: shippingAddress,
        deliveryZone: deliveryZone,
        paymentMethod: paymentMethod,
      );
      state = AsyncValue.data(order);
      return order;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, AsyncValue<Order?>>(
  (ref) => OrderNotifier(ref.read(orderRepositoryProvider)),
);
