import { createClient } from "https://esm.sh/@supabase/supabase-js@2.57.4";

const url = Deno.env.get("SUPABASE_URL")!;
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const admin = createClient(url, serviceKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});
const codeColumns = new Map([
  ["student", "student_code"],
  ["teacher", "lecturer_code"],
  ["technician", "employee_code"],
]);
const headers = {
  "Cache-Control": "no-store",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (body: object, status: number) => Response.json(body, { status, headers });
const invalid = () => json({ code: "invalid_credentials" }, 401);
const unavailable = () => json({ code: "login_unavailable" }, 503);
const rateLimited = () => Response.json({ code: "over_request_rate_limit" }, {
  status: 429,
  headers: { ...headers, "Retry-After": "300" },
});

const loginHashKey = crypto.subtle.importKey(
  "raw", new TextEncoder().encode(serviceKey),
  { name: "HMAC", hash: "SHA-256" }, false, ["sign"],
);

async function identifierHash(identifier: string) {
  const digest = await crypto.subtle.sign("HMAC", await loginHashKey, new TextEncoder().encode(identifier));
  return Array.from(new Uint8Array(digest), (byte) => byte.toString(16).padStart(2, "0")).join("");
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers });
  if (req.method !== "POST") return json({ code: "method_not_allowed" }, 405);
  if (Number(req.headers.get("content-length")) > 4096) return invalid();
  try {
    const raw = await req.text();
    if (raw.length > 4096) return invalid();
    let body;
    try {
      body = JSON.parse(raw);
    } catch {
      return invalid();
    }
    if (!body || typeof body.password !== "string" || !body.password) return invalid();
    const hasEmail = typeof body.email === "string";
    const hasCode = typeof body.code === "string";
    if (hasEmail === hasCode || (!codeColumns.has(body.role) && !(hasEmail && body.role === "admin"))) return invalid();
    const code = hasCode ? body.code.trim() : "";
    let email = hasEmail ? body.email.trim().toLowerCase() : "";
    if (hasEmail ? email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) : !code || code.length > 128) return invalid();
    if (body.captchaToken !== undefined && typeof body.captchaToken !== "string") return invalid();

    const { data: allowed, error: rateError } = await admin.rpc("consume_code_login_attempt", {
      login_hash: await identifierHash(hasEmail ? `email-login:${email}` : `code-login:${body.role}:${code.toLowerCase()}`),
    });
    if (rateError) return unavailable();
    if (allowed !== true) return rateLimited();

    let expectedUserId: string | undefined;
    if (hasCode) {
      const { data: profile, error } = await admin.from("profiles")
        .select("id").eq(codeColumns.get(body.role)!, code).eq("role", body.role)
        .eq("is_active", true).maybeSingle();
      if (error) return unavailable();
      if (!profile) return invalid();
      const { data, error: accountError } = await admin.auth.admin.getUserById(profile.id);
      if (accountError || !data.user?.email) return invalid();
      expectedUserId = profile.id;
      email = data.user.email;
    }

    const auth = createClient(url, Deno.env.get("SUPABASE_ANON_KEY")!, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const signedIn = await auth.auth.signInWithPassword({
      email, password: body.password,
      options: { captchaToken: body.captchaToken },
    });
    if (signedIn.error?.status === 429) {
      return rateLimited();
    }
    if (signedIn.error?.code === "captcha_failed") return json({ code: "captcha_failed" }, 400);
    const { session, user } = signedIn.data;
    if (!session || !user) return invalid();
    const { data: profile, error: profileError } = await admin.from("profiles")
      .select("id").eq("id", user.id).eq("role", body.role).eq("is_active", true).maybeSingle();
    if (profileError || !profile || (expectedUserId && expectedUserId !== user.id)) {
      await auth.auth.signOut({ scope: "local" });
      return profileError ? unavailable() : invalid();
    }
    return json({
      session,
      refresh_token: session.refresh_token,
    }, 200);
  } catch {
    return unavailable();
  }
});
