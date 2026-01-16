import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paikari_shop/features/products/models/product.dart';

final productListProvider = FutureProvider<List<Product>>((ref) async {
  // Sample data for demonstration
  return [
    const Product(
      id: '1',
      name: 'সয়াবিন তেল (Soybean Oil) - 5L',
      description: 'Premium quality soybean oil',
      retailPrice: 850,
      wholesaleTiers: [
        WholesaleTier(minQuantity: 10, price: 780),
        WholesaleTier(minQuantity: 50, price: 750),
      ],
      imageUrl: 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5',
      category: 'Groceries',
      isAvailable: true,
    ),
    const Product(
      id: '2',
      name: 'বাসমতি চাল (Basmati Rice) - 25kg',
      description: 'Long grain aromatic rice',
      retailPrice: 3200,
      wholesaleTiers: [
        WholesaleTier(minQuantity: 5, price: 2900),
        WholesaleTier(minQuantity: 20, price: 2750),
      ],
      imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c',
      category: 'Groceries',
      isAvailable: true,
    ),
  ];
});
