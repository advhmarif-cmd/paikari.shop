import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paikari_shop/features/quotations/models/quotation_request.dart';
import 'package:paikari_shop/features/quotations/repositories/quotation_repository.dart';

final buyerQuotationsProvider = StreamProvider<List<QuotationRequest>>((ref) {
  return ref.watch(quotationRepositoryProvider).watchBuyerQuotes();
});

final vendorQuotationsProvider = StreamProvider<List<QuotationRequest>>((ref) {
  return ref.watch(quotationRepositoryProvider).watchVendorQuotes();
});
