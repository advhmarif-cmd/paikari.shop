import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paikari_shop/core/theme/paikari_theme.dart';
import 'package:paikari_shop/core/widgets/product_image.dart';
import 'package:paikari_shop/features/products/models/product.dart';
import 'package:paikari_shop/features/cart/providers/cart_provider.dart';

class ProductDetailScreen extends ConsumerWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isShared = product.source == 'origen';

    return Scaffold(
      appBar: AppBar(title: const Text('পণ্যের বিবরণ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'product-${product.id}',
              child: ProductImage(
                url: product.imageUrl,
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: isShared ? Icons.verified_outlined : Icons.storefront_outlined,
                        label: isShared ? 'Origen shared product' : 'Paikari marketplace',
                      ),
                      _InfoChip(
                        icon: product.isAvailable ? Icons.check_circle_outline : Icons.remove_circle_outline,
                        label: product.isAvailable ? 'স্টকে আছে' : 'স্টক শেষ',
                        color: product.isAvailable ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    product.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  if (product.category.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      product.category,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'মূল্য তালিকা',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  _PricingTile(
                    label: 'খুচরা মূল্য',
                    price: product.retailPrice,
                    quantity: '১ ইউনিট',
                    isRetail: true,
                  ),
                  if (product.wholesaleTiers.isNotEmpty) ...[
                    const Divider(height: 20),
                    ...product.wholesaleTiers.map(
                      (tier) => _PricingTile(
                        label: 'পাইকারি মূল্য',
                        price: tier.price,
                        quantity: '${tier.minQuantity}+ ইউনিট',
                        isRetail: false,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Text(
                    'বিবরণ',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description.trim().isEmpty ? 'এই পণ্যের বিস্তারিত বিবরণ শীঘ্রই যোগ করা হবে।' : product.description,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: ElevatedButton.icon(
          onPressed: product.isAvailable
              ? () {
                  ref.read(cartProvider.notifier).addItem(product);
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('কার্টে যোগ করা হয়েছে'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                }
              : null,
          icon: const Icon(Icons.add_shopping_cart_outlined),
          label: Text(product.isAvailable ? 'কার্টে যোগ করুন' : 'স্টক শেষ'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? PaikariTheme.primaryColor;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: chipColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(color: chipColor, fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ],
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isRetail ? theme.colorScheme.surfaceContainerHighest : PaikariTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRetail ? theme.colorScheme.outlineVariant : PaikariTheme.primaryColor.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: isRetail ? theme.colorScheme.onSurface : PaikariTheme.primaryColor, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(quantity, style: TextStyle(color: theme.colorScheme.outline, fontSize: 12)),
            ],
          ),
          Text(
            '৳${price.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isRetail ? theme.colorScheme.onSurface : PaikariTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
