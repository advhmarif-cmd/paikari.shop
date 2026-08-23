import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paikari_shop/features/auth/repositories/auth_repository.dart';
import 'package:paikari_shop/features/vendors/models/vendor_profile.dart';
import 'package:paikari_shop/features/vendors/repositories/vendor_repository.dart';

final myVendorProfileProvider = FutureProvider<VendorProfile?>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(vendorRepositoryProvider).getMyProfile();
});


final publicVendorProfileProvider = FutureProvider.family<VendorProfile?, String>((ref, userId) async {
  return ref.watch(vendorRepositoryProvider).getPublicProfile(userId);
});
