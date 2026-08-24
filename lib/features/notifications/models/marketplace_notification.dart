class MarketplaceNotification {
  final String id;
  final String? orderGroupId;
  final String? returnRequestId;
  final String notificationType;
  final String title;
  final String body;
  final DateTime? readAt;
  final DateTime createdAt;

  const MarketplaceNotification({
    required this.id,
    required this.orderGroupId,
    required this.returnRequestId,
    required this.notificationType,
    required this.title,
    required this.body,
    required this.readAt,
    required this.createdAt,
  });

  factory MarketplaceNotification.fromJson(Map<String, dynamic> json) {
    return MarketplaceNotification(
      id: json['id'] as String,
      orderGroupId: json['order_group_id'] as String?,
      returnRequestId: json['return_request_id'] as String?,
      notificationType: json['notification_type'] as String? ?? 'system',
      title: json['title'] as String? ?? 'Notification',
      body: json['body'] as String? ?? '',
      readAt: DateTime.tryParse(json['read_at'] as String? ?? ''),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
