import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paikari_shop/core/theme/paikari_theme.dart';
import 'package:paikari_shop/core/widgets/product_image.dart';
import 'package:paikari_shop/features/cart/models/cart_item.dart';
import 'package:paikari_shop/features/cart/providers/cart_provider.dart';
import 'package:paikari_shop/l10n/generated/app_localizations.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final l10n = AppLocalizations.of(context)!;
    final items = cartState.items.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cart),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              tooltip: 'কার্ট খালি করুন',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClear(context, ref),
            ),
        ],
      ),
      body: items.isEmpty
          ? _EmptyCart(l10n: l10n, onBrowse: () => Navigator.pop(context))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Row(
                    children: [
                      Text(
                        '${items.length} টি পণ্য',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      Text(
                        'Checkout-এ delivery charge যোগ হবে',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _CartItemTile(
                        item: item,
                        onDecrease: () => ref.read(cartProvider.notifier).removeOneItem(item.product.id),
                        onIncrease: () => ref.read(cartProvider.notifier).addItem(item.product, businessMode: item.businessMode),
                        onRemove: () => ref.read(cartProvider.notifier).removeItem(item.product.id),
                      );
                    },
                  ),
                ),
                _CartSummary(
                  totalAmount: cartState.totalAmount,
                  checkoutLabel: l10n.checkout,
                  onCheckout: () => Navigator.pushNamed(context, '/checkout'),
                ),
              ],
            ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('কার্ট খালি করবেন?'),
        content: const Text('কার্টের সব পণ্য সরিয়ে দেওয়া হবে।'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('না')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('হ্যাঁ, খালি করুন')),
        ],
      ),
    );
    if (shouldClear == true) ref.read(cartProvider.notifier).clear();
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;

  const _CartItemTile({
    required this.item,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ProductImage(
              url: item.product.imageUrl,
              width: 76,
              height: 76,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, height: 1.25),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        '৳${item.price.toStringAsFixed(0)} / ${item.product.unitLabel}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      if (item.businessMode)
                        _CartBadge(label: 'B2B · MOQ ${item.product.moq}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _QuantityButton(icon: Icons.remove, onPressed: onDecrease),
                      SizedBox(
                        width: 34,
                        child: Text('${item.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900)),
                      ),
                      _QuantityButton(icon: Icons.add, onPressed: onIncrease),
                      const Spacer(),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'পণ্য সরান',
                        icon: Icon(Icons.delete_outline, color: Colors.grey.shade600),
                        onPressed: onRemove,
                      ),
                    ],
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

class _CartBadge extends StatelessWidget {
  final String label;

  const _CartBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: PaikariTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: PaikariTheme.primaryColor)),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _QuantityButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton.filledTonal(
        padding: EdgeInsets.zero,
        iconSize: 18,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final double totalAmount;
  final String checkoutLabel;
  final VoidCallback onCheckout;

  const _CartSummary({required this.totalAmount, required this.checkoutLabel, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, -6))],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                Text('৳${totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: PaikariTheme.primaryColor)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: onCheckout,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(checkoutLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onBrowse;

  const _EmptyCart({required this.l10n, required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: PaikariTheme.primaryColor.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: const Icon(Icons.shopping_cart_outlined, size: 64, color: PaikariTheme.primaryColor),
            ),
            const SizedBox(height: 20),
            Text(l10n.emptyCart, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('পছন্দের পণ্য যোগ করলে এখানে দেখা যাবে।', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            OutlinedButton.icon(onPressed: onBrowse, icon: const Icon(Icons.storefront_outlined), label: const Text('পণ্য দেখুন')),
          ],
        ),
      ),
    );
  }
}
