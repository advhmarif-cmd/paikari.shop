-- Make courier metadata visible through the buyer-safe event timeline.

create or replace function public.record_delivery_tracking_event()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.tracking_number is distinct from old.tracking_number
     or new.courier_name is distinct from old.courier_name
     or new.tracking_url is distinct from old.tracking_url then
    insert into public.order_status_events(order_group_id, vendor_order_id, previous_status, new_status, actor_id, actor_type, note)
    values(
      new.order_group_id,
      new.id,
      old.status,
      new.status,
      auth.uid(),
      case when auth.uid() = new.vendor_id then 'vendor' else 'system' end,
      concat(
        'Courier: ', coalesce(nullif(new.courier_name, ''), 'Not provided'),
        ' · Tracking: ', coalesce(nullif(new.tracking_number, ''), 'Not provided'),
        case when new.tracking_url is null or new.tracking_url = '' then '' else concat(' · ', new.tracking_url) end
      )
    );
  end if;
  return new;
end;
$$;

drop trigger if exists vendor_orders_delivery_tracking_event_trigger on public.vendor_orders;
create trigger vendor_orders_delivery_tracking_event_trigger
after update of courier_name, tracking_number, tracking_url on public.vendor_orders
for each row execute function public.record_delivery_tracking_event();

revoke all on function public.record_delivery_tracking_event() from public;
