# Paikari.shop Auth, order security, and Hybrid B1 catalog handoff

## Implementation status

The Firebase Auth to Supabase Auth migration and server-authoritative order hardening are merged on GitHub `main` at commit `a2c1c02`. The Hybrid B1 catalog changes are now prepared locally on branch `chore/supabase-auth-migration` and are ready to be committed to `main` after the final repository checks.

Paikari.shop remains a separate Flutter application. Its B2C catalog now reads from `public.catalog_products`, which contains both read-only shared products mastered by Origen-Prime (`source = 'origen'`) and locally owned marketplace products (`source = 'paikari'`). The current live catalog contains the Origen demo product `default-product`, with retail price `৳2400` and sale price `৳2000`. The customer-facing `public.b2c_products` view returns that active row.

## Completed changes

Firebase Auth has been replaced by Supabase Auth for session state, Phone OTP, Google OAuth, optional Facebook OAuth, profile provisioning, signup, and route guards. Android and iOS use the `io.paikari.shop://login-callback/` deep-link scheme. Firebase Auth SDKs and provider dependencies were removed, while Firebase Core/Storage remain only for the existing trade-license upload path.

Order persistence no longer uses Firestore. The checkout screen sends only product IDs, quantities, shipping address, delivery zone, and payment method to `place_order_from_cart`. The RPC reads current prices and wholesale tiers from `catalog_products`, validates availability and quantities, calculates delivery and total values, and inserts the order under the authenticated user. Client-side totals remain display-only and are not trusted for the stored order amount.

The Hybrid B1 catalog schema adds source ownership, origin-product mapping, active-state controls, and RLS policies. Origen rows are read-only from Paikari’s client side. Authenticated users can create their own `paikari` rows through the repository, while shared `origen` rows cannot be edited from Paikari. The repository supports both Origen snake_case fields and the existing Paikari camelCase fields.

The `sync-origen-catalog` Supabase Edge Function is deployed with JWT verification enabled. It fetches active products from `https://origen-prime.vercel.app/api/products`, upserts shared rows, and deactivates previously synced Origen products that are no longer returned. It supports the normal authenticated JWT path and an optional server-to-server `x-origen-sync-secret` header backed by the `ORIGEN_SYNC_SECRET` Edge Function secret. The current function defaults to that URL but accepts an `ORIGEN_CATALOG_URL` secret for future configuration.

The product-card rendering path was adjusted for shared Origen products that do not have wholesale tiers. Such products now display retail pricing and an Origen label instead of indexing an empty list and crashing. Local wholesale products retain the existing wholesale-price presentation.

## Verification and limitations

Live Supabase verification confirmed that `public.catalog_products` contains the seeded Origen product and that `public.b2c_products` exposes the same active row. The catalog migration, the order-RPC migration, and the Edge Function deployment all completed successfully. The Edge Function is active with JWT verification enabled.

The sandbox does not have Flutter/Dart installed, so `flutter pub get`, `flutter analyze`, `flutter test`, Android build validation, and device-level UI smoke tests could not be run here. These checks must be run on a Flutter-enabled development machine. The lockfile should be regenerated locally with `flutter pub get` if dependency metadata has changed.

## Required launch configuration

Before live launch, configure Supabase Auth providers for Phone OTP and Google OAuth, optionally enable Facebook OAuth, and register the exact native redirect URI `io.paikari.shop://login-callback/`. Replace the two zero-valued rows in `shipping_settings` with the actual inside-city and outside-city delivery charges. Keep the Edge Function JWT verification enabled, set a strong `ORIGEN_SYNC_SECRET` if Origen admin-triggered sync is needed, and set `ORIGEN_CATALOG_URL` only if the default Origen endpoint should be overridden.

Origen-Prime still requires its Vercel environment variables to be configured: `SUPABASE_SERVICE_ROLE_KEY`, `VITE_SUPABASE_URL`, `ADMIN_PASSWORD`, a random `ADMIN_SESSION_SECRET` of at least 32 characters, and `PUBLIC_SITE_ORIGIN=https://origen-prime.vercel.app`. Until those values are present in Vercel, the deployed frontend/API may not use the hardened runtime configuration even though the source changes are already merged.

## Recommended final validation

On a Flutter-enabled machine, run `flutter pub get`, `flutter analyze`, and `flutter test`. Then sign in to Paikari.shop, verify that the shared Origen product appears in the B2C catalog, add a local Paikari product through the vendor flow, confirm that shared Origen rows cannot be edited, and place a test order. The resulting order total should match the server response from `place_order_from_cart`, not any client-provided amount.

## References

[1]: https://supabase.com/docs/reference/dart/auth-signinwithoauth "Supabase Flutter OAuth reference"
[2]: https://supabase.com/docs/reference/dart/auth-onauthstatechange "Supabase Flutter auth state reference"
[3]: https://supabase.com/docs/guides/auth/native-mobile-deep-linking "Supabase native mobile deep linking"
[4]: https://supabase.com/docs/guides/auth/redirect-urls "Supabase Auth redirect URL configuration"
[5]: https://supabase.com/docs/guides/functions "Supabase Edge Functions documentation"
