-- Restore the profile table expected by the Supabase Auth client repository.
-- Admin authorization remains app_metadata.role based; this table is not an
-- authorization source for admin operations.

create table if not exists public.users (
  uid uuid primary key references auth.users(id) on delete cascade,
  email text,
  "displayName" text,
  role text not null default 'consumer' check (role in ('consumer', 'vendor')),
  "isKycVerified" boolean not null default false,
  "phoneNumber" text,
  "businessName" text,
  "businessAddress" text,
  "tradeLicenseUrl" text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

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
    new.role := old.role;
    new."isKycVerified" := old."isKycVerified";
  end if;
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists protect_user_profile_fields_trigger on public.users;
create trigger protect_user_profile_fields_trigger
before insert or update on public.users
for each row execute function public.protect_user_profile_fields();

alter table public.users enable row level security;
drop policy if exists users_select_own on public.users;
drop policy if exists users_insert_own on public.users;
drop policy if exists users_update_own on public.users;
create policy users_select_own
on public.users
for select
to authenticated
using (uid = auth.uid());
create policy users_insert_own
on public.users
for insert
to authenticated
with check (uid = auth.uid() and role in ('consumer', 'vendor'));
create policy users_update_own
on public.users
for update
to authenticated
using (uid = auth.uid())
with check (uid = auth.uid());

revoke all on table public.users from anon;
revoke delete on table public.users from authenticated;
grant select, insert, update on table public.users to authenticated;
revoke all on function public.protect_user_profile_fields() from public, anon, authenticated;
