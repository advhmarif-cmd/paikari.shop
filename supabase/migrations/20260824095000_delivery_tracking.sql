-- Delivery tracking foundation for vendor fulfillment.

alter table public.vendor_orders
  add column if not exists courier_name text,
  add column if not exists tracking_number text,
  add column if not exists tracking_url text,
  add column if not exists shipped_at timestamptz,
  add column if not exists delivered_at timestamptz;

create index if not exists vendor_orders_tracking_number_idx
  on public.vendor_orders (tracking_number)
  where tracking_number is not null and tracking_number <> '';

create or replace function public.update_vendor_order_fulfillment(
  p_vendor_order_id uuid,
  p_status text,
  p_courier_name text default null,
  p_tracking_number text default null,
  p_tracking_url text default null
)
returns public.vendor_orders
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.vendor_orders;
  v_now timestamptz := now();
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_tracking_url is not null and p_tracking_url <> '' and p_tracking_url !~ '^https?://' then raise exception 'Tracking URL must use http or https'; end if;

  update public.vendor_orders
  set courier_name = coalesce(nullif(trim(p_courier_name), ''), courier_name),
      tracking_number = coalesce(nullif(trim(p_tracking_number), ''), tracking_number),
      tracking_url = coalesce(nullif(trim(p_tracking_url), ''), tracking_url),
      shipped_at = case when p_status = 'shipped' then coalesce(shipped_at, v_now) else shipped_at end,
      delivered_at = case when p_status = 'delivered' then coalesce(delivered_at, v_now) else delivered_at end
  where id = p_vendor_order_id and vendor_id = auth.uid()
  returning * into v_order;
  if not found then raise exception 'Vendor order not found'; end if;

  return public.update_vendor_order_status(p_vendor_order_id, p_status);
end;
$$;

revoke all on function public.update_vendor_order_fulfillment(uuid, text, text, text, text) from public;
grant execute on function public.update_vendor_order_fulfillment(uuid, text, text, text, text) to authenticated;
