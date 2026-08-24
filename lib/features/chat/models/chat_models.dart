class ChatConversation {
  final String id;
  final String buyerId;
  final String vendorId;
  final String productId;
  final String? productName;
  final String? productImageUrl;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final String? lastSenderId;
  final DateTime? buyerLastReadAt;
  final DateTime? vendorLastReadAt;

  const ChatConversation({
    required this.id,
    required this.buyerId,
    required this.vendorId,
    required this.productId,
    this.productName,
    this.productImageUrl,
    this.lastMessagePreview,
    this.lastMessageAt,
    this.lastSenderId,
    this.buyerLastReadAt,
    this.vendorLastReadAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] as String,
      buyerId: json['buyer_id'] as String,
      vendorId: json['vendor_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String?,
      productImageUrl: json['product_image_url'] as String?,
      lastMessagePreview: json['last_message_preview'] as String?,
      lastMessageAt: DateTime.tryParse(json['last_message_at'] as String? ?? ''),
      lastSenderId: json['last_sender_id'] as String?,
      buyerLastReadAt: DateTime.tryParse(json['buyer_last_read_at'] as String? ?? ''),
      vendorLastReadAt: DateTime.tryParse(json['vendor_last_read_at'] as String? ?? ''),
    );
  }

  bool isUnreadFor(String userId) {
    if (lastMessageAt == null || lastSenderId == userId) return false;
    final readAt = userId == buyerId ? buyerLastReadAt : vendorLastReadAt;
    return readAt == null || lastMessageAt!.isAfter(readAt);
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      body: json['body'] as String,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
