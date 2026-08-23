class ProductInquiry {
  final String id;
  final String buyerId;
  final String vendorId;
  final String productId;
  final int requestedQuantity;
  final double? targetPrice;
  final String message;
  final String status;
  final String? vendorResponse;
  final DateTime createdAt;

  const ProductInquiry({
    required this.id,
    required this.buyerId,
    required this.vendorId,
    required this.productId,
    required this.requestedQuantity,
    required this.message,
    required this.status,
    required this.createdAt,
    this.targetPrice,
    this.vendorResponse,
  });

  factory ProductInquiry.fromJson(Map<String, dynamic> json) {
    return ProductInquiry(
      id: json['id'] as String,
      buyerId: json['buyer_id'] as String,
      vendorId: json['vendor_id'] as String,
      productId: json['product_id'] as String,
      requestedQuantity: (json['requested_quantity'] as num?)?.toInt() ?? 1,
      targetPrice: (json['target_price'] as num?)?.toDouble(),
      message: (json['message'] ?? '') as String,
      status: (json['status'] ?? 'open') as String,
      vendorResponse: json['vendor_response'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
