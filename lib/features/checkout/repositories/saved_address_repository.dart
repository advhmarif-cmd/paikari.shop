import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:paikari_shop/features/checkout/models/address.dart';
import 'package:paikari_shop/features/checkout/models/saved_address.dart';

class SavedAddressRepository {
  SavedAddressRepository({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<List<SavedAddress>> list() async {
    final response = await _supabase
        .from('saved_addresses')
        .select('id, label, address, is_default, created_at')
        .order('is_default', ascending: false)
        .order('created_at', ascending: false);
    return (response as List)
        .map((row) => SavedAddress.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<void> save({
    required String label,
    required Address address,
    bool isDefault = false,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('লগইন করা প্রয়োজন');

    if (isDefault) {
      await _supabase
          .from('saved_addresses')
          .update({'is_default': false})
          .eq('user_id', user.id);
    }

    await _supabase.from('saved_addresses').insert({
      'user_id': user.id,
      'label': label.trim().isEmpty ? 'আমার ঠিকানা' : label.trim(),
      'address': address.toJson(),
      'is_default': isDefault,
    });
  }

  Future<void> delete(String id) async {
    await _supabase.from('saved_addresses').delete().eq('id', id);
  }
}

final savedAddressRepositoryProvider = Provider<SavedAddressRepository>((ref) {
  return SavedAddressRepository();
});

final savedAddressesProvider = FutureProvider.autoDispose<List<SavedAddress>>((ref) {
  return ref.watch(savedAddressRepositoryProvider).list();
});
