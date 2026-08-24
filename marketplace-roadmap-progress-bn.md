# Paikari.shop — Marketplace roadmap progress

## বর্তমান অবস্থান

Paikari এখন B2B-first এবং B2C-enabled marketplace foundation-এর উপর চলছে। Origen-Prime আলাদা master catalog/landing project হিসেবে আছে; Paikari-তে Origen-এর shared rows read-only এবং local supplier products vendor-owned। সর্বশেষ কাজগুলো Paikari repository-তেই করা হয়েছে।

| স্তর | অবস্থা | বাস্তব ফলাফল |
|---|---|---|
| Hybrid B1 catalog | সম্পন্ন | Origen shared product ও Paikari local product আলাদা ownership সহ চলে |
| Server-authoritative cart checkout | সম্পন্ন | Client price/total পাঠালেও server catalog থেকে price নির্ধারণ করে |
| Split orders, MOQ, stock reservation, RFQ | সম্পন্ন | Order group ও vendor order আলাদা থাকে |
| Accepted quote checkout | সম্পন্ন | Immutable quote snapshot ও one-time checkout session |
| Order status tracking | সম্পন্ন | Status event history, buyer timeline ও vendor fulfillment actions |
| Payment foundation | সম্পন্ন | COD/Bkash state, payment transaction audit trail, server-only confirmation RPC |
| Admin moderation foundation | সম্পন্ন | JWT app_metadata-ভিত্তিক vendor/product approval RPC ও Admin Center |
| Payment webhook idempotency | সম্পন্ন | Provider event ID unique handling ও illegal payment regression block |
| Delivery tracking foundation | সম্পন্ন | Courier, tracking number, tracking URL এবং shipped/delivered timestamps |
| Returns/disputes foundation | সম্পন্ন | Delivered order থেকে buyer return request, vendor/admin response এবং refund-state boundary |
| Notifications foundation | সম্পন্ন | Order, courier ও return events থেকে buyer/vendor in-app notifications |
| Admin reconciliation | সম্পন্ন | Server-recorded payment transactions admin-only read view |
| Buyer conversion UX | সম্পন্ন | B2B/B2C cart context, supplier/stock signals, SKU/supplier search ও quote expiry copy |
| Notification inbox | সম্পন্ন | Home unread badge, dedicated inbox এবং owner-scoped read marking |
| Return/dispute UX | সম্পন্ন | Buyer return request, vendor response queue ও admin resolution controls |
| Buyer/vendor UX polish | সম্পন্ন | Notification inbox, unread badge, supplier/stock context, Bengali order/payment labels |
| Courier event contract | সম্পন্ন | Service-only normalized courier webhook, event idempotency ও buyer-safe tracking note |
| Real Bkash gateway/webhook | পরবর্তী ধাপ | Provider credentials, callback contract ও server endpoint প্রয়োজন |
| Delivery carrier integration | পরবর্তী ধাপ | Carrier/API নির্বাচন এবং carrier-specific tracking workflow প্রয়োজন |

## সম্পন্ন server-side controls

Order status-এর জন্য `pending → confirmed → processing → shipped → delivered` ধারাবাহিকতা enforce করা হয়েছে। Shipment-এর পরে vendor cancellation নিষিদ্ধ; pending, confirmed বা processing পর্যায়ে vendor cancellation করলে reserved stock release হয়। Buyer tracking-এর জন্য `order_status_events` table participant-only read policy ব্যবহার করে।

Payment foundation-এ `order_groups` ও `order_records`-এ server-owned `payment_status`, `payment_reference` এবং `paid_at` যোগ হয়েছে। `payment_transactions` audit table-এ order amount, method, state, provider reference, provider event ID এবং confirmation time রাখা হয়। `confirm_order_payment` client-authenticated execution থেকে বন্ধ; এটি কেবল trusted Supabase `service_role`-এর জন্য executable রাখা হয়েছে। একই `provider + event_id` দ্বিতীয়বার এলে idempotentভাবে আগের order state ফেরত আসে, এবং paid/refunded state-এ অবৈধ regression বন্ধ থাকে।

Admin moderation-এ কোনো `public.users` role lookup ব্যবহার করা হয়নি। `is_admin()` Supabase JWT-এর `app_metadata.role = admin` দেখে। Vendor verification এবং Paikari local product approval status পরিবর্তনের জন্য আলাদা server-authorized RPC ব্যবহার হয়েছে। Payment reconciliation শুধু server-recorded transaction read করে; client থেকে payment status পরিবর্তনের কোনো admin UI নেই। Origen master rows admin local-product approval RPC দ্বারা পরিবর্তনযোগ্য নয়।

Returns/disputes foundation-এ delivered order-এর buyer return request, vendor response এবং admin-only refunded state আছে। `order_notifications` order status, courier tracking ও return status থেকে participant-specific in-app update তৈরি করে। Notification read marking-ও owner-scoped RPC-এর মাধ্যমে হয়; direct notification mutation বন্ধ।

