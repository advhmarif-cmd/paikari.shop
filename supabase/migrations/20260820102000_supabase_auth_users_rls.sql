-- Paikari.shop: secure profile access after migrating identity to Supabase Auth.
-- Apply this migration after the paikari.shop Supabase project is restored.

alter table if exists public.users enable row level security;

-- Remove broad or stale policies before recreating the least-privilege set.
drop policy if exists users_select_own on public.users;
drop policy if exists users_insert_own on public.users;
drop policy if exists users_update_own on public.users;

create policy users_select_own
on public.users
for select
to authenticated
using (uid::text = auth.uid()::text);

create policy users_insert_own
on public.users
for insert
to authenticated
with check (
  uid::text = auth.uid()::text
  and role in ('consumer', 'vendor')
);

create policy users_update_own
on public.users
for update
to authenticated
using (uid::text = auth.uid()::text)
with check (
  uid::text = auth.uid()::text
  and role in ('consumer', 'vendor')
);

revoke all on table public.users from anon;
grant select, insert, update on table public.users to authenticated;
