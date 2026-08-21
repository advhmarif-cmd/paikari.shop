import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const origenCatalogUrl = Deno.env.get("ORIGEN_CATALOG_URL") ?? "https://origen-prime.vercel.app/api/products";
const origenSyncSecret = Deno.env.get("ORIGEN_SYNC_SECRET");

if (!supabaseUrl || !serviceRoleKey) {
  throw new Error("Supabase service configuration is missing");
}

const supabase = createClient(supabaseUrl, serviceRoleKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

type OrigenProduct = {
  id: string;
  slug?: string;
  title?: string;
  description?: string;
  sale_price?: number | string;
  regular_price?: number | string;
  images?: unknown;
  video_url?: string | null;
  category?: string | null;
  stock_status?: string | null;
  is_active?: boolean;
  updated_at?: string | null;
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });

Deno.serve(async (request) => {
  if (request.method !== "POST") return json({ error: "POST required" }, 405);

  const syncSecret = request.headers.get("x-origen-sync-secret");
  const hasValidSyncSecret = Boolean(origenSyncSecret && syncSecret && syncSecret === origenSyncSecret);
  let triggeredBy = "service-secret";

  if (!hasValidSyncSecret) {
    const authHeader = request.headers.get("authorization");
    if (!authHeader?.startsWith("Bearer ")) return json({ error: "Authentication required" }, 401);
    const accessToken = authHeader.slice("Bearer ".length);
    const { data: authData, error: authError } = await supabase.auth.getUser(accessToken);
    if (authError || !authData.user) return json({ error: "Invalid session" }, 401);
    triggeredBy = authData.user.id;
  }

  try {
    const response = await fetch(origenCatalogUrl, {
      headers: { accept: "application/json" },
    });
    if (!response.ok) {
      return json({ error: `Origen catalog request failed: ${response.status}` }, 502);
    }

    const payload = await response.json();
    const products = Array.isArray(payload) ? payload as OrigenProduct[] : [payload as OrigenProduct];
    const activeProducts = products.filter((product) => product.id && product.is_active !== false);

    const rows = activeProducts.map((product) => {
      const images = Array.isArray(product.images)
        ? product.images.filter((image): image is string => typeof image === "string")
        : [];
      const retailPrice = Number(product.regular_price ?? product.sale_price ?? 0);
      const salePrice = Number(product.sale_price ?? retailPrice);
      if (!Number.isFinite(retailPrice) || !Number.isFinite(salePrice)) {
        throw new Error(`Invalid price for product ${product.id}`);
      }

      return {
        id: product.id,
        source: "origen",
        origin_product_id: product.id,
        owner_id: null,
        slug: product.slug ?? product.id,
        name: product.title ?? "",
        description: product.description ?? "",
        retail_price: retailPrice,
        sale_price: salePrice,
        wholesale_tiers: [],
        image_url: images[0] ?? "",
        images,
        video_url: product.video_url ?? null,
        category: product.category ?? "",
        stock_status: product.stock_status ?? "In Stock",
        is_active: true,
        source_updated_at: product.updated_at ?? null,
        last_synced_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      };
    });

    const { data: existingRows, error: existingError } = await supabase
      .from("catalog_products")
      .select("id, origin_product_id")
      .eq("source", "origen")
      .limit(5000);
    if (existingError) throw existingError;

    const currentOriginIds = new Set(rows.map((row) => row.origin_product_id));
    const removedIds = (existingRows ?? [])
      .filter((row) => row.origin_product_id && !currentOriginIds.has(row.origin_product_id))
      .map((row) => row.id);

    if (removedIds.length > 0) {
      const { error: deactivateError } = await supabase
        .from("catalog_products")
        .update({ is_active: false, updated_at: new Date().toISOString() })
        .in("id", removedIds);
      if (deactivateError) throw deactivateError;
    }

    if (rows.length > 0) {
      const { error: upsertError } = await supabase
        .from("catalog_products")
        .upsert(rows, { onConflict: "source,origin_product_id" });
      if (upsertError) throw upsertError;
    }

    return json({
      synced: rows.length,
      deactivated: removedIds.length,
      source: "origen",
      triggeredBy,
    });
  } catch (error) {
    console.error("Hybrid catalog sync failed", error);
    return json({ error: error instanceof Error ? error.message : "Sync failed" }, 500);
  }
});
