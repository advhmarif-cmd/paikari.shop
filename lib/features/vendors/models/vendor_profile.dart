class VendorProfile {
  final String userId;
  final String storeName;
  final String slug;
  final String description;
  final String logoUrl;
  final String phone;
  final String city;
  final String address;
  final String verificationStatus;
  final bool isActive;
  final int? responseTimeHours;

  const VendorProfile({
    required this.userId,
    required this.storeName,
    required this.slug,
    this.description = '',
    this.logoUrl = '',
    this.phone = '',
    this.city = '',
    this.address = '',
    this.verificationStatus = 'pending',
    this.isActive = false,
    this.responseTimeHours,
  });

  factory VendorProfile.fromJson(Map<String, dynamic> json) {
    return VendorProfile(
      userId: json['user_id'] as String,
      storeName: (json['store_name'] ?? '') as String,
      slug: (json['slug'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      logoUrl: (json['logo_url'] ?? '') as String,
      phone: (json['phone'] ?? '') as String,
      city: (json['city'] ?? '') as String,
      address: (json['address'] ?? '') as String,
      verificationStatus: (json['verification_status'] ?? 'pending') as String,
      isActive: json['is_active'] as bool? ?? false,
      responseTimeHours: (json['response_time_hours'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'store_name': storeName,
      'slug': slug,
      'description': description,
      'logo_url': logoUrl,
      'phone': phone,
      'city': city,
      'address': address,
      'verification_status': verificationStatus,
      'is_active': isActive,
      'response_time_hours': responseTimeHours,
    };
  }
}
