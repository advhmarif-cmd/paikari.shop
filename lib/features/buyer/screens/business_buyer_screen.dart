import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paikari_shop/core/theme/paikari_theme.dart';
import 'package:paikari_shop/features/buyer/providers/business_buyer_provider.dart';
import 'package:paikari_shop/features/buyer/repositories/business_buyer_repository.dart';

class BusinessBuyerScreen extends ConsumerStatefulWidget {
  const BusinessBuyerScreen({super.key});

  @override
  ConsumerState<BusinessBuyerScreen> createState() => _BusinessBuyerScreenState();
}

class _BusinessBuyerScreenState extends ConsumerState<BusinessBuyerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _businessTypeController = TextEditingController();
  bool _isSaving = false;
  bool _hasHydrated = false;
  final _categories = const ['ফ্যাশন', 'ইলেকট্রনিক্স', 'গ্রোসারি', 'বিউটি', 'হোম & লিভিং', 'অন্যান্য'];
  final Set<String> _selectedCategories = {};

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessTypeController.dispose();
    super.dispose();
  }

  void _hydrate() {
    if (_hasHydrated) return;
    final profile = ref.read(myBusinessBuyerProfileProvider).valueOrNull;
    if (profile == null) return;
    _businessNameController.text = profile.businessName;
    _businessTypeController.text = profile.businessType;
    _selectedCategories.addAll(profile.preferredCategories);
    _hasHydrated = true;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myBusinessBuyerProfileProvider);
    profileAsync.whenData((_) => WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _hydrate();
        }));

    return Scaffold(
      appBar: AppBar(title: const Text('B2B buyer profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildForm(),
        data: (_) => _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: PaikariTheme.secondaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.business_center_outlined, color: PaikariTheme.secondaryColor),
                SizedBox(width: 10),
                Expanded(child: Text('B2B mode-এ MOQ, wholesale tiers এবং supplier inquiry আরও পরিষ্কারভাবে ব্যবহার করতে business profile সম্পূর্ণ করুন।', style: TextStyle(height: 1.4, fontWeight: FontWeight.w700))),
              ],
            ),
          ),
          const SizedBox(height: 22),
          TextFormField(
            controller: _businessNameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Business name', prefixIcon: Icon(Icons.storefront_outlined)),
            validator: (value) => value == null || value.trim().isEmpty ? 'Business name প্রয়োজনীয়' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _businessTypeController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Business type', hintText: 'যেমন: Retail shop / Reseller / Distributor', prefixIcon: Icon(Icons.category_outlined)),
            validator: (value) => value == null || value.trim().isEmpty ? 'Business type প্রয়োজনীয়' : null,
          ),
          const SizedBox(height: 22),
          const Text('আপনি কোন ধরনের product source করেন?', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((category) => FilterChip(
                  label: Text(category),
                  selected: _selectedCategories.contains(category),
                  onSelected: (selected) => setState(() => selected ? _selectedCategories.add(category) : _selectedCategories.remove(category)),
                )).toList(),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_outlined),
              label: Text(_isSaving ? 'সেভ হচ্ছে...' : 'B2B profile save করুন', style: const TextStyle(fontWeight: FontWeight.w900)),
              style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    FocusScope.of(context).unfocus();
    try {
      await ref.read(businessBuyerRepositoryProvider).saveMyProfile(
            businessName: _businessNameController.text,
            businessType: _businessTypeController.text,
            preferredCategories: _selectedCategories.toList(),
          );
      ref.invalidate(myBusinessBuyerProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('B2B buyer profile save হয়েছে'), behavior: SnackBarBehavior.floating));
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile save করা যায়নি: $error'), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
