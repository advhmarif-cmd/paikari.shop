import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:paikari_shop/features/cart/models/cart_item.dart';
import 'package:paikari_shop/features/checkout/models/address.dart';
import 'package:paikari_shop/features/checkout/models/order.dart' as app_order;

class SupabaseOrderRepository {
  SupabaseOrderRepository({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<app_order.Order> placeOrder({
    required List<CartItem> items,
    required Address shippingAddress,
    required String deliveryZone,
    required String paymentMethod,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('লগইন করা প্রয়োজন');
    if (items.isEmpty) throw Exception('কার্ট খালি আছে');

    final response = await _supabase.rpc(
      'place_order_from_cart',
      params: {
        'p_items': items
            .map((item) => {
                  'productId': item.product.id,
                  'quantity': item.quantity,
                })
            .toList(),
        'p_shipping_address': {
          ...shippingAddress.toJson(),
          'zone': deliveryZone,
        },
        'p_payment_method': paymentMethod,
      },
    );

    return app_order.Order.fromSupabase(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Stream<List<app_order.Order>> getOrders(String userId) {
    return _supabase
        .from('order_records')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((rows) => rows
            .map((row) => app_order.Order.fromSupabase(row))
            .toList());
  }
}
