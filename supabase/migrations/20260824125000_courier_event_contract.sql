-- Provider-neutral courier event contract.
-- Courier callbacks update delivery metadata and buyer-visible notes only;
-- canonical order status remains controlled by the existing vendor transition RPC.

alter table public.vendor_orders
  add column if not exists courier_provider text,
  add column if not exists courier_event_id text,
  add column if not exists courier_status text,
  add column if not exists courier_updated_at timestamptz;

create unique index if not exists vendor_orders_courier_event_unique_idx
  on public.vendor_orders (courier_provider, courier_event_id)
  where courier_provider is not null and courier_event_id is not null;

create or replace function public.sync_courier_tracking_event(
  p_tracking_number text,
  p_provider text,
  p_event_id text,
  p_courier_status text,
  p_message text default null
)
returns public.vendor_orders
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.vendor_orders;
  v_note text;
begin
  if auth.role() <> 'service_role' then raise exception 'Service role required'; end if;
  if char_length(trim(coalesce(p_tracking_number, ''))) < 2 then raise exception 'Tracking number is required'; end if;
  if char_length(trim(coalesce(p_provider, ''))) < 2 then raise exception 'Courier provider is required'; end if;
  if char_length(trim(coalesce(p_event_id, ''))) < 3 then raise exception 'Courier event ID is required'; end if;
  if exists (select 1 from public.vendor_orders where courier_provider = trim(p_provider) and courier_event_id = trim(p_event_id)) then
    select * into v_order from public.vendor_orders where courier_provider = trim(p_provider) and courier_event_id = trim(p_event_id) limit 1;
    return v_order;
  end if;

  update public.vendor_orders
  set courier_provider = trim(p_provider),
      courier_event_id = trim(p_event_id),
      courier_status = nullif(trim(p_courier_status), ''),
      courier_updated_at = now()
  where tracking_number = trim(p_tracking_number)
  returning * into v_order;
  if not found then raise exception 'Vendor order for tracking number not found'; end if;

  v_note := 'Courier: ' || trim(p_provider) || ' · ' || coalesce(nullif(trim(p_courier_status), ''), 'updated');
  if p_message is not null and trim(p_message) <> '' then v_note := v_note || ' · ' || left(trim(p_message), 300); end if;
  insert into public.order_status_events(order_group_id, vendor_order_id, previous_status, new_status, actor_id, actor_type, note)
  values(v_order.order_group_id, v_order.id, v_order.status, v_order.status, null, 'system', v_note);

  return v_order;
end;
$$;

revoke all on function public.sync_courier_tracking_event(text, text, text, text, text) from public;
revoke execute on function public.sync_courier_tracking_event(text, text, text, text, text) from anon, authenticated;
grant execute on function public.sync_courier_tracking_event(text, text, text, text, text) to service_role;
