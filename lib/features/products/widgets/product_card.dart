import 'package:flutter/material.dart';
import 'package:paikari_shop/core/theme/paikari_theme.dart';
import 'package:paikari_shop/core/widgets/product_image.dart';
import 'package:paikari_shop/features/products/models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final bool businessMode;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.businessMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wholesalePrice = businessMode && product.wholesaleTiers.isNotEmpty
        ? product.wholesaleTiers.first.price
        : null;
    final displayPrice = wholesalePrice ?? product.retailPrice;
    final isShared = product.source == 'origen';

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: product.isAvailable ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.08,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'product-${product.id}',
                    child: ProductImage(
                      url: product.imageUrl,
                      fit: BoxFit.cover,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _SourceBadge(isShared: isShared),
                  ),
                  if (!product.isAvailable)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.5),
                        alignment: Alignment.center,
                        child: const Text(
                          'স্টক শেষ',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.category.trim().isNotEmpty)
                    Text(
                      product.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (wholesalePrice != null) ...[
                        Text(
                          '৳${product.retailPrice.toStringAsFixed(0)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        '৳${displayPrice.toStringAsFixed(0)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: PaikariTheme.primaryColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    wholesalePrice == null
                        ? (businessMode && product.moq > 1
                            ? 'MOQ: ${product.moq} ${product.unitLabel}'
                            : (isShared ? 'Origen shared product' : 'খুচরা মূল্য'))
                        : 'MOQ: ${product.moq} ${product.unitLabel} · পাইকারি',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontWeight: FontWeight.w700,
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

class _SourceBadge extends StatelessWidget {
  final bool isShared;

  const _SourceBadge({required this.isShared});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          isShared ? 'ORIGEN' : 'PAIKARI',
          style: TextStyle(
            color: isShared ? PaikariTheme.primaryColor : Colors.black87,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
