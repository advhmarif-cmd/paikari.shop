# Bangla QR payment readiness

## Official/reference findings

Bangladesh Bank-এর official circular index-এ 2021 সালের Payment Systems Department circular হিসেবে `Guidelines for 'Bangla QR' Code Based Payments` তালিকাভুক্ত আছে। সরাসরি official guideline PDF: https://www.bb.org.bd/mediaroom/circulars/psd/jan062021psd01.pdf । এতে Bangla QR-এর issuing/acquiring institution boundary, non-proprietary/interoperable standard এবং static Bangla QR-এর transaction-limit বিষয় উল্লেখ আছে। এটি Bangla QR-এর regulator-level guideline source। Official index: https://www.bb.org.bd/en/index.php/mediaroom/circular/59

SSLCOMMERZ-এর Bangla QR implementation page অনুযায়ী Bangla QR Bangladesh Bank guideline-compliant interoperable QR payment acceptance method। Merchant customer-এর QR-enabled app দিয়ে code scan করে amount enter ও OTP/passcode authorization করে payment করতে পারে; merchant account-এ funds receive করে। একই page-এ POS/MIS-এর সঙ্গে API integration, transaction management/reporting এবং settlement workflow-এর কথা বলা আছে। Reference: https://sslcommerz.com/bangla-qr/

## Official guideline details

Bangladesh Bank guideline-এ Acquirer হিসেবে bank/MFS/PSP/PSO merchant enrolment, merchant ID/record/account এবং merchant fund settlement পরিচালনা করে; Issuer customer-এর account/card/MFS/e-wallet থেকে QR payment facilitate করে; transaction processor off-us transaction route ও settlement position process করে। Third-party payment aggregator সরাসরি onboard করলে Bangladesh Bank PSO licensing boundary প্রযোজ্য হতে পারে। Bangla QR Merchant-Presented Mode-এর issuer, acquirer, processor, aggregator, customer ও merchant—সব অংশগ্রহণকারীর জন্য প্রযোজ্য।

Guideline অনুযায়ী successful transaction issuer-authorize করবে এবং customer ও merchant-কে transaction completion information instant notification দিতে হবে। Bangladesh Bank network-এ processed transaction next business day settlement হতে পারে; issuer/acquirer account policy অনুযায়ী transaction limit নির্ধারণ করতে পারে। Bangla QR EMVCo-based security controls, merchant awareness, customer-এর merchant-name verification এবং Bangladesh Bank/BFIU compliance-এর সঙ্গে চালাতে হবে। Acquirer-এর MDR customer-এর ওপর pass-through করা যাবে না; on-us ও off-us transaction-এর dispute-management procedure থাকতে হবে।

## Paikari implementation boundary

Bangla QR নিজে একক gateway credential নয়; Paikari-কে একটি acquiring bank বা PSP/aggregator-এর merchant onboarding, merchant ID, QR payload/terminal details, payment status query বা callback API, settlement account এবং reconciliation contract নিতে হবে। Provider contract না পাওয়া পর্যন্ত payment confirmation client-side বা screenshot/manual claim দিয়ে করা যাবে না।

Existing Paikari payment contract তাই রাখা হবে: checkout server-side order তৈরি করবে, payment initially `pending`/`unpaid` থাকবে, trusted server-side provider callback normalized event তৈরি করবে, provider event idempotency যাচাই হবে, এবং service-role-only confirmation RPC-এর মাধ্যমে order payment state বদলাবে। Bangla QR adapter কেবল provider-specific request/response normalization করবে; service role বা secret Flutter APK-তে যাবে না।

## Activation blockers

Merchant acquiring bank/PSP selection, merchant account/MID, official API or hosted flow documentation, callback/webhook or transaction-query capability, signing/HMAC requirements, settlement and refund rules, sandbox credentials এবং production support contact এখনও প্রয়োজন। এই তথ্য ছাড়া source code-এ fake endpoint, fake merchant ID বা guessed Bangla QR payload যোগ করা হবে না.

## Current Paikari gap

বর্তমান checkout ও database payment constraint-এ `Cash on Delivery` এবং `Bkash` আছে; Bangla QR-এর জন্য নতুন server-validated payment method যোগ করতে হবে। Bangla QR যোগ করার সময় order `pending`/`unpaid` থেকে শুরু হবে এবং provider-authorized callback বা transaction verification ছাড়া `paid` হবে না। Static merchant-presented QR-এর ক্ষেত্রে buyer-entered amount order-bound প্রমাণ নয়; তাই acquiring provider-এর dynamic/order-linked flow বা verified transaction-query/callback না পাওয়া পর্যন্ত manual payment screenshot-কে confirmation হিসেবে গ্রহণ করা যাবে না। বর্তমান database `payment_transactions.payment_method` constraint এবং initial-payment trigger-এ শুধু `Cash on Delivery`/`Bkash` ধরে; Bangla QR-এর জন্য নতুন server migration-এ অনুমোদিত method ও `pending` initialization যোগ করতে হবে।
