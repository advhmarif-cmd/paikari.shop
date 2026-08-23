# Paikari.shop: 1688-style B2B + B2C roadmap

## Product position

Paikari.shop will be a Bangladesh-focused, B2B-first and B2C-enabled marketplace. B2B buyers will discover suppliers, compare MOQ and wholesale tiers, submit inquiries or quotations, and place bulk orders. B2C buyers will purchase individual units through a simple local checkout with Bangladesh delivery and payment options.

The app will not be a literal China-market clone. It will use 1688’s sourcing patterns—supplier context, MOQ, quantity pricing, product comparison, inquiry, quotation, and vendor ownership—while keeping the local buyer experience simple and supporting COD/Bkash and local delivery.

## Feature-complete map

| Domain | Required capability | Paikari implementation direction |
|---|---|---|
| Identity | Phone OTP, Google, Facebook, profile | Existing Supabase Auth; keep user roles consumer/vendor/admin |
| Buyer modes | Retail and business buyer mode | Buyer can switch intent; B2B mode surfaces MOQ, tiers, supplier and inquiry |
| Discovery | Search, category, filter, sort, pagination | Supabase-safe query layer with active products only |
| Catalog | Shared Origen products and local vendor products | Hybrid B1 remains; Origen rows read-only in Paikari |
| Supplier | Vendor profile, storefront, verification, location, contact | New vendor profile entity and public read model |
| Product | Images, SKU, variants, category, availability | Extend local rows; Origen sync maps safe fields |
| Wholesale | MOQ, tier prices, unit/pack size, wholesale eligibility | Structured metadata with server-side price selection |
| Inventory | Available, reserved, sold, threshold, stock movement | Atomic order reservation and release; no client-side deduction |
| Buyer action | Cart, wishlist, compare, inquiry, RFQ/quotation | Start with inquiry/RFQ; wishlist/compare follow in the next UI slice |
| Orders | Retail checkout, bulk order, split by vendor, status timeline | Server-side RPC creates order group and vendor order records |
| Vendor | Onboarding, KYC/trade license, product CRUD, order inbox | Vendor-owned rows and vendor-only order views via RLS |
| Payments | COD, Bkash, later gateway | COD remains immediate; Bkash remains explicit pending confirmation |
| Delivery | Zone charges, address book, delivery status | Existing shipping settings extended with order-level snapshot |
| Trust | Reviews, seller rating, response time, verification badge | Buyer reviews after delivered order; admin moderation later |
| Admin | Vendor approval, product moderation, order operations, settings | Central admin controls shared catalog and marketplace governance |
| Notifications | Order/status/inquiry alerts | Push/email/SMS later; in-app status first |
| Analytics | Seller sales, buyer order history, admin marketplace metrics | Add after order/vendor entities are stable |

## Delivery phases

### Phase 1: Marketplace foundation

Apply the first secure schema for vendor profiles, product metadata, MOQ, SKU, unit/pack information, inventory quantity fields, buyer business profile, inquiries, and vendor order ownership. Add RLS policies and server-side validation before exposing the new fields in the app.

### Phase 2: Buyer discovery and B2B/B2C experience

Add a search field, category chips, filter/sort controls, B2B/B2C intent selector, MOQ and wholesale tier presentation, supplier context, and a product detail flow that makes the next buyer action obvious.

### Phase 3: Vendor operations

Add vendor onboarding and KYC status, public storefront, vendor product management, stock controls, wholesale tiers, inquiry inbox, and vendor order status operations. Shared Origen products remain read-only for vendors.

### Phase 4: Transaction depth

Replace the current aggregated order-only model with an order group plus vendor-specific order records. Add atomic inventory reservation, cancellation release, B2B quotation acceptance, payment state, delivery state, and buyer order timeline.

### Phase 5: Trust and scale

Add verified vendor signals, reviews after delivery, seller response metrics, wishlist/compare, address book, notifications, analytics, and moderation tooling. Add variants and batch/expiry only when product volume requires them.

## Non-negotiable rules

Client-provided prices, totals, stock, seller ownership, KYC status, and order status must never be trusted. All pricing, MOQ checks, stock reservation, vendor assignment, and order totals must be enforced in Supabase functions or secure server-side paths.

Origen products are catalog-master rows. Paikari vendors can create and edit only `source = 'paikari'` rows that they own. Origen product price, content, active state, and origin mapping remain read-only in Paikari.

B2C must stay simple: single-unit retail purchase, local delivery, and clear checkout. B2B must expose MOQ, tier prices, supplier identity, and inquiry/quotation without forcing a retail buyer through procurement complexity.

## First implementation milestone

The first implementation will focus on the backend-safe marketplace foundation and buyer discovery UI. It will not attempt to ship payments, chat, push notifications, warehouse management, or international freight forwarding in the same change. Those capabilities are mapped explicitly so they are not forgotten, but they will be delivered only after their ownership and transaction rules are implemented correctly.

## References

[1]: https://www.worldfirst.com/nz/blog/ecommerce-seller-resources/the-guide-to-buy-from-1688-outside-china/ "WorldFirst: The Complete Guide to Buy from 1688 Outside China"
[2]: https://www.globalsources.com/knowledge/1688-vs-alibaba-vs-aliexpress/ "Global Sources: 1688 vs Alibaba vs AliExpress"
