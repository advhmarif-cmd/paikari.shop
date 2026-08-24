-- Milestone 5 foundation: payment state and audit trail.
-- This does not claim or capture real money; gateway confirmation remains server-only.

create table if not exists public.payment_transactions (
  id uuid primary key default gen_random_uuid(),
  order_group_id uuid not null references public.order_groups(id) on delete cascade,
  amount numeric not null check (amount >= 0),
  payment_method text not null check (payment_method in ('Cash on Delivery', 'Bkash')),
  status text not null check (status in ('unpaid', 'pending', 'paid', 'failed', 'refunded')),
  provider text,
  provider_reference text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  confirmed_at timestamptz
);

alter table public.order_groups
  add column if not exists payment_status text not null default 'unpaid' check (payment_status in ('unpaid', 'pending', 'paid', 'failed', 'refunded')),
  add column if not exists payment_reference text,
  add column if not exists paid_at timestamptz;

alter table public.order_records
  add column if not exists payment_status text not null default 'unpaid' check (payment_status in ('unpaid', 'pending', 'paid', 'failed', 'refunded')),
  add column if not exists payment_reference text,
  add column if not exists paid_at timestamptz;

update public.order_groups
set payment_status = case when lower(payment_method) = 'bkash' then 'pending' else 'unpaid' end
where payment_status = 'unpaid';

update public.order_records
set payment_status = case when lower(payment_method) = 'bkash' then 'pending' else 'unpaid' end
where payment_status = 'unpaid';

create index if not exists payment_transactions_group_created_idx on public.payment_transactions (order_group_id, created_at desc);
create index if not exists payment_transactions_reference_idx on public.payment_transactions (provider, provider_reference);

alter table public.payment_transactions enable row level security;
drop policy if exists payment_transactions_select_buyer on public.payment_transactions;
create policy payment_transactions_select_buyer on public.payment_transactions for select to authenticated using (
  exists (select 1 from public.order_groups og where og.id = order_group_id and og.buyer_id = auth.uid())
);
grant select on public.payment_transactions to authenticated;
revoke insert, update, delete on public.payment_transactions from anon, authenticated;

create or replace function public.sync_order_payment_state()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_status text;
  v_payment_method text;
  v_amount numeric;
  v_should_log boolean := false;
begin
  if TG_TABLE_NAME = 'order_groups' then
    v_status := new.payment_status;
    v_payment_method := new.payment_method;
    v_amount := new.total_amount;
    if TG_OP = 'INSERT' or old.payment_status is distinct from new.payment_status or old.payment_reference is distinct from new.payment_reference then
      v_should_log := true;
    end if;
    update public.order_records
    set payment_status = new.payment_status, payment_reference = new.payment_reference, paid_at = new.paid_at
    where order_group_id = new.id;
  else
    v_status := new.payment_status;
    v_payment_method := new.payment_method;
    v_amount := new.total_amount;
    if TG_OP = 'INSERT' or old.payment_status is distinct from new.payment_status or old.payment_reference is distinct from new.payment_reference then
      v_should_log := true;
    end if;
  end if;

  if v_should_log and new.order_group_id is not null then
    insert into public.payment_transactions(order_group_id, amount, payment_method, status, provider_reference, confirmed_at)
    values(new.order_group_id, v_amount, v_payment_method, v_status, case when v_status in ('paid', 'failed', 'refunded') then new.payment_reference else null end, case when v_status = 'paid' then coalesce(new.paid_at, now()) else null end);
  end if;
  return new;
end;
$$;

create or replace function public.set_initial_order_payment_state()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.payment_status := case when lower(new.payment_method) = 'bkash' then 'pending' else 'unpaid' end;
  new.payment_reference := null;
  new.paid_at := null;
  return new;
end;
$$;

drop trigger if exists order_groups_initial_payment_trigger on public.order_groups;
create trigger order_groups_initial_payment_trigger
before insert on public.order_groups
for each row execute function public.set_initial_order_payment_state();

drop trigger if exists order_records_initial_payment_trigger on public.order_records;
create trigger order_records_initial_payment_trigger
before insert on public.order_records
for each row execute function public.set_initial_order_payment_state();

drop trigger if exists order_groups_payment_sync_trigger on public.order_groups;
create trigger order_groups_payment_sync_trigger
after insert or update of payment_status, payment_reference, paid_at on public.order_groups
for each row execute function public.sync_order_payment_state();

drop trigger if exists order_records_payment_audit_trigger on public.order_records;
create trigger order_records_payment_audit_trigger
after insert or update of payment_status, payment_reference, paid_at on public.order_records
for each row execute function public.sync_order_payment_state();

insert into public.payment_transactions(order_group_id, amount, payment_method, status)
select og.id, og.total_amount, og.payment_method, og.payment_status
from public.order_groups og
where not exists (select 1 from public.payment_transactions pt where pt.order_group_id = og.id)
limit 10000;

create or replace function public.confirm_order_payment(
  p_order_group_id uuid,
  p_status text,
  p_provider text default null,
  p_provider_reference text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns public.order_groups
language plpgsql
security definer
set search_path = public
as $$
declare
  v_group public.order_groups;
  v_paid_at timestamptz;
begin
  if auth.role() <> 'service_role' then raise exception 'Payment confirmation is server-only'; end if;
  if p_status not in ('pending', 'paid', 'failed', 'refunded') then raise exception 'Invalid payment status'; end if;
  if jsonb_typeof(coalesce(p_metadata, '{}'::jsonb)) <> 'object' then raise exception 'Invalid payment metadata'; end if;

  select * into v_group from public.order_groups where id = p_order_group_id for update;
  if not found then raise exception 'Order group not found'; end if;
  if p_status = 'paid' and v_group.payment_method = 'Cash on Delivery' then raise exception 'Cash on Delivery cannot be marked paid by gateway'; end if;
  if v_group.payment_status = 'refunded' and p_status <> 'refunded' then raise exception 'Refunded payment is closed'; end if;
  v_paid_at := case when p_status = 'paid' then now() else null end;

  update public.order_groups
  set payment_status = p_status, payment_reference = p_provider_reference, paid_at = v_paid_at, updated_at = now()
  where id = p_order_group_id
  returning * into v_group;

  update public.payment_transactions
  set provider = p_provider, provider_reference = p_provider_reference, metadata = coalesce(p_metadata, '{}'::jsonb), updated_at = now(), confirmed_at = v_paid_at
  where id = (select pt.id from public.payment_transactions pt where pt.order_group_id = p_order_group_id order by pt.created_at desc limit 1);
  return v_group;
end;
$$;

revoke all on function public.sync_order_payment_state() from public;
revoke all on function public.set_initial_order_payment_state() from public;
revoke all on function public.confirm_order_payment(uuid, text, text, text, jsonb) from public;
