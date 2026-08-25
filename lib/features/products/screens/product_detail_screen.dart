import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paikari_shop/core/theme/paikari_theme.dart';
import 'package:paikari_shop/features/products/widgets/product_gallery.dart';
import 'package:paikari_shop/features/products/models/product.dart';
import 'package:paikari_shop/features/cart/providers/cart_provider.dart';
import 'package:paikari_shop/features/inquiries/widgets/inquiry_sheet.dart';
import 'package:paikari_shop/features/quotations/widgets/quotation_sheet.dart';
import 'package:paikari_shop/features/chat/screens/chat_screen.dart';
import 'package:paikari_shop/features/vendors/models/vendor_profile.dart';
import 'package:paikari_shop/features/vendors/providers/vendor_provider.dart';

void _copyProductLink(BuildContext context, Product product) {
  final slug = product.slug?.trim();
  if (slug == null || slug.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('এই product-এর share link এখনো তৈরি হয়নি.')));
    return;
  }
  final link = 'https://paikari.shop/p/${Uri.encodeComponent(slug)}';
  Clipboard.setData(ClipboardData(text: link));
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product link কপি হয়েছে.')));
}

class ProductDetailScreen extends ConsumerWidget {
  final Product product;
  final bool businessMode;

  const ProductDetailScreen({super.key, required this.product, this.businessMode = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isShared = product.source == 'origen';
    final vendorAsync = product.vendorId == null ? null : ref.watch(publicVendorProfileProvider(product.vendorId!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('পণ্যের বিবরণ'),
        actions: [
          IconButton(
            tooltip: 'Product link কপি করুন',
            icon: const Icon(Icons.link_outlined),
            onPressed: () => _copyProductLink(context, product),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'product-${product.id}',
              child: ProductGallery(
                images: product.images,
                fallbackUrl: product.imageUrl,
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
                      if (businessMode) const _InfoChip(icon: Icons.business_center_outlined, label: 'B2B mode'),
                      if (businessMode && product.moq > 1) _InfoChip(icon: Icons.inventory_2_outlined, label: 'MOQ ${product.moq} ${product.unitLabel}'),
                      if (businessMode && product.isNegotiable) const _InfoChip(icon: Icons.handshake_outlined, label: 'দরদাম করা যাবে'),
                      if (product.stockQuantity != null) _InfoChip(icon: Icons.warehouse_outlined, label: 'Available ${product.availableQuantity} ${product.unitLabel}', color: product.isAvailable ? Colors.green.shade700 : Colors.red.shade700),
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
                  if (vendorAsync != null)
                    vendorAsync.when(
                      data: (vendor) => vendor == null ? const SizedBox.shrink() : Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _VendorInfoCard(vendor: vendor),
                      ),
                      loading: () => const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator()),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (product.vendorId != null) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        productId: product.id,
                        vendorId: product.vendorId,
                        productName: product.name,
                        vendorName: product.vendorName,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Seller-এর সঙ্গে chat করুন'),
                ),
              ),
              if (businessMode) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => showInquirySheet(context, ref, product),
                        icon: const Icon(Icons.message_outlined),
                        label: const Text('Inquiry'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => showQuotationSheet(context, ref, product),
                        icon: const Icon(Icons.request_quote_outlined),
                        label: const Text('Quote'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: product.isAvailable
                    ? () {
                        ref.read(cartProvider.notifier).addItem(product, businessMode: businessMode);
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
          ],
        ),
      ),
    );
  }
}

class _VendorInfoCard extends StatelessWidget {
  final VendorProfile vendor;

  const _VendorInfoCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    final verified = vendor.verificationStatus == 'verified';
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(child: Icon(verified ? Icons.verified_outlined : Icons.storefront_outlined)),
        title: Text(vendor.storeName, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text('${vendor.city.isEmpty ? 'বাংলাদেশ' : vendor.city} · ${verified ? 'Verified supplier' : 'Supplier'}'),
        trailing: verified ? const Icon(Icons.check_circle, color: Colors.green) : null,
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
