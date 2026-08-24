import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { normalizePaymentEvent, type NormalizedPaymentEvent } from "../_shared/payment_adapter.ts";

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const webhookSecret = Deno.env.get("PAYMENT_WEBHOOK_SECRET");

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });

const isHexSignature = (value: string) => /^[a-f0-9]{64}$/i.test(value);

async function hmacSha256(secret: string, message: string): Promise<string> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign("HMAC", key, encoder.encode(message));
  return Array.from(new Uint8Array(signature), (byte) => byte.toString(16).padStart(2, "0")).join("");
}

function timingSafeEqual(left: string, right: string): boolean {
  if (left.length !== right.length) return false;
  let difference = 0;
  for (let index = 0; index < left.length; index += 1) {
    difference |= left.charCodeAt(index) ^ right.charCodeAt(index);
  }
  return difference === 0;
}

Deno.serve(async (request) => {
  if (request.method !== "POST") return json({ error: "POST required" }, 405);
  if (!supabaseUrl || !serviceRoleKey || !webhookSecret) return json({ error: "Payment webhook is not configured" }, 503);

  const rawBody = await request.text();
  const signature = request.headers.get("x-paikari-signature")?.trim() ?? "";
  if (!isHexSignature(signature)) return json({ error: "Valid x-paikari-signature is required" }, 401);

  const expectedSignature = await hmacSha256(webhookSecret, rawBody);
  if (!timingSafeEqual(signature.toLowerCase(), expectedSignature)) return json({ error: "Invalid webhook signature" }, 401);

  let parsed: unknown;
  try {
    parsed = JSON.parse(rawBody);
  } catch (_error) {
    return json({ error: "Invalid JSON payload" }, 400);
  }

  let event: NormalizedPaymentEvent;
  try {
    event = normalizePaymentEvent(parsed);
  } catch (error) {
    return json({ error: error instanceof Error ? error.message : "Invalid payment payload" }, 400);
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  try {
    const { data, error } = await supabase.rpc("confirm_order_payment", {
      p_order_group_id: event.orderGroupId,
      p_status: event.status,
      p_provider: event.provider,
      p_provider_reference: event.providerReference,
      p_metadata: event.metadata,
    });
    if (error) throw error;
    return json({ accepted: true, order_group_id: event.orderGroupId, payment_status: data?.payment_status ?? event.status, event_id: event.eventId });
  } catch (error) {
    console.error("Payment webhook confirmation failed", error);
    return json({ error: "Payment confirmation failed" }, 500);
  }
});
