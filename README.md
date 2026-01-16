# paikari_shop

A new Flutter project.

## Firebase setup checklist

- Android: ensure `android/app/google-services.json` is present and that your app's package name and signing certificate SHA-1/SHA-256 are registered in the Firebase Console (required for Google Sign-In and Phone Auth in release builds).
- iOS: add `GoogleService-Info.plist` to `ios/Runner/` and register the bundle id in Firebase if you plan to build for iOS.
- Web: ensure `web/index.html` contains a `div` with id `recaptcha-container` (used for Firebase Phone Auth on web). The project already contains this div by default.
- OAuth: configure Google and Facebook sign-in in the Firebase Console and in the provider consoles (Google Cloud Console and Facebook Developers) and provide any required app IDs/secrets.
- Storage/Firestore rules: ensure rules allow the authenticated operations you expect during development.

Run the included checker to validate local config files:
```
dart tool/check_firebase_setup.dart
```
