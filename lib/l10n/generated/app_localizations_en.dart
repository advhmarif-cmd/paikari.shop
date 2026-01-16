// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Paikari.shop';

  @override
  String get wholesalePrice => 'Wholesale Price';

  @override
  String get retailPrice => 'Retail Price';

  @override
  String get addToCart => 'Add to Cart';

  @override
  String get cart => 'Cart';

  @override
  String get emptyCart => 'Your cart is empty';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get checkout => 'Checkout';

  @override
  String get shippingAddress => 'Shipping Address';

  @override
  String get district => 'District';

  @override
  String get thana => 'Thana/Upazila';

  @override
  String get phone => 'Phone Number';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get placeOrder => 'Place Order';

  @override
  String get cashOnDelivery => 'Cash on Delivery';

  @override
  String get profile => 'Profile';

  @override
  String get myOrders => 'My Orders';

  @override
  String get orderDate => 'Order Date';

  @override
  String get status => 'Status';

  @override
  String get wholesaleTiers => 'Wholesale Tiers';

  @override
  String minQuantity(int quantity) {
    return 'Min Quantity: $quantity';
  }
}
