import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paikari_shop/features/quotations/models/quote_checkout_session.dart';
import 'package:paikari_shop/features/quotations/providers/quotation_provider.dart';
import 'package:paikari_shop/features/checkout/providers/order_provider.dart';
import 'package:intl/intl.dart';

class _QuoteCheckoutSheet extends ConsumerStatefulWidget {
  final String sessionId;

  const _QuoteCheckoutSheet({required this.sessionId});

  @override
  ConsumerState<_QuoteCheckoutSheet> createState() =>
      _QuoteCheckoutSheetState();
}

class _QuoteCheckoutSheetState extends ConsumerState<_QuoteCheckoutSheet> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _street = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _zip = TextEditingController();
  String _paymentMethod = 'Cash on Delivery';
  bool _saving = false;

  @override
  void dispose() {
    _phone.dispose();
    _street.dispose();
    _city.dispose();
    _state.dispose();
    _zip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState =
        ref.watch(quoteCheckoutSessionProvider(widget.sessionId));
    return sessionState.when(
      loading: () => const SafeArea(
          child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()))),
      error: (error, _) => SafeArea(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Quote details load করা যায়নি: $error'))),
      data: (session) => session == null
          ? const SafeArea(
              child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Quote checkout পাওয়া যায়নি।')))
          : _buildContent(context, session),
    );
  }

  Widget _buildContent(BuildContext context, QuoteCheckoutSession session) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final canCheckout = session.isOpen;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, inset + 20),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            const Text('Quote checkout',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text(
                '${session.quantity} units · ৳${session.unitPrice.toStringAsFixed(0)} / unit',
                style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 4),
            Text(
                'Agreed delivery: ৳${session.deliveryCharge.toStringAsFixed(0)} · Total: ৳${session.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
                canCheckout
                    ? 'Valid until ${DateFormat('dd MMM yyyy, hh:mm a').format(session.expiresAt.toLocal())}'
                    : 'এই quote session আর ব্যবহারযোগ্য নয় (${session.status})',
                style: TextStyle(
                    color: canCheckout
                        ? Colors.green.shade700
                        : Colors.red.shade700)),
            const SizedBox(height: 16),
            if (canCheckout) ...[
              TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Phone number',
                      prefixIcon: Icon(Icons.phone_outlined)),
                  validator: _required),
              const SizedBox(height: 10),
              TextFormField(
                  controller: _street,
                  decoration: const InputDecoration(
                      labelText: 'Address',
                      prefixIcon: Icon(Icons.home_outlined)),
                  validator: _required),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final fields = [
                    TextFormField(
                      controller: _city,
                      decoration: const InputDecoration(labelText: 'District'),
                      validator: _required,
                    ),
                    TextFormField(
                      controller: _state,
                      decoration:
                          const InputDecoration(labelText: 'Thana/Upazila'),
                      validator: _required,
                    ),
                  ];
                  if (constraints.maxWidth < 520) {
                    return Column(
                      children: [
                        fields[0],
                        const SizedBox(height: 10),
                        fields[1],
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: fields[0]),
                      const SizedBox(width: 10),
                      Expanded(child: fields[1]),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                  controller: _zip,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Postal code'),
                  validator: _required),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(
                    labelText: 'Payment method',
                    prefixIcon: Icon(Icons.payments_outlined)),
                items: const [
                  DropdownMenuItem(
                      value: 'Cash on Delivery',
                      child: Text('Cash on Delivery')),
                  DropdownMenuItem(value: 'Bkash', child: Text('Bkash')),
                  DropdownMenuItem(
                      value: 'Bangla QR', child: Text('Bangla QR')),
                ],
                onChanged: (value) => setState(
                    () => _paymentMethod = value ?? 'Cash on Delivery'),
              ),
              if (_paymentMethod == 'Bkash' ||
                  _paymentMethod == 'Bangla QR') ...[
                const SizedBox(height: 8),
                Text(
                  _paymentMethod == 'Bangla QR'
                      ? 'Bangla QR acquiring partner এখনো সংযুক্ত হয়নি; verified callback ছাড়া এই order paid হবে না।'
                      : 'Bkash gateway confirmation এখনো চালু হয়নি; এই order paid হিসেবে ধরা হবে না।',
                  style: const TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.lock_outline),
                  label: Text(
                      _saving ? 'Order হচ্ছে...' : 'Quote দিয়ে order করুন',
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'এই ঘরটি পূরণ করুন' : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final order =
          await ref.read(orderRepositoryProvider).checkoutAcceptedQuote(
                checkoutSessionId: widget.sessionId,
                shippingAddress: {
                  'phoneNumber': _phone.text.trim(),
                  'streetAddress': _street.text.trim(),
                  'city': _city.text.trim(),
                  'state': _state.text.trim(),
                  'zipCode': _zip.text.trim(),
                },
                paymentMethod: _paymentMethod,
              );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(
          content: Text('Order #${order.id.substring(0, 8)} তৈরি হয়েছে'),
          behavior: SnackBarBehavior.floating));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Quote order করা যায়নি: $error'),
          behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class QuoteCheckoutScreen extends StatelessWidget {
  final String sessionId;

  const QuoteCheckoutScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quote checkout')),
      body: _QuoteCheckoutSheet(sessionId: sessionId),
    );
  }
}
