import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paikari_shop/core/theme/paikari_theme.dart';
import 'package:paikari_shop/features/products/models/product.dart';
import 'package:paikari_shop/features/cart/providers/cart_provider.dart';

class ProductDetailScreen extends ConsumerWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('পণ্যের বিবরণ (Details)')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'product-${product.id}',
              child: Image.network(
                product.imageUrl,
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.category,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'মূল্য তালিকা (Pricing Tiers)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _PricingTile(
                    label: 'খুচরা মূল্য (Retail)',
                    price: product.retailPrice,
                    quantity: '১ ইউনিট',
                    isRetail: true,
                  ),
                  const Divider(),
                  ...product.wholesaleTiers.map((tier) => _PricingTile(
                        label: 'পাইকারি (Wholesale)',
                        price: tier.price,
                        quantity: '${tier.minQuantity}+ ইউনিট',
                        isRetail: false,
                      )),
                  const SizedBox(height: 30),
                  const Text(
                    'বিবরণ (Description)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5))
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            ref.read(cartProvider.notifier).addItem(product);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('কার্টে যোগ করা হয়েছে'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('কার্টে যোগ করুন (Add to Cart)',
              style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}

class _PricingTile extends StatelessWidget {
  final String label;
  final double price;
  final String quantity;
  final bool isRetail;

  const _PricingTile({
    required this.label,
    required this.price,
    required this.quantity,
    required this.isRetail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: isRetail ? Colors.grey : PaikariTheme.primaryColor,
                      fontWeight:
                          isRetail ? FontWeight.normal : FontWeight.bold)),
              Text(quantity,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          Text(
            '৳${price.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isRetail ? Colors.black : PaikariTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
