import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paikari_shop/core/theme/paikari_theme.dart';
import 'package:paikari_shop/features/auth/models/user_model.dart';
import 'package:paikari_shop/features/auth/repositories/auth_repository.dart';
import 'package:paikari_shop/l10n/generated/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  String? _verificationId;
  dynamic _confirmationResult;
  RecaptchaVerifier? _recaptchaVerifier;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _recaptchaVerifier = RecaptchaVerifier(
        auth: FirebaseAuthPlatform.instance,
        container: 'recaptcha-container',
        size: RecaptchaVerifierSize.normal,
        onSuccess: () => debugPrint('reCAPTCHA verified'),
        onError: (error) => debugPrint('reCAPTCHA error: $error'),
        onExpired: () => debugPrint('reCAPTCHA expired'),
      );
    }
  }

  String _normalizePhoneNumber(String input) {
    const banglaDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    String normalized = input;
    for (int i = 0; i < 10; i++) {
      normalized = normalized.replaceAll(banglaDigits[i], englishDigits[i]);
    }
    return normalized.replaceAll(RegExp(r'\D'), '');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _recaptchaVerifier?.clear();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty) return;

    final normalized = _normalizePhoneNumber(rawPhone);
    if (normalized.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('সঠিক মোবাইল নম্বর দিন')),
      );
      return;
    }

    setState(() => _isLoading = true);
    debugPrint('OTP: Starting verification for +88$normalized');

    try {
      final result = await ref.read(authRepositoryProvider).verifyPhoneNumber(
            phoneNumber: '+88$normalized',
            onCodeSent: (verificationId) {
              debugPrint('OTP: Code sent. Verification ID: $verificationId');
              if (mounted) {
                setState(() {
                  _verificationId = verificationId;
                  _isLoading = false;
                });
              }
            },
            onVerificationFailed: (e) {
              debugPrint('OTP: Verification failed: ${e.message}');
              if (mounted) {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.message}')),
                );
              }
            },
            verifier: _recaptchaVerifier,
          );

      if (result != null) {
        debugPrint('OTP: Web confirmation result received');
        if (mounted) {
          setState(() {
            _confirmationResult = result;
            _verificationId = "web-auth"; // Placeholder
            _isLoading = false;
          });
        }
      } else if (!kIsWeb) {
        // On mobile, if verifyPhoneNumber returns null but codeSent hasn't fired yet,
        // we keep loading. But we should add a timeout or check if codeSent took too long.
        debugPrint('OTP: Mobile verification initiated (waiting for callback)');
      }
    } catch (e) {
      debugPrint('OTP: Catch error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('অনুরোধ ব্যর্থ হয়েছে: $e')),
        );
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final userCredential =
          await ref.read(authRepositoryProvider).signInWithOtp(
                verificationId: _verificationId ?? "",
                smsCode: _otpController.text.trim(),
                confirmationResult: _confirmationResult,
              );

      // Ensure user document exists in Firestore
      if (userCredential.user != null) {
        await ref.read(authRepositoryProvider).ensureUserDocumentExists(
              userCredential.user!,
              UserRole.consumer, // Default role for phone auth
            );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ভুল OTP: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSocialLogin(
      Future<UserCredential> Function() loginMethod) async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await loginMethod();

      // Ensure user document exists in Firestore
      if (userCredential.user != null) {
        await ref.read(authRepositoryProvider).ensureUserDocumentExists(
              userCredential.user!,
              UserRole.consumer, // Default role for social auth
            );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('লগইন ব্যর্থ হয়েছে: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Image.asset(
                    'assets/logo.jpg',
                    height: 120,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.store, size: 80, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.appTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 30),
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        if (_verificationId == null) ...[
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'মোবাইল নম্বর (Phone Number)',
                              prefixText: '+৮৮ ',
                              prefixIcon: const Icon(Icons.phone_android),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _sendOtp,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text('OTP পাঠান (Send OTP)',
                                    style: TextStyle(fontSize: 16)),
                          ),
                        ] else ...[
                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: '৬ সংখ্যার কোড (OTP)',
                              prefixIcon: const Icon(Icons.lock_clock),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _verifyOtp,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text('যাচাই করুন (Verify)',
                                    style: TextStyle(fontSize: 18)),
                          ),
                          TextButton(
                            onPressed: () =>
                                setState(() => _verificationId = null),
                            child: const Text('নম্বর পরিবর্তন করুন'),
                          ),
                        ],
                        const SizedBox(height: 16),
                        const Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('অথবা (OR)'),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _SocialButton(
                              label: 'Google',
                              color: Colors.red.shade600,
                              icon: Icons.g_mobiledata,
                              onPressed: () => _handleSocialLogin(ref
                                  .read(authRepositoryProvider)
                                  .signInWithGoogle),
                            ),
                            _SocialButton(
                              label: 'Facebook',
                              color: Colors.blue.shade800,
                              icon: Icons.facebook,
                              onPressed: () => _handleSocialLogin(ref
                                  .read(authRepositoryProvider)
                                  .signInWithFacebook),
                            ),
                          ],
                        ),
                        // Hidden reCAPTCHA container for Web Phone Auth
                        const SizedBox(
                            height: 0,
                            child: Divider(
                              height: 0,
                              color: Colors.transparent,
                            )),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  'অ্যাকাউন্ট নেই? নিবন্ধন করুন',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
