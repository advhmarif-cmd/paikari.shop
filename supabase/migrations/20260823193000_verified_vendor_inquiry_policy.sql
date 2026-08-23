-- Only active verified supplier stores should receive buyer inquiries.

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
      and cp.approval_status = 'approved'
      and cp.owner_id = vendor_id
  )
  and exists (
    select 1
    from public.vendor_profiles vp
    where vp.user_id = vendor_id
      and vp.is_active = true
      and vp.verification_status = 'verified'
  )
);
