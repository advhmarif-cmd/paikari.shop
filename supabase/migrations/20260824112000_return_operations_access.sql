-- Return/dispute access helpers for Vendor Center and Admin Center.

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
  else
    select exists(select 1 from public.vendor_orders vo where vo.order_group_id = v_request.order_group_id and vo.vendor_id = auth.uid()) into v_is_vendor;
  end if;
  if not v_is_admin and not v_is_vendor then raise exception 'Return response access denied'; end if;
  if p_status = 'refunded' and not v_is_admin then raise exception 'Only admin can mark refunded'; end if;
  if v_request.status in ('rejected', 'refunded', 'cancelled') then raise exception 'Return request is closed'; end if;
  update public.return_requests set status = p_status, resolution_note = p_resolution_note, updated_at = now() where id = p_return_request_id returning * into v_request;
  return v_request;
end;
$$;

create or replace function public.vendor_list_return_requests()
returns setof public.return_requests
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  return query
    select rr.* from public.return_requests rr
    where exists (
      select 1 from public.vendor_orders vo
      where vo.vendor_id = auth.uid()
        and (vo.id = rr.vendor_order_id or (rr.vendor_order_id is null and vo.order_group_id = rr.order_group_id))
    )
    order by rr.created_at desc
    limit 200;
end;
$$;

create or replace function public.admin_list_return_requests()
returns setof public.return_requests
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  return query select rr.* from public.return_requests rr order by rr.created_at desc limit 200;
end;
$$;

revoke all on function public.respond_to_return_request(uuid, text, text) from public;
revoke all on function public.vendor_list_return_requests() from public;
revoke all on function public.admin_list_return_requests() from public;
grant execute on function public.respond_to_return_request(uuid, text, text) to authenticated;
grant execute on function public.vendor_list_return_requests() to authenticated;
grant execute on function public.admin_list_return_requests() to authenticated;
