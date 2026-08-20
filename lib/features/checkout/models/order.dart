import 'package:paikari_shop/features/cart/models/cart_item.dart';
import 'package:paikari_shop/features/products/models/product.dart';
import 'package:paikari_shop/features/checkout/models/address.dart';

enum OrderStatus { pending, processing, shipped, delivered, cancelled }

class Order {
  final String id;
  final List<CartItem> items;
  final double totalAmount;
  final Address shippingAddress;
  final String paymentMethod;
  final DateTime createdAt;
  final OrderStatus status;

  const Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.createdAt,
    this.status = OrderStatus.pending,
  });

  factory Order.fromSupabase(Map<String, dynamic> data) {
    final rawItems = (data['items'] as List<dynamic>? ?? const []);
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
        ),
        quantity: (item['quantity'] as num?)?.toInt() ?? 1,
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
      createdAt: DateTime.tryParse(data['created_at'] as String? ?? '') ?? DateTime.now(),
      status: OrderStatus.values.firstWhere(
        (status) => status.name == rawStatus,
        orElse: () => OrderStatus.pending,
      ),
    );
  }
}
