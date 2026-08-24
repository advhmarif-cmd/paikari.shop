import 'package:paikari_shop/features/checkout/models/address.dart';

class SavedAddress {
  final String id;
  final String label;
  final Address address;
  final bool isDefault;

  const SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.isDefault,
  });

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: json['id'] as String,
      label: (json['label'] as String? ?? 'আমার ঠিকানা').trim(),
      address: Address.fromJson(
        Map<String, dynamic>.from((json['address'] as Map?) ?? const {}),
      ),
      isDefault: json['is_default'] as bool? ?? false,
    );
  }
}
