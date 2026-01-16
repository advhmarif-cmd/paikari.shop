class Address {
  final String streetAddress;
  final String city; // District
  final String state; // Thana/Upazila
  final String zipCode;
  final String phoneNumber;

  const Address({
    required this.streetAddress,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'streetAddress': streetAddress,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'phoneNumber': phoneNumber,
    };
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      streetAddress: json['streetAddress'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      zipCode: json['zipCode'] as String,
      phoneNumber: json['phoneNumber'] as String,
    );
  }
}
