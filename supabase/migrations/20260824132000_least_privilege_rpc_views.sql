-- Final least-privilege hardening for exposed RPCs and catalog read views.
-- User-facing RPCs remain available only to authenticated callers; internal,
-- trigger-only helpers remain unavailable through the PostgREST RPC surface.

-- Catalog read views must evaluate base-table RLS as the requesting role.
alter view public.b2c_products set (security_invoker = true);
alter view public.b2b_products set (security_invoker = true);

-- Remove anonymous execution from every application RPC. The authenticated
-- grants below preserve the existing Flutter buyer/vendor/admin flows while
-- their function bodies continue to enforce ownership or admin checks.
revoke execute on function public.place_order_from_cart(jsonb, jsonb, text) from anon;
revoke execute on function public.place_order_group_from_cart(jsonb, jsonb, text) from anon;
revoke execute on function public.accept_quotation(uuid) from anon;
revoke execute on function public.checkout_accepted_quote(uuid, jsonb, text) from anon;
revoke execute on function public.create_quotation_request(uuid, integer, numeric, text) from anon;
revoke execute on function public.respond_to_quotation(uuid, integer, numeric, numeric, timestamptz, text) from anon;
revoke execute on function public.cancel_order_group(uuid) from anon;
revoke execute on function public.update_vendor_order_status(uuid, text) from anon;
revoke execute on function public.update_vendor_order_fulfillment(uuid, text, text, text, text) from anon;
revoke execute on function public.create_return_request(uuid, uuid, uuid, integer, text, text) from anon;
revoke execute on function public.cancel_return_request(uuid) from anon;
revoke execute on function public.respond_to_return_request(uuid, text, text) from anon;
revoke execute on function public.vendor_list_return_requests() from anon;
revoke execute on function public.admin_list_vendor_queue() from anon;
revoke execute on function public.admin_list_product_queue() from anon;
revoke execute on function public.admin_update_vendor_status(uuid, text) from anon;
revoke execute on function public.admin_update_product_status(uuid, text) from anon;
revoke execute on function public.admin_list_payment_transactions() from anon;
revoke execute on function public.admin_list_return_requests() from anon;
revoke execute on function public.mark_order_notification_read(uuid) from anon;
revoke execute on function public.is_admin() from anon;

-- Payment confirmation is service-role-only; it must not be callable from
-- either the anonymous or authenticated PostgREST roles.
revoke execute on function public.confirm_order_payment(uuid, text, text, text, jsonb) from anon, authenticated;
grant execute on function public.confirm_order_payment(uuid, text, text, text, jsonb) to service_role;

-- Trigger-only and server-only helpers must not be exposed through RPC.
revoke execute on function public.create_order_status_notification() from anon, authenticated;
revoke execute on function public.create_payment_notification() from anon, authenticated;
revoke execute on function public.create_return_notification() from anon, authenticated;
revoke execute on function public.record_order_status_event() from anon, authenticated;
revoke execute on function public.record_delivery_tracking_event() from anon, authenticated;
revoke execute on function public.rls_auto_enable() from anon, authenticated;
revoke execute on function public.set_initial_order_payment_state() from anon, authenticated;
revoke execute on function public.sync_order_payment_state() from anon, authenticated;

-- These functions are intentionally unavailable to the client roles; the
-- existing triggers and service-role callers are unaffected by these revokes.
