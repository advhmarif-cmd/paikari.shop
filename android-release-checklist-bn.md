# Paikari.shop Android release checklist

## Release scope

এই build-এ B2B-first/B2C checkout, immutable accepted-quote checkout, vendor order lifecycle, buyer tracking timeline, payment-state foundation, delivery metadata এবং server-authorized admin moderation অন্তর্ভুক্ত। Origen-Prime আলাদা project; এই checklist Paikari Android app-এর জন্য।

## Local commands

```bash
flutter pub get
dart format lib
flutter analyze
flutter test
flutter build apk --debug
```

Debug APK install করার আগে Supabase URL ও anon key-এর environment configuration যাচাই করতে হবে। কোনো service-role key, webhook secret বা payment credential APK-তে রাখা যাবে না।

## Authentication checks

Phone OTP এবং Google sign-in দিয়ে buyer login পরীক্ষা করতে হবে। Login-এর পরে Profile, order list, RFQ এবং quote checkout route কাজ করছে কি না দেখতে হবে। Vendor account-এর জন্য vendor onboarding, profile status এবং local product creation পরীক্ষা করতে হবে।

## Buyer flow checks

| Flow | Expected result |
|---|---|
| B2C cart checkout | Server catalog price/stock দিয়ে order তৈরি হবে |
| B2B cart checkout | MOQ না পূরণ হলে client-side warning এবং server-side enforcement থাকবে |
| Accepted quotation | Quote accept করার পরে immutable session তৈরি হবে |
| Quote checkout | UI snapshot দেখাবে; RPC-তে কেবল session ID, address, payment method যাবে |
| Repeated quote checkout | One-time session ব্যবহৃত হলে দ্বিতীয় order তৈরি হবে না |
| Expired quote | Checkout disabled/error state দেখাবে |
| Buyer cancellation | Allowed lifecycle stage-এ cancellation ও reserved stock release হবে |
| Order tracking | Order card tap করলে chronological status event দেখাবে |

## Vendor flow checks

Verified vendor-এর local product approval pending অবস্থায় public catalog-এ দেখা যাবে না। Vendor Center-এ order pending থেকে confirmed, processing, shipped এবং delivered ধারাবাহিকতায় যাবে। Shipped করার সময় courier name, tracking number এবং optional HTTPS URL দেওয়া যাবে। Shipment-এর পরে vendor cancellation button থাকবে না। Pending, confirmed অথবা processing অবস্থায় cancellation করলে reserved stock release হবে।

## Payment checks

Cash on Delivery order-এর server payment state `unpaid` থাকবে। Bkash selection এখন `pending` state তৈরি করবে; gateway confirmation না হওয়া পর্যন্ত paid দেখানো যাবে না। Webhook contract test করার সময় raw normalized JSON body-এর HMAC signature, provider event ID এবং service-only RPC requirement পরীক্ষা করতে হবে। একই provider ও event ID পুনরায় পাঠালে duplicate payment transition হবে না।

## Admin checks

Supabase Auth user-এর `app_metadata.role` সত্যিই `admin` না হলে `/admin/moderation` route কোনো moderation data দেখাবে না। Admin user vendor verification status এবং শুধু Paikari local product approval status পরিবর্তন করতে পারবে। Origen shared product edit বা approval operation-এর মাধ্যমে পরিবর্তনযোগ্য নয়।

## Release blockers

Flutter analyzer/test/build চালানো না গেলে release অনুমোদন করা যাবে না। কোনো authenticated user অন্য buyer-এর order, payment transaction, quote session বা tracking history পড়তে পারলে release বন্ধ করতে হবে। Client request-এ trusted price, total, vendor ownership, stock বা payment confirmation পাঠানো হলে implementation পুনরায় review করতে হবে।

বর্তমান sandbox-এ Flutter/Dart executable অনুপস্থিত, তাই এই checklist-এর local command ও device section এখানে execute করা হয়নি।
