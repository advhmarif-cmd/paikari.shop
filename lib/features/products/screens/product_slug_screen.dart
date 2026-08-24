import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paikari_shop/features/products/models/product.dart';
import 'package:paikari_shop/features/products/repositories/product_repository.dart';
import 'package:paikari_shop/features/products/screens/product_detail_screen.dart';

class ProductSlugScreen extends ConsumerStatefulWidget {
  final String slug;

  const ProductSlugScreen({super.key, required this.slug});

  @override
  ConsumerState<ProductSlugScreen> createState() => _ProductSlugScreenState();
}

class _ProductSlugScreenState extends ConsumerState<ProductSlugScreen> {
  late Future<Product?> _productFuture;

  @override
  void initState() {
    super.initState();
    _productFuture = ref.read(productRepositoryProvider).getProductBySlug(widget.slug);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Product?>(
      future: _productFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return _ProductLinkState(
            title: 'Product load করা যায়নি',
            message: 'ইন্টারনেট সংযোগ যাচাই করে আবার চেষ্টা করুন।',
            onRetry: () => setState(() {
              _productFuture = ref.read(productRepositoryProvider).getProductBySlug(widget.slug);
            }),
          );
        }
        final product = snapshot.data;
        if (product == null) {
          return const _ProductLinkState(
            title: 'Product পাওয়া যায়নি',
            message: 'এই link-এর product আর available নেই বা linkটি সঠিক নয়।',
          );
        }
        return ProductDetailScreen(product: product);
      },
    );
  }
}

class _ProductLinkState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const _ProductLinkState({required this.title, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paikari.shop')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.link_off_outlined, size: 56, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 14),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700, height: 1.45)),
              if (onRetry != null) ...[
                const SizedBox(height: 18),
                OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('আবার চেষ্টা করুন')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
