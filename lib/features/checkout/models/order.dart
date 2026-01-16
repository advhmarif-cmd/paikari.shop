import 'package:cloud_firestore/cloud_firestore.dart';
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items
          .map((x) => {
                'productId': x.product.id,
                'quantity': x.quantity,
                'price': x.price
              })
          .toList(),
      'totalAmount': totalAmount,
      'shippingAddress': shippingAddress.toJson(),
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
    };
  }

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Order(
      id: doc.id,
      items: (data['items'] as List<dynamic>)
          .map((x) => CartItem(
                product: Product(
                  id: x['productId'] as String,
                  name: '',
                  description: '',
                  retailPrice: 0,
                  wholesaleTiers: [],
                  imageUrl: '',
                  category: '',
                  isAvailable: true,
                ),
                quantity: x['quantity'] as int,
              ))
          .toList(),
      totalAmount: (data['totalAmount'] as num).toDouble(),
      shippingAddress:
          Address.fromJson(data['shippingAddress'] as Map<String, dynamic>),
      paymentMethod: data['paymentMethod'] as String,
      createdAt: DateTime.parse(data['createdAt'] as String),
      status: OrderStatus.values.firstWhere((e) => e.name == data['status']),
    );
  }
}
