import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paikari_shop/features/inquiries/repositories/inquiry_repository.dart';
import 'package:paikari_shop/features/products/models/product.dart';

Future<void> showInquirySheet(
    BuildContext context, WidgetRef ref, Product product) async {
  if (product.vendorId == null) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _InquirySheet(product: product),
  );
}

class _InquirySheet extends ConsumerStatefulWidget {
  final Product product;

  const _InquirySheet({required this.product});

  @override
  ConsumerState<_InquirySheet> createState() => _InquirySheetState();
}

class _InquirySheetState extends ConsumerState<_InquirySheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, bottomInset + 20),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            const Text('Supplier inquiry',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text(widget.product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 18),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: 'প্রয়োজনীয় quantity',
                  suffixText: widget.product.unitLabel,
                  prefixIcon: const Icon(Icons.inventory_2_outlined)),
              validator: (value) {
                final quantity = int.tryParse(value ?? '');
                if (quantity == null || quantity < widget.product.moq) {
                  return 'কমপক্ষে ${widget.product.moq} ${widget.product.unitLabel} দিন';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Target unit price (optional)',
                  prefixText: '৳ ',
                  prefixIcon: Icon(Icons.sell_outlined)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'আপনার requirement',
                  hintText: 'Delivery, packaging বা custom requirement লিখুন',
                  prefixIcon: Icon(Icons.message_outlined)),
              validator: (value) => value == null || value.trim().length < 8
                  ? 'কমপক্ষে ৮ character লিখুন'
                  : null,
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _submit,
                icon: _isSending
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_outlined),
                label: Text(_isSending ? 'পাঠানো হচ্ছে...' : 'Inquiry পাঠান',
                    style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);
    try {
      final targetPrice = double.tryParse(_priceController.text.trim());
      await ref.read(inquiryRepositoryProvider).createInquiry(
            productId: widget.product.id,
            vendorId: widget.product.vendorId!,
            requestedQuantity: int.parse(_quantityController.text.trim()),
            targetPrice: targetPrice,
            message: _messageController.text,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Supplier inquiry পাঠানো হয়েছে'),
          behavior: SnackBarBehavior.floating));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Inquiry পাঠানো যায়নি: $error'),
          behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
}
