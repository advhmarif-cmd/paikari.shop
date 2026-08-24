-- Buyer-safe catalog metadata: supplier identity and available quantity only.
-- Reserved quantity and raw inventory controls remain private.

drop view if exists public.b2c_products;
create view public.b2c_products as
select
  cp.id,
  cp.source,
  cp.origin_product_id,
  cp.slug,
  cp.name,
  cp.description,
  cp.retail_price,
  cp.sale_price,
  cp.wholesale_tiers,
  cp.image_url,
  cp.images,
  cp.video_url,
  cp.category,
  cp.stock_status,
  case when cp.stock_quantity is null then null else greatest(cp.stock_quantity - cp.reserved_quantity, 0) end as available_quantity,
  cp.is_active,
  cp.sku,
  cp.unit_label,
  cp.moq,
  cp.is_negotiable,
  vp.store_name as vendor_store_name,
  cp.updated_at
from public.catalog_products cp
left join public.vendor_profiles vp on vp.user_id = cp.owner_id and vp.is_active = true
where cp.is_active = true
  and cp.approval_status = 'approved';

revoke all on public.b2c_products from public;
grant select on public.b2c_products to anon, authenticated;

drop view if exists public.b2b_products;
create view public.b2b_products as
select
  cp.id,
  cp.source,
  cp.slug,
  cp.name,
  cp.description,
  cp.retail_price,
  cp.sale_price,
  cp.wholesale_tiers,
  cp.image_url,
  cp.images,
  cp.category,
  cp.stock_status,
  case when cp.stock_quantity is null then null else greatest(cp.stock_quantity - cp.reserved_quantity, 0) end as available_quantity,
  cp.is_active,
  cp.sku,
  cp.unit_label,
  cp.moq,
  cp.is_negotiable,
  cp.owner_id as vendor_id,
  vp.store_name as vendor_store_name,
  cp.updated_at
from public.catalog_products cp
left join public.vendor_profiles vp on vp.user_id = cp.owner_id and vp.is_active = true
where cp.is_active = true
  and cp.approval_status = 'approved';

revoke all on public.b2b_products from public;
grant select on public.b2b_products to anon, authenticated;
