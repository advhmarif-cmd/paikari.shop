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
    final quantity = _readInt(json, 'quantity');
    final unitPrice = _readDouble(json, 'unit_price');
    final deliveryCharge = _readDouble(json, 'delivery_charge', fallback: 0);
    final totalAmount = _readDouble(json, 'total_amount');
    if (quantity < 1 ||
        unitPrice < 0 ||
        deliveryCharge < 0 ||
        totalAmount < 0) {
      throw const FormatException('Invalid quote checkout session amounts');
    }

    return QuoteCheckoutSession(
      id: _requiredString(json, 'id'),
      quotationId: _requiredString(json, 'quotation_id'),
      buyerId: _requiredString(json, 'buyer_id'),
      vendorId: _requiredString(json, 'vendor_id'),
      productId: _requiredString(json, 'product_id'),
      quantity: quantity,
      unitPrice: unitPrice,
      deliveryCharge: deliveryCharge,
      totalAmount: totalAmount,
      status: _requiredString(json, 'status').toLowerCase(),
      expiresAt: _readDate(json, 'expires_at'),
      orderGroupId: _optionalString(json, 'order_group_id'),
      createdAt: _readDate(json, 'created_at'),
      usedAt: _optionalDate(json, 'used_at'),
    );
  }

  bool get isOpen => status == 'open' && expiresAt.isAfter(DateTime.now());

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = _optionalString(json, key);
    if (value == null || value.isEmpty) {
      throw FormatException('Missing quote session field: $key');
    }
    return value;
  }

  static String? _optionalString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    final normalized = value.toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  static int _readInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is num) return value.toInt();
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed == null) {
      throw FormatException('Invalid quote session field: $key');
    }
    return parsed;
  }

  static double _readDouble(
    Map<String, dynamic> json,
    String key, {
    double? fallback,
  }) {
    final value = json[key];
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
    if (fallback != null) return fallback;
    throw FormatException('Invalid quote session field: $key');
  }

  static DateTime _readDate(Map<String, dynamic> json, String key) {
    final value = DateTime.tryParse(_optionalString(json, key) ?? '');
    if (value == null) {
      throw FormatException('Invalid quote session field: $key');
    }
    return value;
  }

  static DateTime? _optionalDate(Map<String, dynamic> json, String key) {
    final raw = _optionalString(json, key);
    return raw == null ? null : DateTime.tryParse(raw);
  }
}
