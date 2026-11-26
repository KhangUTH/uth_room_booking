const verificationUrl = "https://challenges.cloudflare.com/turnstile/v0/siteverify";

export async function verifyAdminCaptcha(token: string): Promise<"valid" | "invalid" | "unavailable"> {
  const secret = Deno.env.get("ADMIN_TURNSTILE_SECRET_KEY");
  if (!secret) return "unavailable";
  if (!token || token.length > 2048) return "invalid";

  try {
    const response = await fetch(verificationUrl, {
      method: "POST",
      body: new URLSearchParams({ secret, response: token }),
      signal: AbortSignal.timeout(5000),
    });
    if (!response.ok) return "unavailable";
    const result = await response.json();
    return result.success === true && result.action === "admin_login" ? "valid" : "invalid";
  } catch {
    return "unavailable";
  }
}
