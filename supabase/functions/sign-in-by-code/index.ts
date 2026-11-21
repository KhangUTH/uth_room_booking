import { createClient } from "https://esm.sh/@supabase/supabase-js@2.57.4";

const url = Deno.env.get("SUPABASE_URL")!;
const admin = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
  auth: { persistSession: false, autoRefreshToken: false },
});
const codeColumns = new Map([
  ["student", "student_code"],
  ["teacher", "lecturer_code"],
  ["technician", "employee_code"],
]);
const json = (body: object, status: number) =>
  Response.json(body, { status, headers: { "Cache-Control": "no-store" } });
const invalid = () => json({ code: "invalid_credentials" }, 401);
const unavailable = () => json({ code: "login_unavailable" }, 503);

Deno.serve(async (req) => {
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
    if (!body || typeof body.code !== "string" ||
        typeof body.password !== "string" || !codeColumns.has(body.role)) return invalid();
    const code = body.code.trim();
    if (!code || code.length > 128 || !body.password) return invalid();

    const { data: profile, error } = await admin.from("profiles")
      .select("id").eq(codeColumns.get(body.role)!, code).eq("role", body.role)
      .eq("is_active", true).maybeSingle();
    if (error) return unavailable();
    if (!profile) return invalid();

    const { data, error: accountError } = await admin.auth.admin.getUserById(profile.id);
    if (accountError || !data.user?.email) return invalid();

    const auth = createClient(url, Deno.env.get("SUPABASE_ANON_KEY")!, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const signedIn = await auth.auth.signInWithPassword({
      email: data.user.email, password: body.password,
    });
    if (signedIn.error?.status === 429) {
      return json({ code: "over_request_rate_limit" }, 429);
    }
    if (!signedIn.data.session || signedIn.data.user?.id !== profile.id) return invalid();
    return json({
      session: signedIn.data.session,
      refresh_token: signedIn.data.session.refresh_token,
    }, 200);
  } catch {
    return unavailable();
  }
});
