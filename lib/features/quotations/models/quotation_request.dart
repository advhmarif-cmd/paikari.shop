class QuotationRequest {
  final String id;
  final String buyerId;
  final String vendorId;
  final String productId;
  final int requestedQuantity;
  final double? targetUnitPrice;
  final String message;
  final String status;
  final int? quotedQuantity;
  final double? quotedUnitPrice;
  final double quotedDeliveryCharge;
  final String? vendorMessage;
  final DateTime? validUntil;
  final DateTime createdAt;
  final String? checkoutSessionId;
  final DateTime? acceptedAt;

  const QuotationRequest({
    required this.id,
    required this.buyerId,
    required this.vendorId,
    required this.productId,
    required this.requestedQuantity,
    required this.message,
    required this.status,
    required this.quotedDeliveryCharge,
    required this.createdAt,
    this.targetUnitPrice,
    this.quotedQuantity,
    this.quotedUnitPrice,
    this.vendorMessage,
    this.validUntil,
    this.checkoutSessionId,
    this.acceptedAt,
  });

  factory QuotationRequest.fromJson(Map<String, dynamic> json) {
    return QuotationRequest(
      id: json['id'] as String,
      buyerId: json['buyer_id'] as String,
      vendorId: json['vendor_id'] as String,
      productId: json['product_id'] as String,
      requestedQuantity: (json['requested_quantity'] as num?)?.toInt() ?? 1,
      targetUnitPrice: (json['target_unit_price'] as num?)?.toDouble(),
      message: (json['message'] ?? '') as String,
      status: (json['status'] ?? 'open') as String,
      quotedQuantity: (json['quoted_quantity'] as num?)?.toInt(),
      quotedUnitPrice: (json['quoted_unit_price'] as num?)?.toDouble(),
      quotedDeliveryCharge: (json['quoted_delivery_charge'] as num?)?.toDouble() ?? 0,
      vendorMessage: json['vendor_message'] as String?,
      validUntil: DateTime.tryParse(json['valid_until'] as String? ?? ''),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      checkoutSessionId: json['checkout_session_id'] as String?,
      acceptedAt: DateTime.tryParse(json['accepted_at'] as String? ?? ''),
    );
  }
}
