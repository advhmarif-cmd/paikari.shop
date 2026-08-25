import 'package:paikari_shop/features/cart/models/cart_item.dart';
import 'package:paikari_shop/features/products/models/product.dart';
import 'package:paikari_shop/features/checkout/models/address.dart';

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled
}

class Order {
  final String id;
  final List<CartItem> items;
  final double totalAmount;
  final Address shippingAddress;
  final String paymentMethod;
  final String paymentStatus;
  final String? paymentReference;
  final DateTime? paidAt;
  final DateTime createdAt;
  final OrderStatus status;
  final String buyerMode;
  final String? orderGroupId;

  const Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.shippingAddress,
    required this.paymentMethod,
    this.paymentStatus = 'unpaid',
    this.paymentReference,
    this.paidAt,
    required this.createdAt,
    this.status = OrderStatus.pending,
    this.buyerMode = 'b2c',
    this.orderGroupId,
  });

  factory Order.fromSupabase(Map<String, dynamic> data) {
    final buyerMode = (data['buyer_mode']?.toString() ?? 'b2c').toLowerCase();
    final rawItems = data['items'] is List<dynamic>
        ? data['items'] as List<dynamic>
        : const <dynamic>[];
    final items = rawItems.map((rawItem) {
      final item = Map<String, dynamic>.from(rawItem as Map);
      final productId = item['productId'] as String? ?? '';
      final unitPrice = (item['unitPrice'] as num?)?.toDouble() ?? 0;
      return CartItem(
        product: Product(
          id: productId,
          name: item['productName'] as String? ?? '',
          description: '',
          retailPrice: unitPrice,
          wholesaleTiers: const [],
          imageUrl: item['imageUrl'] as String? ?? '',
          category: '',
          isAvailable: true,
          sku: item['sku'] as String?,
          moq: (item['moq'] as num?)?.toInt() ?? 1,
          vendorId: item['vendorId'] as String?,
        ),
        quantity: (item['quantity'] as num?)?.toInt() ?? 1,
        businessMode:
            (item['buyerMode']?.toString().toLowerCase() ?? buyerMode) == 'b2b',
      );
    }).toList();

    final rawAddress = Map<String, dynamic>.from(
      (data['shipping_address'] as Map?) ?? const {},
    );
    final rawStatus = (data['status'] as String? ?? 'pending').toLowerCase();

    return Order(
      id: data['id'] as String,
      items: items,
      totalAmount: (data['total_amount'] as num?)?.toDouble() ?? 0,
      shippingAddress: Address.fromJson(rawAddress),
      paymentMethod: data['payment_method'] as String? ?? 'Cash on Delivery',
      paymentStatus: data['payment_status'] as String? ?? 'unpaid',
      paymentReference: data['payment_reference'] as String?,
      paidAt: DateTime.tryParse(data['paid_at'] as String? ?? ''),
      createdAt: DateTime.tryParse(data['created_at'] as String? ?? '') ??
          DateTime.now(),
      status: OrderStatus.values.firstWhere(
        (status) => status.name == rawStatus,
        orElse: () => OrderStatus.pending,
      ),
      buyerMode: buyerMode == 'b2b' ? 'b2b' : 'b2c',
      orderGroupId: data['order_group_id'] as String?,
    );
  }
}
