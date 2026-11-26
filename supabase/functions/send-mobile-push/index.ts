import { createClient } from "https://esm.sh/@supabase/supabase-js@2.57.4";

const admin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false, autoRefreshToken: false } },
);

type ServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
};

type Job = { job_id: number; attempt: number; token: string; notice_id: number };
const encoder = new TextEncoder();
const oauthUrl = "https://oauth2.googleapis.com/token";

function base64Url(bytes: Uint8Array): string {
  return btoa(String.fromCharCode(...bytes))
    .replaceAll("+", "-").replaceAll("/", "_").replace(/=+$/, "");
}

async function accessToken(account: ServiceAccount): Promise<string> {
  const pem = account.private_key.replace(/-----[^-]+-----|\s/g, "");
  const key = await crypto.subtle.importKey(
    "pkcs8", Uint8Array.from(atob(pem), (char) => char.charCodeAt(0)),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"],
  );
  const now = Math.floor(Date.now() / 1000);
  const encode = (value: object) => base64Url(encoder.encode(JSON.stringify(value)));
  const assertion = [
    encode({ alg: "RS256", typ: "JWT" }),
    encode({
      iss: account.client_email,
      aud: oauthUrl,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      iat: now,
      exp: now + 3600,
    }),
  ].join(".");
  const signature = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, encoder.encode(assertion));
  const response = await fetch(oauthUrl, {
    method: "POST",
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: assertion + "." + base64Url(new Uint8Array(signature)),
    }),
    signal: AbortSignal.timeout(10000),
  });
  if (!response.ok) throw new Error("FCM OAuth failed");
  const result = await response.json();
  if (typeof result.access_token !== "string") throw new Error("Missing OAuth token");
  return result.access_token;
}

async function deliver(job: Job, project: string, bearer: string): Promise<boolean> {
  const result = await fetch(
    "https://fcm.googleapis.com/v1/projects/" + encodeURIComponent(project) + "/messages:send",
    {
      method: "POST",
      headers: { Authorization: "Bearer " + bearer, "Content-Type": "application/json" },
      body: JSON.stringify({
        message: {
          token: job.token,
          data: { uth_notice_id: String(job.notice_id) },
          notification: { title: "UTH Lab", body: "Bạn có thông báo mới." },
          android: {
            ttl: "3600s",
            notification: { channel_id: "uth_updates", tag: "uth-notice-" + job.notice_id },
          },
        },
      }),
      signal: AbortSignal.timeout(10000),
    },
  );
  const invalid = !result.ok && result.status === 404 &&
    (await result.json()).error?.details?.some(
      (detail: { errorCode?: string }) => detail.errorCode === "UNREGISTERED",
    );
  if (!result.ok && !invalid) return false;
  const { error } = await admin.rpc("finish_mobile_push_job", {
    job_id: job.job_id,
    job_attempt: job.attempt,
    invalid_token: invalid ? job.token : null,
  });
  return !error;
}

Deno.serve(async (request) => {
  if (request.method !== "POST") return new Response(null, { status: 405 });
  const workerToken = request.headers.get("x-push-worker-token");
  if (!workerToken || !/^[a-f0-9]{64}$/.test(workerToken)) {
    return new Response(null, { status: 401 });
  }
  const config = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
  if (!config) return new Response(null, { status: 503 });

  const { data, error } = await admin.rpc("claim_mobile_push_jobs", {
    worker_token: workerToken,
  });
  if (error) return new Response(null, { status: error.code === "42501" ? 401 : 500 });
  const jobs = (data ?? []) as Job[];
  if (jobs.length === 0) return Response.json({ processed: 0 });

  try {
    const account: ServiceAccount = JSON.parse(config);
    const bearer = await accessToken(account);
    const results = await Promise.allSettled(jobs.map((job) => deliver(job, account.project_id, bearer)));
    const processed = results.filter((result) => result.status === "fulfilled" && result.value).length;
    return Response.json({ processed, retrying: jobs.length - processed });
  } catch (_) {
    return new Response(null, { status: 502 });
  }
});
