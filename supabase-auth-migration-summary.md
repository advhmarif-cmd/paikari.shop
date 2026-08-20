# Paikari.shop Auth and order-security handoff

## Implementation status

The migration is complete locally on branch `chore/supabase-auth-migration`. The branch contains three commits: `f81c681` for Firebase Auth to Supabase Auth, `28828e6` for server-authoritative order pricing, and `a7c6277` for removing the obsolete Firestore order repository. The working tree is clean.

The Supabase migration `secure_orders_rpc` was applied successfully to the Paikari.shop project. Live verification confirms that `public.order_records` and `public.shipping_settings` exist with RLS enabled, the `order_records_select_own` policy restricts reads to `user_id = auth.uid()`, and the `place_order_from_cart` function exists.

## Completed changes

Firebase Auth has been replaced by Supabase Auth for session state, Phone OTP, Google OAuth, optional Facebook OAuth, profile provisioning, signup, and route guards. Android and iOS use the `io.paikari.shop://login-callback/` deep-link scheme. Firebase Auth SDKs and provider dependencies were removed.

Order persistence no longer uses Firestore. The checkout screen sends only product IDs, quantities, shipping address, delivery zone, and payment method to `place_order_from_cart`. The RPC reads the current product price and wholesale tiers from Supabase, validates product availability and quantity, calculates delivery and total values, and inserts the order under the authenticated user. The client-side cart total remains display-only and is not used as the trusted amount.

Order history now streams from `order_records` and is filtered by the current Supabase user ID. The former Firestore order repository and `cloud_firestore` dependency were removed. Firebase Core/Storage remain only for the existing trade-license upload path.

## Verification and limitations

Static checks pass for `git diff --check`, removal of Firestore order references, and removal of old Firebase Auth references. The live Supabase migration and RLS policy checks passed. Flutter/Dart are not installed in the sandbox, so `flutter pub get`, `flutter analyze`, and `flutter test` could not be run. The lockfile should be regenerated locally with `flutter pub get`.

The GitHub push was rejected by the available Git credential with HTTP 403, so the branch has not been pushed automatically. A complete patch is available at `/home/ubuntu/paikari-auth-and-order-hardening.patch`.

## Required follow-up

Run `flutter pub get`, `flutter analyze`, and `flutter test` on a Flutter-enabled environment. Configure Supabase Google, Phone, and optional Facebook providers, add the exact native redirect URI, verify the `users` profile RLS policies from the earlier migration, and set real delivery charges in `shipping_settings` instead of the initial zero defaults.

## References

[1]: https://supabase.com/docs/reference/dart/auth-signinwithoauth "Supabase Flutter OAuth reference"
[2]: https://supabase.com/docs/reference/dart/auth-onauthstatechange "Supabase Flutter auth state reference"
[3]: https://supabase.com/docs/guides/auth/native-mobile-deep-linking "Supabase native mobile deep linking"
[4]: https://supabase.com/docs/guides/auth/redirect-urls "Supabase Auth redirect URL configuration"
