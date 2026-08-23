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
    // Determine price based on wholesale tiers (assuming tiers are sorted by minQuantity)
    double selectedPrice = product.retailPrice;
    if (!businessMode) return selectedPrice;
    for (var tier in product.wholesaleTiers) {
      if (quantity >= tier.minQuantity) {
        // Since we want the best price for the user, we take the minimum price met
        if (tier.price < selectedPrice) {
          selectedPrice = tier.price;
        }
      }
    }
    return selectedPrice;
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
