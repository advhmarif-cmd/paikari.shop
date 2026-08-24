-- Remove the implicit PUBLIC execution path from trigger-only helpers.
-- Trigger execution by the table owner is unaffected by function ACLs.
revoke execute on function public.rls_auto_enable() from public, anon, authenticated;
revoke execute on function public.create_order_status_notification() from public, anon, authenticated;
revoke execute on function public.create_payment_notification() from public, anon, authenticated;
revoke execute on function public.create_return_notification() from public, anon, authenticated;
revoke execute on function public.record_order_status_event() from public, anon, authenticated;
revoke execute on function public.record_delivery_tracking_event() from public, anon, authenticated;
revoke execute on function public.set_initial_order_payment_state() from public, anon, authenticated;
revoke execute on function public.sync_order_payment_state() from public, anon, authenticated;
