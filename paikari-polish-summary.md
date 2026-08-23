# Paikari.shop Android-first UI polish

## Scope

This pass polished the existing Flutter app without changing Supabase schema, queries, migrations, Edge Functions, authentication configuration, or order RPC behavior. The Hybrid B1 product and checkout architecture remains unchanged.

## Changes

A reusable `ProductImage` widget now handles empty URLs, network loading, and broken image URLs with a consistent placeholder. Product cards have clearer source badges for Origen versus Paikari products, safer pricing when wholesale tiers are absent, stock-state overlays, improved hierarchy, and more comfortable card spacing.

The product detail screen now shows source and availability cues, uses the same resilient image treatment, presents retail and wholesale pricing more clearly, gives empty descriptions a safe fallback, and uses a larger Android-friendly add-to-cart action.

The cart screen now uses a stable item list, larger quantity controls, a per-item remove action, clear subtotal presentation, an explicit delivery-charge note, a stronger checkout CTA, a confirmation dialog for clearing the cart, and a more useful empty state.

Checkout now guards against an empty cart, groups address and payment sections, improves field labels and validation, keeps the server-authoritative total messaging clear, disables duplicate submission while loading, and fixes the success dialog so the confirmed server total is interpolated correctly.

The home catalog now supports pull-to-refresh, responsive two/four-column grids, branded empty and error states, a clearer cart badge, and a corrected comment describing Firebase as legacy storage-only while Supabase handles auth and orders.

The shared theme now improves scaffold, input, focus, and button presentation for Android touch and readability.

## Validation

`git diff --check` passed. No Supabase operation was performed during this pass. Flutter and Dart are not installed in the sandbox, so `flutter pub get`, `dart format`, `flutter analyze`, `flutter test`, and Android device validation must be run on a Flutter-enabled machine.
