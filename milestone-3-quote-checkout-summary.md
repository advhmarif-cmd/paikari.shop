# Milestone 3 — Accepted quotation থেকে নিরাপদ checkout

**প্রকল্প:** Paikari.shop  
**মাইলস্টোন:** Accepted supplier quotation → immutable quote-price checkout → one-time order creation  
**অবস্থা:** Backend live, Flutter integration source-complete, Android build/device validation pending

## উদ্দেশ্য

এই মাইলস্টোনে supplier-এর quotation buyer গ্রহণ করার পর agreed quantity, unit price, delivery charge এবং total server-side snapshot হিসেবে সংরক্ষিত হয়। Buyer এরপর সাধারণ cart checkout-এ quote মেশায় না; একটি আলাদা quote checkout route থেকে shipping address ও payment method পাঠায়। Order তৈরির সময় client কোনো price, quantity, stock, vendor বা total পাঠাতে পারে না।

## Backend lifecycle

| ধাপ | Server-side আচরণ | Client-এর ভূমিকা |
|---|---|---|
| Supplier quote দেয় | `quotation_requests`-এ quoted quantity, unit price, delivery charge, validity রাখা হয় | Buyer quote দেখতে পারে |
| Buyer Accept করে | `accept_quotation(uuid)` quotation lock করে, একটি `quote_checkout_sessions` snapshot তৈরি করে এবং `checkout_session_id` ফেরত দেয় | শুধু quotation ID পাঠায় |
| Quote checkout খোলে | Buyer-owned session থেকে server snapshot পড়া হয়; status ও expiry দেখানো হয় | Snapshot display-only হিসেবে দেখায় |
| Order submit হয় | `checkout_accepted_quote(uuid, jsonb, text)` session lock করে, server price/quantity দিয়ে stock reserve, order group, vendor order ও compatibility order record তৈরি করে | শুধু session ID, shipping address ও payment method পাঠায় |
| সফল order | Session `used`, `order_group_id` এবং `used_at`-সহ চিহ্নিত হয় | Order model দিয়ে success feedback দেখায় |

`accept_quotation` repeat-safe: একই accepted quotation-এর existing checkout session থাকলে নতুন price snapshot না বানিয়ে একই accepted row ফেরত দেয়। Session unique quotation index-এর কারণে একই quotation-এর বিপরীতে দ্বিতীয় snapshot তৈরি হওয়ার সুযোগ নেই।

## Live schema ও security verification

২৪ আগস্ট ২০২৬ তারিখে Paikari Supabase project `mcapstuvnfyyymievjae`-এ read-only verification করা হয়েছে। `quotation_requests.checkout_session_id` এবং `accepted_at` কলাম, পাশাপাশি `quote_checkout_sessions`-এর identity, buyer/vendor/product, quantity, unit price, delivery charge, total, status, expiry এবং used-order fields উপস্থিত আছে। `accept_quotation` ও `checkout_accepted_quote`—দুইটি live PostgreSQL function হিসেবেও পাওয়া গেছে।

`quote_checkout_sessions` table-এ RLS enabled এবং buyer-only select policy `quote_checkout_sessions_select_own` সক্রিয় আছে। Policy-টি `buyer_id = auth.uid()` শর্ত ব্যবহার করে; vendor বা anonymous client session snapshot পড়তে পারে না। RPC-দুটি authenticated role-এর জন্য executable এবং public role থেকে revoke করা হয়েছে।

## Flutter integration

