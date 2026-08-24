-- Keep a small product snapshot in chat conversations for a useful inbox row.
alter table public.chat_conversations
  add column if not exists product_name text,
  add column if not exists product_image_url text;

create or replace function public.get_or_create_chat_conversation(
  p_product_id uuid,
  p_vendor_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_buyer_id uuid := auth.uid();
  v_conversation_id uuid;
  v_product_name text;
  v_product_image_url text;
begin
  if v_buyer_id is null then raise exception 'Authentication required'; end if;
  if v_buyer_id = p_vendor_id then raise exception 'Buyer and vendor must differ'; end if;
  select name, image_url into v_product_name, v_product_image_url
  from public.catalog_products
  where id = p_product_id
    and owner_id = p_vendor_id
    and source = 'paikari'
    and is_active = true
    and approval_status = 'approved';
  if v_product_name is null then raise exception 'Product is not available for chat'; end if;

  insert into public.chat_conversations(buyer_id, vendor_id, product_id, product_name, product_image_url)
  values(v_buyer_id, p_vendor_id, p_product_id, v_product_name, v_product_image_url)
  on conflict (buyer_id, vendor_id, product_id) do update set id = public.chat_conversations.id
  returning id into v_conversation_id;
  return v_conversation_id;
end;
$$;

revoke all on function public.get_or_create_chat_conversation(uuid, uuid) from public, anon;
grant execute on function public.get_or_create_chat_conversation(uuid, uuid) to authenticated;
