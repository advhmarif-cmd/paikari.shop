import 'package:flutter_test/flutter_test.dart';
import 'package:paikari_shop/features/cart/models/cart_item.dart';
import 'package:paikari_shop/features/cart/providers/cart_provider.dart';
import 'package:paikari_shop/features/products/models/product.dart';

Product _fixtureProduct() {
  return const Product(
    id: '00000000-0000-0000-0000-000000000001',
    name: 'Test product',
    description: 'Checkout contract fixture',
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

void main() {
  group('checkout buyer-mode contract', () {
    test('B2C uses retail price and quantity total', () {
      final item = CartItem(product: _fixtureProduct(), quantity: 3);

      expect(item.price, 100);
      expect(item.total, 300);
    });

    test('B2B chooses the highest qualifying MOQ tier', () {
      final product = _fixtureProduct();

      expect(
        CartItem(product: product, quantity: 10, businessMode: true).price,
        80,
      );
      expect(
        CartItem(product: product, quantity: 50, businessMode: true).price,
        60,
      );
      expect(
        CartItem(product: product, quantity: 100, businessMode: true).price,
        60,
      );
    });

    test('same product remains separate for B2B and B2C cart lines', () {
      final notifier = CartNotifier();
      final product = _fixtureProduct();

      notifier.addItem(product, quantity: 2);
      notifier.addItem(product, businessMode: true, quantity: 10);

      expect(notifier.state.itemCount, 2);
      expect(
        notifier.state.items.values
            .where((item) => !item.businessMode)
            .single
            .quantity,
        2,
      );
      expect(
        notifier.state.items.values
            .where((item) => item.businessMode)
            .single
            .quantity,
        10,
      );
    });
  });
}
