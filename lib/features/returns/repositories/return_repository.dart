import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:paikari_shop/features/returns/models/return_request.dart';

class ReturnRepository {
  ReturnRepository({SupabaseClient? client}) : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<ReturnRequest> create({
    required String orderGroupId,
    String? vendorOrderId,
    String? productId,
    required int quantity,
    required String reason,
    String details = '',
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('লগইন করা প্রয়োজন');
    final result = await _supabase.rpc('create_return_request', params: {
      'p_order_group_id': orderGroupId,
      'p_vendor_order_id': vendorOrderId,
      'p_product_id': productId,
      'p_quantity': quantity,
      'p_reason': reason,
      'p_details': details,
    });
    return ReturnRequest.fromJson(Map<String, dynamic>.from(result as Map));
  }

  Future<void> cancel(String returnRequestId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('লগইন করা প্রয়োজন');
    await _supabase.rpc('cancel_return_request', params: {'p_return_request_id': returnRequestId});
  }

  Future<List<ReturnRequest>> vendorList() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('লগইন করা প্রয়োজন');
    final result = await _supabase.rpc('vendor_list_return_requests');
    return (result as List<dynamic>).map((row) => ReturnRequest.fromJson(Map<String, dynamic>.from(row as Map))).toList();
  }

  Future<List<ReturnRequest>> adminList() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('লগইন করা প্রয়োজন');
    final result = await _supabase.rpc('admin_list_return_requests');
    return (result as List<dynamic>).map((row) => ReturnRequest.fromJson(Map<String, dynamic>.from(row as Map))).toList();
  }

  Future<void> respond({required String returnRequestId, required String status, String? resolutionNote}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('লগইন করা প্রয়োজন');
    await _supabase.rpc('respond_to_return_request', params: {
      'p_return_request_id': returnRequestId,
      'p_status': status,
      'p_resolution_note': resolutionNote,
    });
  }
}

final returnRepositoryProvider = Provider<ReturnRepository>((ref) {
  return ReturnRepository();
});

final vendorReturnRequestsProvider = FutureProvider<List<ReturnRequest>>((ref) {
  return ref.watch(returnRepositoryProvider).vendorList();
});

final adminReturnRequestsProvider = FutureProvider<List<ReturnRequest>>((ref) {
  return ref.watch(returnRepositoryProvider).adminList();
});
