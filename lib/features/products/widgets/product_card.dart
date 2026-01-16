import 'package:flutter/material.dart';
import 'package:paikari_shop/core/theme/paikari_theme.dart';
import 'package:paikari_shop/features/products/models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Hero(
                tag: 'product-${product.id}',
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    image: DecorationImage(
                      image: NetworkImage(product.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '৳${product.retailPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '৳${product.wholesaleTiers.first.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: PaikariTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: PaikariTheme.secondaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'পাইকারি (Wholesale)',
                      style: TextStyle(
                        fontSize: 10,
                        color: PaikariTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
