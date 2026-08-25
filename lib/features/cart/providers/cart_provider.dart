import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:paikari_shop/features/cart/models/cart_item.dart';
import 'package:paikari_shop/features/products/models/product.dart';

class CartState {
  final Map<String, CartItem> items;

  CartState({this.items = const {}});

  double get totalAmount {
    var total = 0.0;
    items.forEach((key, cartItem) {
      total += cartItem.total;
    });
    return total;
  }

  int get itemCount => items.length;

  CartState copyWith({Map<String, CartItem>? items}) {
    return CartState(items: items ?? this.items);
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState());

  void addItem(Product product, {bool businessMode = false, int quantity = 1}) {
    final safeQuantity = quantity < 1 ? 1 : quantity;
    final itemKey = _cartKey(product.id, businessMode);
    final existing = state.items[itemKey];
    final updatedItems = Map<String, CartItem>.from(state.items);
    updatedItems[itemKey] = existing == null
        ? CartItem(
            product: product,
            quantity: safeQuantity,
            businessMode: businessMode)
        : existing.copyWith(quantity: existing.quantity + safeQuantity);
    state = state.copyWith(items: updatedItems);
  }

  void removeOneItem(String productId, {bool businessMode = false}) {
    final itemKey = _cartKey(productId, businessMode);
    final item = state.items[itemKey];
    if (item == null) return;

    if (item.quantity > 1) {
      final updatedItems = Map<String, CartItem>.from(state.items);
      updatedItems[itemKey] = item.copyWith(quantity: item.quantity - 1);
      state = state.copyWith(items: updatedItems);
    } else {
      removeItem(productId, businessMode: businessMode);
    }
  }

  void removeItem(String productId, {bool businessMode = false}) {
    final updatedItems = Map<String, CartItem>.from(state.items);
    updatedItems.remove(_cartKey(productId, businessMode));
    state = state.copyWith(items: updatedItems);
  }

  void clear() {
    state = CartState();
  }
}

String _cartKey(String productId, bool businessMode) =>
    '$productId:${businessMode ? 'b2b' : 'b2c'}';

final cartProvider =
    StateNotifierProvider<CartNotifier, CartState>((ref) => CartNotifier());
