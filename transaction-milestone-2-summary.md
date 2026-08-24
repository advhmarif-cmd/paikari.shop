# Transaction Milestone 2 handoff

## Live backend

Paikari Supabase migration `transaction_milestone_2` is applied successfully. It adds:

- `order_groups` for the buyer-level checkout group.
- `vendor_orders` for supplier-specific operational orders.
- `stock_movements` for reserve, release, sale and adjustment audit records.
- `quotation_requests` for RFQ and supplier quotation lifecycle.
- `order_records.order_group_id` for compatibility with the existing buyer order history.

The live RPCs are:

- `place_order_group_from_cart(jsonb, jsonb, text)`
- `cancel_order_group(uuid)`
- `update_vendor_order_status(uuid, text)`
- `create_quotation_request(uuid, integer, numeric, text)`
- `respond_to_quotation(uuid, integer, numeric, numeric, timestamptz, text)`
- `accept_quotation(uuid)`

All are security-definer functions with a fixed `search_path`, and execute access is granted only to `authenticated`. Client prices and totals are ignored. The checkout RPC reads active approved catalog rows, enforces MOQ, calculates B2B/B2C price, locks product rows, checks available stock, reserves stock atomically, groups lines by vendor, and writes the compatibility order record.

## Stock lifecycle

A finite-stock line creates a positive `reserve` movement and increments `reserved_quantity`. Buyer cancellation calls the release RPC and records a negative `release` movement. Vendor delivery converts the reservation into a `sale` movement and decrements `stock_quantity`. Backordered lines are not reserved.

## Flutter changes

Checkout now calls `place_order_group_from_cart` and still returns the existing `Order` model. Order history understands `order_group_id` and `confirmed` status, and buyers can cancel pending/confirmed/processing grouped orders from Profile. Vendor Center now shows vendor-specific orders and advances them through confirmed, processing, shipped and delivered. Delivered/cancelled transitions update stock via the server.

B2B product detail now has Inquiry and RFQ actions for local supplier products. Buyers can create quotation requests and accept a valid quote from Profile. Vendors can see quotation requests in Vendor Center and respond with quantity, unit price, delivery charge, expiry and message. Inquiry and quotation creation are restricted to active approved products and active verified suppliers.

## Remaining product-depth work

This milestone is the transaction foundation, not the final marketplace surface. Remaining work includes multi-tier quote editing, quote-to-checkout price snapshots, buyer/vendor conversation history, admin moderation dashboards, payment settlement, delivery tracking, review-after-delivery, wishlist/compare, notifications, variants, and warehouse-level inventory.

## Validation

The live migration applied successfully. Bounded live checks confirmed the new routines contain buyer-mode/MOQ logic, and the existing marketplace RLS model remains in place. `git diff --check` and control-character checks are required before commit. Flutter and Dart are not installed in the sandbox, so Android build, `dart analyze`, tests and device smoke testing must run on a Flutter-enabled machine.
