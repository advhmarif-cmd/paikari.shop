import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paikari_shop/features/auth/repositories/auth_repository.dart';
import 'package:paikari_shop/features/buyer/models/business_buyer_profile.dart';
import 'package:paikari_shop/features/buyer/repositories/business_buyer_repository.dart';

final myBusinessBuyerProfileProvider = FutureProvider<BusinessBuyerProfile?>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(businessBuyerRepositoryProvider).getMyProfile();
});
