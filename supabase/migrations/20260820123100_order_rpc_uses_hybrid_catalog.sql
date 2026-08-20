-- Price orders from the Hybrid B1 catalog rather than the old products table.

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

  if p_payment_method not in ('Cash on Delivery', 'Bkash') then
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
    user_id,
    items,
    subtotal,
    delivery_charge,
    total_amount,
    shipping_address,
    payment_method,
    status
  ) values (
    v_user_id,
    v_items,
    v_subtotal,
    v_delivery,
    v_subtotal + v_delivery,
    p_shipping_address,
    p_payment_method,
    'pending'
  ) returning * into v_order;

  return v_order;
end;
$$;

revoke all on function public.place_order_from_cart(jsonb, jsonb, text) from public;
grant execute on function public.place_order_from_cart(jsonb, jsonb, text) to authenticated;
