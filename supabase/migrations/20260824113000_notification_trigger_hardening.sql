-- Notification trigger hardening and payment-state notifications.

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
  return new;
end;
$$;

create or replace function public.create_payment_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_buyer_id uuid;
begin
  if TG_OP = 'INSERT' or old.status is distinct from new.status then
    select buyer_id into v_buyer_id from public.order_groups where id = new.order_group_id;
    if v_buyer_id is not null then
      insert into public.order_notifications(recipient_id, order_group_id, notification_type, title, body)
      values(v_buyer_id, new.order_group_id, 'payment', 'Payment status updated', 'Payment status: ' || new.status);
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists payment_transaction_notification_trigger on public.payment_transactions;
create trigger payment_transaction_notification_trigger
after insert or update of status on public.payment_transactions
for each row execute function public.create_payment_notification();

revoke all on function public.create_payment_notification() from public;
