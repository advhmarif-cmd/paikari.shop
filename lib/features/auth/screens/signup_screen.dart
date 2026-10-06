import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
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
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _business = TextEditingController();
  UserRole _role = UserRole.consumer;
  XFile? _license;
  bool _loading = false;
  bool _hidePassword = true;
  bool _hideConfirm = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _business.dispose();
    super.dispose();
  }

  Future<void> _pickLicense() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (mounted && file != null) setState(() => _license = file);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final auth = ref.read(authRepositoryProvider);
      final response = await auth.signUpWithEmail(
        email: _email.text,
        password: _password.text,
        displayName: _name.text,
      );
      final user = response.user;
      if (user == null) throw const sb.AuthException('Account could not be created.');
      if (response.session == null) {
        _message('Account তৈরি হয়েছে। Email confirm করে Login করুন।');
        if (mounted) Navigator.of(context).pop();
        return;
      }
      String? licenseUrl;
      if (_license != null) {
        licenseUrl = await ref.read(storageRepositoryProvider).uploadFile(
          path: 'trade_licenses',
          id: user.id,
          fileBytes: await _license!.readAsBytes(),
        );
      }
      await auth.updateUserData(UserModel(
        uid: user.id,
        email: user.email,
        displayName: _name.text.trim(),
        phoneNumber: user.phone,
        role: _role,
        businessName: _role == UserRole.vendor ? _business.text.trim() : null,
        tradeLicenseUrl: licenseUrl,
      ));
      if (mounted) Navigator.of(context).pushReplacementNamed('/home');
    } catch (error) {
      if (mounted) _message(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('already registered') || text.contains('already exists')) {
      return 'এই email দিয়ে account আগে থেকেই আছে।';
    }
    if (text.contains('password')) return 'Password কমপক্ষে ৬ অক্ষরের দিন।';
    return 'Account তৈরি করা যায়নি। তথ্যগুলো যাচাই করুন।';
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('নিবন্ধন করুন (Register)')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('নতুন account খুলুন', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text('Email confirmation চালু থাকলে inbox থেকে email confirm করতে হবে।'),
            const SizedBox(height: 24),
            TextFormField(controller: _name, textInputAction: TextInputAction.next, autofillHints: const [AutofillHints.name], decoration: const InputDecoration(labelText: 'পূর্ণ নাম (Full name)', prefixIcon: Icon(Icons.person_outline)), validator: (v) => (v?.trim().length ?? 0) < 2 ? 'পূর্ণ নাম দিন' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, autofillHints: const [AutofillHints.email], decoration: const InputDecoration(labelText: 'ইমেইল (Email)', prefixIcon: Icon(Icons.email_outlined)), validator: (v) => (v?.contains('@') ?? false) ? null : 'সঠিক email দিন'),
            const SizedBox(height: 16),
            TextFormField(controller: _password, obscureText: _hidePassword, textInputAction: TextInputAction.next, decoration: InputDecoration(labelText: 'পাসওয়ার্ড (Password)', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => _hidePassword = !_hidePassword), icon: Icon(_hidePassword ? Icons.visibility : Icons.visibility_off))), validator: (v) => (v?.length ?? 0) < 6 ? 'কমপক্ষে ৬ অক্ষরের password দিন' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _confirm, obscureText: _hideConfirm, textInputAction: TextInputAction.done, decoration: InputDecoration(labelText: 'পাসওয়ার্ড আবার দিন (Confirm)', prefixIcon: const Icon(Icons.lock_reset_outlined), suffixIcon: IconButton(onPressed: () => setState(() => _hideConfirm = !_hideConfirm), icon: Icon(_hideConfirm ? Icons.visibility : Icons.visibility_off))), validator: (v) => v != _password.text ? 'Password দুইটি এক নয়' : null),
            const SizedBox(height: 24),
            const Text('Account type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: _RoleCard(title: 'ক্রেতা', icon: Icons.person_outline, selected: _role == UserRole.consumer, onTap: () => setState(() => _role = UserRole.consumer))), const SizedBox(width: 12), Expanded(child: _RoleCard(title: 'বিক্রেতা', icon: Icons.store_mall_directory_outlined, selected: _role == UserRole.vendor, onTap: () => setState(() => _role = UserRole.vendor)))]),
            if (_role == UserRole.vendor) ...[
              const SizedBox(height: 16),
              TextFormField(controller: _business, decoration: const InputDecoration(labelText: 'ব্যবসার নাম (Business name)', prefixIcon: Icon(Icons.storefront_outlined)), validator: (v) => (v?.trim().isEmpty ?? true) ? 'ব্যবসার নাম দিন' : null),
              const SizedBox(height: 12),
              InkWell(onTap: _pickLicense, borderRadius: BorderRadius.circular(12), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.upload_file, color: PaikariTheme.primaryColor), const SizedBox(width: 12), Expanded(child: Text(_license == null ? 'ট্রেড লাইসেন্স আপলোড করুন' : 'লাইসেন্স ফাইল যোগ হয়েছে', style: TextStyle(color: _license == null ? Colors.grey.shade600 : Colors.green)))]))),
            ],
            const SizedBox(height: 28),
            ElevatedButton(onPressed: _loading ? null : _submit, child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('অ্যাকাউন্ট তৈরি করুন', style: TextStyle(fontSize: 17))),
          ]),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.title, required this.icon, required this.selected, required this.onTap});
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: selected ? PaikariTheme.primaryColor.withValues(alpha: 0.1) : null, borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? PaikariTheme.primaryColor : Colors.grey.shade300, width: 2)), child: Column(children: [Icon(icon, size: 34, color: selected ? PaikariTheme.primaryColor : Colors.grey), const SizedBox(height: 6), Text(title, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal))])));
}
