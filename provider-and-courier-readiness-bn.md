# Payment ও courier readiness

**লেখক:** Manus AI  
**Project:** Paikari.shop

## উদ্দেশ্য

Paikari-এর mobile client কখনো payment confirmation, provider secret, courier token বা order total-এর source of truth হবে না। Mobile app কেবল server-created order group, shipping information এবং payment method পাঠাবে। Provider ও courier callback server-side Edge Function-এ signature/token validation-এর পর normalized event contract-এ রূপান্তরিত হবে।

## Payment provider boundary

বর্তমানে Paikari-তে COD এবং pending online-payment state আছে। `supabase/functions/payment-webhook/index.ts` raw body-এর HMAC-SHA256 signature যাচাই করে এবং shared `supabase/functions/_shared/payment_adapter.ts` normalized event validation boundary হিসেবে ব্যবহার করে। এরপর webhook server-only `confirm_order_payment` RPC call করে। একই provider event পুনরায় এলে database idempotency protection কার্যকর থাকে।

Official bKash developer material-এ hosted page, token-based payment এবং server notification-এর মতো integration modes উল্লেখ আছে [1]। SSLCOMMERZ-এর official developer page-এ session creation, IPN listener, validation API এবং callback flow উল্লেখ আছে [2]। এই পার্থক্যের কারণে provider-specific mapping না লিখে কোনো gateway activation করা নিরাপদ নয়।

| Provider path | Adapter-এ যা লাগবে | Production activation-এর আগে |
|---|---|---|
| bKash | Create payment, execute/query, callback notification ও server validation mapping | Merchant account, sandbox credentials, callback secret/signature rules |
| SSLCOMMERZ | Session API, GatewayPageURL redirect, IPN listener, validation API ও success/fail callback mapping | Store credentials, IPN URL, validation response rules ও TLS 1.2+ deployment |
| Nagad বা অন্য provider | Provider-এর official create/verify/callback mapping | Official documentation ও merchant sandbox access |

## Courier boundary

`vendor_orders`-এ courier provider, tracking number, courier status, event ID এবং last update time রাখা হয়। `sync_courier_tracking_event` RPC কেবল `service_role`-এর জন্য executable। এটি tracking number দিয়ে vendor order খুঁজে provider event idempotently সংরক্ষণ করে এবং buyer-visible tracking note তৈরি করে; canonical order status transition bypass করে না।

`supabase/functions/courier-webhook/index.ts` provider-neutral HMAC callback receiver হিসেবে প্রস্তুত। কোনো নির্দিষ্ট courier-এর raw callback এই endpoint-এ সরাসরি পাঠানোর আগে provider adapter-কে তার official token/signature rule validate করে normalized payload তৈরি করতে হবে।

Official RedX OpenAPI page-এ sandbox এবং production base URL, parcel create/info/track, area lookup এবং webhook callback structure documented আছে [3]। Pathao-এর official courier page-এ nationwide delivery, live parcel tracking, COD এবং parcel return service-এর কথা বলা হয়েছে [4]। এই মুহূর্তে কোনো courier merchant token codebase-এ রাখা হয়নি।

## Normalized courier payload

```json
{
  "tracking_number": "COURIER_TRACKING_ID",
  "provider": "redx",
  "event_id": "provider-event-123",
  "status": "picked_up",
  "message": "পার্সেল পিকআপ সম্পন্ন হয়েছে"
}
```

## নিরাপদ deployment sequence

প্রথমে sandbox account ও credentials environment secret হিসেবে configure করতে হবে। এরপর provider-specific adapter-এ official callback verification লিখে normalized endpoint-এ mapping করতে হবে। একটি test order দিয়ে duplicate callback, invalid signature, unknown tracking number, out-of-order status এবং retry behavior যাচাই করতে হবে। সব validation সফল হলে production secret আলাদা environment-এ সেট করে deploy করা যাবে। Mobile APK-তে কোনো service-role key, payment secret, courier token বা webhook secret রাখা যাবে না।

## বর্তমান সীমা

এই repository batch provider-neutral boundary ও server contracts প্রস্তুত করেছে, কিন্তু real payment capture, refund API, courier parcel booking এবং live carrier status polling চালু করেনি। এগুলো merchant/provider configuration পাওয়ার পর আলাদা ছোট adapter change হিসেবে যোগ করা উচিত।

## References

[1]: https://developer.bka.sh/ "bKash Developer Portal — Online Payment Solutions"

[2]: https://developer.sslcommerz.com/ "SSLCOMMERZ Developers — API and IPN Integration"

[3]: https://redx.com.bd/developer-api/ "REDX OpenAPI Documentation"

[4]: https://pathao.com/courier/ "Pathao Courier — Services and Merchant Delivery"
