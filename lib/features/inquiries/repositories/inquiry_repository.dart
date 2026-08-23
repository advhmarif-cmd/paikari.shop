import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:paikari_shop/features/inquiries/models/product_inquiry.dart';

class InquiryRepository {
  InquiryRepository({SupabaseClient? client}) : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<void> createInquiry({
    required String productId,
    required String vendorId,
    required int requestedQuantity,
    required String message,
    double? targetPrice,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('লগইন করা প্রয়োজন');
    if (requestedQuantity < 1) throw Exception('Quantity সঠিক নয়');

    await _supabase.from('product_inquiries').insert({
      'buyer_id': user.id,
      'vendor_id': vendorId,
      'product_id': productId,
      'requested_quantity': requestedQuantity,
      'target_price': targetPrice,
      'message': message.trim(),
    });
  }

  Stream<List<ProductInquiry>> watchVendorInquiries() {
    final user = _supabase.auth.currentUser;
    if (user == null) return const Stream.empty();

    return _supabase
        .from('product_inquiries')
        .stream(primaryKey: ['id'])
        .eq('vendor_id', user.id)
        .order('created_at', ascending: false)
        .map((rows) => rows
            .map((row) => ProductInquiry.fromJson(Map<String, dynamic>.from(row)))
            .toList());
  }

  Future<void> respondToInquiry({required String inquiryId, required String response, required String status}) async {
    if (!['responded', 'accepted', 'closed'].contains(status)) throw Exception('Invalid inquiry status');
    await _supabase
        .from('product_inquiries')
        .update({'vendor_response': response.trim(), 'status': status})
        .eq('id', inquiryId);
  }
}

final inquiryRepositoryProvider = Provider<InquiryRepository>((ref) {
  return InquiryRepository();
});
