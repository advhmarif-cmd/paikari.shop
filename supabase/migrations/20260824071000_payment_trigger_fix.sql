-- Correct payment audit trigger key handling for order_groups versus order_records.

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
  v_group_id uuid;
  v_should_log boolean := false;
begin
  if TG_TABLE_NAME = 'order_groups' then
    v_group_id := new.id;
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
    v_group_id := new.order_group_id;
    v_status := new.payment_status;
    v_payment_method := new.payment_method;
    v_amount := new.total_amount;
    if TG_OP = 'INSERT' or old.payment_status is distinct from new.payment_status or old.payment_reference is distinct from new.payment_reference then
      v_should_log := true;
    end if;
  end if;

  if v_should_log and v_group_id is not null then
    insert into public.payment_transactions(order_group_id, amount, payment_method, status, provider_reference, confirmed_at)
    values(v_group_id, v_amount, v_payment_method, v_status, case when v_status in ('paid', 'failed', 'refunded') then new.payment_reference else null end, case when v_status = 'paid' then coalesce(new.paid_at, now()) else null end);
  end if;
  return new;
end;
$$;

drop trigger if exists order_records_payment_audit_trigger on public.order_records;
revoke all on function public.sync_order_payment_state() from public;
