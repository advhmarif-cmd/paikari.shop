import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const webhookSecret = Deno.env.get("COURIER_WEBHOOK_SECRET");

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });

const isHexSignature = (value: string) => /^[a-f0-9]{64}$/i.test(value);

async function hmacSha256(secret: string, message: string): Promise<string> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey("raw", encoder.encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const signature = await crypto.subtle.sign("HMAC", key, encoder.encode(message));
  return Array.from(new Uint8Array(signature), (byte) => byte.toString(16).padStart(2, "0")).join("");
}

function timingSafeEqual(left: string, right: string): boolean {
  if (left.length !== right.length) return false;
  let difference = 0;
  for (let index = 0; index < left.length; index += 1) difference |= left.charCodeAt(index) ^ right.charCodeAt(index);
  return difference === 0;
}

const isRecord = (value: unknown): value is Record<string, unknown> => Boolean(value) && typeof value === "object" && !Array.isArray(value);

Deno.serve(async (request) => {
  if (request.method !== "POST") return json({ error: "POST required" }, 405);
  if (!supabaseUrl || !serviceRoleKey || !webhookSecret) return json({ error: "Courier webhook is not configured" }, 503);

  const rawBody = await request.text();
  const signature = request.headers.get("x-paikari-signature")?.trim() ?? "";
  if (!isHexSignature(signature)) return json({ error: "Valid x-paikari-signature is required" }, 401);
  const expectedSignature = await hmacSha256(webhookSecret, rawBody);
  if (!timingSafeEqual(signature.toLowerCase(), expectedSignature)) return json({ error: "Invalid webhook signature" }, 401);

  let payload: unknown;
  try {
    payload = JSON.parse(rawBody);
  } catch (_error) {
    return json({ error: "Invalid JSON payload" }, 400);
  }
  if (!isRecord(payload)) return json({ error: "Payload must be an object" }, 400);

  const trackingNumber = payload.tracking_number;
  const provider = payload.provider;
  const eventId = payload.event_id;
  const status = payload.status;
  const message = payload.message;
  if (typeof trackingNumber !== "string" || trackingNumber.trim().length < 2 || trackingNumber.length > 160) return json({ error: "tracking_number is required" }, 400);
  if (typeof provider !== "string" || provider.trim().length < 2 || provider.length > 64) return json({ error: "provider is required" }, 400);
  if (typeof eventId !== "string" || eventId.trim().length < 3 || eventId.length > 160) return json({ error: "event_id is required" }, 400);
  if (typeof status !== "string" || status.trim().length < 2 || status.length > 80) return json({ error: "status is required" }, 400);
  if (message !== undefined && message !== null && (typeof message !== "string" || message.length > 500)) return json({ error: "Invalid message" }, 400);

  const supabase = createClient(supabaseUrl, serviceRoleKey, { auth: { autoRefreshToken: false, persistSession: false } });
  try {
    const { data, error } = await supabase.rpc("sync_courier_tracking_event", {
      p_tracking_number: trackingNumber.trim(),
      p_provider: provider.trim(),
      p_event_id: eventId.trim(),
      p_courier_status: status.trim(),
      p_message: typeof message === "string" ? message.trim() || null : null,
    });
    if (error) throw error;
    return json({ accepted: true, tracking_number: trackingNumber.trim(), provider: provider.trim(), event_id: eventId.trim(), vendor_order_id: data?.id ?? null });
  } catch (error) {
    console.error("Courier webhook synchronization failed", error);
    return json({ error: "Courier tracking synchronization failed" }, 500);
  }
});
