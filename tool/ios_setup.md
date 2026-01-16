iOS Build & Firebase Setup Checklist

1. Register your iOS app in Firebase Console
   - Bundle ID must match `ios/Runner/Info.plist` (currently: `com.example.paikariShop` in `firebase_options.dart`).
   - Download `GoogleService-Info.plist` and place it at `ios/Runner/GoogleService-Info.plist`.

2. CocoaPods
   - On macOS run:
     ```bash
     cd ios
     pod install
     ```
   - Ensure Xcode command line tools are installed.

3. Entitlements and Capabilities
   - Enable Push Notifications and Background Modes if needed.
   - Configure Sign-In with Apple if you support it.

4. App signing
   - Set up a signing certificate and provisioning profile in Xcode.
   - use an Apple Developer account and ensure provisioning includes the app's bundle id.

5. Firebase Auth providers
   - In Firebase Console > Authentication, enable Phone, Google, Facebook as needed.
   - For Google Sign-In on iOS, create an OAuth client for iOS in Google Cloud Console and add its reverse client ID to `Info.plist` if required.

6. Privacy strings
   - Add `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` and other relevant privacy keys to `Info.plist`.

7. Build
   - On macOS:
     ```bash
     flutter build ios --release
     ```
   - Or use Xcode to archive and distribute.

Notes:
- I cannot build iOS artifacts on this Windows environment; follow the checklist above on a macOS machine with Xcode installed.
- I can prepare any files or instructions you want added to the repo (example `GoogleService-Info.plist` placeholder or CI build steps).
