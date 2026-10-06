import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:paikari_shop/core/theme/paikari_theme.dart';
import 'package:paikari_shop/features/auth/repositories/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      final response = await ref.read(authRepositoryProvider).signInWithEmail(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (response.user == null || response.session == null) {
        throw const sb.AuthException('Email confirmation is required before login.');
      }
      await ref.read(authRepositoryProvider).ensureUserProfileExists(response.user!);
    } catch (error) {
      if (mounted) _showError(_friendlyAuthError(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSocialLogin(sb.OAuthProvider provider) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithOAuth(provider);
    } catch (error) {
      if (mounted) {
        _showError('এই OAuth provider এখনো Supabase-এ সঠিকভাবে কনফিগার করা হয়নি।');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyAuthError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'ইমেইল বা পাসওয়ার্ড সঠিক নয়।';
    }
    if (message.contains('email not confirmed')) {
      return 'আগে আপনার ইমেইল confirm করুন, তারপর login করুন।';
    }
    if (message.contains('network')) return 'ইন্টারনেট সংযোগ যাচাই করুন।';
    return 'লগইন করা যায়নি। তথ্যগুলো যাচাই করে আবার চেষ্টা করুন।';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [PaikariTheme.primaryColor, Colors.white],
            stops: [0.3, 0.3],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Center(child: Image.asset('assets/logo.png', height: 120)),
                  const SizedBox(height: 10),
                  const Text(
                    'Paikari.shop',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 30),
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.username, AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'ইমেইল (Email)',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty || !email.contains('@')) return 'সঠিক ইমেইল দিন';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _login(),
                            decoration: InputDecoration(
                              labelText: 'পাসওয়ার্ড (Password)',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                              ),
                            ),
                            validator: (value) => (value?.length ?? 0) < 6 ? 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের দিন' : null,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('লগইন করুন (Login)', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('Google/Facebook login provider কনফিগার হলে চালু করা যাবে।', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            children: [
                              TextButton.icon(onPressed: _isLoading ? null : () => _handleSocialLogin(sb.OAuthProvider.google), icon: const Icon(Icons.g_mobiledata), label: const Text('Google')),
                              TextButton.icon(onPressed: _isLoading ? null : () => _handleSocialLogin(sb.OAuthProvider.facebook), icon: const Icon(Icons.facebook), label: const Text('Facebook')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextButton.icon(
                    onPressed: _isLoading ? null : () => Navigator.pushNamed(context, '/signup'),
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('অ্যাকাউন্ট নেই? নিবন্ধন করুন'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
