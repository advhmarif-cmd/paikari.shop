-- Milestone 3: accepted quotation to secure checkout/order.
-- Quote prices are snapshotted server-side and never read from client input.

create table if not exists public.quote_checkout_sessions (
  id uuid primary key default gen_random_uuid(),
  quotation_id uuid not null references public.quotation_requests(id) on delete restrict,
  buyer_id uuid not null references auth.users(id) on delete restrict,
  vendor_id uuid not null references auth.users(id) on delete restrict,
  product_id uuid not null references public.catalog_products(id) on delete restrict,
  quantity integer not null check (quantity > 0),
  unit_price numeric not null check (unit_price >= 0),
  delivery_charge numeric not null default 0 check (delivery_charge >= 0),
  total_amount numeric not null check (total_amount >= 0),
  status text not null default 'open' check (status in ('open', 'used', 'expired', 'cancelled')),
  expires_at timestamptz not null,
  order_group_id uuid references public.order_groups(id) on delete set null,
  created_at timestamptz not null default now(),
  used_at timestamptz
);

alter table public.quotation_requests
  add column if not exists checkout_session_id uuid,
  add column if not exists accepted_at timestamptz;

create index if not exists quote_checkout_sessions_buyer_status_idx on public.quote_checkout_sessions (buyer_id, status, created_at desc);
create unique index if not exists quote_checkout_sessions_quotation_unique on public.quote_checkout_sessions (quotation_id);
create index if not exists quotation_requests_checkout_session_idx on public.quotation_requests (checkout_session_id);

alter table public.quote_checkout_sessions enable row level security;

drop policy if exists quote_checkout_sessions_select_own on public.quote_checkout_sessions;
create policy quote_checkout_sessions_select_own on public.quote_checkout_sessions for select to authenticated using (buyer_id = auth.uid());

grant select on public.quote_checkout_sessions to authenticated;

create or replace function public.accept_quotation(p_quotation_id uuid)
returns public.quotation_requests
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_quote public.quotation_requests;
  v_product record;
  v_session_id uuid;
  v_expires_at timestamptz;
begin
  if v_user_id is null then raise exception 'Authentication required'; end if;
  select * into v_quote from public.quotation_requests where id = p_quotation_id and buyer_id = v_user_id for update;
  if not found then raise exception 'Quotation not found'; end if;
  if v_quote.status = 'accepted' and v_quote.checkout_session_id is not null then return v_quote; end if;
  if v_quote.status <> 'quoted' then raise exception 'Quotation is not available'; end if;
  if v_quote.valid_until is not null and v_quote.valid_until < now() then
    update public.quotation_requests set status = 'expired', updated_at = now() where id = p_quotation_id;
    raise exception 'Quotation is expired';
  end if;
  if v_quote.quoted_quantity is null or v_quote.quoted_unit_price is null then raise exception 'Quotation is incomplete'; end if;

  select * into v_product from public.catalog_products where id = v_quote.product_id and is_active = true and approval_status = 'approved' for share;
  if not found then raise exception 'Product is unavailable'; end if;
  if v_product.owner_id is null or v_product.owner_id <> v_quote.vendor_id then raise exception 'Supplier no longer owns this product'; end if;
  if v_quote.quoted_quantity < greatest(coalesce(v_product.moq, 1), 1) then raise exception 'Quoted quantity is below MOQ'; end if;

  v_expires_at := coalesce(v_quote.valid_until, now() + interval '7 days');
  insert into public.quote_checkout_sessions(quotation_id, buyer_id, vendor_id, product_id, quantity, unit_price, delivery_charge, total_amount, status, expires_at)
  values(v_quote.id, v_user_id, v_quote.vendor_id, v_quote.product_id, v_quote.quoted_quantity, v_quote.quoted_unit_price, coalesce(v_quote.quoted_delivery_charge, 0), v_quote.quoted_quantity * v_quote.quoted_unit_price + coalesce(v_quote.quoted_delivery_charge, 0), 'open', v_expires_at)
  returning id into v_session_id;

  update public.quotation_requests
  set status = 'accepted', checkout_session_id = v_session_id, accepted_at = now(), updated_at = now()
  where id = v_quote.id
  returning * into v_quote;
  return v_quote;
end;
$$;

create or replace function public.checkout_accepted_quote(
  p_checkout_session_id uuid,
  p_shipping_address jsonb,
  p_payment_method text default 'Cash on Delivery'
)
returns public.order_records
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_session public.quote_checkout_sessions;
  v_quote public.quotation_requests;
  v_product record;
  v_group_id uuid := gen_random_uuid();
  v_group public.order_groups;
  v_order public.order_records;
  v_vendor_order_id uuid;
  v_store_name text;
  v_items jsonb;
