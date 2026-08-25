import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:paikari_shop/core/config/supabase_config.dart';
import 'package:paikari_shop/features/auth/models/user_model.dart';

class AuthRepository {
  AuthRepository({sb.SupabaseClient? client})
      : _supabase = client ?? sb.Supabase.instance.client;

  final sb.SupabaseClient _supabase;

  sb.GoTrueClient get _auth => _supabase.auth;

  sb.User? get currentUser => _auth.currentUser;

  Stream<sb.User?> get authStateChanges =>
      _auth.onAuthStateChange.map((state) => state.session?.user);

  Future<void> sendPhoneOtp({required String phoneNumber}) async {
    await _auth.signInWithOtp(phone: phoneNumber);
  }

  Future<sb.AuthResponse> verifyPhoneOtp({
    required String phoneNumber,
    required String token,
  }) async {
    return _auth.verifyOTP(
      phone: phoneNumber,
      token: token,
      type: sb.OtpType.sms,
    );
  }

  String? get _authRedirectUrl =>
      kIsWeb ? null : SupabaseConfig.authRedirectUrl;

  Future<bool> signInWithGoogle() async {
    return _auth.signInWithOAuth(
      sb.OAuthProvider.google,
      redirectTo: _authRedirectUrl,
    );
  }

  Future<bool> signInWithFacebook() async {
    return _auth.signInWithOAuth(
      sb.OAuthProvider.facebook,
      redirectTo: _authRedirectUrl,
    );
  }

  Future<bool> signInWithOAuth(sb.OAuthProvider provider) {
    return _auth.signInWithOAuth(provider, redirectTo: _authRedirectUrl);
  }

  Future<void> signOut() => _auth.signOut();

  Future<UserModel> ensureUserProfileExists(
    sb.User user, {
    UserRole defaultRole = UserRole.consumer,
  }) async {
    final existing =
        await _supabase.from('users').select().eq('uid', user.id).maybeSingle();

    if (existing != null) {
      return UserModel.fromJson(existing);
    }

    final metadata = user.userMetadata ?? <String, dynamic>{};
    final displayName = metadata['full_name'] as String? ??
        metadata['name'] as String? ??
        user.email?.split('@').first;

    final userModel = UserModel(
      uid: user.id,
      email: user.email,
      displayName: displayName,
      phoneNumber: user.phone,
      role: defaultRole,
    );

    await _supabase.from('users').insert(userModel.toJson());
    return userModel;
  }

  Future<void> updateUserData(UserModel user) async {
    await _supabase.from('users').upsert(
          user.toJson(),
          onConflict: 'uid',
        );
  }

  Stream<UserModel?> getUserModel(String uid) {
    return _supabase
        .from('users')
        .stream(primaryKey: ['uid'])
        .eq('uid', uid)
        .map((data) {
          if (data.isEmpty) return null;
          return UserModel.fromJson(data.first);
        });
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<sb.User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final userProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).getUserModel(authState.id);
});
