import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paikari_shop/core/theme/paikari_theme.dart';
import 'package:paikari_shop/features/auth/repositories/auth_repository.dart';
import 'package:paikari_shop/features/vendors/providers/vendor_provider.dart';
import 'package:paikari_shop/features/vendors/repositories/vendor_repository.dart';

class VendorOnboardingScreen extends ConsumerStatefulWidget {
  const VendorOnboardingScreen({super.key});

  @override
  ConsumerState<VendorOnboardingScreen> createState() =>
      _VendorOnboardingScreenState();
}

class _VendorOnboardingScreenState
    extends ConsumerState<VendorOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _slugController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isSaving = false;
  bool _hasHydrated = false;

  @override
  void dispose() {
    _storeNameController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _hydrateProfile() {
    if (_hasHydrated) return;
    final profile = ref.read(myVendorProfileProvider).valueOrNull;
    if (profile == null) return;
    _storeNameController.text = profile.storeName;
    _slugController.text = profile.slug;
    _descriptionController.text = profile.description;
    _phoneController.text = profile.phone;
    _cityController.text = profile.city;
    _addressController.text = profile.address;
    _hasHydrated = true;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myVendorProfileProvider);
    profileAsync
        .whenData((_) => WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _hydrateProfile();
            }));

    return Scaffold(
      appBar: AppBar(title: const Text('Vendor store setup')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _VendorForm(
          formKey: _formKey,
          storeNameController: _storeNameController,
          slugController: _slugController,
          descriptionController: _descriptionController,
          phoneController: _phoneController,
          cityController: _cityController,
          addressController: _addressController,
          isSaving: _isSaving,
          onSave: _save,
        ),
        data: (_) => _VendorForm(
          formKey: _formKey,
          storeNameController: _storeNameController,
          slugController: _slugController,
          descriptionController: _descriptionController,
          phoneController: _phoneController,
          cityController: _cityController,
          addressController: _addressController,
          isSaving: _isSaving,
          onSave: _save,
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      await ref.read(vendorRepositoryProvider).saveMyProfile(
            storeName: _storeNameController.text,
            slug: _slugController.text,
            description: _descriptionController.text,
            phone: _phoneController.text,
            city: _cityController.text,
            address: _addressController.text,
          );
      ref.invalidate(myVendorProfileProvider);
      ref.invalidate(userProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Vendor profile জমা হয়েছে। Admin approval-এর পর store live হবে।'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Profile save করা যায়নি: $error'),
            behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _VendorForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController storeNameController;
  final TextEditingController slugController;
  final TextEditingController descriptionController;
  final TextEditingController phoneController;
  final TextEditingController cityController;
  final TextEditingController addressController;
  final bool isSaving;
  final VoidCallback onSave;

  const _VendorForm({
    required this.formKey,
    required this.storeNameController,
    required this.slugController,
    required this.descriptionController,
    required this.phoneController,
    required this.cityController,
    required this.addressController,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          16,
          18,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PaikariTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.storefront_outlined,
                    color: PaikariTheme.primaryColor),
                SizedBox(width: 10),
                Expanded(
                    child: Text(
                        'আপনার supplier store তৈরি করুন। Store live হওয়ার আগে admin approval প্রয়োজন হবে।',
                        style: TextStyle(
                            height: 1.4, fontWeight: FontWeight.w700))),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _Field(
              controller: storeNameController,
              label: 'Store name',
              icon: Icons.store_outlined,
              validator: _required),
          const SizedBox(height: 12),
          _Field(
            controller: slugController,
            label: 'Store slug',
            hint: 'যেমন: dhaka-fashion-house',
            icon: Icons.link_outlined,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Store slug প্রয়োজনীয়';
              }
              if (!RegExp(r'^[a-z0-9-]+$').hasMatch(value.trim())) {
                return 'শুধু ছোট হাতের letter, number ও hyphen ব্যবহার করুন';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _Field(
              controller: phoneController,
              label: 'Business phone',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: _required),
          const SizedBox(height: 12),
          _Field(
              controller: cityController,
              label: 'City / District',
              icon: Icons.location_city_outlined,
              validator: _required),
          const SizedBox(height: 12),
          _Field(
              controller: addressController,
              label: 'Business address',
              icon: Icons.location_on_outlined,
              maxLines: 2,
              validator: _required),
          const SizedBox(height: 12),
          _Field(
              controller: descriptionController,
              label: 'Store description',
              hint: 'আপনি কী ধরনের product supply করেন?',
              icon: Icons.description_outlined,
              maxLines: 4,
              validator: _required),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : onSave,
              icon: isSaving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_outlined),
              label: Text(
                  isSaving ? 'সেভ হচ্ছে...' : 'Vendor profile save করুন',
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
            ),
          ),
        ],
      ),
    );
  }

  static String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'প্রয়োজনীয়' : null;
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction:
          maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      decoration: InputDecoration(
          labelText: label, hintText: hint, prefixIcon: Icon(icon)),
      validator: validator,
    );
  }
}
