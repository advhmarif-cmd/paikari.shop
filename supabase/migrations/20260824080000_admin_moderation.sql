-- Milestone 6 foundation: admin moderation via Supabase JWT app_metadata.
-- Admin role must be provisioned in Supabase Auth app_metadata; client input never grants access.

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin', false)
$$;

create or replace function public.admin_list_vendor_queue()
returns setof public.vendor_profiles
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  return query select vp.* from public.vendor_profiles vp order by vp.created_at desc limit 200;
end;
$$;

create or replace function public.admin_list_product_queue()
returns setof public.catalog_products
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  return query
    select cp.* from public.catalog_products cp
    where cp.source = 'paikari'
    order by cp.updated_at desc
    limit 200;
end;
$$;

create or replace function public.admin_update_vendor_status(p_vendor_id uuid, p_status text)
returns public.vendor_profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_vendor public.vendor_profiles;
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  if p_status not in ('pending', 'verified', 'rejected', 'suspended') then raise exception 'Invalid vendor status'; end if;
  update public.vendor_profiles
  set verification_status = p_status,
      is_active = p_status = 'verified',
      updated_at = now()
  where user_id = p_vendor_id
  returning * into v_vendor;
  if not found then raise exception 'Vendor profile not found'; end if;
  return v_vendor;
end;
$$;

create or replace function public.admin_update_product_status(p_product_id uuid, p_status text)
returns public.catalog_products
language plpgsql
security definer
set search_path = public
as $$
declare
  v_product public.catalog_products;
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  if p_status not in ('pending', 'approved', 'rejected', 'suspended') then raise exception 'Invalid product status'; end if;
  update public.catalog_products
  set approval_status = p_status,
      published_at = case when p_status = 'approved' then coalesce(published_at, now()) else null end,
      updated_at = now()
  where id = p_product_id and source = 'paikari'
  returning * into v_product;
  if not found then raise exception 'Local product not found'; end if;
  return v_product;
end;
$$;

revoke all on function public.is_admin() from public;
revoke all on function public.admin_list_vendor_queue() from public;
revoke all on function public.admin_list_product_queue() from public;
revoke all on function public.admin_update_vendor_status(uuid, text) from public;
revoke all on function public.admin_update_product_status(uuid, text) from public;
grant execute on function public.is_admin() to authenticated;
grant execute on function public.admin_list_vendor_queue() to authenticated;
grant execute on function public.admin_list_product_queue() to authenticated;
grant execute on function public.admin_update_vendor_status(uuid, text) to authenticated;
grant execute on function public.admin_update_product_status(uuid, text) to authenticated;
