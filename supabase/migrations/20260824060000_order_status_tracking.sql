-- Milestone 4: secure order lifecycle history and fulfillment tracking.

create table if not exists public.order_status_events (
  id uuid primary key default gen_random_uuid(),
  order_group_id uuid not null references public.order_groups(id) on delete cascade,
  vendor_order_id uuid references public.vendor_orders(id) on delete cascade,
  previous_status text,
  new_status text not null check (new_status in ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled')),
  actor_id uuid references auth.users(id) on delete set null,
  actor_type text not null default 'system' check (actor_type in ('buyer', 'vendor', 'admin', 'system')),
  note text,
  created_at timestamptz not null default now()
);

create index if not exists order_status_events_group_created_idx on public.order_status_events (order_group_id, created_at asc);
create index if not exists order_status_events_vendor_created_idx on public.order_status_events (vendor_order_id, created_at asc);

alter table public.order_status_events enable row level security;
drop policy if exists order_status_events_select_participant on public.order_status_events;
create policy order_status_events_select_participant on public.order_status_events for select to authenticated using (
  exists (select 1 from public.order_groups og where og.id = order_group_id and og.buyer_id = auth.uid())
  or exists (select 1 from public.vendor_orders vo where vo.id = vendor_order_id and vo.vendor_id = auth.uid())
);
grant select on public.order_status_events to authenticated;
revoke insert, update, delete on public.order_status_events from anon, authenticated;

create or replace function public.record_order_status_event()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_id uuid := auth.uid();
  v_actor_type text := 'system';
  v_group_id uuid;
  v_vendor_order_id uuid;
  v_previous text;
  v_new text;
begin
  if TG_TABLE_NAME = 'vendor_orders' then
    v_group_id := new.order_group_id;
    v_vendor_order_id := new.id;
    v_previous := case when TG_OP = 'UPDATE' then old.status else null end;
    v_new := new.status;
    if v_actor_id is not null and new.vendor_id = v_actor_id then v_actor_type := 'vendor'; end if;
  else
    v_group_id := new.id;
    v_previous := case when TG_OP = 'UPDATE' then old.status else null end;
    v_new := new.status;
    if v_actor_id is not null and new.buyer_id = v_actor_id then v_actor_type := 'buyer'; end if;
  end if;

  if TG_OP = 'INSERT' or v_previous is distinct from v_new then
    insert into public.order_status_events(order_group_id, vendor_order_id, previous_status, new_status, actor_id, actor_type, note)
    values(v_group_id, v_vendor_order_id, v_previous, v_new, v_actor_id, v_actor_type, case when TG_OP = 'INSERT' then 'Order created' else 'Order status changed' end);
  end if;
  return new;
end;
$$;

drop trigger if exists order_groups_status_event_trigger on public.order_groups;
create trigger order_groups_status_event_trigger
after insert or update of status on public.order_groups
for each row execute function public.record_order_status_event();

drop trigger if exists vendor_orders_status_event_trigger on public.vendor_orders;
create trigger vendor_orders_status_event_trigger
after insert or update of status on public.vendor_orders
for each row execute function public.record_order_status_event();

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

  if p_status = 'cancelled' then
    if v_order.status not in ('pending', 'confirmed', 'processing') then raise exception 'Order cannot be cancelled after shipment'; end if;
  elsif not (
    (v_order.status = 'pending' and p_status = 'confirmed')
    or (v_order.status = 'confirmed' and p_status = 'processing')
    or (v_order.status = 'processing' and p_status = 'shipped')
    or (v_order.status = 'shipped' and p_status = 'delivered')
  ) then
    raise exception 'Invalid status transition from % to %', v_order.status, p_status;
  end if;

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
    when bool_and(status in ('delivered', 'cancelled')) then 'delivered'
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

revoke all on function public.record_order_status_event() from public;
revoke all on function public.update_vendor_order_status(uuid, text) from public;
grant execute on function public.update_vendor_order_status(uuid, text) to authenticated;
