# Transaction Milestone 2 design

## উদ্দেশ্য

একটি cart-এ Origen shared product এবং একাধিক Paikari vendor-এর local product থাকলেও checkout যেন একবারেই নিরাপদভাবে সম্পন্ন হয়, কিন্তু operationally প্রতিটি vendor নিজের অংশের order দেখবে। Buyer-এর কাছে একটি `order_group` থাকবে; vendor-এর জন্য একই group-এর অধীনে এক বা একাধিক `vendor_order` থাকবে।

## Order hierarchy

| Entity | Ownership | Purpose |
|---|---|---|
| `order_groups` | Buyer | Checkout session, overall total, delivery address, payment method, buyer mode, overall status |
| `vendor_orders` | Vendor | Vendor-specific items, subtotal, status, vendor fulfilment workflow |
| `order_records` | Buyer compatibility record | Existing app/order-history compatibility; new checkout group ID reference |
| `stock_movements` | System/admin | Reserve, release, sell and adjustment audit trail |
| `quotation_requests` | Buyer/vendor | RFQ quantity, target price, message, quote status, expiry and vendor response |

## Server-side checkout rules

The new `place_order_group_from_cart` RPC will accept only product IDs, quantities, address, delivery zone, payment method and buyer mode. It will ignore all client prices and totals. For every line it will lock the catalog row, verify active approved status, enforce MOQ, calculate the best applicable tier, check available stock unless backorder is allowed, reserve stock atomically, and snapshot the resulting line data.

The RPC will group lines by `owner_id`. Origen shared rows are platform-master rows and are kept in a platform group with `vendor_id = null`; Paikari local rows are grouped by the verified local vendor owner. A buyer can therefore receive one overall group and multiple vendor order records. The old `place_order_from_cart` function remains for compatibility until the new client flow is fully validated.

## Stock lifecycle

`reserved_quantity` increases in the same transaction as checkout and a `reserve` movement is recorded. Buyer cancellation or an allowed vendor cancellation decrements the reservation and records a `release` movement. A later fulfilment transition will convert reservation into `sale` and decrement `stock_quantity`. The system must never accept a new order when `stock_quantity - reserved_quantity < requested_quantity`, unless `allow_backorder = true`.

## Status model

The buyer-facing group starts at `pending`. Vendor orders start at `pending` and may move through `confirmed`, `processing`, `shipped`, `delivered`, or `cancelled`. The server will reject invalid transitions and only the buyer, the relevant vendor, or an admin can perform the corresponding action.

## RFQ model

B2B buyers can create a quotation request for an active approved local product and verified vendor. The vendor can respond with unit price, minimum quantity, delivery estimate and expiry. The buyer can accept or decline an unexpired quote. Quote acceptance will create a future checkout-ready price snapshot; it will not mutate catalog prices.

## Security boundaries

All order and stock mutation must happen in security-definer RPCs with a fixed `search_path`. Public users can read only active approved catalog views. Buyers can read their own groups, vendor orders attached to their groups, stock movement summaries are private, vendors can read and update only their own vendor orders and their own RFQs, and admins will require an explicit admin role check for moderation operations.

## Scope of this milestone

This milestone implements the order-group/vendor-order schema, atomic reservation and release RPCs, vendor order status RPC, and RFQ storage plus core buyer/vendor operations. Payment settlement, delivery tracking, push notifications, reviews, and full quotation negotiation remain subsequent layers on top of this safe transaction base.
