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

    final businessMode = items.any((item) => item.businessMode);
    final response = await _supabase.rpc(
      'place_order_group_from_cart',
      params: {
        'p_items': items
            .map((item) => {
                  'productId': item.product.id,
                  'quantity': item.quantity,
                  'buyerMode': item.businessMode ? 'b2b' : 'b2c',
                })
            .toList(),
        'p_shipping_address': {
          ...shippingAddress.toJson(),
          'zone': deliveryZone,
          'buyer_mode': businessMode ? 'b2b' : 'b2c',
        },
        'p_payment_method': paymentMethod,
      },
    );

    return app_order.Order.fromSupabase(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<void> cancelOrderGroup(String orderGroupId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('লগইন করা প্রয়োজন');
    await _supabase.rpc('cancel_order_group', params: {'p_order_group_id': orderGroupId});
  }

  Future<void> updateVendorOrderStatus({required String vendorOrderId, required String status}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('লগইন করা প্রয়োজন');
    await _supabase.rpc('update_vendor_order_status', params: {
      'p_vendor_order_id': vendorOrderId,
      'p_status': status,
    });
  }

  Stream<List<Map<String, dynamic>>> watchVendorOrders() {
    final user = _supabase.auth.currentUser;
    if (user == null) return const Stream.empty();
    return _supabase
        .from('vendor_orders')
        .stream(primaryKey: ['id'])
        .eq('vendor_id', user.id)
        .order('created_at', ascending: false);
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
