# Paikari.shop Supabase Auth migration handoff

## Status

The Firebase Auth portion of Paikari.shop has been migrated locally to Supabase Auth on branch `chore/supabase-auth-migration` at commit `f81c681` (`Migrate app auth from Firebase to Supabase`). The working tree is clean.

The branch could not be pushed to GitHub because the available Git transport token returns HTTP 403 for `advhmarif-cmd/paikari.shop.git`, even though the GitHub CLI reports repository viewer permission `ADMIN`. A binary patch is available at `/home/ubuntu/paikari-supabase-auth-migration.patch`.

## Completed code changes

The app now initializes Supabase Auth with PKCE and keeps Firebase Core initialization only for the existing Firestore order repository. The AuthRepository uses Supabase sessions, `onAuthStateChange`, phone OTP, Google OAuth, Facebook OAuth, Supabase user profiles, sign-out, and profile streams. The login screen no longer imports Firebase Auth, Firebase reCAPTCHA, Google Sign-In, or Facebook Auth SDKs. Signup reads the current Supabase user and writes the existing `users` profile model.

The existing route guard still provides the same user experience: unauthenticated users see LoginScreen, authenticated users without a profile see SignupScreen, and users with a profile reach HomeScreen. The profile order provider now uses Supabase User IDs. Android and iOS have the `io.paikari.shop://login-callback/` OAuth deep-link scheme.

Firebase Auth-specific dependencies were removed from `pubspec.yaml`: `firebase_auth`, `firebase_auth_platform_interface`, `google_sign_in`, `flutter_facebook_auth`, and `firebase_auth_mocks`. Firebase Core, Firestore, and Storage remain because the current app still uses Firestore for orders and Firebase Storage for trade-license uploads. The lockfile must be regenerated with `flutter pub get`.

A Supabase migration was added at `supabase/migrations/20260820102000_supabase_auth_users_rls.sql`. It enables RLS on `public.users`, creates own-profile select/insert/update policies for authenticated users, limits self-created roles to consumer/vendor, revokes anon table access, and grants the required authenticated table operations.

## Verification

Static verification passed for `git diff --check`, no remaining Firebase Auth references in `lib`, `test`, or `pubspec.yaml`, and the committed branch has no uncommitted changes. XML validation could not run because `xmllint` is not installed. Flutter/Dart validation could not run because neither `flutter` nor `dart` is installed in the sandbox.

## Required dashboard and local follow-up

The Paikari.shop Supabase project is currently `INACTIVE`. The attempted restore was rejected because the organization has reached its maximum active free-project limit. Therefore the database schema could not be inspected or the RLS migration applied from this task.

After restoring or upgrading the Supabase project, apply the migration, enable the Phone, Google, and optional Facebook providers, and add the exact redirect URI `io.paikari.shop://login-callback/` to Supabase Auth URL Configuration. For web builds, configure the deployed web URL and local URL as additional redirect URLs; the app uses the Supabase Site URL on web and the custom deep link on native platforms.

Then run:

```bash
flutter pub get
flutter analyze
flutter test
```

Finally, verify that new signups cannot self-assign `admin`, that a user can read/update only their own `users` row, and that Google OAuth returns to the Android/iOS app.
