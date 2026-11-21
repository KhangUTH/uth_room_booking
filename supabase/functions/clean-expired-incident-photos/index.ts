import { createClient } from "https://esm.sh/@supabase/supabase-js@2.57.4";

const admin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false, autoRefreshToken: false } },
);

Deno.serve(async (request) => {
  if (request.method !== "POST") return new Response(null, { status: 405 });
  const token = request.headers.get("x-cleanup-token");
  if (!token || !/^[0-9a-f]{64}$/.test(token)) {
    return new Response(null, { status: 401 });
  }

  const { data: paths, error } = await admin.rpc(
    "claim_expired_incident_photos",
    { cleanup_token: token },
  );
  if (error) {
    return new Response(null, { status: error.code === "42501" ? 401 : 500 });
  }
  if (!paths?.length) return Response.json({ removed: 0 });

  const result = await admin.storage.from("incident-images").remove(paths);
  if (result.error) return new Response(null, { status: 502 });
  return Response.json({ removed: result.data.length });
});
