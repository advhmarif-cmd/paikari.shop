# Paikari.shop 1688-style marketplace foundation

## Product direction

Paikari.shop is being prepared as a Bangladesh-focused, B2B-first and B2C-enabled marketplace. B2C buyers get a simple retail catalog and checkout. B2B buyers get MOQ, wholesale tier pricing, supplier context, business profile, and inquiry support.

## Live Supabase status

The Paikari Supabase project is `ACTIVE_HEALTHY`. These marketplace migrations are applied:

- `marketplace_foundation`: vendor profiles, business-buyer profiles, SKU/MOQ/stock/negotiation metadata, product inquiries, and ownership RLS.
- `marketplace_order_rules`: `order_records.buyer_mode` plus server-side B2B/B2C pricing selection and MOQ enforcement in `place_order_from_cart`.
- `marketplace_catalog_views`: safe `b2c_products` and `b2b_products` read views containing catalog and wholesale metadata but no customer/order data.
- `verified_vendor_inquiry_policy`: buyer inquiry creation restricted to active, verified suppliers with active approved local products.

The existing Hybrid B1 rules remain: Origen rows are shared master rows, while Paikari rows are locally vendor-owned. New local products are created inactive with `approval_status = pending`. Origen products remain read-only in Paikari.

## Flutter implementation in this milestone

The home catalog now supports a B2C/B2B mode switch, search, category filters, pull-to-refresh, safe empty/error states, and mode-specific catalog views. Product cards and product detail show MOQ, wholesale context, stock availability, source badges, and safe image fallbacks.

Cart items now preserve buyer mode. B2C items use retail pricing; B2B items use the best applicable wholesale tier. Checkout sends buyer mode into the existing server-authoritative RPC and gives early MOQ feedback while the server remains final authority. Stored order history now preserves B2B/B2C mode and line-level supplier/SKU/MOQ metadata.

Buyers can submit a bulk inquiry from a local vendor product detail page. Vendors can create a supplier store profile, submit local products with SKU, MOQ, one wholesale tier, optional stock quantity and negotiability, and see/respond to inquiry records from Vendor Center. Business buyers can create a business profile with buyer type and preferred sourcing categories.

## Mapped but not yet complete

The next transaction-depth milestone must add an order group and vendor-specific order records so a cart containing products from multiple vendors can split operationally. It must also add atomic stock reservation/release, quotation acceptance, payment settlement, delivery tracking, buyer inquiry history, reviews after delivery, wishlist/compare, notifications, and admin moderation.

Supplier storefront detail pages, multiple wholesale-tier editing, product edit/publish controls for vendors, verified vendor administration, and full vendor order status workflows should follow after the order-group model is in place.

## Security rules

Client-provided price, total, MOQ eligibility, stock, vendor ownership, approval state, KYC state, and order status are not trusted. Pricing and MOQ are checked in the server RPC. Vendor and buyer profile rows are self-owned. Public catalog views expose only active approved products. Inquiry creation requires an active verified supplier and an active approved local product.

## Validation limits

Live Supabase project status, migration application, B2C/B2B view reads, order function metadata, and RLS policy presence were verified with bounded queries. The sandbox does not have Flutter or Dart installed, so `flutter pub get`, `dart format`, `flutter analyze`, `flutter test`, and Android device testing still need to run on a Flutter-enabled machine.
