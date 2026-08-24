class QuoteCheckoutSession {
  final String id;
  final String quotationId;
  final String buyerId;
  final String vendorId;
  final String productId;
  final int quantity;
  final double unitPrice;
  final double deliveryCharge;
  final double totalAmount;
  final String status;
  final DateTime expiresAt;
  final String? orderGroupId;
  final DateTime createdAt;
  final DateTime? usedAt;

  const QuoteCheckoutSession({
    required this.id,
    required this.quotationId,
    required this.buyerId,
    required this.vendorId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.deliveryCharge,
    required this.totalAmount,
    required this.status,
    required this.expiresAt,
    this.orderGroupId,
    required this.createdAt,
    this.usedAt,
  });

  factory QuoteCheckoutSession.fromJson(Map<String, dynamic> json) {
    return QuoteCheckoutSession(
      id: json['id'] as String,
      quotationId: json['quotation_id'] as String,
      buyerId: json['buyer_id'] as String,
      vendorId: json['vendor_id'] as String,
      productId: json['product_id'] as String,
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unit_price'] as num).toDouble(),
      deliveryCharge: (json['delivery_charge'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      orderGroupId: json['order_group_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      usedAt: DateTime.tryParse(json['used_at'] as String? ?? ''),
    );
  }

  bool get isOpen => status == 'open' && expiresAt.isAfter(DateTime.now());
}
