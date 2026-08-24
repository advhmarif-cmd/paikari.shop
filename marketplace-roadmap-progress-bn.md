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
| Real Bkash gateway/webhook | পরবর্তী ধাপ | Provider credentials, callback contract ও server endpoint প্রয়োজন |
| Delivery carrier integration | পরবর্তী ধাপ | Carrier/API নির্বাচন এবং tracking-number workflow প্রয়োজন |

## সম্পন্ন server-side controls

Order status-এর জন্য `pending → confirmed → processing → shipped → delivered` ধারাবাহিকতা enforce করা হয়েছে। Shipment-এর পরে vendor cancellation নিষিদ্ধ; pending, confirmed বা processing পর্যায়ে vendor cancellation করলে reserved stock release হয়। Buyer tracking-এর জন্য `order_status_events` table participant-only read policy ব্যবহার করে।

Payment foundation-এ `order_groups` ও `order_records`-এ server-owned `payment_status`, `payment_reference` এবং `paid_at` যোগ হয়েছে। `payment_transactions` audit table-এ order amount, method, state, provider reference ও confirmation time রাখা হয়। `confirm_order_payment` client-authenticated execution থেকে বন্ধ; এটি কেবল trusted Supabase `service_role`-এর জন্য executable রাখা হয়েছে, যাতে ভবিষ্যৎ gateway webhook server-side confirmation করতে পারে।

Admin moderation-এ কোনো `public.users` role lookup ব্যবহার করা হয়নি। `is_admin()` Supabase JWT-এর `app_metadata.role = admin` দেখে। Vendor verification এবং Paikari local product approval status পরিবর্তনের জন্য আলাদা server-authorized RPC ব্যবহার হয়েছে। Origen master rows admin local-product approval RPC দ্বারা পরিবর্তনযোগ্য নয়।

## Flutter Android UX

Buyer Profile-এ order card tap করলে tracking timeline খোলে। Vendor Center-এ next status এবং shipment-এর আগের cancellation action আছে। Checkout success state server-returned payment status দেখায়। Bkash নির্বাচন করলে UI স্পষ্টভাবে জানায় যে gateway confirmation এখনও চালু হয়নি এবং order paid হিসেবে গণ্য হবে না। Admin Center route `/admin/moderation` রাখা হয়েছে; route-এ ঢুকলেও backend `is_admin()` false হলে moderation data দেখানো হয় না।

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

তারপর অন্তত দুইটি authenticated test identity দিয়ে এই flow পরীক্ষা করা উচিত: verified local vendor product → buyer RFQ → vendor quote → buyer accept → quote checkout → pending order → vendor confirm → processing → shipped → delivered। আলাদা test order দিয়ে vendor cancellation, buyer cancellation, insufficient stock, expired quote, repeated quote checkout এবং Bkash pending state যাচাই করতে হবে।

## পরবর্তী বাস্তব milestone

পরবর্তী business-critical ধাপ হলো একটি নির্দিষ্ট Bangladesh payment provider নির্বাচন করে sandbox payment flow তৈরি করা। Provider নির্বাচন না হওয়া পর্যন্ত কোনো secret, merchant credential বা callback URL codebase-এ যোগ করা উচিত নয়। এরপর delivery tracking number, buyer/vendor notification-ready events এবং admin dispute view যোগ করা যাবে।
