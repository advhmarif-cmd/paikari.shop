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
      streetAddress: _readString(json, 'streetAddress', 'street_address'),
      city: _readString(json, 'city', 'district'),
      state: _readString(json, 'state', 'thana'),
      zipCode: _readString(json, 'zipCode', 'zip_code'),
      phoneNumber: _readString(json, 'phoneNumber', 'phone_number', 'phone'),
    );
  }

  static String _readString(
    Map<String, dynamic> json,
    String key, [
    String? alternateKey,
    String? secondAlternateKey,
  ]) {
    final value = json[key] ??
        (alternateKey == null ? null : json[alternateKey]) ??
        (secondAlternateKey == null ? null : json[secondAlternateKey]);
    return value?.toString().trim() ?? '';
  }
}
