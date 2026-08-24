import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paikari_shop/core/theme/paikari_theme.dart';
import 'package:paikari_shop/features/cart/models/cart_item.dart';
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
  String _selectedDeliveryZone = 'inside';

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
    final orderState = ref.watch(orderProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.checkout)),
      body: cartState.items.isEmpty
          ? _EmptyCheckout(onBack: () => Navigator.pop(context))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeading(icon: Icons.location_on_outlined, title: l10n.shippingAddress),
                    const SizedBox(height: 12),
                    _AddressForm(
                      districtController: _districtController,
                      thanaController: _thanaController,
                      streetController: _streetController,
                      phoneController: _phoneController,
                      districtLabel: l10n.district,
                      thanaLabel: l10n.thana,
                      phoneLabel: l10n.phone,
                    ),
                    const SizedBox(height: 24),
                    _SectionHeading(icon: Icons.local_shipping_outlined, title: 'ডেলিভারি এলাকা'),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedDeliveryZone,
                      decoration: const InputDecoration(
                        labelText: 'এলাকা নির্বাচন করুন',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'inside', child: Text('ঢাকার ভিতরে')),
                        DropdownMenuItem(value: 'outside', child: Text('ঢাকার বাইরে')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedDeliveryZone = value);
                      },
                    ),
                    const SizedBox(height: 24),
                    _SectionHeading(icon: Icons.payments_outlined, title: l10n.paymentMethod),
                    const SizedBox(height: 8),
                    _PaymentOptions(
                      value: _selectedPaymentMethod,
                      onChanged: (value) => setState(() => _selectedPaymentMethod = value),
                      cashLabel: l10n.cashOnDelivery,
                    ),
                    if (_selectedPaymentMethod == 'Bkash') ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(12)),
                        child: const Text('Bkash payment confirmation এখন server-side pending থাকবে। বাস্তব payment gateway confirmation না হওয়া পর্যন্ত order paid হিসেবে ধরা হবে না।', style: TextStyle(fontSize: 12, height: 1.4)),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _OrderSummary(totalAmount: cartState.totalAmount),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: orderState.isLoading ? null : () => _submitOrder(cartState),
                        icon: orderState.isLoading
                            ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.lock_outline),
                        label: Text(orderState.isLoading ? 'অর্ডার পাঠানো হচ্ছে...' : l10n.placeOrder, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        'চূড়ান্ত মূল্য সার্ভার থেকে যাচাই হবে',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _submitOrder(CartState cartState) async {
    if (!_formKey.currentState!.validate()) return;

    final items = cartState.items.values.toList();
    CartItem? moqViolation;
    for (final item in items) {
      if (item.businessMode && item.quantity < item.product.moq) {
        moqViolation = item;
        break;
      }
    }
    if (moqViolation != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('B2B order-এর জন্য কমপক্ষে ${moqViolation.product.moq} ${moqViolation.product.unitLabel} প্রয়োজন।'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    FocusScope.of(context).unfocus();

    final address = Address(
      streetAddress: _streetController.text.trim(),
      city: _districtController.text.trim(),
      state: _thanaController.text.trim(),
      zipCode: '',
      phoneNumber: _phoneController.text.trim(),
    );

    final confirmedOrder = await ref.read(orderProvider.notifier).placeOrder(
          items: cartState.items.values.toList(),
          shippingAddress: address,
          deliveryZone: _selectedDeliveryZone,
          paymentMethod: _selectedPaymentMethod,
        );

    if (!mounted) return;

    if (confirmedOrder == null) {
      final error = ref.read(orderProvider).error;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error ?? 'অর্ডার সম্পন্ন করা যায়নি। আবার চেষ্টা করুন।'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } else {
      _showSuccessDialog(confirmedOrder);
    }
  }

  void _showSuccessDialog(Order order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        title: const Text('অর্ডার সফল হয়েছে', textAlign: TextAlign.center),
        content: Text(
          'আপনার অর্ডারটি সফলভাবে গ্রহণ করা হয়েছে।\n\nসার্ভার-নির্ধারিত মোট: ৳${order.totalAmount.toStringAsFixed(0)}\nPayment status: ${order.paymentStatus.toUpperCase()}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, height: 1.45),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                ref.read(cartProvider.notifier).clear();
                Navigator.of(context).popUntil((route) => route.isFirst);
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: const Text('ঠিক আছে'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressForm extends StatelessWidget {
  final TextEditingController districtController;
  final TextEditingController thanaController;
  final TextEditingController streetController;
  final TextEditingController phoneController;
  final String districtLabel;
  final String thanaLabel;
  final String phoneLabel;

  const _AddressForm({
    required this.districtController,
    required this.thanaController,
    required this.streetController,
    required this.phoneController,
    required this.districtLabel,
    required this.thanaLabel,
    required this.phoneLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: districtController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: districtLabel, prefixIcon: const Icon(Icons.location_city_outlined)),
          validator: _required,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: thanaController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: thanaLabel, prefixIcon: const Icon(Icons.account_balance_outlined)),
          validator: _required,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: streetController,
          maxLines: 2,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'বিস্তারিত ঠিকানা', hintText: 'গ্রাম, বাড়ি/রোড, landmark', prefixIcon: Icon(Icons.home_outlined)),
          validator: (value) => value == null || value.trim().length < 6 ? 'বিস্তারিত ঠিকানা দিন' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(labelText: phoneLabel, prefixIcon: const Icon(Icons.phone_outlined), prefixText: '+৮৮ '),
          validator: (value) => value == null || value.replaceAll(RegExp(r'\D'), '').length < 11 ? 'সঠিক মোবাইল নম্বর দিন' : null,
        ),
      ],
    );
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'প্রয়োজনীয়' : null;
}

class _PaymentOptions extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final String cashLabel;

  const _PaymentOptions({required this.value, required this.onChanged, required this.cashLabel});

  @override
  Widget build(BuildContext context) {
    return RadioGroup<String>(
      groupValue: value,
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
        child: Column(
          children: [
            RadioListTile<String>(
              value: 'Cash on Delivery',
              title: Text(cashLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('পণ্য হাতে পেয়ে টাকা দিন'),
              secondary: const Icon(Icons.local_atm_outlined),
            ),
            const Divider(height: 1),
            const RadioListTile<String>(
              value: 'Bkash',
              title: Text('Bkash (বিকাশ)', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('Payment confirmation পরে নেওয়া হবে'),
              secondary: Icon(Icons.account_balance_wallet_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final double totalAmount;

  const _OrderSummary({required this.totalAmount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PaikariTheme.primaryColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PaikariTheme.primaryColor.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('কার্ট subtotal', style: TextStyle(fontWeight: FontWeight.w800)),
              SizedBox(height: 4),
              Text('Delivery charge checkout-এ যোগ হবে', style: TextStyle(fontSize: 12)),
            ],
          ),
          Text('৳${totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: PaikariTheme.primaryColor)),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeading({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: PaikariTheme.primaryColor),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _EmptyCheckout extends StatelessWidget {
  final VoidCallback onBack;

  const _EmptyCheckout({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 68, color: PaikariTheme.primaryColor),
            const SizedBox(height: 18),
            const Text('আপনার কার্ট খালি', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('Checkout করার আগে একটি product কার্টে যোগ করুন।', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            OutlinedButton.icon(onPressed: onBack, icon: const Icon(Icons.arrow_back), label: const Text('কার্টে ফিরে যান')),
          ],
        ),
      ),
    );
  }
}
