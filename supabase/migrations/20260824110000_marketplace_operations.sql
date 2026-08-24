-- Marketplace operations foundation: returns, disputes, notifications and reconciliation.

create table if not exists public.return_requests (
  id uuid primary key default gen_random_uuid(),
  order_group_id uuid not null references public.order_groups(id) on delete cascade,
  vendor_order_id uuid references public.vendor_orders(id) on delete cascade,
  buyer_id uuid not null references auth.users(id) on delete cascade,
  product_id uuid references public.catalog_products(id) on delete set null,
  quantity integer not null default 1 check (quantity >= 1),
  reason text not null check (char_length(trim(reason)) >= 3),
  details text not null default '',
  status text not null default 'requested' check (status in ('requested', 'approved', 'rejected', 'received', 'refunded', 'cancelled')),
  resolution_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists return_requests_buyer_idx on public.return_requests (buyer_id, created_at desc);
create index if not exists return_requests_vendor_idx on public.return_requests (vendor_order_id, status, created_at desc);

alter table public.return_requests enable row level security;
drop policy if exists return_requests_select_participant on public.return_requests;
create policy return_requests_select_participant on public.return_requests for select to authenticated using (
  buyer_id = auth.uid()
  or exists (select 1 from public.vendor_orders vo where vo.id = vendor_order_id and vo.vendor_id = auth.uid())
  or public.is_admin()
);
revoke all on public.return_requests from anon, authenticated;
grant select on public.return_requests to authenticated;

create table if not exists public.order_notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references auth.users(id) on delete cascade,
  order_group_id uuid references public.order_groups(id) on delete cascade,
  return_request_id uuid references public.return_requests(id) on delete cascade,
  notification_type text not null check (notification_type in ('order_status', 'payment', 'return', 'system')),
  title text not null,
  body text not null,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists order_notifications_recipient_idx on public.order_notifications (recipient_id, created_at desc);

alter table public.order_notifications enable row level security;
drop policy if exists order_notifications_select_own on public.order_notifications;
create policy order_notifications_select_own on public.order_notifications for select to authenticated using (recipient_id = auth.uid());
revoke all on public.order_notifications from anon, authenticated;
grant select on public.order_notifications to authenticated;

create or replace function public.create_order_status_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_buyer_id uuid;
  v_vendor_id uuid;
begin
  if new.vendor_order_id is null then
    select buyer_id into v_buyer_id from public.order_groups where id = new.order_group_id;
    if v_buyer_id is not null then
      insert into public.order_notifications(recipient_id, order_group_id, notification_type, title, body)
      values(v_buyer_id, new.order_group_id, 'order_status', 'Order status updated', coalesce(new.note, 'Order status changed to ' || new.new_status));
    end if;
  else
    select og.buyer_id, vo.vendor_id into v_buyer_id, v_vendor_id
    from public.vendor_orders vo join public.order_groups og on og.id = vo.order_group_id
    where vo.id = new.vendor_order_id;
    if new.note like 'Courier:%' and v_buyer_id is not null then
      insert into public.order_notifications(recipient_id, order_group_id, notification_type, title, body)
      values(v_buyer_id, new.order_group_id, 'order_status', 'Shipment tracking updated', new.note);
    end if;
    if v_vendor_id is not null then
      insert into public.order_notifications(recipient_id, order_group_id, notification_type, title, body)
      values(v_vendor_id, new.order_group_id, 'order_status', 'Vendor order updated', coalesce(new.note, 'Vendor order status changed to ' || new.new_status));
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists order_status_notification_trigger on public.order_status_events;
create trigger order_status_notification_trigger
after insert on public.order_status_events
for each row execute function public.create_order_status_notification();

create or replace function public.create_return_request(
  p_order_group_id uuid,
  p_vendor_order_id uuid default null,
  p_product_id uuid default null,
  p_quantity integer default 1,
  p_reason text default '',
  p_details text default ''
)
returns public.return_requests
language plpgsql
security definer
set search_path = public
as $$
declare
  v_buyer_id uuid := auth.uid();
  v_request public.return_requests;
  v_vendor_status text;
  v_group_status text;
begin
  if v_buyer_id is null then raise exception 'Authentication required'; end if;
  if p_quantity is null or p_quantity < 1 then raise exception 'Quantity must be positive'; end if;
  if char_length(trim(coalesce(p_reason, ''))) < 3 then raise exception 'Return reason is required'; end if;
  select status into v_group_status from public.order_groups where id = p_order_group_id and buyer_id = v_buyer_id;
  if not found then raise exception 'Order group not found'; end if;
  if p_vendor_order_id is not null then
    select status into v_vendor_status from public.vendor_orders where id = p_vendor_order_id and order_group_id = p_order_group_id;
    if not found then raise exception 'Vendor order does not belong to order group'; end if;
    if v_vendor_status <> 'delivered' then raise exception 'Return is available after delivery'; end if;
  elsif v_group_status <> 'delivered' then
    raise exception 'Return is available after delivery';
  end if;
  if p_product_id is not null then
    if p_vendor_order_id is not null then
      if not exists (
        select 1 from public.vendor_orders vo, jsonb_array_elements(vo.items) as line
        where vo.id = p_vendor_order_id
          and line->>'productId' = p_product_id::text
          and (line->>'quantity')::integer >= p_quantity
      ) then raise exception 'Product does not belong to vendor order'; end if;
    elsif not exists (
      select 1 from public.vendor_orders vo, jsonb_array_elements(vo.items) as line
      where vo.order_group_id = p_order_group_id
        and line->>'productId' = p_product_id::text
        and (line->>'quantity')::integer >= p_quantity
    ) then raise exception 'Product does not belong to order group'; end if;
  end if;
  insert into public.return_requests(order_group_id, vendor_order_id, buyer_id, product_id, quantity, reason, details)
  values(p_order_group_id, p_vendor_order_id, v_buyer_id, p_product_id, p_quantity, trim(p_reason), coalesce(p_details, ''))
  returning * into v_request;
  return v_request;
end;
$$;

create or replace function public.cancel_return_request(p_return_request_id uuid)
returns public.return_requests
language plpgsql
security definer
set search_path = public
as $$
declare
  v_request public.return_requests;
begin
  update public.return_requests
  set status = 'cancelled', updated_at = now()
  where id = p_return_request_id and buyer_id = auth.uid() and status = 'requested'
  returning * into v_request;
  if not found then raise exception 'Return request cannot be cancelled'; end if;
  return v_request;
end;
$$;

create or replace function public.respond_to_return_request(p_return_request_id uuid, p_status text, p_resolution_note text default null)
returns public.return_requests
language plpgsql
security definer
set search_path = public
as $$
declare
  v_request public.return_requests;
  v_is_admin boolean := public.is_admin();
  v_is_vendor boolean := false;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_status not in ('approved', 'rejected', 'received', 'refunded') then raise exception 'Invalid return status'; end if;
  select rr.* into v_request from public.return_requests rr where rr.id = p_return_request_id for update;
  if not found then raise exception 'Return request not found'; end if;
  if v_request.vendor_order_id is not null then
    select exists(select 1 from public.vendor_orders vo where vo.id = v_request.vendor_order_id and vo.vendor_id = auth.uid()) into v_is_vendor;
  end if;
  if not v_is_admin and not v_is_vendor then raise exception 'Return response access denied'; end if;
  if p_status = 'refunded' and not v_is_admin then raise exception 'Only admin can mark refunded'; end if;
  if v_request.status in ('rejected', 'refunded', 'cancelled') then raise exception 'Return request is closed'; end if;
  update public.return_requests set status = p_status, resolution_note = p_resolution_note, updated_at = now() where id = p_return_request_id returning * into v_request;
  return v_request;
end;
$$;

create or replace function public.create_return_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_vendor_id uuid;
  v_title text;
  v_body text;
begin
  if TG_OP = 'INSERT' then
    v_title := 'Return request created';
  elsif old.status is distinct from new.status then
    v_title := 'Return request updated';
  else
    return new;
  end if;
  if TG_OP = 'INSERT' or old.status is distinct from new.status then
    v_body := coalesce(new.resolution_note, 'Return request status: ' || new.status);
    insert into public.order_notifications(recipient_id, order_group_id, return_request_id, notification_type, title, body)
    values(new.buyer_id, new.order_group_id, new.id, 'return', v_title, v_body);
    if new.vendor_order_id is not null then
      select vendor_id into v_vendor_id from public.vendor_orders where id = new.vendor_order_id;
      if v_vendor_id is not null then
        insert into public.order_notifications(recipient_id, order_group_id, return_request_id, notification_type, title, body)
        values(v_vendor_id, new.order_group_id, new.id, 'return', v_title, v_body);
      end if;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists return_request_notification_trigger on public.return_requests;
create trigger return_request_notification_trigger
after insert or update of status on public.return_requests
for each row execute function public.create_return_notification();

create or replace function public.mark_order_notification_read(p_notification_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.order_notifications set read_at = coalesce(read_at, now()) where id = p_notification_id and recipient_id = auth.uid();
end;
$$;

create or replace function public.admin_list_payment_transactions()
returns setof public.payment_transactions
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  return query select pt.* from public.payment_transactions pt order by pt.created_at desc limit 200;
end;
$$;

revoke all on function public.create_order_status_notification() from public;
revoke all on function public.create_return_notification() from public;
revoke all on function public.create_return_request(uuid, uuid, uuid, integer, text, text) from public;
revoke all on function public.cancel_return_request(uuid) from public;
revoke all on function public.respond_to_return_request(uuid, text, text) from public;
revoke all on function public.mark_order_notification_read(uuid) from public;
revoke all on function public.admin_list_payment_transactions() from public;
grant execute on function public.create_return_request(uuid, uuid, uuid, integer, text, text) to authenticated;
grant execute on function public.cancel_return_request(uuid) to authenticated;
grant execute on function public.respond_to_return_request(uuid, text, text) to authenticated;
grant execute on function public.mark_order_notification_read(uuid) to authenticated;
grant execute on function public.admin_list_payment_transactions() to authenticated;
