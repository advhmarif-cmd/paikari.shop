import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paikari_shop/features/checkout/providers/order_provider.dart';
import 'package:paikari_shop/features/vendors/models/vendor_order.dart';

final vendorOrdersProvider = StreamProvider<List<VendorOrder>>((ref) {
  return ref.watch(orderRepositoryProvider).watchVendorOrders().map(
        (rows) => rows.map((row) => VendorOrder.fromJson(row)).toList(),
      );
});