| ফাইল | পরিবর্তন |
|---|---|
| `lib/features/quotations/models/quotation_request.dart` | `checkoutSessionId` ও `acceptedAt` parsing যোগ হয়েছে |
| `lib/features/quotations/models/quote_checkout_session.dart` | Server snapshot-এর typed model এবং `isOpen` lifecycle helper যোগ হয়েছে |
| `lib/features/quotations/repositories/quotation_repository.dart` | Buyer-scoped session fetch যোগ হয়েছে; quotation accept flow unchanged রাখা হয়েছে |
| `lib/features/quotations/providers/quotation_provider.dart` | `quoteCheckoutSessionProvider` যোগ হয়েছে |
| `lib/features/checkout/repositories/supabase_order_repository.dart` | `checkoutAcceptedQuote` RPC call যোগ হয়েছে এবং response existing `Order` model-এ parse হয় |
| `lib/features/quotations/widgets/quote_checkout_sheet.dart` | Dedicated quote checkout UI, server snapshot display, expiry/used state, address/payment form, loading/error/success feedback |
| `lib/features/profile/screens/profile_screen.dart` | Quoted quotation থেকে Accept এবং accepted session থেকে Order action যোগ হয়েছে |
| `lib/main.dart` | Safe typed argument handling-সহ `/quote/checkout` route যোগ হয়েছে |
| `supabase/migrations/20260824040000_quote_to_order.sql` | Live-applied Milestone 3 schema, RLS, acceptance এবং one-time checkout RPC-এর source migration |

Buyer UI agreed delivery charge ও server total দেখায়, কিন্তু এই values submit payload-এ পাঠায় না। Submit payload-এর কার্যকর shape হলো:

```json
{
  "p_checkout_session_id": "<accepted-session-uuid>",
  "p_shipping_address": {
    "phoneNumber": "...",
    "streetAddress": "...",
    "city": "...",
    "state": "...",
    "zipCode": "..."
  },
  "p_payment_method": "Cash on Delivery"
}
```

## Validation ফলাফল

`git diff --check` সফল হয়েছে। Milestone 3 source-এ control-character scan সফল হয়েছে এবং reference scan-এ RPC, session provider, route ও migration references মিলেছে। Working tree-তে Milestone 3-সংশ্লিষ্ট পরিবর্তনগুলিই দেখা গেছে: quotation model/provider/repository, quote checkout model/widget, profile, main route, shared order repository এবং নতুন migration।

এই sandbox-এ Flutter বা Dart executable নেই। তাই `dart format`, `flutter analyze`, `flutter test`, Android build এবং physical-device flow চালানো সম্ভব হয়নি। Local Flutter environment-এ নিচের validation চালানো আবশ্যক:

```bash
flutter pub get
dart format lib supabase
flutter analyze
flutter test
flutter build apk --debug
```

এরপর একটি verified vendor-owned local product এবং buyer account দিয়ে RFQ → vendor quote → buyer Accept → quote checkout → order success flow পরীক্ষা করতে হবে। বর্তমান demo catalog-এর Origen shared product vendor-owned নয়; তাই vendor quote-এর পূর্ণ end-to-end test-এর জন্য verified local vendor product প্রয়োজন।

## ইচ্ছাকৃত সীমা

এই মাইলস্টোনে online payment gateway capture, payment webhook, delivery tracking, admin moderation dashboard এবং notification automation যোগ করা হয়নি। `Bkash` option এখনও payment-method label হিসেবে RPC validation পাস করে; বাস্তব টাকা নেওয়ার আগে আলাদা payment-confirmation milestone প্রয়োজন। Quote order normal cart-এর সঙ্গে মেশে না, কারণ quote-এর immutable price snapshot আলাদা রাখা হয়েছে।

## নিরাপত্তা সিদ্ধান্ত

> Client কখনও quote price, quantity, delivery charge, total, stock বা vendor ownership-এর source of truth নয়।

Server-side session lock, buyer ownership check, expiry check, accepted-quotation check, current product ownership/approval check, MOQ check, stock reservation এবং one-time `used` transition একই transactional RPC-এর মধ্যে রাখা হয়েছে। ফলে UI পরিবর্তন করে কম দামে order বা একই accepted quote দিয়ে দ্বিতীয় order তৈরি করার সুযোগ থাকা উচিত নয়; বাস্তব নিশ্চয়তার শেষ ধাপ হবে স্থানীয় Flutter build এবং authenticated staging-style end-to-end test।
