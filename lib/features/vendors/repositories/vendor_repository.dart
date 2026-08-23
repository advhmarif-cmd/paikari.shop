import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:paikari_shop/features/vendors/models/vendor_profile.dart';

class VendorRepository {
  VendorRepository({SupabaseClient? client}) : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<VendorProfile?> getMyProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('vendor_profiles')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return VendorProfile.fromJson(Map<String, dynamic>.from(response));
  }

  Future<VendorProfile?> getPublicProfile(String userId) async {
    final response = await _supabase
        .from('vendor_profiles')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .maybeSingle();

    if (response == null) return null;
    return VendorProfile.fromJson(Map<String, dynamic>.from(response));
  }

  Future<VendorProfile> saveMyProfile({
    required String storeName,
    required String slug,
    required String description,
    required String phone,
    required String city,
    required String address,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('লগইন করা প্রয়োজন');

    final profile = VendorProfile(
      userId: user.id,
      storeName: storeName.trim(),
      slug: slug.trim().toLowerCase(),
      description: description.trim(),
      phone: phone.trim(),
      city: city.trim(),
      address: address.trim(),
    );

    await _supabase.from('vendor_profiles').upsert(
          {
            'user_id': profile.userId,
            'store_name': profile.storeName,
            'slug': profile.slug,
            'description': profile.description,
            'phone': profile.phone,
            'city': profile.city,
            'address': profile.address,
          },
          onConflict: 'user_id',
        );

    await _supabase
        .from('users')
        .update({'role': 'vendor'})
        .eq('uid', user.id);

    return profile;
  }
}

final vendorRepositoryProvider = Provider<VendorRepository>((ref) {
  return VendorRepository();
});
