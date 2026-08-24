class ReturnRequest {
  final String id;
  final String orderGroupId;
  final String? vendorOrderId;
  final String? productId;
  final int quantity;
  final String reason;
  final String details;
  final String status;
  final String? resolutionNote;
  final DateTime createdAt;

  const ReturnRequest({
    required this.id,
    required this.orderGroupId,
    required this.vendorOrderId,
    required this.productId,
    required this.quantity,
    required this.reason,
    required this.details,
    required this.status,
    required this.resolutionNote,
    required this.createdAt,
  });

  factory ReturnRequest.fromJson(Map<String, dynamic> json) {
    return ReturnRequest(
      id: json['id'] as String,
      orderGroupId: json['order_group_id'] as String,
      vendorOrderId: json['vendor_order_id'] as String?,
      productId: json['product_id'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      reason: json['reason'] as String? ?? '',
      details: json['details'] as String? ?? '',
      status: json['status'] as String? ?? 'requested',
      resolutionNote: json['resolution_note'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
