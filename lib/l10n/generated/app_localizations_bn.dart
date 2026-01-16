// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'পাইকারি.শপ';

  @override
  String get wholesalePrice => 'পাইকারি মূল্য';

  @override
  String get retailPrice => 'খুচরা মূল্য';

  @override
  String get addToCart => 'কার্টে যোগ করুন';

  @override
  String get cart => 'কার্ট';

  @override
  String get emptyCart => 'আপনার কার্ট খালি আছে';

  @override
  String get subtotal => 'সাবটোটাল';

  @override
  String get checkout => 'চেকআউট';

  @override
  String get shippingAddress => 'শিপিং ঠিকানা';

  @override
  String get district => 'জেলা';

  @override
  String get thana => 'থানা/উপজেলা';

  @override
  String get phone => 'ফোন নম্বর';

  @override
  String get paymentMethod => 'পেমেন্ট পদ্ধতি';

  @override
  String get placeOrder => 'অর্ডার সম্পন্ন করুন';

  @override
  String get cashOnDelivery => 'ক্যাশ অন ডেলিভারি';

  @override
  String get profile => 'প্রোফাইল';

  @override
  String get myOrders => 'আমার অর্ডারসমূহ';

  @override
  String get orderDate => 'অর্ডারের তারিখ';

  @override
  String get status => 'অবস্থা';

  @override
  String get wholesaleTiers => 'পাইকারি ধাপসমূহ';

  @override
  String minQuantity(int quantity) {
    return 'সর্বনিম্ন পরিমাণ: $quantity';
  }
}
