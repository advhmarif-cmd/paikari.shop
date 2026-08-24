import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:paikari_shop/features/quotations/models/quotation_request.dart';

class QuotationRepository {
  QuotationRepository({SupabaseClient? client}) : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<QuotationRequest> createRequest({
    required String productId,
    required int requestedQuantity,
    double? targetUnitPrice,
    required String message,
  }) async {
    final response = await _supabase.rpc('create_quotation_request', params: {
      'p_product_id': productId,
      'p_requested_quantity': requestedQuantity,
      'p_target_unit_price': targetUnitPrice,
      'p_message': message.trim(),
    });
    return QuotationRequest.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<QuotationRequest> respond({
    required String quotationId,
    required int quotedQuantity,
    required double quotedUnitPrice,
    required double deliveryCharge,
    DateTime? validUntil,
    required String vendorMessage,
  }) async {
    final response = await _supabase.rpc('respond_to_quotation', params: {
      'p_quotation_id': quotationId,
      'p_quoted_quantity': quotedQuantity,
      'p_quoted_unit_price': quotedUnitPrice,
      'p_delivery_charge': deliveryCharge,
      'p_valid_until': validUntil?.toIso8601String(),
      'p_vendor_message': vendorMessage.trim(),
    });
    return QuotationRequest.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<QuotationRequest> accept(String quotationId) async {
    final response = await _supabase.rpc('accept_quotation', params: {'p_quotation_id': quotationId});
    return QuotationRequest.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Stream<List<QuotationRequest>> watchBuyerQuotes() {
    final user = _supabase.auth.currentUser;
    if (user == null) return const Stream.empty();
    return _supabase
        .from('quotation_requests')
        .stream(primaryKey: ['id'])
        .eq('buyer_id', user.id)
        .order('created_at', ascending: false)
        .map((rows) => rows.map((row) => QuotationRequest.fromJson(Map<String, dynamic>.from(row))).toList());
  }

  Stream<List<QuotationRequest>> watchVendorQuotes() {
    final user = _supabase.auth.currentUser;
    if (user == null) return const Stream.empty();
    return _supabase
        .from('quotation_requests')
        .stream(primaryKey: ['id'])
        .eq('vendor_id', user.id)
        .order('created_at', ascending: false)
        .map((rows) => rows.map((row) => QuotationRequest.fromJson(Map<String, dynamic>.from(row))).toList());
  }
}

final quotationRepositoryProvider = Provider<QuotationRepository>((ref) {
  return QuotationRepository();
});
