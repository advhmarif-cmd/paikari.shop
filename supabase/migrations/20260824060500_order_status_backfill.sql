-- Backfill the current order state into the tracking timeline.

insert into public.order_status_events(order_group_id, vendor_order_id, previous_status, new_status, actor_type, note)
select og.id, null, null, og.status, 'system', 'Tracking history initialized'
from public.order_groups og
where not exists (
  select 1 from public.order_status_events ose
  where ose.order_group_id = og.id and ose.vendor_order_id is null
)
limit 10000;

insert into public.order_status_events(order_group_id, vendor_order_id, previous_status, new_status, actor_type, note)
select vo.order_group_id, vo.id, null, vo.status, 'system', 'Vendor tracking history initialized'
from public.vendor_orders vo
where not exists (
  select 1 from public.order_status_events ose
  where ose.vendor_order_id = vo.id
)
limit 10000;
