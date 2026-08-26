import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:image_picker/image_picker.dart';
import 'package:paikari_shop/core/repositories/storage_repository.dart';
import 'package:paikari_shop/core/theme/paikari_theme.dart';
import 'package:paikari_shop/features/auth/models/user_model.dart';
import 'package:paikari_shop/features/auth/repositories/auth_repository.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  UserRole _selectedRole = UserRole.consumer;
  final _nameController = TextEditingController();
  final _businessController = TextEditingController();
  XFile? _tradeLicenseFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _businessController.dispose();
    super.dispose();
  }

  Future<void> _pickTradeLicense() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (!mounted || image == null) return;
    setState(() => _tradeLicenseFile = image);
  }

  Future<void> _handleSignup() async {
    final user = sb.Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অনুগ্রহ করে আপনার নাম দিন')),
      );
      return;
    }

    if (_selectedRole == UserRole.vendor &&
        (_businessController.text.isEmpty || _tradeLicenseFile == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('আপনার ব্যবসার নাম ও ট্রেড লাইসেন্স দিন')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? tradeLicenseUrl;
      if (_tradeLicenseFile != null) {
        final bytes = await _tradeLicenseFile!.readAsBytes();
        tradeLicenseUrl = await ref
            .read(storageRepositoryProvider)
            .uploadFile(path: 'trade_licenses', id: user.id, fileBytes: bytes);
      }

      final userModel = UserModel(
        uid: user.id,
        email: user.email,
        displayName: _nameController.text.trim(),
        phoneNumber: user.phone,
        role: _selectedRole,
        businessName: _selectedRole == UserRole.vendor
            ? _businessController.text.trim()
            : null,
        tradeLicenseUrl: tradeLicenseUrl,
      );

      await ref.read(authRepositoryProvider).updateUserData(userModel);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('প্রোফাইল আপডেট ব্যর্থ হয়েছে: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('নিবন্ধন করুন (Register)'),
        backgroundColor: Colors.transparent,
        foregroundColor: PaikariTheme.primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'আপনার ভূমিকা নির্বাচন করুন',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _RoleCard(
                    title: 'ক্রেতা (Consumer)',
                    icon: Icons.person_outline,
                    isSelected: _selectedRole == UserRole.consumer,
                    onTap: () =>
                        setState(() => _selectedRole = UserRole.consumer),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _RoleCard(
                    title: 'বিক্রেতা (Vendor)',
                    icon: Icons.store_mall_directory_outlined,
                    isSelected: _selectedRole == UserRole.vendor,
                    onTap: () =>
                        setState(() => _selectedRole = UserRole.vendor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              decoration: InputDecoration(
                labelText: 'আপনার নাম (Your Name)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (_selectedRole == UserRole.vendor) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _businessController,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.organizationName],
                decoration: InputDecoration(
                  labelText: 'ব্যবসার নাম (Business Name)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickTradeLicense,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.upload_file,
                        color: PaikariTheme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _tradeLicenseFile == null
                              ? 'ট্রেড লাইসেন্স আপলোড করুন (Upload Trade License)'
                              : 'লাইসেন্স ফাইল যোগ হয়েছে (File Added)',
                          style: TextStyle(
                            color: _tradeLicenseFile == null
                                ? Colors.grey.shade600
                                : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSignup,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'অ্যাকাউন্ট তৈরি করুন',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? PaikariTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? PaikariTheme.primaryColor
                : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? PaikariTheme.primaryColor : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? PaikariTheme.primaryColor : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