## Flutter Android UX

Buyer Profile-এ recent updates, order card tracking timeline এবং delivered order-এর Return request action আছে। Home app bar-এ unread notification badge এবং dedicated notification inbox আছে। Product cards/search/catalog views supplier name, SKU ও buyer-safe available quantity ব্যবহার করে; Cart-এ B2B/B2C context এবং server revalidation notice দেখায়। Vendor Center-এ next status, shipment-এর আগে cancellation action, shipped করার সময় courier/tracking details এবং return response queue আছে। Courier metadata buyer-safe timeline event ও notification হিসেবে দেখা যায়। Checkout success state server-returned payment status দেখায়। Bkash নির্বাচন করলে UI স্পষ্টভাবে জানায় যে gateway confirmation এখনও চালু হয়নি এবং order paid হিসেবে গণ্য হবে না। Admin Center route `/admin/moderation`-এ vendor/product moderation, payment reconciliation এবং returns/disputes resolution আছে; route-এ ঢুকলেও backend `is_admin()` false হলে moderation data দেখানো হয় না।

## নিরাপত্তা সীমা

> UI-কে কখনোই price, total, stock, vendor ownership, payment confirmation বা admin privilege-এর source of truth ধরা হয়নি।

Direct inserts/updates সাধারণ authenticated client-এর জন্য বন্ধ রাখা হয়েছে যেখানে mutation RPC-এর প্রয়োজন। Tracking ও payment history participant/buyer policies দ্বারা সীমিত। Admin status change JWT app metadata যাচাই ছাড়া চলবে না। Payment gateway যোগ করার আগে webhook signature verification, idempotency key, provider reference uniqueness এবং refund state machine আলাদা করে harden করা উচিত।

## Live verification

Paikari Supabase project-এ order-status tracking migration, tracking backfill, payment foundation, payment-trigger correction, service-role grant এবং admin moderation migration সফলভাবে apply হয়েছে। Live read-only audit-এ status-event/payment/quote session-এর participant policies এবং order/payment trigger উপস্থিতি যাচাই করা হয়েছে।

## স্থানীয় validation checklist

Sandbox-এ Flutter/Dart executable নেই। তাই Android build, analyzer ও device test এখান থেকে চালানো হয়নি। Local Flutter environment-এ এখন চালাতে হবে:

```bash
flutter pub get
dart format lib
flutter analyze
flutter test
flutter build apk --debug
```

তারপর অন্তত দুইটি authenticated test identity দিয়ে এই flow পরীক্ষা করা উচিত: verified local vendor product → buyer RFQ → vendor quote → buyer accept → quote checkout → pending order → vendor confirm → processing → shipped → delivered। আলাদা test order দিয়ে vendor cancellation, buyer cancellation, insufficient stock, expired quote, repeated quote checkout, courier details, delivered-order return request, vendor return response, notification read marking, admin reconciliation এবং Bkash pending state যাচাই করতে হবে।

## পরবর্তী বাস্তব milestone

পরবর্তী business-critical ধাপ হলো একটি নির্দিষ্ট Bangladesh payment provider নির্বাচন করে sandbox payment flow তৈরি করা। Provider নির্বাচন না হওয়া পর্যন্ত কোনো secret, merchant credential বা callback URL codebase-এ যোগ করা উচিত নয়। এরপর provider-specific webhook signature verification, callback endpoint এবং payment reconciliation যোগ করা যাবে। Delivery carrier integration ও admin dispute view-এর foundation এখন আছে; live carrier token, parcel booking এবং provider-specific callback adapter এখনো configuration-dependent।

## Final release-hardening update — 24 August 2026

শেষ release-hardening pass-এ `sync-origen-catalog` Edge Function-এ anonymous authenticated-user fallback বন্ধ করে কেবল valid `ORIGEN_SYNC_SECRET` অথবা `auth.jwt()->app_metadata.role = 'admin'` JWT path রাখা হয়েছে। Function version 2 active এবং JWT verification enabled।

Live Supabase security-advisor audit-এ পাওয়া anonymous RPC execution exposure remediate করা হয়েছে। Buyer/vendor/admin RPC-গুলো এখন কেবল `authenticated` role-এর জন্য executable; internal trigger-only helpers এবং `confirm_order_payment` client roles থেকে revoked। `b2c_products` এবং `b2b_products` view-এ `security_invoker=true` সেট করা হয়েছে, ফলে view query-তে base-table RLS caller role অনুযায়ী কার্যকর হবে। Direct live verification-এ anonymous `place_order_group_from_cart` ও `rls_auto_enable` execution false এবং authenticated order RPC execution true পাওয়া গেছে।

