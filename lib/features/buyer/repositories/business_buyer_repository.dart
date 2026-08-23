import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:paikari_shop/features/buyer/models/business_buyer_profile.dart';

class BusinessBuyerRepository {
  BusinessBuyerRepository({SupabaseClient? client}) : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<BusinessBuyerProfile?> getMyProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('business_buyer_profiles')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return BusinessBuyerProfile.fromJson(Map<String, dynamic>.from(response));
  }

  Future<BusinessBuyerProfile> saveMyProfile({
    required String businessName,
    required String businessType,
    required List<String> preferredCategories,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('লগইন করা প্রয়োজন');

    final profile = BusinessBuyerProfile(
      userId: user.id,
      businessName: businessName.trim(),
      businessType: businessType.trim(),
      preferredCategories: preferredCategories,
    );

    await _supabase.from('business_buyer_profiles').upsert(
          {
            'user_id': profile.userId,
            'business_name': profile.businessName,
            'business_type': profile.businessType,
            'preferred_categories': profile.preferredCategories,
          },
          onConflict: 'user_id',
        );
    return profile;
  }
}

final businessBuyerRepositoryProvider = Provider<BusinessBuyerRepository>((ref) {
  return BusinessBuyerRepository();
});
