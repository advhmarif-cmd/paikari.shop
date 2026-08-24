-- Buyer-owned saved delivery addresses.
create table if not exists public.saved_addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  label text not null default 'আমার ঠিকানা',
  address jsonb not null,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint saved_addresses_label_length check (char_length(trim(label)) between 1 and 80),
  constraint saved_addresses_address_object check (jsonb_typeof(address) = 'object')
);

create index if not exists saved_addresses_user_created_idx
  on public.saved_addresses (user_id, is_default desc, created_at desc);

create unique index if not exists saved_addresses_one_default_per_user
  on public.saved_addresses (user_id)
  where is_default = true;

create or replace function public.touch_saved_address()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists touch_saved_address_trigger on public.saved_addresses;
create trigger touch_saved_address_trigger
before update on public.saved_addresses
for each row execute function public.touch_saved_address();

alter table public.saved_addresses enable row level security;
drop policy if exists saved_addresses_select_own on public.saved_addresses;
drop policy if exists saved_addresses_insert_own on public.saved_addresses;
drop policy if exists saved_addresses_update_own on public.saved_addresses;
drop policy if exists saved_addresses_delete_own on public.saved_addresses;
create policy saved_addresses_select_own
on public.saved_addresses
for select
to authenticated
using (user_id = auth.uid());
create policy saved_addresses_insert_own
on public.saved_addresses
for insert
to authenticated
with check (user_id = auth.uid());
create policy saved_addresses_update_own
on public.saved_addresses
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());
create policy saved_addresses_delete_own
on public.saved_addresses
for delete
to authenticated
using (user_id = auth.uid());

revoke all on table public.saved_addresses from anon;
grant select, insert, update, delete on table public.saved_addresses to authenticated;
revoke all on function public.touch_saved_address() from public, anon, authenticated;
