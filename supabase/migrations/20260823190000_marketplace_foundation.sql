-- Paikari.shop marketplace foundation for B2B-first and B2C-enabled flows.
-- This migration adds supplier/buyer context and safe product metadata without
-- changing the existing Hybrid B1 ownership model or order RPC yet.

create table if not exists public.vendor_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  store_name text not null,
  slug text not null unique,
  description text not null default '',
  logo_url text not null default '',
  phone text not null default '',
  city text not null default '',
  address text not null default '',
  verification_status text not null default 'pending'
    check (verification_status in ('pending', 'verified', 'rejected', 'suspended')),
  is_active boolean not null default false,
  response_time_hours integer
    check (response_time_hours is null or response_time_hours >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.business_buyer_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  business_name text not null default '',
  business_type text not null default '',
  trade_license_url text not null default '',
  buyer_status text not null default 'pending'
    check (buyer_status in ('pending', 'verified', 'rejected')),
  preferred_categories text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.catalog_products
  add column if not exists sku text,
  add column if not exists unit_label text not null default 'unit',
  add column if not exists moq integer not null default 1,
  add column if not exists stock_quantity integer,
  add column if not exists reserved_quantity integer not null default 0,
  add column if not exists low_stock_threshold integer not null default 5,
  add column if not exists allow_backorder boolean not null default false,
  add column if not exists is_negotiable boolean not null default false,
  add column if not exists approval_status text not null default 'approved'
    check (approval_status in ('pending', 'approved', 'rejected', 'suspended')),
  add column if not exists published_at timestamptz;

alter table public.catalog_products
  drop constraint if exists catalog_products_moq_positive,
  add constraint catalog_products_moq_positive check (moq >= 1),
  drop constraint if exists catalog_products_stock_nonnegative,
  add constraint catalog_products_stock_nonnegative check (stock_quantity is null or stock_quantity >= 0),
  drop constraint if exists catalog_products_reserved_nonnegative,
  add constraint catalog_products_reserved_nonnegative check (reserved_quantity >= 0),
  drop constraint if exists catalog_products_reserved_not_over_stock,
  add constraint catalog_products_reserved_not_over_stock check (stock_quantity is null or reserved_quantity <= stock_quantity);

create index if not exists catalog_products_category_idx
  on public.catalog_products (category, is_active, updated_at desc);
create index if not exists catalog_products_moq_idx
  on public.catalog_products (moq, is_active);
create index if not exists catalog_products_owner_idx
  on public.catalog_products (owner_id, is_active, updated_at desc);
create unique index if not exists catalog_products_sku_unique_idx
  on public.catalog_products (sku)
  where sku is not null and sku <> '';

create table if not exists public.product_inquiries (
  id uuid primary key default gen_random_uuid(),
  buyer_id uuid not null references auth.users(id) on delete cascade,
  vendor_id uuid not null references auth.users(id) on delete cascade,
  product_id uuid not null references public.catalog_products(id) on delete cascade,
  requested_quantity integer not null check (requested_quantity >= 1),
  target_price numeric check (target_price is null or target_price >= 0),
  message text not null,
  status text not null default 'open'
    check (status in ('open', 'responded', 'accepted', 'closed', 'cancelled')),
  vendor_response text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists product_inquiries_buyer_idx
  on public.product_inquiries (buyer_id, created_at desc);
create index if not exists product_inquiries_vendor_idx
  on public.product_inquiries (vendor_id, status, created_at desc);

alter table public.vendor_profiles enable row level security;
alter table public.business_buyer_profiles enable row level security;
alter table public.product_inquiries enable row level security;

revoke all on table public.vendor_profiles from anon, authenticated;
grant select on table public.vendor_profiles to anon, authenticated;
grant insert, update on table public.vendor_profiles to authenticated;

revoke all on table public.business_buyer_profiles from anon, authenticated;
grant select, insert, update on table public.business_buyer_profiles to authenticated;

revoke all on table public.product_inquiries from anon, authenticated;
grant select, insert, update on table public.product_inquiries to authenticated;

drop policy if exists vendor_profiles_public_read on public.vendor_profiles;
create policy vendor_profiles_public_read
on public.vendor_profiles
for select
to anon, authenticated
using (is_active = true or user_id = auth.uid());

drop policy if exists vendor_profiles_insert_own on public.vendor_profiles;
create policy vendor_profiles_insert_own
on public.vendor_profiles
for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists vendor_profiles_update_own on public.vendor_profiles;
create policy vendor_profiles_update_own
on public.vendor_profiles
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists business_buyer_profiles_select_own on public.business_buyer_profiles;
create policy business_buyer_profiles_select_own
on public.business_buyer_profiles
for select
to authenticated
using (user_id = auth.uid());

drop policy if exists business_buyer_profiles_insert_own on public.business_buyer_profiles;
create policy business_buyer_profiles_insert_own
on public.business_buyer_profiles
for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists business_buyer_profiles_update_own on public.business_buyer_profiles;
create policy business_buyer_profiles_update_own
on public.business_buyer_profiles
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists product_inquiries_buyer_access on public.product_inquiries;
create policy product_inquiries_buyer_access
on public.product_inquiries
for select
to authenticated
using (buyer_id = auth.uid());

drop policy if exists product_inquiries_vendor_access on public.product_inquiries;
create policy product_inquiries_vendor_access
on public.product_inquiries
for select
to authenticated
using (vendor_id = auth.uid());

drop policy if exists product_inquiries_buyer_insert on public.product_inquiries;
create policy product_inquiries_buyer_insert
on public.product_inquiries
for insert
to authenticated
with check (
  buyer_id = auth.uid()
  and vendor_id <> auth.uid()
  and exists (
    select 1
    from public.catalog_products cp
    where cp.id = product_id
      and cp.is_active = true
      and cp.owner_id = vendor_id
  )
);

drop policy if exists product_inquiries_vendor_update on public.product_inquiries;
create policy product_inquiries_vendor_update
on public.product_inquiries
for update
to authenticated
using (vendor_id = auth.uid())
with check (vendor_id = auth.uid());

-- Public product read should only expose active approved rows. Existing local
-- owner access remains available through the existing RLS policy.
drop policy if exists catalog_products_public_read on public.catalog_products;
create policy catalog_products_public_read
on public.catalog_products
for select
to anon, authenticated
using (
  (is_active = true and approval_status = 'approved')
  or (source = 'paikari' and owner_id = auth.uid())
);
