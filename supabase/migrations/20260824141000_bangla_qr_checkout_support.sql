-- Add Bangla QR to the server-authoritative checkout boundary.
-- This migration does not invent provider credentials or QR payloads.

alter table public.order_groups
  drop constraint if exists order_groups_payment_method_check,
  add constraint order_groups_payment_method_check
  check (payment_method in ('Cash on Delivery', 'Bkash', 'Bangla QR'));

alter table public.order_records
  drop constraint if exists order_records_payment_method_check,
  add constraint order_records_payment_method_check
  check (payment_method in ('Cash on Delivery', 'Bkash', 'Bangla QR'));

alter table public.payment_transactions
  drop constraint if exists payment_transactions_payment_method_check,
  add constraint payment_transactions_payment_method_check
  check (payment_method in ('Cash on Delivery', 'Bkash', 'Bangla QR'));

create or replace function public.place_order_from_cart(
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
  v_item jsonb;
  v_product record;
  v_quantity integer;
  v_unit_price numeric;
  v_subtotal numeric := 0;
  v_delivery numeric := 0;
  v_items jsonb := '[]'::jsonb;
  v_zone text := coalesce(p_shipping_address->>'zone', 'inside');
  v_order public.order_records;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) < 1 or jsonb_array_length(p_items) > 50 then
    raise exception 'Cart is empty or too large';
  end if;
  if jsonb_typeof(p_shipping_address) <> 'object' then
    raise exception 'Shipping address is required';
  end if;
  if p_payment_method not in ('Cash on Delivery', 'Bkash', 'Bangla QR') then
    raise exception 'Invalid payment method';
  end if;

  select charge into v_delivery
  from public.shipping_settings
  where zone = v_zone and is_active = true;
  v_delivery := coalesce(v_delivery, 0);

  for v_item in select value from jsonb_array_elements(p_items) as items(value) loop
    if (v_item->>'productId') is null then
      raise exception 'Product ID is required';
    end if;
    begin
      v_quantity := (v_item->>'quantity')::integer;
    exception when others then
      raise exception 'Invalid quantity';
    end;
    if v_quantity is null or v_quantity < 1 or v_quantity > 100 then
      raise exception 'Invalid quantity';
    end if;

    select
      cp.id,
      cp.name as product_name,
      cp.retail_price,
      cp.sale_price,
      cp.wholesale_tiers,
      cp.image_url,
      cp.is_active,
      cp.stock_status
    into v_product
    from public.catalog_products cp
    where cp.id::text = v_item->>'productId'
      and cp.is_active = true
    for share;
    if not found or lower(coalesce(v_product.stock_status, '')) not in ('in stock', 'available', 'active') then
      raise exception 'Product is unavailable';
    end if;

    select coalesce(
      (
        select (tier->>'price')::numeric
        from jsonb_array_elements(coalesce(v_product.wholesale_tiers, '[]'::jsonb)) as tier
        where (tier->>'minQuantity')::integer <= v_quantity
        order by (tier->>'minQuantity')::integer desc
        limit 1
      ),
      coalesce(v_product.sale_price, v_product.retail_price)
    ) into v_unit_price;
    if v_unit_price is null or v_unit_price < 0 then
      raise exception 'Product price is not configured';
    end if;

    v_subtotal := v_subtotal + v_unit_price * v_quantity;
    v_items := v_items || jsonb_build_array(jsonb_build_object(
      'productId', v_product.id,
      'productName', v_product.product_name,
      'quantity', v_quantity,
      'unitPrice', v_unit_price,
      'imageUrl', v_product.image_url
    ));
  end loop;

  insert into public.order_records (
    user_id, items, subtotal, delivery_charge, total_amount,
    shipping_address, payment_method, status
  ) values (
    v_user_id, v_items, v_subtotal, v_delivery, v_subtotal + v_delivery,
    p_shipping_address, p_payment_method, 'pending'
  ) returning * into v_order;
  return v_order;
end;
$$;

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
  if p_payment_method not in ('Cash on Delivery', 'Bkash', 'Bangla QR') then raise exception 'Invalid payment method'; end if;

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
  set subtotal = v_subtotal, total_amount = v_subtotal + v_delivery, updated_at = now()
  where id = v_group_id;

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

-- Reassert the intended client execution boundary after replacing functions.
revoke all on function public.place_order_from_cart(jsonb, jsonb, text) from public;
revoke all on function public.place_order_group_from_cart(jsonb, jsonb, text) from public;
grant execute on function public.place_order_from_cart(jsonb, jsonb, text) to authenticated;
grant execute on function public.place_order_group_from_cart(jsonb, jsonb, text) to authenticated;

create or replace function public.set_initial_order_payment_state()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.payment_status := case
    when lower(new.payment_method) in ('bkash', 'bangla qr') then 'pending'
    else 'unpaid'
  end;
  new.payment_reference := null;
  new.paid_at := null;
  return new;
end;
$$;
revoke execute on function public.set_initial_order_payment_state() from public, anon, authenticated;
