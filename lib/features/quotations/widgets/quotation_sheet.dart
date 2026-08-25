import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paikari_shop/features/products/models/product.dart';
import 'package:paikari_shop/features/quotations/repositories/quotation_repository.dart';

Future<void> showQuotationSheet(
    BuildContext context, WidgetRef ref, Product product) async {
  if (product.vendorId == null) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _QuotationSheet(product: product),
  );
}

class _QuotationSheet extends ConsumerStatefulWidget {
  final Product product;

  const _QuotationSheet({required this.product});

  @override
  ConsumerState<_QuotationSheet> createState() => _QuotationSheetState();
}

class _QuotationSheetState extends ConsumerState<_QuotationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _targetPrice = TextEditingController();
  final _message = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _quantity.dispose();
    _targetPrice.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, inset + 20),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            const Text('Request for quotation',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text(widget.product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 18),
            TextFormField(
              controller: _quantity,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: 'Requested quantity',
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
              controller: _targetPrice,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Target unit price (optional)',
                  prefixText: '৳ ',
                  prefixIcon: Icon(Icons.price_change_outlined)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _message,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Requirement',
                  hintText: 'Packaging, delivery বা custom requirement লিখুন',
                  prefixIcon: Icon(Icons.message_outlined)),
              validator: (value) => value == null || value.trim().length < 8
                  ? 'কমপক্ষে ৮ character লিখুন'
                  : null,
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.request_quote_outlined),
                label: Text(_saving ? 'জমা হচ্ছে...' : 'Quote request পাঠান',
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
    setState(() => _saving = true);
    try {
      await ref.read(quotationRepositoryProvider).createRequest(
            productId: widget.product.id,
            requestedQuantity: int.parse(_quantity.text.trim()),
            targetUnitPrice: double.tryParse(_targetPrice.text.trim()),
            message: _message.text,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Quotation request পাঠানো হয়েছে'),
          behavior: SnackBarBehavior.floating));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Quote request পাঠানো যায়নি: $error'),
          behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
