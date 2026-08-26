import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:paikari_shop/core/theme/paikari_theme.dart';
import 'package:paikari_shop/features/auth/repositories/auth_repository.dart';
import 'package:paikari_shop/features/chat/repositories/chat_repository.dart';
import 'package:paikari_shop/features/notifications/repositories/notification_repository.dart';
import 'package:paikari_shop/features/products/models/product.dart';
import 'package:paikari_shop/features/products/providers/product_provider.dart';
import 'package:paikari_shop/l10n/generated/app_localizations.dart';
import 'package:paikari_shop/main.dart';

void main() {
  test('catalog columns scale across mobile and tablet widths', () {
    expect(catalogColumnsForWidth(320), 2);
    expect(catalogColumnsForWidth(375), 2);
    expect(catalogColumnsForWidth(519), 2);
    expect(catalogColumnsForWidth(520), 3);
    expect(catalogColumnsForWidth(600), 3);
    expect(catalogColumnsForWidth(679), 3);
    expect(catalogColumnsForWidth(680), 4);
    expect(catalogColumnsForWidth(800), 4);
    expect(catalogColumnsForWidth(1024), 4);
  });

  test('catalog tile extent stays positive for supported breakpoints', () {
    for (final width in [320.0, 375.0, 520.0, 600.0, 680.0, 1024.0]) {
      final columns = catalogColumnsForWidth(width);
      final extent = catalogTileExtentForWidth(width, columns);
      expect(extent, greaterThan(0));
      expect(extent.isFinite, isTrue);
    }
  });

  testWidgets(
    'HomeScreen has no layout exception across phone and tablet sizes',
    (tester) async {
      const product = Product(
        id: 'responsive-product',
        name: 'বাংলা বাজারের দীর্ঘ নামের পরীক্ষামূলক পণ্য',
        description: 'Responsive layout fixture',
        retailPrice: 1250,
        wholesaleTiers: [WholesaleTier(minQuantity: 10, price: 1100)],
        imageUrl: '',
        category: 'খাদ্যপণ্য',
        isAvailable: true,
        vendorName: 'পরীক্ষামূলক সরবরাহকারী',
        stockQuantity: 42,
        moq: 10,
        unitLabel: 'কার্টন',
      );
      final testClient = SupabaseClient(
        'https://example.com',
        'test-anon-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        testClient.dispose();
      });

      for (final size in [
        const Size(320, 568),
        const Size(360, 800),
        const Size(375, 812),
        const Size(600, 960),
        const Size(768, 1024),
        const Size(1024, 768),
      ]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(
                AuthRepository(client: testClient),
              ),
              productListProvider(false).overrideWith((ref) async => [product]),
              myNotificationsProvider.overrideWith(
                (ref) => Stream.value(const []),
              ),
              buyerChatConversationsProvider.overrideWith(
                (ref) => Stream.value(const []),
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
              home: const HomeScreen(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull, reason: 'viewport $size');
      }
    },
  );
}
