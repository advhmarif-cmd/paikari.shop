import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;

void main() {
  developer.log('Checking Firebase config files...',
      name: 'check_firebase_setup');

  final projectRoot = Directory.current.path;

  final androidJson = File('$projectRoot/android/app/google-services.json');
  if (androidJson.existsSync()) {
    developer.log(' - Found android/app/google-services.json',
        name: 'check_firebase_setup');
    try {
      final json = jsonDecode(androidJson.readAsStringSync());
      final clients = (json['client'] as List).cast<Map<String, dynamic>>();
      final client =
          clients.firstWhere((c) => c['client_info'] != null, orElse: () => {});
      final oauth = client['oauth_client'] as List?;
      if (oauth != null) {
        for (var o in oauth) {
          if (o['android_info'] != null) {
            developer.log(
                '   - Android oauth client: package=${o['android_info']['package_name']}, cert=${o['android_info']['certificate_hash']}',
                name: 'check_firebase_setup');
          }
        }
      }
    } catch (e) {
      developer.log('   Warning: failed to parse google-services.json: $e',
          name: 'check_firebase_setup');
    }
  } else {
    developer.log(' - Missing android/app/google-services.json',
        name: 'check_firebase_setup');
  }

  final firebaseOptions = File('$projectRoot/lib/firebase_options.dart');
  if (firebaseOptions.existsSync()) {
    developer.log(' - Found lib/firebase_options.dart',
        name: 'check_firebase_setup');
  } else {
    developer.log(' - Missing lib/firebase_options.dart',
        name: 'check_firebase_setup');
  }

  final iosPlist = File('$projectRoot/ios/Runner/GoogleService-Info.plist');
  if (iosPlist.existsSync()) {
    developer.log(' - Found ios/Runner/GoogleService-Info.plist',
        name: 'check_firebase_setup');
  } else {
    developer.log(
        ' - Missing ios/Runner/GoogleService-Info.plist (optional if using firebase_options.dart, but recommended)',
        name: 'check_firebase_setup');
  }

  final webIndex = File('$projectRoot/web/index.html');
  if (webIndex.existsSync()) {
    final content = webIndex.readAsStringSync();
    if (content.contains('recaptcha-container')) {
      developer.log(' - web/index.html contains recaptcha-container',
          name: 'check_firebase_setup');
    } else {
      developer.log(
          ' - web/index.html missing recaptcha-container (required for web phone auth)',
          name: 'check_firebase_setup');
    }
  } else {
    developer.log(' - Missing web/index.html', name: 'check_firebase_setup');
  }

  developer.log('\nChecklist:', name: 'check_firebase_setup');
  developer.log(
      ' - Ensure Android SHA-1 and SHA-256 from your signing key are registered in Firebase Console for Google Sign-In and Phone Auth.',
      name: 'check_firebase_setup');
  developer.log(
      ' - Ensure Facebook appId and settings are configured in Firebase Console and Facebook developer console.',
      name: 'check_firebase_setup');
  developer.log(
      ' - For iOS builds, add GoogleService-Info.plist to ios/Runner and register bundle id in Firebase.',
      name: 'check_firebase_setup');
  developer.log(
      ' - For web phone auth, ensure recaptcha container exists and domain is authorized.',
      name: 'check_firebase_setup');
  developer.log(
      ' - Check Firebase Storage/Firestore rules if uploads or reads fail.',
      name: 'check_firebase_setup');

  exit(0);
}
