import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paikari_shop/features/inquiries/models/product_inquiry.dart';
import 'package:paikari_shop/features/inquiries/repositories/inquiry_repository.dart';

final vendorInquiriesProvider = StreamProvider<List<ProductInquiry>>((ref) {
  return ref.watch(inquiryRepositoryProvider).watchVendorInquiries();
});
