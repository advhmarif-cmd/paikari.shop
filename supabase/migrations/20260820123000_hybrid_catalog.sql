-- Hybrid B1 catalog for Paikari.shop.
-- Origen rows are shared/read-only; Paikari rows are locally owned.

create table if not exists public.catalog_products (
  id uuid primary key default gen_random_uuid(),
  source text not null check (source in ('origen', 'paikari')),
  origin_product_id uuid,
  owner_id uuid references auth.users(id) on delete set null,
  slug text not null,
  name text not null,
  description text not null default '',
  retail_price numeric not null default 0,
  sale_price numeric,
  wholesale_tiers jsonb not null default '[]'::jsonb,
  image_url text not null default '',
  images jsonb not null default '[]'::jsonb,
  video_url text,
  category text not null default '',
  stock_status text not null default 'In Stock',
  is_active boolean not null default false,
  source_updated_at timestamptz,
  last_synced_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint shared_rows_require_origin_id check (
    (source = 'origen' and origin_product_id is not null and owner_id is null)
    or (source = 'paikari')
  ),
  constraint shared_rows_require_unique_origin unique (source, origin_product_id)
);

create index if not exists catalog_products_active_idx
  on public.catalog_products (is_active, updated_at desc);
create index if not exists catalog_products_source_idx
  on public.catalog_products (source, updated_at desc);

alter table public.catalog_products enable row level security;

revoke all on table public.catalog_products from anon, authenticated;
grant select on table public.catalog_products to anon, authenticated;
grant insert, update on table public.catalog_products to authenticated;

drop policy if exists catalog_products_public_read on public.catalog_products;
create policy catalog_products_public_read
on public.catalog_products
for select
to anon, authenticated
using (
  is_active = true
  or (source = 'paikari' and owner_id = auth.uid())
);

drop policy if exists catalog_products_local_insert on public.catalog_products;
create policy catalog_products_local_insert
on public.catalog_products
for insert
to authenticated
with check (
  source = 'paikari'
  and owner_id = auth.uid()
);

drop policy if exists catalog_products_local_update on public.catalog_products;
create policy catalog_products_local_update
on public.catalog_products
for update
to authenticated
using (
  source = 'paikari'
  and owner_id = auth.uid()
)
with check (
  source = 'paikari'
  and owner_id = auth.uid()
);

-- This read model is intentionally public and contains no customer/order data.
create or replace view public.b2c_products as
select
  id,
  source,
  origin_product_id,
  slug,
  name,
  description,
  retail_price,
  sale_price,
  wholesale_tiers,
  image_url,
  images,
  video_url,
  category,
  stock_status,
  is_active,
  updated_at
from public.catalog_products
where is_active = true;

revoke all on public.b2c_products from public;
grant select on public.b2c_products to anon, authenticated;
