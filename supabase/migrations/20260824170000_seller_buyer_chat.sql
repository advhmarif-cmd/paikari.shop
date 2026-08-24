-- Product-centric buyer/vendor chat. Admin moderation is intentionally outside
-- this MVP surface; participant access is enforced at the database boundary.
create table if not exists public.chat_conversations (
  id uuid primary key default gen_random_uuid(),
  buyer_id uuid not null references auth.users(id) on delete cascade,
  vendor_id uuid not null references auth.users(id) on delete cascade,
  product_id uuid not null references public.catalog_products(id) on delete cascade,
  last_message_preview text,
  last_message_at timestamptz,
  last_sender_id uuid references auth.users(id) on delete set null,
  buyer_last_read_at timestamptz,
  vendor_last_read_at timestamptz,
  created_at timestamptz not null default now(),
  constraint chat_conversations_distinct_participants check (buyer_id <> vendor_id),
  constraint chat_conversations_preview_length check (last_message_preview is null or char_length(last_message_preview) <= 2000),
  unique (buyer_id, vendor_id, product_id)
);

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.chat_conversations(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now(),
  constraint chat_messages_body_length check (char_length(trim(body)) between 1 and 2000)
);

create index if not exists chat_conversations_buyer_idx
  on public.chat_conversations (buyer_id, last_message_at desc);
create index if not exists chat_conversations_vendor_idx
  on public.chat_conversations (vendor_id, last_message_at desc);
create index if not exists chat_messages_conversation_idx
  on public.chat_messages (conversation_id, created_at asc);

alter table public.chat_conversations enable row level security;
alter table public.chat_messages enable row level security;

drop policy if exists chat_conversations_select_participant on public.chat_conversations;
create policy chat_conversations_select_participant
on public.chat_conversations
for select
to authenticated
using (buyer_id = auth.uid() or vendor_id = auth.uid());

drop policy if exists chat_messages_select_participant on public.chat_messages;
create policy chat_messages_select_participant
on public.chat_messages
for select
to authenticated
using (
  exists (
    select 1
    from public.chat_conversations c
    where c.id = conversation_id
      and (c.buyer_id = auth.uid() or c.vendor_id = auth.uid())
  )
);

revoke all on table public.chat_conversations from anon, authenticated;
revoke all on table public.chat_messages from anon, authenticated;
grant select on table public.chat_conversations, public.chat_messages to authenticated;

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
begin
  if v_buyer_id is null then raise exception 'Authentication required'; end if;
  if v_buyer_id = p_vendor_id then raise exception 'Buyer and vendor must differ'; end if;
  if not exists (
    select 1 from public.catalog_products
    where id = p_product_id
      and owner_id = p_vendor_id
      and source = 'paikari'
      and is_active = true
      and approval_status = 'approved'
  ) then
    raise exception 'Product is not available for chat';
  end if;

  insert into public.chat_conversations(buyer_id, vendor_id, product_id)
  values(v_buyer_id, p_vendor_id, p_product_id)
  on conflict (buyer_id, vendor_id, product_id) do update set id = public.chat_conversations.id
  returning id into v_conversation_id;
  return v_conversation_id;
end;
$$;

create or replace function public.send_chat_message(
  p_conversation_id uuid,
  p_body text
)
returns public.chat_messages
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_message public.chat_messages;
  v_body text := trim(coalesce(p_body, ''));
begin
  if v_user_id is null then raise exception 'Authentication required'; end if;
  if char_length(v_body) < 1 or char_length(v_body) > 2000 then raise exception 'Message length is invalid'; end if;
  if not exists (
    select 1 from public.chat_conversations
    where id = p_conversation_id
      and (buyer_id = v_user_id or vendor_id = v_user_id)
  ) then
    raise exception 'Chat participant access denied';
  end if;

  insert into public.chat_messages(conversation_id, sender_id, body)
  values(p_conversation_id, v_user_id, v_body)
  returning * into v_message;

  update public.chat_conversations
  set last_message_preview = left(v_body, 2000),
      last_message_at = v_message.created_at,
      last_sender_id = v_user_id
  where id = p_conversation_id;
  return v_message;
end;
$$;

create or replace function public.mark_chat_read(p_conversation_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then raise exception 'Authentication required'; end if;
  update public.chat_conversations
  set buyer_last_read_at = case when buyer_id = v_user_id then now() else buyer_last_read_at end,
      vendor_last_read_at = case when vendor_id = v_user_id then now() else vendor_last_read_at end
  where id = p_conversation_id
    and (buyer_id = v_user_id or vendor_id = v_user_id);
end;
$$;

revoke all on function public.get_or_create_chat_conversation(uuid, uuid) from public, anon;
revoke all on function public.send_chat_message(uuid, text) from public, anon;
revoke all on function public.mark_chat_read(uuid) from public, anon;
grant execute on function public.get_or_create_chat_conversation(uuid, uuid) to authenticated;
grant execute on function public.send_chat_message(uuid, text) to authenticated;
grant execute on function public.mark_chat_read(uuid) to authenticated;
