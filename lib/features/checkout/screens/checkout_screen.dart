import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paikari_shop/core/theme/paikari_theme.dart';
import 'package:paikari_shop/features/cart/providers/cart_provider.dart';
import 'package:paikari_shop/features/checkout/models/address.dart';
import 'package:paikari_shop/features/checkout/models/order.dart';
import 'package:paikari_shop/features/checkout/providers/order_provider.dart';
import 'package:paikari_shop/l10n/generated/app_localizations.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _districtController = TextEditingController();
  final _thanaController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedPaymentMethod = 'Cash on Delivery';

  @override
  void dispose() {
    _streetController.dispose();
    _districtController.dispose();
    _thanaController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.checkout)),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.shippingAddress,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _districtController,
                decoration: InputDecoration(
                  labelText: l10n.district,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'প্রয়োজনীয়' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _thanaController,
                decoration: InputDecoration(
                  labelText: l10n.thana,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'প্রয়োজনীয়' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(
                  labelText: 'বিস্তারিত ঠিকানা (Village/House/Road)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'প্রয়োজনীয়' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: l10n.phone,
                  border: const OutlineInputBorder(),
                  prefixText: '+৮৮ ',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value == null || value.isEmpty ? 'প্রয়োজনীয়' : null,
              ),
              const SizedBox(height: 30),
              Text(l10n.paymentMethod,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              RadioGroup<String>(
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPaymentMethod = value);
                  }
                },
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: Text(l10n.cashOnDelivery),
                      value: 'Cash on Delivery',
                    ),
                    const RadioListTile<String>(
                      title: Text('Bkash (বিকাশ)'),
                      value: 'Bkash',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.subtotal),
                        Text('৳${cartState.totalAmount.toStringAsFixed(2)}'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('মোট (Total)',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('৳${cartState.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: PaikariTheme.primaryColor)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: cartState.items.isEmpty ||
                          ref.watch(orderProvider).isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            final order = Order(
                              id: DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString(),
                              items: cartState.items.values.toList(),
                              totalAmount: cartState.totalAmount,
                              shippingAddress: Address(
                                streetAddress: _streetController.text,
                                city: _districtController.text,
                                state: _thanaController.text,
                                zipCode: '',
                                phoneNumber: _phoneController.text,
                              ),
                              paymentMethod: _selectedPaymentMethod,
                              createdAt: DateTime.now(),
                            );

                            await ref
                                .read(orderProvider.notifier)
                                .placeOrder(order);

                            if (!context.mounted) return;

                            final orderResult = ref.read(orderProvider);
                            if (orderResult.hasError) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text(orderResult.error.toString())),
                              );
                            } else {
                              _showSuccessDialog();
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PaikariTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: ref.watch(orderProvider).isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(l10n.placeOrder,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text(
          'আপনার অর্ডারটি সফলভাবে গ্রহণ করা হয়েছে!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clear();
              Navigator.of(context).popUntil((route) => route.isFirst);
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: const Text('ঠিক আছে'),
          ),
        ],
      ),
    );
  }
}