Live-এ প্রয়োগ করা migration দুটি হলো `least_privilege_rpc_views` এবং `internal_rpc_privilege_cleanup`। Source repository-তে এগুলো যথাক্রমে `20260824132000_least_privilege_rpc_views.sql` এবং `20260824133000_internal_rpc_privilege_cleanup.sql` হিসেবে রাখা হয়েছে। শেষ code push `986dbdc`।

Security advisor-এ অবশিষ্ট authenticated SECURITY DEFINER warnings ইচ্ছাকৃত: এগুলো client-facing RPC হলেও প্রতিটি function-এর ভিতরে buyer/vendor/admin ownership বা role validation আছে, আর server-authoritative transaction ও RLS enforcement বজায় রাখতে SECURITY DEFINER প্রয়োজন। `shipping_settings` এবং `stock_movements`-এর RLS-without-policy notices-ও intentional private tables; client roles-এর access নেই।


## Auth profile repair — 24 August 2026
নতুন live audit-এ দেখা যায় যে `public.users` table অনুপস্থিত ছিল, অথচ Supabase Auth-এর পরে profile read/insert/update flow এই table ব্যবহার করে। এটি login-এর পরে profile bootstrap-এর বাস্তব blocker ছিল। `20260824150000_create_auth_profile_users.sql` migration-এ secure `public.users` table, own-row RLS policies এবং profile trigger যোগ করা হয়েছে এবং live Supabase-এ সফলভাবে apply হয়েছে।

Live verification-এ `public.users`-এর RLS enabled এবং কেবল authenticated own-row `SELECT`, `INSERT`, `UPDATE` policies পাওয়া গেছে। Anonymous access ও authenticated delete বন্ধ। Profile trigger client-কে role বা KYC verification নিজে elevate করতে দেয় না; admin authorization এখনও `auth.jwt()->app_metadata->>'role'`-ভিত্তিক এবং `public.users` admin privilege-এর উৎস নয়।

## Bangla QR payment boundary — 24 August 2026
Bangla QR checkout method এখন cart এবং accepted-quote checkout উভয় flow-এ server-validated। `order_groups`, `order_records` এবং `payment_transactions`-এর allowlist-এ `Bangla QR` যোগ হয়েছে; initial payment state `pending` হয়। Acquiring bank/PSP callback বা trusted transaction-query ছাড়া order `paid` করা যাবে না। Merchant ID, provider API, callback signing এবং settlement credentials না থাকায় কোনো fake QR payload বা live gateway activation করা হয়নি।


## Android UI polish pass — 24 August 2026
Shared Material 3 theme-এ Bangla typography hierarchy, app bar, input fields, primary/secondary buttons, chips, dividers, list tiles, progress indicators এবং floating snackbars-এর consistent design tokens যোগ করা হয়েছে। Product card-এ screen-reader label ও tap hint যোগ হয়েছে; shimmer loading theme-aware হয়েছে; authenticated profile-load failure-এ clear retry state দেখানো হয়েছে। Checkout ও quote checkout-এ Bangla QR pending notice বজায় রেখে payment selection hierarchy consistent করা হয়েছে।


## High-value buyer features — 24 August 2026
Facebook/WhatsApp campaign-এর জন্য `/p/<slug>` product route, vendor-এর optional readable slug field এবং Android HTTPS intent filters যোগ করা হয়েছে। Product detail থেকে product link clipboard-এ copy করা যায়। Catalog-এ availability/wholesale filters এবং latest/price/MOQ sorting যোগ হয়েছে।

Checkout-এ buyer নিজের saved delivery address select করতে বা পরেরবারের জন্য own-account address save করতে পারে; live `saved_addresses` table-এ authenticated own-row RLS আছে। Product model এখন multiple images parse করে এবং detail page swipe gallery দেখায়; vendor form comma-separated image URLs নেয়। Previous order card থেকে current catalog re-fetch করে unavailable items বাদ দিয়ে reorder করা যায়, ফলে পুরনো client-side price বা stock authoritative হিসেবে ব্যবহৃত হয় না।


## Seller-buyer chat — 24 August 2026
Product detail থেকে B2C/B2B buyer seller chat শুরু করতে পারে; buyer profile-এ Seller chats inbox এবং Home app bar-এ unread chat badge যোগ হয়েছে। Vendor Center-এ Buyer chats shortcut আছে। Conversation product-centric, inbox row-তে product name/image snapshot, message bubble, timestamp, composer, read state এবং retry/empty states আছে। Inquiry/quotation workflow অপরিবর্তিত রেখে chat আলাদা lightweight communication layer হিসেবে রাখা হয়েছে।

Live Supabase-এ `chat_conversations` ও `chat_messages` table RLS-enabled। Conversation read ও message read কেবল participant-এর জন্য; create/send/read RPC-তে authenticated-only execution, participant checks, active approved Paikari product ownership validation এবং 2,000-character message limit আছে। Chat tables Supabase Realtime publication-এ যুক্ত হয়েছে। Live verification-এ anonymous RPC execution false এবং authenticated execution true পাওয়া গেছে।
