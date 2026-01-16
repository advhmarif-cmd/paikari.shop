enum UserRole {
  consumer,
  vendor,
  admin;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.consumer,
    );
  }
}

class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final UserRole role;
  final bool isKycVerified;
  final String? phoneNumber;
  final String? businessName;
  final String? businessAddress;
  final String? tradeLicenseUrl;

  const UserModel({
    required this.uid,
    this.email,
    this.displayName,
    required this.role,
    this.isKycVerified = false,
    this.phoneNumber,
    this.businessName,
    this.businessAddress,
    this.tradeLicenseUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      role: UserRole.fromString(json['role'] as String),
      isKycVerified: json['isKycVerified'] as bool? ?? false,
      phoneNumber: json['phoneNumber'] as String?,
      businessName: json['businessName'] as String?,
      businessAddress: json['businessAddress'] as String?,
      tradeLicenseUrl: json['tradeLicenseUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'isKycVerified': isKycVerified,
      'phoneNumber': phoneNumber,
      'businessName': businessName,
      'businessAddress': businessAddress,
      'tradeLicenseUrl': tradeLicenseUrl,
    };
  }
}
