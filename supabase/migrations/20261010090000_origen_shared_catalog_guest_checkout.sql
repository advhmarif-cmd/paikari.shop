-- Shared Paikari catalog compatibility for the Origen-Prime landing system.
-- Keeps marketplace tables intact and adds a server-only guest checkout contract.

alter table public.catalog_products
  add column if not exists landing_metadata jsonb not null default '{}'::jsonb;

create or replace function public.create_origen_guest_order_from_cart(
  p_items jsonb,
  p_customer_name text,
  p_customer_phone text,
  p_customer_address text,
  p_delivery_zone text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_item jsonb;
  v_product record;
  v_quantity integer;
  v_unit_price numeric;
  v_subtotal numeric := 0;
  v_delivery numeric := 0;
  v_items jsonb := '[]'::jsonb;
  v_order public.order_records;
  v_first_product_name text;
  v_first_quantity integer;
begin
  if jsonb_typeof(p_items) <> 'array'
    or jsonb_array_length(p_items) < 1
    or jsonb_array_length(p_items) > 20 then
    raise exception 'Cart is empty or too large';
  end if;

  if length(trim(coalesce(p_customer_name, ''))) < 2 then
    raise exception 'Customer name is required';
  end if;

  if length(regexp_replace(coalesce(p_customer_phone, ''), '\s', '', 'g')) < 11 then
    raise exception 'Valid customer phone is required';
  end if;

  if length(trim(coalesce(p_customer_address, ''))) < 8 then
    raise exception 'Customer address is required';
  end if;

  if p_delivery_zone not in ('inside', 'outside') then
    raise exception 'Invalid delivery zone';
  end if;

  select coalesce(s.charge, 0)
    into v_delivery
  from public.shipping_settings s
  where s.zone = p_delivery_zone and s.is_active = true;

  for v_item in select value from jsonb_array_elements(p_items) as items(value) loop
    begin
      if (v_item->>'product_id') is null then
        raise exception 'Product ID is required';
      end if;
      v_quantity := (v_item->>'quantity')::integer;
    exception when others then
      raise exception 'Invalid cart item';
    end;

    if v_quantity is null or v_quantity < 1 or v_quantity > 100 then
      raise exception 'Invalid quantity';
    end if;

    select
      cp.id,
      cp.name,
      cp.sale_price,
      cp.retail_price,
      cp.image_url,
      cp.stock_status,
      cp.moq,
      cp.stock_quantity,
      cp.reserved_quantity
    into v_product
    from public.catalog_products cp
    where cp.id = (v_item->>'product_id')::uuid
      and cp.is_active = true
      and cp.approval_status = 'approved'
    for share;

    if not found or lower(coalesce(v_product.stock_status, '')) not in ('in stock', 'available', 'active') then
      raise exception 'Product is unavailable';
    end if;

    if v_quantity < coalesce(v_product.moq, 1) then
      raise exception 'Minimum order quantity is %', v_product.moq;
    end if;

    if v_product.stock_quantity is not null
      and v_quantity > (v_product.stock_quantity - coalesce(v_product.reserved_quantity, 0))
      then raise exception 'Product quantity is unavailable';
    end if;

    v_unit_price := coalesce(v_product.sale_price, v_product.retail_price);
    if v_unit_price is null or v_unit_price < 0 then
      raise exception 'Product price is not configured';
    end if;

    if v_first_product_name is null then
      v_first_product_name := v_product.name;
      v_first_quantity := v_quantity;
    end if;

    v_subtotal := v_subtotal + v_unit_price * v_quantity;
    v_items := v_items || jsonb_build_array(jsonb_build_object(
      'productId', v_product.id,
      'productName', v_product.name,
      'quantity', v_quantity,
      'unitPrice', v_unit_price,
      'imageUrl', v_product.image_url
    ));
  end loop;

  insert into public.order_records (
    user_id,
    items,
    subtotal,
    delivery_charge,
    total_amount,
    shipping_address,
    payment_method,
    status,
    buyer_mode,
    payment_status
  ) values (
    null,
    v_items,
    v_subtotal,
    v_delivery,
    v_subtotal + v_delivery,
    jsonb_build_object(
      'name', trim(p_customer_name),
      'phone', regexp_replace(trim(p_customer_phone), '\s', '', 'g'),
      'address', trim(p_customer_address),
      'zone', p_delivery_zone,
      'source', 'origen_prime'
    ),
    'Cash on Delivery',
    'pending',
    'b2c',
    'unpaid'
  ) returning * into v_order;

  return jsonb_build_object(
    'id', v_order.id,
    'created_at', v_order.created_at,
    'status', v_order.status,
    'customer_name', trim(p_customer_name),
    'customer_phone', regexp_replace(trim(p_customer_phone), '\s', '', 'g'),
    'customer_address', trim(p_customer_address),
    'delivery_zone', p_delivery_zone,
    'delivery_charge', v_order.delivery_charge,
    'product_title', v_first_product_name,
    'quantity', v_first_quantity,
    'items', v_order.items,
    'total_amount', v_order.total_amount
  );
end;
$$;

revoke all on function public.create_origen_guest_order_from_cart(jsonb, text, text, text, text) from public, anon, authenticated;
grant execute on function public.create_origen_guest_order_from_cart(jsonb, text, text, text, text) to service_role;
