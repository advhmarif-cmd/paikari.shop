import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:paikari_shop/features/auth/models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Phone Auth Step 1: Send OTP (Cross-platform)
  Future<dynamic> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(FirebaseAuthException) onVerificationFailed,
    required dynamic verifier, // For Web: RecaptchaVerifier
  }) async {
    if (kIsWeb) {
      // For Web, signInWithPhoneNumber is simpler and highly recommended
      try {
        if (kDebugMode) {
          debugPrint(
              'AuthRepository: verifyPhoneNumber (web) for $phoneNumber');
        }
        // Check if we are on web
        return await _auth.signInWithPhoneNumber(phoneNumber, verifier);
      } catch (e) {
        throw Exception('OTP পাঠাতে সমস্যা হয়েছে: $e');
      }
    } else {
      if (kDebugMode) {
        debugPrint(
            'AuthRepository: verifyPhoneNumber (mobile) for $phoneNumber');
      }
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: onVerificationFailed,
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
      return null;
    }
  }

  // Cross-platform OTP verify
  Future<UserCredential> signInWithOtp({
    required String verificationId,
    required String smsCode,
    ConfirmationResult? confirmationResult,
  }) async {
    if (confirmationResult != null) {
      if (kDebugMode) {
        debugPrint('AuthRepository: signInWithOtp using confirmationResult');
      }
      return await confirmationResult.confirm(smsCode);
    }
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    if (kDebugMode) {
      debugPrint('AuthRepository: signInWithOtp using PhoneAuthCredential');
    }
    return await _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithGoogle() async {
    if (kDebugMode) debugPrint('AuthRepository: signInWithGoogle start');
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google Sign-In canceled');

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithFacebook() async {
    try {
      if (kDebugMode) {
        debugPrint('AuthRepository: signInWithFacebook start (kIsWeb=$kIsWeb)');
      }
      if (kIsWeb) {
        // On Web, ensure we use the web-specific login call if needed,
        // though flutter_facebook_auth handles most of it.
        // We add extra logging to debug 'window.FB' issues.
        debugPrint('FB: Starting web login...');
      }

      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      debugPrint('FB: Login status: ${result.status}');

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final OAuthCredential credential =
            FacebookAuthProvider.credential(accessToken.tokenString);

        if (kDebugMode) {
          debugPrint(
              'AuthRepository: signInWithFacebook success, signing in with credential');
        }
        return await _auth.signInWithCredential(credential);
      } else {
        throw Exception(
            'Facebook Login Failed: ${result.status} - ${result.message}');
      }
    } catch (e) {
      debugPrint('FB: Error during login: $e');
      rethrow;
    }
  }

  // Helper to ensure user exists in Firestore after login
  Future<void> ensureUserDocumentExists(User user, UserRole role) async {
    if (kDebugMode) {
      debugPrint('AuthRepository: ensureUserDocumentExists for ${user.uid}');
    }
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      final userModel = UserModel(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        phoneNumber: user.phoneNumber,
        role: role,
      );
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toJson());
    }
  }

  Future<void> updateUserData(UserModel user) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(user.toJson(), SetOptions(merge: true));
  }

  Future<void> signOut() {
    return _auth.signOut();
  }

  Stream<UserModel?> getUserModel(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserModel.fromJson(snapshot.data()!);
      }
      return null;
    });
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final userProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState != null) {
    return ref.watch(authRepositoryProvider).getUserModel(authState.uid);
  }
  return Stream.value(null);
});
