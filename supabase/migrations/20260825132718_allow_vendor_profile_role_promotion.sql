-- Allow a user to become a vendor only after a vendor profile exists.
-- Public users.role is not an admin authorization source; admin remains
-- app_metadata.role based and is never writable through this path.
create or replace function public.protect_user_profile_fields()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    if new.role not in ('consumer', 'vendor') then
      new.role := 'consumer';
    end if;
    new."isKycVerified" := false;
  else
    if old.role = 'consumer'
       and new.role = 'vendor'
       and exists (
         select 1
         from public.vendor_profiles vp
         where vp.user_id = new.uid
           and vp.verification_status in ('pending', 'verified')
       ) then
      new.role := 'vendor';
    else
      new.role := old.role;
    end if;
    new."isKycVerified" := old."isKycVerified";
  end if;
  new.updated_at := now();
  return new;
end;
$$;

revoke all on function public.protect_user_profile_fields() from public, anon, authenticated;