begin
  if v_user_id is null then raise exception 'Authentication required'; end if;
  if jsonb_typeof(p_shipping_address) <> 'object' then raise exception 'Shipping address is required'; end if;
  if p_payment_method not in ('Cash on Delivery', 'Bkash') then raise exception 'Invalid payment method'; end if;

  select * into v_session from public.quote_checkout_sessions where id = p_checkout_session_id and buyer_id = v_user_id for update;
  if not found then raise exception 'Quote checkout session not found'; end if;
  if v_session.status <> 'open' then raise exception 'Quote checkout session has already been used'; end if;
  if v_session.expires_at < now() then
    update public.quote_checkout_sessions set status = 'expired' where id = v_session.id;
    raise exception 'Quote checkout session is expired';
  end if;

  select * into v_quote from public.quotation_requests where id = v_session.quotation_id and buyer_id = v_user_id for share;
  if not found or v_quote.status <> 'accepted' then raise exception 'Quotation is not accepted'; end if;

  select cp.* into v_product
  from public.catalog_products cp
  where cp.id = v_session.product_id and cp.is_active = true and cp.approval_status = 'approved'
  for update;
  if not found then raise exception 'Product is unavailable'; end if;
  if v_product.owner_id is null or v_product.owner_id <> v_session.vendor_id then raise exception 'Supplier no longer owns this product'; end if;
  if v_product.stock_quantity is not null and not coalesce(v_product.allow_backorder, false) then
    if v_product.stock_quantity - coalesce(v_product.reserved_quantity, 0) < v_session.quantity then raise exception 'Insufficient stock'; end if;
    update public.catalog_products
    set reserved_quantity = coalesce(reserved_quantity, 0) + v_session.quantity,
        stock_status = case when stock_quantity - (coalesce(reserved_quantity, 0) + v_session.quantity) <= 0 then 'Out of Stock' else stock_status end,
        updated_at = now()
    where id = v_product.id;
    insert into public.stock_movements(product_id, order_group_id, movement_type, quantity, note, created_by)
    values(v_product.id, v_group_id, 'reserve', v_session.quantity, 'Reserved for accepted quotation checkout', v_user_id);
  end if;

  v_items := jsonb_build_array(jsonb_build_object(
    'productId', v_product.id,
    'productName', v_product.name,
    'quantity', v_session.quantity,
    'unitPrice', v_session.unit_price,
    'lineTotal', v_session.unit_price * v_session.quantity,
    'imageUrl', v_product.image_url,
    'source', v_product.source,
    'vendorId', v_session.vendor_id,
    'sku', v_product.sku,
    'moq', greatest(coalesce(v_product.moq, 1), 1),
    'unitLabel', v_product.unit_label,
    'buyerMode', 'b2b',
    'stockReserved', v_product.stock_quantity is not null and not coalesce(v_product.allow_backorder, false),
    'quotationId', v_quote.id,
    'quoteCheckoutSessionId', v_session.id
  ));

  insert into public.order_groups(id, buyer_id, buyer_mode, subtotal, delivery_charge, total_amount, shipping_address, payment_method, status)
  values(v_group_id, v_user_id, 'b2b', v_session.unit_price * v_session.quantity, v_session.delivery_charge, v_session.total_amount, p_shipping_address, p_payment_method, 'pending');

  select vp.store_name into v_store_name from public.vendor_profiles vp where vp.user_id = v_session.vendor_id;
  insert into public.vendor_orders(order_group_id, vendor_id, vendor_store_name, items, subtotal, delivery_charge, total_amount, status)
  values(v_group_id, v_session.vendor_id, coalesce(v_store_name, 'Supplier'), v_items, v_session.unit_price * v_session.quantity, v_session.delivery_charge, v_session.total_amount, 'pending')
  returning id into v_vendor_order_id;

  update public.stock_movements set vendor_order_id = v_vendor_order_id where order_group_id = v_group_id and product_id = v_product.id;

  insert into public.order_records(user_id, order_group_id, items, subtotal, delivery_charge, total_amount, shipping_address, payment_method, status, buyer_mode)
  values(v_user_id, v_group_id, v_items, v_session.unit_price * v_session.quantity, v_session.delivery_charge, v_session.total_amount, p_shipping_address, p_payment_method, 'pending', 'b2b')
  returning * into v_order;

  update public.quote_checkout_sessions set status = 'used', order_group_id = v_group_id, used_at = now() where id = v_session.id;
  return v_order;
end;
$$;

revoke all on function public.accept_quotation(uuid) from public;
revoke all on function public.checkout_accepted_quote(uuid, jsonb, text) from public;
grant execute on function public.accept_quotation(uuid) to authenticated;
grant execute on function public.checkout_accepted_quote(uuid, jsonb, text) to authenticated;
