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

  void addItem(Product product, {bool businessMode = false}) {
    if (state.items.containsKey(product.id)) {
      state = state.copyWith(
        items: {
          ...state.items,
          product.id: state.items[product.id]!.copyWith(
            quantity: state.items[product.id]!.quantity + 1,
            businessMode: state.items[product.id]!.businessMode || businessMode,
          ),
        },
      );
    } else {
      state = state.copyWith(
        items: {
          ...state.items,
          product.id: CartItem(product: product, quantity: 1, businessMode: businessMode),
        },
      );
    }
  }

  void removeOneItem(String productId) {
    if (!state.items.containsKey(productId)) return;

    if (state.items[productId]!.quantity > 1) {
      state = state.copyWith(
        items: {
          ...state.items,
          productId: state.items[productId]!.copyWith(
            quantity: state.items[productId]!.quantity - 1,
          ),
        },
      );
    } else {
      removeItem(productId);
    }
  }

  void removeItem(String productId) {
    final updatedItems = Map<String, CartItem>.from(state.items);
    updatedItems.remove(productId);
    state = state.copyWith(items: updatedItems);
  }

  void clear() {
    state = CartState();
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, CartState>((ref) => CartNotifier());
