import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paikari_shop/core/theme/paikari_theme.dart';
import 'package:paikari_shop/core/widgets/product_image.dart';
import 'package:paikari_shop/features/products/models/product.dart';
import 'package:paikari_shop/features/products/repositories/product_repository.dart';
import 'package:paikari_shop/features/vendors/providers/vendor_products_provider.dart';
import 'package:paikari_shop/features/vendors/providers/vendor_provider.dart';
import 'package:paikari_shop/features/inquiries/models/product_inquiry.dart';
import 'package:paikari_shop/features/inquiries/providers/inquiry_provider.dart';
import 'package:paikari_shop/features/inquiries/repositories/inquiry_repository.dart';

class VendorDashboardScreen extends ConsumerWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorAsync = ref.watch(myVendorProfileProvider);
    final productsAsync = ref.watch(myLocalProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor center'),
        actions: [
          IconButton(
            tooltip: 'নতুন product',
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () async {
              await Navigator.pushNamed(context, '/vendor/products/new');
              ref.invalidate(myLocalProductsProvider);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/vendor/products/new');
          ref.invalidate(myLocalProductsProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('Product যোগ করুন'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.refresh(myLocalProductsProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            vendorAsync.when(
              data: (vendor) => _VendorSummary(
                storeName: vendor?.storeName ?? 'Vendor store',
                status: vendor?.verificationStatus ?? 'pending',
                city: vendor?.city,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const _VendorSummary(storeName: 'Vendor store', status: 'pending'),
            ),
            const SizedBox(height: 20),
            const Text('আপনার products', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            productsAsync.when(
              loading: () => const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator())),
              error: (error, stack) => Text('Product load করা যায়নি: $error'),
              data: (products) => products.isEmpty ? const _EmptyVendorProducts() : Column(children: products.map((product) => _VendorProductTile(product: product)).toList()),
            ),
            const SizedBox(height: 24),
            const Text('Buyer inquiries', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            ref.watch(vendorInquiriesProvider).when(
              loading: () => const LinearProgressIndicator(),
              error: (error, stack) => Text('Inquiry load করা যায়নি: $error'),
              data: (inquiries) => inquiries.isEmpty
                  ? const Text('এখনও কোনো bulk inquiry নেই', style: TextStyle(color: Colors.grey))
                  : Column(children: inquiries.map((inquiry) => _InquiryTile(inquiry: inquiry, onRespond: () => _respondToInquiry(context, ref, inquiry))).toList()),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _respondToInquiry(BuildContext context, WidgetRef ref, ProductInquiry inquiry) async {
  final responseController = TextEditingController(text: inquiry.vendorResponse ?? '');
  String selectedStatus = inquiry.status == 'open' ? 'responded' : inquiry.status;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Inquiry-এর উত্তর দিন'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Quantity: ${inquiry.requestedQuantity}', style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TextField(controller: responseController, maxLines: 4, decoration: const InputDecoration(labelText: 'আপনার উত্তর')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'responded', child: Text('Responded')),
                DropdownMenuItem(value: 'accepted', child: Text('Accepted')),
                DropdownMenuItem(value: 'closed', child: Text('Closed')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => selectedStatus = value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('বাতিল')),
          FilledButton(
            onPressed: () async {
              if (responseController.text.trim().length < 3) return;
              await ref.read(inquiryRepositoryProvider).respondToInquiry(inquiryId: inquiry.id, response: responseController.text, status: selectedStatus);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  responseController.dispose();
}

class _InquiryTile extends StatelessWidget {
  final ProductInquiry inquiry;
  final VoidCallback onRespond;

  const _InquiryTile({required this.inquiry, required this.onRespond});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: const CircleAvatar(child: Icon(Icons.request_quote_outlined)),
        title: Text('${inquiry.requestedQuantity} units · ${inquiry.status}', style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(inquiry.message, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: IconButton(tooltip: 'উত্তর দিন', onPressed: onRespond, icon: const Icon(Icons.reply_outlined)),
      ),
    );
  }
}

class _VendorSummary extends StatelessWidget {
  final String storeName;
  final String status;
  final String? city;

  const _VendorSummary({required this.storeName, required this.status, this.city});

  @override
  Widget build(BuildContext context) {
    final isVerified = status == 'verified';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: PaikariTheme.primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          const CircleAvatar(radius: 26, child: Icon(Icons.storefront_outlined)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(storeName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('${city ?? 'বাংলাদেশ'} · ${isVerified ? 'Verified supplier' : 'Approval pending'}', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
              ],
            ),
          ),
          Icon(isVerified ? Icons.verified : Icons.hourglass_top, color: isVerified ? Colors.green : Colors.orange),
        ],
      ),
    );
  }
}

class _VendorProductTile extends StatelessWidget {
  final Product product;

  const _VendorProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final approvalLabel = product.approvalStatus == 'approved' ? 'Approved' : 'Pending review';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: ProductImage(url: product.imageUrl, width: 58, height: 58, borderRadius: BorderRadius.circular(10)),
        title: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('৳${product.retailPrice.toStringAsFixed(0)} · MOQ ${product.moq} · $approvalLabel'),
        ),
        trailing: Icon(product.isAvailable ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: product.isAvailable ? Colors.green : Colors.grey),
      ),
    );
  }
}

class _EmptyVendorProducts extends StatelessWidget {
  const _EmptyVendorProducts();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 46, color: Colors.grey),
          SizedBox(height: 8),
          Text('এখনও কোনো local product নেই', style: TextStyle(fontWeight: FontWeight.w800)),
          SizedBox(height: 4),
          Text('আপনার প্রথম product যোগ করুন।', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class VendorProductFormScreen extends ConsumerStatefulWidget {
  const VendorProductFormScreen({super.key});

  @override
  ConsumerState<VendorProductFormScreen> createState() => _VendorProductFormScreenState();
}

class _VendorProductFormScreenState extends ConsumerState<VendorProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _retailPrice = TextEditingController();
  final _wholesalePrice = TextEditingController();
  final _wholesaleMin = TextEditingController();
  final _imageUrl = TextEditingController();
  final _category = TextEditingController();
  final _sku = TextEditingController();
  final _unit = TextEditingController(text: 'unit');
  final _moq = TextEditingController(text: '1');
  final _stock = TextEditingController();
  bool _negotiable = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in [_name, _description, _retailPrice, _wholesalePrice, _wholesaleMin, _imageUrl, _category, _sku, _unit, _moq, _stock]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('নতুন local product')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            const Text('Product information', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            _Field(controller: _name, label: 'Product name', icon: Icons.title, validator: _required),
            const SizedBox(height: 12),
            _Field(controller: _description, label: 'Description', icon: Icons.description_outlined, maxLines: 3, validator: _required),
            const SizedBox(height: 12),
            _Field(controller: _category, label: 'Category', icon: Icons.category_outlined, validator: _required),
            const SizedBox(height: 12),
            _Field(controller: _imageUrl, label: 'Image URL', icon: Icons.image_outlined, keyboardType: TextInputType.url),
            const SizedBox(height: 12),
            _Field(controller: _sku, label: 'SKU (optional)', icon: Icons.qr_code_2_outlined),
            const SizedBox(height: 20),
            const Text('Pricing & stock', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            _Field(controller: _retailPrice, label: 'Retail price', icon: Icons.sell_outlined, keyboardType: TextInputType.number, validator: _positiveNumber),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _Field(controller: _wholesaleMin, label: 'Wholesale min qty', icon: Icons.format_list_numbered, keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: _Field(controller: _wholesalePrice, label: 'Wholesale price', icon: Icons.price_change_outlined, keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _Field(controller: _moq, label: 'MOQ', icon: Icons.inventory_2_outlined, keyboardType: TextInputType.number, validator: _positiveNumber)),
                const SizedBox(width: 10),
                Expanded(child: _Field(controller: _unit, label: 'Unit label', icon: Icons.straighten_outlined, validator: _required)),
              ],
            ),
            const SizedBox(height: 12),
            _Field(controller: _stock, label: 'Stock quantity (optional)', icon: Icons.warehouse_outlined, keyboardType: TextInputType.number),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('দরদাম করা যাবে', style: TextStyle(fontWeight: FontWeight.w800)),
              value: _negotiable,
              onChanged: (value) => setState(() => _negotiable = value),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(12)),
              child: const Text('নতুন product approval-এর জন্য pending থাকবে এবং admin approval ছাড়া public catalog-এ দেখা যাবে না।', style: TextStyle(fontSize: 12, height: 1.4)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_outlined),
                label: Text(_saving ? 'জমা হচ্ছে...' : 'Approval-এর জন্য জমা দিন', style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final retailPrice = double.tryParse(_retailPrice.text.trim());
    final moq = int.tryParse(_moq.text.trim());
    if (retailPrice == null || moq == null) return;
    setState(() => _saving = true);
    try {
      final wholesaleMin = int.tryParse(_wholesaleMin.text.trim());
      final wholesalePrice = double.tryParse(_wholesalePrice.text.trim());
      final tiers = wholesaleMin != null && wholesalePrice != null && wholesaleMin >= moq
          ? [WholesaleTier(minQuantity: wholesaleMin, price: wholesalePrice)]
          : <WholesaleTier>[];
      await ref.read(productRepositoryProvider).createLocalProduct(
            name: _name.text,
            description: _description.text,
            retailPrice: retailPrice,
            wholesaleTiers: tiers,
            imageUrl: _imageUrl.text,
            category: _category.text,
            sku: _sku.text,
            unitLabel: _unit.text,
            moq: moq,
            stockQuantity: int.tryParse(_stock.text.trim()),
            isNegotiable: _negotiable,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product approval-এর জন্য জমা হয়েছে'), behavior: SnackBarBehavior.floating));
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product save করা যায়নি: $error'), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static String? _required(String? value) => value == null || value.trim().isEmpty ? 'প্রয়োজনীয়' : null;

  static String? _positiveNumber(String? value) {
    final number = double.tryParse(value ?? '');
    return number == null || number <= 0 ? 'সঠিক সংখ্যা দিন' : null;
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({required this.controller, required this.label, required this.icon, this.maxLines = 1, this.keyboardType, this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: validator,
    );
  }
}
