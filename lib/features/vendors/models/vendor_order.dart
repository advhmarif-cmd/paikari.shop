class VendorOrder {
  final String id;
  final String orderGroupId;
  final String? vendorId;
  final String vendorStoreName;
  final double subtotal;
  final double deliveryCharge;
  final double totalAmount;
  final String status;
  final String? courierName;
  final String? trackingNumber;
  final String? trackingUrl;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final String? courierProvider;
  final String? courierStatus;
  final DateTime? courierUpdatedAt;
  final List<Map<String, dynamic>> items;
  final DateTime createdAt;

  const VendorOrder({
    required this.id,
    required this.orderGroupId,
    required this.vendorStoreName,
    required this.subtotal,
    required this.deliveryCharge,
    required this.totalAmount,
    required this.status,
    this.courierName,
    this.trackingNumber,
    this.trackingUrl,
    this.shippedAt,
    this.deliveredAt,
    this.courierProvider,
    this.courierStatus,
    this.courierUpdatedAt,
    required this.items,
    required this.createdAt,
    this.vendorId,
  });

  factory VendorOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>? ?? const []);
    return VendorOrder(
      id: json['id'] as String,
      orderGroupId: json['order_group_id'] as String,
      vendorId: json['vendor_id'] as String?,
      vendorStoreName: (json['vendor_store_name'] ?? 'Supplier') as String,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryCharge: (json['delivery_charge'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      status: (json['status'] ?? 'pending') as String,
      courierName: json['courier_name'] as String?,
      trackingNumber: json['tracking_number'] as String?,
      trackingUrl: json['tracking_url'] as String?,
      shippedAt: DateTime.tryParse(json['shipped_at'] as String? ?? ''),
      deliveredAt: DateTime.tryParse(json['delivered_at'] as String? ?? ''),
      courierProvider: json['courier_provider'] as String?,
      courierStatus: json['courier_status'] as String?,
      courierUpdatedAt: DateTime.tryParse(json['courier_updated_at'] as String? ?? ''),
      items: rawItems.map((item) => Map<String, dynamic>.from(item as Map)).toList(),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
