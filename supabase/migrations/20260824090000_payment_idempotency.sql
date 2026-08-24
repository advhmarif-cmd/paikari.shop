-- Payment webhook hardening: one provider event can be processed only once.

alter table public.payment_transactions
  add column if not exists provider_event_id text;

create unique index if not exists payment_transactions_provider_event_unique_idx
  on public.payment_transactions (provider, provider_event_id)
  where provider_event_id is not null and provider_event_id <> '';

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
  v_event_id text;
  v_existing_group_id uuid;
  v_latest_transaction_id uuid;
begin
  if auth.role() <> 'service_role' then raise exception 'Payment confirmation is server-only'; end if;
  if p_status not in ('pending', 'paid', 'failed', 'refunded') then raise exception 'Invalid payment status'; end if;
  if jsonb_typeof(coalesce(p_metadata, '{}'::jsonb)) <> 'object' then raise exception 'Invalid payment metadata'; end if;
  v_event_id := nullif(trim(coalesce(p_metadata ->> 'event_id', '')), '');

  select * into v_group from public.order_groups where id = p_order_group_id for update;
  if not found then raise exception 'Order group not found'; end if;

  if v_event_id is not null then
    select pt.order_group_id into v_existing_group_id
    from public.payment_transactions pt
    where pt.provider = p_provider and pt.provider_event_id = v_event_id
    limit 1;
    if found then
      if v_existing_group_id <> p_order_group_id then raise exception 'Payment event is already linked to another order'; end if;
      return v_group;
    end if;
  end if;

  if p_status = 'paid' and v_group.payment_method = 'Cash on Delivery' then raise exception 'Cash on Delivery cannot be marked paid by gateway'; end if;
  if v_group.payment_status = 'refunded' and p_status <> 'refunded' then raise exception 'Refunded payment is closed'; end if;
  if v_group.payment_status = 'paid' and p_status not in ('paid', 'refunded') then raise exception 'Paid payment cannot move backwards'; end if;
  v_paid_at := case when p_status = 'paid' then coalesce(v_group.paid_at, now()) else null end;

  update public.order_groups
  set payment_status = p_status, payment_reference = p_provider_reference, paid_at = v_paid_at, updated_at = now()
  where id = p_order_group_id
  returning * into v_group;

  select pt.id into v_latest_transaction_id
  from public.payment_transactions pt
  where pt.order_group_id = p_order_group_id
  order by pt.created_at desc
  limit 1;

  update public.payment_transactions
  set provider = p_provider,
      provider_reference = p_provider_reference,
      provider_event_id = v_event_id,
      metadata = coalesce(p_metadata, '{}'::jsonb),
      updated_at = now(),
      confirmed_at = v_paid_at
  where id = v_latest_transaction_id;
  return v_group;
exception
  when unique_violation then
    if v_event_id is not null then
      select * into v_group from public.order_groups where id = p_order_group_id;
      return v_group;
    end if;
    raise;
end;
$$;

revoke all on function public.confirm_order_payment(uuid, text, text, text, jsonb) from public;
grant execute on function public.confirm_order_payment(uuid, text, text, text, jsonb) to service_role;
