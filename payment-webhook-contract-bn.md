# Provider-neutral payment webhook contract

এই contract কোনো নির্দিষ্ট Bangladesh payment provider-এর API ধরে নেয় না। `supabase/functions/_shared/payment_adapter.ts` হলো normalized event-এর একক validation boundary। ভবিষ্যতের provider adapter প্রথমে provider callback payload থেকে normalized payload তৈরি করবে, তারপর raw normalized JSON body-এর HMAC-SHA256 signature সহ Edge Function-এ পাঠাবে।

## Endpoint contract

| বিষয় | মান |
|---|---|
| Method | `POST` |
| Header | `content-type: application/json` |
| Signature header | `x-paikari-signature` |
| Signature | `PAYMENT_WEBHOOK_SECRET` দিয়ে raw request body-এর lowercase hexadecimal HMAC-SHA256 |
| Required payload | `order_group_id`, `status`, `provider`, `event_id` |
| Optional payload | `provider_reference`, `metadata` |
| Accepted status | `pending`, `paid`, `failed`, `refunded` |

উদাহরণ normalized payload:

```json
{
  "order_group_id": "00000000-0000-4000-8000-000000000001",
  "status": "paid",
  "provider": "provider-name",
  "provider_reference": "gateway-transaction-id",
  "event_id": "gateway-event-id",
  "metadata": {
    "raw_status": "success"
  }
}
```

Edge Function প্রথমে raw body signature verify করে, তারপর shared adapter দিয়ে payload validation করে এবং `service_role` Supabase client দিয়ে `confirm_order_payment` RPC call করে। Mobile client কখনও এই endpoint-এর secret, provider callback signature বা service role key পাবে না।

## Idempotency ও state safety

`event_id` normalized payload-এ বাধ্যতামূলক। একই provider ও event ID পুনরায় এলে database duplicate processing না করে আগের order state ফেরত দেয়। একই event ID অন্য order-এর সঙ্গে ব্যবহার করলে request প্রত্যাখ্যান করা উচিত। `paid` state থেকে `pending` বা `failed` এবং `refunded` state থেকে অন্য state-এ backward transition database function বন্ধ করে।

## Deployment variables

| Variable | কোথায় থাকবে | উদ্দেশ্য |
|---|---|---|
| `SUPABASE_URL` | Edge Function secret | Supabase project URL |
| `SUPABASE_SERVICE_ROLE_KEY` | Edge Function secret | Server-only RPC execution |
| `PAYMENT_WEBHOOK_SECRET` | Edge Function secret | Normalized webhook HMAC verification |

বাস্তব provider callback চালুর আগে provider-এর webhook support, signature algorithm, retry behavior এবং sandbox documentation আলাদাভাবে যাচাই করতে হবে। Provider নির্বাচন না হওয়া পর্যন্ত এই function deploy করা যাবে, কিন্তু `PAYMENT_WEBHOOK_SECRET` ছাড়া এটি `503` দেবে এবং কোনো payment update করবে না।

## Local fixture test

```bash
BODY='{"order_group_id":"00000000-0000-4000-8000-000000000001","status":"paid","provider":"provider-name","provider_reference":"gateway-transaction-id","event_id":"gateway-event-id","metadata":{"raw_status":"success"}}'
SIGNATURE="$(printf '%s' "$BODY" | openssl dgst -sha256 -hmac "$PAYMENT_WEBHOOK_SECRET" -hex | sed 's/^.* //')"
curl -X POST "$SUPABASE_FUNCTION_URL/payment-webhook" \
  -H 'content-type: application/json' \
  -H "x-paikari-signature: $SIGNATURE" \
  --data "$BODY"
```

এই fixture কেবল test UUID ব্যবহার করে। বাস্তব order ID এবং real gateway credentials ছাড়া production payment confirmation পরীক্ষা করা যাবে না।
