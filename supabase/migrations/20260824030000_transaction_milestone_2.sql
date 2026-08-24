-- Transaction Milestone 2: multi-vendor orders, stock lifecycle and RFQ.
-- All mutations are server-authoritative security-definer functions.

create extension if not exists pgcrypto;

create table if not exists public.order_groups (
  id uuid primary key default gen_random_uuid(),
  buyer_id uuid not null references auth.users(id) on delete restrict,
  buyer_mode text not null default 'b2c' check (buyer_mode in ('b2c', 'b2b')),
  subtotal numeric not null default 0 check (subtotal >= 0),
  delivery_charge numeric not null default 0 check (delivery_charge >= 0),
  total_amount numeric not null default 0 check (total_amount >= 0),
  shipping_address jsonb not null default '{}'::jsonb,
  payment_method text not null default 'Cash on Delivery',
  status text not null default 'pending' check (status in ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.vendor_orders (
  id uuid primary key default gen_random_uuid(),
  order_group_id uuid not null references public.order_groups(id) on delete cascade,
  vendor_id uuid references auth.users(id) on delete set null,
  vendor_store_name text,
  items jsonb not null default '[]'::jsonb,
  subtotal numeric not null default 0 check (subtotal >= 0),
  delivery_charge numeric not null default 0 check (delivery_charge >= 0),
  total_amount numeric not null default 0 check (total_amount >= 0),
  status text not null default 'pending' check (status in ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.order_records
  add column if not exists order_group_id uuid references public.order_groups(id) on delete set null;

create table if not exists public.stock_movements (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.catalog_products(id) on delete restrict,
  order_group_id uuid references public.order_groups(id) on delete set null,
  vendor_order_id uuid references public.vendor_orders(id) on delete set null,
  movement_type text not null check (movement_type in ('reserve', 'release', 'sale', 'adjustment')),
  quantity integer not null,
  note text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.quotation_requests (
  id uuid primary key default gen_random_uuid(),
  buyer_id uuid not null references auth.users(id) on delete restrict,
  vendor_id uuid not null references auth.users(id) on delete restrict,
  product_id uuid not null references public.catalog_products(id) on delete restrict,
  requested_quantity integer not null check (requested_quantity > 0),
  target_unit_price numeric check (target_unit_price is null or target_unit_price >= 0),
  message text not null default '',
  status text not null default 'open' check (status in ('open', 'quoted', 'accepted', 'declined', 'expired', 'cancelled')),
  quoted_quantity integer check (quoted_quantity is null or quoted_quantity > 0),
  quoted_unit_price numeric check (quoted_unit_price is null or quoted_unit_price >= 0),
  quoted_delivery_charge numeric check (quoted_delivery_charge is null or quoted_delivery_charge >= 0),
  vendor_message text,
  valid_until timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (buyer_id <> vendor_id)
);

create index if not exists order_groups_buyer_created_idx on public.order_groups (buyer_id, created_at desc);
create index if not exists vendor_orders_vendor_status_idx on public.vendor_orders (vendor_id, status, created_at desc);
create index if not exists vendor_orders_group_idx on public.vendor_orders (order_group_id);
create index if not exists stock_movements_product_created_idx on public.stock_movements (product_id, created_at desc);
create index if not exists quotation_requests_buyer_status_idx on public.quotation_requests (buyer_id, status, created_at desc);
create index if not exists quotation_requests_vendor_status_idx on public.quotation_requests (vendor_id, status, created_at desc);

alter table public.order_groups enable row level security;
alter table public.vendor_orders enable row level security;
alter table public.stock_movements enable row level security;
alter table public.quotation_requests enable row level security;

-- No direct insert/update/delete policies are granted for order groups, vendor orders or stock movements.
drop policy if exists order_groups_select_own on public.order_groups;
create policy order_groups_select_own on public.order_groups for select to authenticated using (buyer_id = auth.uid());

drop policy if exists vendor_orders_select_participant on public.vendor_orders;
create policy vendor_orders_select_participant on public.vendor_orders for select to authenticated using (
  vendor_id = auth.uid()
  or exists (select 1 from public.order_groups og where og.id = order_group_id and og.buyer_id = auth.uid())
);

drop policy if exists quotation_requests_select_participant on public.quotation_requests;
create policy quotation_requests_select_participant on public.quotation_requests for select to authenticated using (buyer_id = auth.uid() or vendor_id = auth.uid());

-- Stock movements are private and exposed only through future aggregate RPCs.

grant select on public.order_groups, public.vendor_orders, public.quotation_requests to authenticated;
revoke all on public.stock_movements from anon, authenticated;

create or replace function public.place_order_group_from_cart(
  p_items jsonb,
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
  v_group_id uuid := gen_random_uuid();
  v_item jsonb;
  v_product record;
  v_quantity integer;
  v_unit_price numeric;
  v_subtotal numeric := 0;
  v_delivery numeric := 0;
  v_items jsonb := '[]'::jsonb;
  v_zone text := coalesce(p_shipping_address->>'zone', 'inside');
  v_buyer_mode text := coalesce(p_shipping_address->>'buyer_mode', 'b2c');
  v_order public.order_records;
  v_group record;
  v_vendor_key text;
  v_vendor_id uuid;
  v_vendor_name text;
  v_vendor_items jsonb;
  v_vendor_subtotal numeric;
  v_vendor_order_id uuid;
begin
  if v_user_id is null then raise exception 'Authentication required'; end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) < 1 or jsonb_array_length(p_items) > 50 then raise exception 'Cart is empty or too large'; end if;
  if jsonb_typeof(p_shipping_address) <> 'object' then raise exception 'Shipping address is required'; end if;
  if v_buyer_mode not in ('b2c', 'b2b') then raise exception 'Invalid buyer mode'; end if;
  if p_payment_method not in ('Cash on Delivery', 'Bkash') then raise exception 'Invalid payment method'; end if;

  select charge into v_delivery from public.shipping_settings where zone = v_zone and is_active = true;
  v_delivery := coalesce(v_delivery, 0);

  insert into public.order_groups(id, buyer_id, buyer_mode, subtotal, delivery_charge, total_amount, shipping_address, payment_method, status)
  values(v_group_id, v_user_id, v_buyer_mode, 0, v_delivery, v_delivery, p_shipping_address - 'buyer_mode', p_payment_method, 'pending');

  for v_item in select value from jsonb_array_elements(p_items) as items(value) loop
    begin v_quantity := (v_item->>'quantity')::integer; exception when others then raise exception 'Invalid quantity'; end;
    if (v_item->>'productId') is null or v_quantity is null or v_quantity < 1 or v_quantity > 100 then raise exception 'Invalid cart item'; end if;

    select cp.* into v_product
    from public.catalog_products cp
    where cp.id::text = v_item->>'productId'
      and cp.is_active = true
      and cp.approval_status = 'approved'
    for update;

    if not found then raise exception 'Product is unavailable'; end if;
    if lower(coalesce(v_product.stock_status, '')) not in ('in stock', 'available', 'active') and not coalesce(v_product.allow_backorder, false) then raise exception 'Product is unavailable'; end if;
    if v_buyer_mode = 'b2b' and v_quantity < greatest(coalesce(v_product.moq, 1), 1) then raise exception 'Minimum order quantity is %', greatest(coalesce(v_product.moq, 1), 1); end if;

    select coalesce(
      case when v_buyer_mode = 'b2b' then (
        select (tier->>'price')::numeric
        from jsonb_array_elements(coalesce(v_product.wholesale_tiers, '[]'::jsonb)) as tier
        where (tier->>'minQuantity')::integer <= v_quantity
        order by (tier->>'minQuantity')::integer desc
        limit 1
      ) end,
      coalesce(v_product.sale_price, v_product.retail_price)
    ) into v_unit_price;
    if v_unit_price is null or v_unit_price < 0 then raise exception 'Product price is not configured'; end if;

    if v_product.stock_quantity is not null and not coalesce(v_product.allow_backorder, false) then
      if v_product.stock_quantity - coalesce(v_product.reserved_quantity, 0) < v_quantity then raise exception 'Insufficient stock'; end if;
      update public.catalog_products
      set reserved_quantity = coalesce(reserved_quantity, 0) + v_quantity,
          stock_status = case when stock_quantity - (coalesce(reserved_quantity, 0) + v_quantity) <= 0 then 'Out of Stock' else stock_status end,
          updated_at = now()
      where id = v_product.id;
      insert into public.stock_movements(product_id, order_group_id, movement_type, quantity, note, created_by)
      values(v_product.id, v_group_id, 'reserve', v_quantity, 'Reserved at checkout', v_user_id);
    end if;

    v_subtotal := v_subtotal + v_unit_price * v_quantity;
    v_items := v_items || jsonb_build_array(jsonb_build_object(
      'productId', v_product.id,
      'productName', v_product.name,
      'quantity', v_quantity,
      'unitPrice', v_unit_price,
      'lineTotal', v_unit_price * v_quantity,
      'imageUrl', v_product.image_url,
      'source', v_product.source,
      'vendorId', v_product.owner_id,
      'sku', v_product.sku,
      'moq', greatest(coalesce(v_product.moq, 1), 1),
      'unitLabel', v_product.unit_label,
      'buyerMode', v_buyer_mode,
      'stockReserved', v_product.stock_quantity is not null and not coalesce(v_product.allow_backorder, false)
    ));
  end loop;

  update public.order_groups
  set subtotal = v_subtotal,
      total_amount = v_subtotal + v_delivery,
      updated_at = now()
  where id = v_group_id;

  -- Insert one vendor order per owner_id; Origen master rows use a platform vendor bucket.
  for v_vendor_key in
    select distinct coalesce(item->>'vendorId', 'platform')
    from jsonb_array_elements(v_items) as lines(item)
  loop
    v_vendor_id := case when v_vendor_key = 'platform' then null else v_vendor_key::uuid end;
    v_vendor_items := coalesce((select jsonb_agg(item) from jsonb_array_elements(v_items) as lines(item) where coalesce(item->>'vendorId', 'platform') = v_vendor_key), '[]'::jsonb);
    select coalesce(sum((item->>'lineTotal')::numeric), 0) into v_vendor_subtotal from jsonb_array_elements(v_vendor_items) as lines(item);
    select vp.store_name into v_vendor_name from public.vendor_profiles vp where vp.user_id = v_vendor_id;
    insert into public.vendor_orders(order_group_id, vendor_id, vendor_store_name, items, subtotal, delivery_charge, total_amount, status)
    values(v_group_id, v_vendor_id, coalesce(v_vendor_name, case when v_vendor_id is null then 'Origen platform' else 'Supplier' end), v_vendor_items, v_vendor_subtotal, case when v_vendor_key = 'platform' then v_delivery else 0 end, v_vendor_subtotal + case when v_vendor_key = 'platform' then v_delivery else 0 end, 'pending') returning id into v_vendor_order_id;
    update public.stock_movements sm set vendor_order_id = v_vendor_order_id where sm.order_group_id = v_group_id and sm.vendor_order_id is null and sm.product_id in (select (item->>'productId')::uuid from jsonb_array_elements(v_vendor_items) as lines(item));
  end loop;

  update public.order_groups set updated_at = now() where id = v_group_id returning * into v_group;
  insert into public.order_records(user_id, order_group_id, items, subtotal, delivery_charge, total_amount, shipping_address, payment_method, status, buyer_mode)
  values(v_user_id, v_group_id, v_items, v_subtotal, v_delivery, v_subtotal + v_delivery, p_shipping_address - 'buyer_mode', p_payment_method, 'pending', v_buyer_mode)
  returning * into v_order;
  return v_order;
end;
$$;

create or replace function public.cancel_order_group(p_order_group_id uuid)
returns public.order_groups
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_group public.order_groups;
  v_vendor_order record;
  v_item jsonb;
  v_quantity integer;
  v_product record;
begin
  if v_user_id is null then raise exception 'Authentication required'; end if;
  select * into v_group from public.order_groups where id = p_order_group_id and buyer_id = v_user_id for update;
  if not found then raise exception 'Order group not found'; end if;
  if v_group.status in ('delivered', 'cancelled') then raise exception 'Order cannot be cancelled'; end if;

  for v_vendor_order in select * from public.vendor_orders where order_group_id = p_order_group_id for update loop
    for v_item in select value from jsonb_array_elements(v_vendor_order.items) as lines(value) loop
      v_quantity := (v_item->>'quantity')::integer;
      if coalesce((v_item->>'stockReserved')::boolean, false) then
        select * into v_product from public.catalog_products where id = (v_item->>'productId')::uuid for update;
        if found then
          update public.catalog_products
          set reserved_quantity = greatest(coalesce(reserved_quantity, 0) - v_quantity, 0),
              stock_status = case when stock_quantity is not null and stock_quantity - greatest(coalesce(reserved_quantity, 0) - v_quantity, 0) > 0 and stock_status = 'Out of Stock' then 'In Stock' else stock_status end,
              updated_at = now()
          where id = v_product.id;
          insert into public.stock_movements(product_id, order_group_id, vendor_order_id, movement_type, quantity, note, created_by)
          values(v_product.id, p_order_group_id, v_vendor_order.id, 'release', -v_quantity, 'Released after buyer cancellation', v_user_id);
        end if;
      end if;
    end loop;
    update public.vendor_orders set status = 'cancelled', updated_at = now() where id = v_vendor_order.id;
  end loop;

  update public.order_groups set status = 'cancelled', updated_at = now() where id = p_order_group_id returning * into v_group;
  update public.order_records set status = 'cancelled' where order_group_id = p_order_group_id;
  return v_group;
end;
$$;

create or replace function public.update_vendor_order_status(p_vendor_order_id uuid, p_status text)
returns public.vendor_orders
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_order public.vendor_orders;
  v_item jsonb;
  v_quantity integer;
  v_product record;
  v_group_status text;
begin
  if v_user_id is null then raise exception 'Authentication required'; end if;
  if p_status not in ('confirmed', 'processing', 'shipped', 'delivered', 'cancelled') then raise exception 'Invalid vendor order status'; end if;
  select * into v_order from public.vendor_orders where id = p_vendor_order_id and vendor_id = v_user_id for update;
  if not found then raise exception 'Vendor order not found'; end if;
  if v_order.status in ('delivered', 'cancelled') then raise exception 'Vendor order is already closed'; end if;
  if p_status = 'delivered' then
    for v_item in select value from jsonb_array_elements(v_order.items) as lines(value) loop
      v_quantity := (v_item->>'quantity')::integer;
      if coalesce((v_item->>'stockReserved')::boolean, false) then
        select * into v_product from public.catalog_products where id = (v_item->>'productId')::uuid for update;
        if found then
          update public.catalog_products
          set stock_quantity = greatest(stock_quantity - v_quantity, 0),
              reserved_quantity = greatest(coalesce(reserved_quantity, 0) - v_quantity, 0),
              stock_status = case when greatest(stock_quantity - v_quantity, 0) <= 0 then 'Out of Stock' else 'In Stock' end,
              updated_at = now()
          where id = v_product.id;
          insert into public.stock_movements(product_id, order_group_id, vendor_order_id, movement_type, quantity, note, created_by)
          values(v_product.id, v_order.order_group_id, v_order.id, 'sale', v_quantity, 'Marked delivered', v_user_id);
        end if;
      end if;
    end loop;
  elsif p_status = 'cancelled' then
    for v_item in select value from jsonb_array_elements(v_order.items) as lines(value) loop
      v_quantity := (v_item->>'quantity')::integer;
      if coalesce((v_item->>'stockReserved')::boolean, false) then
        update public.catalog_products
        set reserved_quantity = greatest(coalesce(reserved_quantity, 0) - v_quantity, 0),
            stock_status = case when stock_quantity is not null and stock_quantity - greatest(coalesce(reserved_quantity, 0) - v_quantity, 0) > 0 and stock_status = 'Out of Stock' then 'In Stock' else stock_status end,
            updated_at = now()
        where id = (v_item->>'productId')::uuid;
        insert into public.stock_movements(product_id, order_group_id, vendor_order_id, movement_type, quantity, note, created_by)
        values((v_item->>'productId')::uuid, v_order.order_group_id, v_order.id, 'release', -v_quantity, 'Released after vendor cancellation', v_user_id);
      end if;
    end loop;
  end if;

  update public.vendor_orders set status = p_status, updated_at = now() where id = p_vendor_order_id returning * into v_order;
  select case
    when bool_and(status = 'delivered') then 'delivered'
    when bool_and(status = 'cancelled') then 'cancelled'
    when bool_or(status = 'shipped') then 'shipped'
    when bool_or(status = 'processing') then 'processing'
    when bool_or(status = 'confirmed') then 'confirmed'
    else 'pending'
  end into v_group_status
  from public.vendor_orders where order_group_id = v_order.order_group_id;
  update public.order_groups set status = v_group_status, updated_at = now() where id = v_order.order_group_id;
  update public.order_records set status = v_group_status where order_group_id = v_order.order_group_id;
  return v_order;
end;
$$;

create or replace function public.create_quotation_request(
  p_product_id uuid,
  p_requested_quantity integer,
  p_target_unit_price numeric default null,
  p_message text default ''
)
returns public.quotation_requests
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_product record;
  v_quote public.quotation_requests;
begin
  if v_user_id is null then raise exception 'Authentication required'; end if;
  if p_requested_quantity < 1 then raise exception 'Invalid requested quantity'; end if;
  select cp.* into v_product from public.catalog_products cp where cp.id = p_product_id and cp.is_active = true and cp.approval_status = 'approved' for share;
  if not found or v_product.owner_id is null then raise exception 'Quotation is available only for local supplier products'; end if;
  if v_product.owner_id = v_user_id then raise exception 'Cannot request a quote from yourself'; end if;
  if p_requested_quantity < greatest(coalesce(v_product.moq, 1), 1) then raise exception 'Minimum order quantity is %', greatest(coalesce(v_product.moq, 1), 1); end if;
  if not exists(select 1 from public.vendor_profiles vp where vp.user_id = v_product.owner_id and vp.is_active = true and vp.verification_status = 'verified') then raise exception 'Supplier is not verified'; end if;

  insert into public.quotation_requests(buyer_id, vendor_id, product_id, requested_quantity, target_unit_price, message)
  values(v_user_id, v_product.owner_id, p_product_id, p_requested_quantity, p_target_unit_price, coalesce(p_message, '')) returning * into v_quote;
  return v_quote;
end;
$$;

create or replace function public.respond_to_quotation(
  p_quotation_id uuid,
  p_quoted_quantity integer,
  p_quoted_unit_price numeric,
  p_delivery_charge numeric default 0,
  p_valid_until timestamptz default null,
  p_vendor_message text default ''
)
returns public.quotation_requests
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_quote public.quotation_requests;
begin
  if v_user_id is null then raise exception 'Authentication required'; end if;
  if p_quoted_quantity < 1 or p_quoted_unit_price < 0 or p_delivery_charge < 0 then raise exception 'Invalid quotation'; end if;
  select * into v_quote from public.quotation_requests where id = p_quotation_id and vendor_id = v_user_id for update;
  if not found then raise exception 'Quotation not found'; end if;
  if v_quote.status not in ('open', 'declined') then raise exception 'Quotation cannot be answered'; end if;
  update public.quotation_requests set status = 'quoted', quoted_quantity = p_quoted_quantity, quoted_unit_price = p_quoted_unit_price, quoted_delivery_charge = p_delivery_charge, valid_until = p_valid_until, vendor_message = coalesce(p_vendor_message, ''), updated_at = now() where id = p_quotation_id returning * into v_quote;
  return v_quote;
end;
$$;

create or replace function public.accept_quotation(p_quotation_id uuid)
returns public.quotation_requests
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_quote public.quotation_requests;
begin
  if v_user_id is null then raise exception 'Authentication required'; end if;
  select * into v_quote from public.quotation_requests where id = p_quotation_id and buyer_id = v_user_id for update;
  if not found then raise exception 'Quotation not found'; end if;
  if v_quote.status <> 'quoted' or (v_quote.valid_until is not null and v_quote.valid_until < now()) then raise exception 'Quotation is not valid'; end if;
  update public.quotation_requests set status = 'accepted', updated_at = now() where id = p_quotation_id returning * into v_quote;
  return v_quote;
end;
$$;

revoke all on function public.place_order_group_from_cart(jsonb, jsonb, text) from public;
revoke all on function public.cancel_order_group(uuid) from public;
revoke all on function public.update_vendor_order_status(uuid, text) from public;
revoke all on function public.create_quotation_request(uuid, integer, numeric, text) from public;
revoke all on function public.respond_to_quotation(uuid, integer, numeric, numeric, timestamptz, text) from public;
revoke all on function public.accept_quotation(uuid) from public;
grant execute on function public.place_order_group_from_cart(jsonb, jsonb, text) to authenticated;
grant execute on function public.cancel_order_group(uuid) to authenticated;
grant execute on function public.update_vendor_order_status(uuid, text) to authenticated;
grant execute on function public.create_quotation_request(uuid, integer, numeric, text) to authenticated;
grant execute on function public.respond_to_quotation(uuid, integer, numeric, numeric, timestamptz, text) to authenticated;
grant execute on function public.accept_quotation(uuid) to authenticated;
