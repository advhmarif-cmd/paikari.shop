import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

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

function isUuid(value: unknown): value is string {
  return typeof value === "string" && /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}

Deno.serve(async (request) => {
  if (request.method !== "POST") return json({ error: "POST required" }, 405);
  if (!supabaseUrl || !serviceRoleKey || !webhookSecret) return json({ error: "Payment webhook is not configured" }, 503);

  const rawBody = await request.text();
  const signature = request.headers.get("x-paikari-signature")?.trim() ?? "";
  if (!isHexSignature(signature)) return json({ error: "Valid x-paikari-signature is required" }, 401);

  const expectedSignature = await hmacSha256(webhookSecret, rawBody);
  if (!timingSafeEqual(signature.toLowerCase(), expectedSignature)) return json({ error: "Invalid webhook signature" }, 401);

  let payload: Record<string, unknown>;
  try {
    const parsed = JSON.parse(rawBody);
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) throw new Error("Payload must be an object");
    payload = parsed as Record<string, unknown>;
  } catch (_error) {
    return json({ error: "Invalid JSON payload" }, 400);
  }

  const orderGroupId = payload.order_group_id;
  const status = payload.status;
  const provider = payload.provider;
  const providerReference = payload.provider_reference;
  const eventId = payload.event_id;
  const metadata = payload.metadata;

  if (!isUuid(orderGroupId)) return json({ error: "order_group_id must be a UUID" }, 400);
  if (status !== "pending" && status !== "paid" && status !== "failed" && status !== "refunded") return json({ error: "Invalid payment status" }, 400);
  if (typeof provider !== "string" || provider.trim().length < 2 || provider.trim().length > 64) return json({ error: "Invalid provider" }, 400);
  if (typeof eventId !== "string" || eventId.trim().length < 3 || eventId.trim().length > 160) return json({ error: "event_id is required" }, 400);
  if (providerReference !== undefined && providerReference !== null && (typeof providerReference !== "string" || providerReference.length > 160)) return json({ error: "Invalid provider_reference" }, 400);
  if (metadata !== undefined && (!metadata || typeof metadata !== "object" || Array.isArray(metadata))) return json({ error: "metadata must be an object" }, 400);

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  try {
    const { data, error } = await supabase.rpc("confirm_order_payment", {
      p_order_group_id: orderGroupId,
      p_status: status,
      p_provider: provider.trim(),
      p_provider_reference: typeof providerReference === "string" ? providerReference.trim() : null,
      p_metadata: { ...(metadata as Record<string, unknown> | undefined), event_id: eventId.trim() },
    });
    if (error) throw error;
    return json({ accepted: true, order_group_id: orderGroupId, payment_status: data?.payment_status ?? status, event_id: eventId.trim() });
  } catch (error) {
    console.error("Payment webhook confirmation failed", error);
    return json({ error: "Payment confirmation failed" }, 500);
  }
});
