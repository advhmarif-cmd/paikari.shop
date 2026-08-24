import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminModerationRepository {
  AdminModerationRepository({SupabaseClient? client}) : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<bool> isAdmin() async {
    final result = await _supabase.rpc('is_admin');
    return result == true;
  }

  Future<List<Map<String, dynamic>>> listVendors() async {
    final result = await _supabase.rpc('admin_list_vendor_queue');
    return (result as List<dynamic>).map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> listProducts() async {
    final result = await _supabase.rpc('admin_list_product_queue');
    return (result as List<dynamic>).map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  Future<void> updateVendorStatus({required String vendorId, required String status}) async {
    await _supabase.rpc('admin_update_vendor_status', params: {'p_vendor_id': vendorId, 'p_status': status});
  }

  Future<void> updateProductStatus({required String productId, required String status}) async {
    await _supabase.rpc('admin_update_product_status', params: {'p_product_id': productId, 'p_status': status});
  }
}

final adminModerationRepositoryProvider = Provider<AdminModerationRepository>((ref) {
  return AdminModerationRepository();
});
