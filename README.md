# Paikari.shop

Paikari.shop is a Flutter marketplace app for the Bangladesh market, supporting B2B and B2C commerce.

## Authentication and backend setup

Supabase Auth is the source of truth for user sessions. Configure the Google and Facebook OAuth providers in the Supabase Dashboard, then add the exact redirect URI below to Supabase Auth URL Configuration:

```text
io.paikari.shop://login-callback/
```

The same custom URL scheme must be registered in the Android and iOS app configuration. For web builds, add the deployed web URL and local development URL to the Supabase redirect allow list.

The app currently retains Firebase Core/Firestore/Storage for the existing order and trade-license upload repositories. Firebase Auth, Firebase Google Sign-In, Firebase Facebook Auth, and Firebase phone-auth dependencies have been removed from the application flow.

## Supabase Auth provider checklist

- Enable Phone provider if OTP login is required.
- Enable Google provider and configure the Google OAuth client with Supabase’s callback URL.
- Enable Facebook provider only if Facebook login is required, and configure the Facebook app credentials in Supabase.
- Set the Site URL and exact redirect URLs in Supabase Auth URL Configuration.
- Ensure the `users` table has an RLS policy allowing an authenticated user to read and update only their own profile row.
- Ensure role assignment is not client-controlled; new public signups must be created as `consumer` unless an administrator promotes them.

## Remaining Firebase services

If Firestore orders or Firebase Storage uploads remain enabled, configure the platform-specific Firebase files required by those services and enforce Firestore/Storage security rules separately. Firebase Auth configuration files are no longer needed for the login flow.

## Development checks

When Flutter is available, run:

```bash
flutter pub get
flutter analyze
flutter test
```
