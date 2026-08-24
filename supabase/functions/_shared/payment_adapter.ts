export type NormalizedPaymentEvent = {
  orderGroupId: string;
  status: "pending" | "paid" | "failed" | "refunded";
  provider: string;
  providerReference: string | null;
  eventId: string;
  metadata: Record<string, unknown>;
};

const isUuid = (value: unknown): value is string =>
  typeof value === "string" && /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);

const isRecord = (value: unknown): value is Record<string, unknown> =>
  Boolean(value) && typeof value === "object" && !Array.isArray(value);

export function normalizePaymentEvent(payload: unknown): NormalizedPaymentEvent {
  if (!isRecord(payload)) throw new Error("Payload must be an object");

  const orderGroupId = payload.order_group_id;
  const status = payload.status;
  const provider = payload.provider;
  const providerReference = payload.provider_reference;
  const eventId = payload.event_id;
  const metadata = payload.metadata;

  if (!isUuid(orderGroupId)) throw new Error("order_group_id must be a UUID");
  if (status !== "pending" && status !== "paid" && status !== "failed" && status !== "refunded") throw new Error("Invalid payment status");
  if (typeof provider !== "string" || provider.trim().length < 2 || provider.trim().length > 64) throw new Error("Invalid provider");
  if (typeof eventId !== "string" || eventId.trim().length < 3 || eventId.trim().length > 160) throw new Error("event_id is required");
  if (providerReference !== undefined && providerReference !== null && (typeof providerReference !== "string" || providerReference.length > 160)) throw new Error("Invalid provider_reference");
  if (metadata !== undefined && !isRecord(metadata)) throw new Error("metadata must be an object");

  return {
    orderGroupId,
    status,
    provider: provider.trim(),
    providerReference: typeof providerReference === "string" ? providerReference.trim() || null : null,
    eventId: eventId.trim(),
    metadata: { ...(metadata ?? {}), event_id: eventId.trim() },
  };
}
