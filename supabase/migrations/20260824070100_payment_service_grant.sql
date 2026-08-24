-- Payment confirmation is intentionally callable only by a trusted server/webhook.

grant execute on function public.confirm_order_payment(uuid, text, text, text, jsonb) to service_role;
