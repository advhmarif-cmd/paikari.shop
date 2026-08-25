import 'package:paikari_shop/features/products/models/product.dart';

class CartItem {
  final Product product;
  final int quantity;
  final bool businessMode;

  const CartItem({
    required this.product,
    required this.quantity,
    this.businessMode = false,
  });

  double get price {
    if (!businessMode) return product.retailPrice;

    // Match the server RPC: choose the tier with the highest qualifying MOQ,
    // not the numerically lowest price across all tiers.
    WholesaleTier? selectedTier;
    for (final tier in product.wholesaleTiers) {
      if (quantity >= tier.minQuantity &&
          (selectedTier == null ||
              tier.minQuantity > selectedTier.minQuantity)) {
        selectedTier = tier;
      }
    }
    return selectedTier?.price ?? product.retailPrice;
  }

  double get total => price * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
    bool? businessMode,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      businessMode: businessMode ?? this.businessMode,
    );
  }
}
