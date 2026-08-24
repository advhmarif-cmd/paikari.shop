class OrderStatusEvent {
  final String id;
  final String orderGroupId;
  final String? vendorOrderId;
  final String? previousStatus;
  final String newStatus;
  final String actorType;
  final String? note;
  final DateTime createdAt;

  const OrderStatusEvent({
    required this.id,
    required this.orderGroupId,
    this.vendorOrderId,
    required this.previousStatus,
    required this.newStatus,
    required this.actorType,
    required this.note,
    required this.createdAt,
  });

  factory OrderStatusEvent.fromJson(Map<String, dynamic> json) {
    return OrderStatusEvent(
      id: json['id'] as String,
      orderGroupId: json['order_group_id'] as String,
      vendorOrderId: json['vendor_order_id'] as String?,
      previousStatus: json['previous_status'] as String?,
      newStatus: json['new_status'] as String? ?? 'pending',
      actorType: json['actor_type'] as String? ?? 'system',
      note: json['note'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
