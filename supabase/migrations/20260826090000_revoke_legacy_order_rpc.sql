-- The active Flutter checkout path uses place_order_group_from_cart.
-- The older single-order RPC does not reserve stock or enforce B2B MOQ,
-- so it must not remain callable through the public API.
revoke execute on function public.place_order_from_cart(jsonb, jsonb, text)
from public, anon, authenticated;
