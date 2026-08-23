class BusinessBuyerProfile {
  final String userId;
  final String businessName;
  final String businessType;
  final String tradeLicenseUrl;
  final String buyerStatus;
  final List<String> preferredCategories;

  const BusinessBuyerProfile({
    required this.userId,
    this.businessName = '',
    this.businessType = '',
    this.tradeLicenseUrl = '',
    this.buyerStatus = 'pending',
    this.preferredCategories = const [],
  });

  factory BusinessBuyerProfile.fromJson(Map<String, dynamic> json) {
    return BusinessBuyerProfile(
      userId: json['user_id'] as String,
      businessName: (json['business_name'] ?? '') as String,
      businessType: (json['business_type'] ?? '') as String,
      tradeLicenseUrl: (json['trade_license_url'] ?? '') as String,
      buyerStatus: (json['buyer_status'] ?? 'pending') as String,
      preferredCategories: (json['preferred_categories'] as List<dynamic>? ?? const []).whereType<String>().toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'business_name': businessName,
      'business_type': businessType,
      'trade_license_url': tradeLicenseUrl,
      'buyer_status': buyerStatus,
      'preferred_categories': preferredCategories,
    };
  }
}
