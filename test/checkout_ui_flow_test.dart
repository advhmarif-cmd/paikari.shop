import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:paikari_shop/core/theme/paikari_theme.dart';
import 'package:paikari_shop/features/cart/providers/cart_provider.dart';
import 'package:paikari_shop/features/checkout/repositories/saved_address_repository.dart';
import 'package:paikari_shop/features/checkout/repositories/supabase_order_repository.dart';
import 'package:paikari_shop/features/checkout/providers/order_provider.dart';
import 'package:paikari_shop/features/checkout/screens/checkout_screen.dart';
import 'package:paikari_shop/features/products/models/product.dart';
import 'package:paikari_shop/l10n/generated/app_localizations.dart';

Product _fixtureProduct() {
  return const Product(
    id: '00000000-0000-0000-0000-000000000002',
    name: 'Android checkout fixture',
    description: 'UI flow fixture',
    retailPrice: 100,
    wholesaleTiers: [
      WholesaleTier(minQuantity: 10, price: 80),
      WholesaleTier(minQuantity: 50, price: 60),
    ],
    imageUrl: '',
    category: 'Test',
    isAvailable: true,
    moq: 10,
    stockQuantity: 500,
  );
}

Future<void> _pumpCheckout(
  WidgetTester tester, {
  required bool businessMode,
  Size viewport = const Size(360, 800),
}) async {
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final cart = CartNotifier();
  cart.addItem(
    _fixtureProduct(),
    businessMode: businessMode,
    quantity: businessMode ? 10 : 1,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        cartProvider.overrideWith((ref) => cart),
        savedAddressesProvider.overrideWith((ref) async => const []),
        orderProvider.overrideWith(
          (ref) => OrderNotifier(
            SupabaseOrderRepository(
              client: SupabaseClient(
                'https://example.supabase.co',
                'test-public-key',
                authOptions: const AuthClientOptions(autoRefreshToken: false),
              ),
            ),
          ),
        ),
      ],
      child: MaterialApp(
        theme: PaikariTheme.lightTheme,
        locale: const Locale('bn'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('bn')],
        home: const CheckoutScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('B2C checkout renders correctly on a narrow Android viewport', (
    tester,
  ) async {
    await _pumpCheckout(tester, businessMode: false);

    expect(find.text('B2C subtotal'), findsOneWidget);
    expect(find.text('ক্যাশ অন ডেলিভারি'), findsOneWidget);
    await tester.ensureVisible(find.text('Bkash (বিকাশ)'));
    await tester.tap(find.text('Bkash (বিকাশ)'));
    await tester.pump();
    expect(find.textContaining('Bkash payment confirmation'), findsOneWidget);
    await tester.ensureVisible(find.text('অর্ডার সম্পন্ন করুন'));
    await tester.tap(find.text('অর্ডার সম্পন্ন করুন'));
    await tester.pump();
    expect(find.text('অর্ডার সম্পন্ন করুন'), findsOneWidget);
    expect(find.text('প্রয়োজনীয়'), findsNWidgets(2));
  });

  testWidgets('B2B checkout renders MOQ and wholesale context on Android', (
    tester,
  ) async {
    await _pumpCheckout(tester, businessMode: true);

    expect(find.text('B2B wholesale subtotal'), findsOneWidget);
    expect(
      find.text('MOQ ও wholesale tier server-এ যাচাই হবে'),
      findsOneWidget,
    );
    expect(find.text('ক্যাশ অন ডেলিভারি'), findsOneWidget);
    await tester.ensureVisible(find.text('Bangla QR'));
    await tester.tap(find.text('Bangla QR'));
    await tester.pump();
    expect(find.textContaining('Bangla QR acquiring partner'), findsOneWidget);
    await tester.ensureVisible(find.text('অর্ডার সম্পন্ন করুন'));
    await tester.tap(find.text('অর্ডার সম্পন্ন করুন'));
    await tester.pump();
    expect(find.text('অর্ডার সম্পন্ন করুন'), findsOneWidget);
    expect(find.text('প্রয়োজনীয়'), findsNWidgets(2));
  });

  testWidgets('B2C checkout fits an iPhone portrait viewport', (tester) async {
    await _pumpCheckout(
      tester,
      businessMode: false,
      viewport: const Size(375, 812),
    );

    expect(find.text('B2C subtotal'), findsOneWidget);
    expect(find.text('অর্ডার সম্পন্ন করুন'), findsOneWidget);
  });

  testWidgets('B2B checkout fits an iPhone portrait viewport', (tester) async {
    await _pumpCheckout(
      tester,
      businessMode: true,
      viewport: const Size(375, 812),
    );

    expect(find.text('B2B wholesale subtotal'), findsOneWidget);
    expect(
      find.text('MOQ ও wholesale tier server-এ যাচাই হবে'),
      findsOneWidget,
    );
    expect(find.text('অর্ডার সম্পন্ন করুন'), findsOneWidget);
  });
}
