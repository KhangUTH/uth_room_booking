import { useEffect, useState } from "react";
import { AuthContext } from "./AuthContext.js";
import { supabase } from "../lib/supabase.js";
import { getAdminAccess, loadProfile } from "../lib/adminAccess.js";

const enforceAdminMfa = import.meta.env.VITE_ADMIN_MFA_REQUIRED === "true";
const deviceStorageKey = "uth-admin-browser-id";

function browserId() {
  const bytes = crypto.getRandomValues(new Uint8Array(16));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  const hex = Array.from(bytes, (byte) => byte.toString(16).padStart(2, "0")).join("");
  const id = [hex.slice(0, 8), hex.slice(8, 12), hex.slice(12, 16), hex.slice(16, 20), hex.slice(20)].join("-");
  try {
    const stored = localStorage.getItem(deviceStorageKey);
    if (stored && /^[\da-f]{8}(?:-[\da-f]{4}){3}-[\da-f]{12}$/i.test(stored)) return stored;
    localStorage.setItem(deviceStorageKey, id);
  } catch { /* This tab can still use its in-memory identifier. */ }
  return id;
}

async function adminSession(action, signal, id) {
  const request = supabase.rpc("admin_web_session", { action, browser_id: id ?? null });
  const { data, error } = await (signal ? request.abortSignal(signal) : request);
  if (error) throw error;
  return data;
}

export default function AuthProvider({ children }) {
  const [session, setSession] = useState(null);
  const [loading, setLoading] = useState(Boolean(supabase));
  const [profileResult, setProfileResult] = useState(null);
  const [profileRevision, setProfileRevision] = useState(0);
  const [deviceId] = useState(browserId);
  const [deviceNotice, setDeviceNotice] = useState("");
  const accessToken = session?.access_token;
  const userId = session?.user?.id;

  const profileLoading = Boolean(session) && (
    profileResult?.accessToken !== accessToken || profileResult?.revision !== profileRevision
  );
  const profile = session && !profileLoading ? profileResult?.profile ?? null : null;
  const mfaRequired = profileResult?.accessToken === accessToken && profileResult?.mfaRequired === true;
  const access = session && !profileLoading
    ? getAdminAccess(userId, profile, profileResult?.error)
    : { isAdmin: false, accessError: null };
  const sessionStatus = !profileLoading ? profileResult?.sessionStatus : null;
  const isAdmin = access.isAdmin && !mfaRequired && sessionStatus === "active";
  const switchRequired = access.isAdmin && !mfaRequired && sessionStatus === "conflict";

  useEffect(() => {
    if (!supabase) return;
    // INITIAL_SESSION also covers sessions restored from storage and recovery URLs.
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, nextSession) => {
      setSession(nextSession);
      if (!nextSession) setProfileResult(null);
      setLoading(false);
    });
    return () => subscription.unsubscribe();
  }, []);

  // Query outside the auth callback; never reuse a previous session's permissions.
  useEffect(() => {
    if (!userId || !accessToken) return;
    let active = true;
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 12000);

    async function fetchProfile() {
      try {
        const nextProfile = await loadProfile(supabase, userId, controller.signal);
        let requiresMfa = false;
        if (enforceAdminMfa && getAdminAccess(userId, nextProfile).isAdmin) {
          const { data, error } = await supabase.auth.mfa.getAuthenticatorAssuranceLevel(accessToken);
          if (error) throw error;
          requiresMfa = data.currentLevel !== "aal2";
        }
        const status = getAdminAccess(userId, nextProfile).isAdmin && !requiresMfa && window.location.pathname !== "/reset-password"
          ? await adminSession("claim", controller.signal, deviceId)
          : null;
        if (!active) return;
        if (status === "revoked") {
          setDeviceNotice("Phiên quản trị đã kết thúc. Vui lòng đăng nhập lại.");
          setSession(null);
          setProfileResult(null);
          void supabase.auth.signOut({ scope: "local" });
          return;
        }
        setProfileResult({ accessToken, revision: profileRevision, profile: nextProfile, mfaRequired: requiresMfa, sessionStatus: status, error: null });
      } catch (error) {
        if (active) setProfileResult({ accessToken, revision: profileRevision, profile: null, error });
      } finally {
        clearTimeout(timeout);
      }
    }

    void fetchProfile();
    return () => {
      active = false;
      clearTimeout(timeout);
      controller.abort();
    };
  }, [userId, accessToken, profileRevision, deviceId]);

  useEffect(() => {
    if (!isAdmin) return;
    let active = true;
    let request;
    async function check() {
      if (request) return;
      request = new AbortController();
      const timeout = setTimeout(() => request.abort(), 8000);
      try {
        if (await adminSession("status", request.signal) === "revoked" && active) {
          setDeviceNotice("Tài khoản đã chuyển sang thiết bị khác. Bạn đã được đăng xuất.");
          setSession(null);
          setProfileResult(null);
          void supabase.auth.signOut({ scope: "local" });
        }
      } catch { /* Keep checking when the connection returns. */ }
      finally { clearTimeout(timeout); request = null; }
    }
    const timer = setInterval(check, 4000);
    document.addEventListener("visibilitychange", check);
    return () => {
      active = false;
      request?.abort();
      clearInterval(timer);
      document.removeEventListener("visibilitychange", check);
    };
  }, [accessToken, isAdmin]);

  function refreshProfile() {
    setProfileRevision((revision) => revision + 1);
  }

  async function signIn(email, password, captchaToken) {
    setDeviceNotice("");
    const { data: result, error: requestError } = await supabase.functions.invoke("sign-in-by-code", {
      body: { email, password, role: "admin", captchaToken },
    });
    if (requestError) {
      const status = requestError.context?.status;
      if (status === 429 || status === 401) {
        throw { status, code: status === 401 ? "invalid_credentials" : "over_request_rate_limit" };
      }
      const body = await requestError.context?.json?.().catch(() => null);
      if (["captcha_required", "captcha_failed", "captcha_unavailable"].includes(body?.code)) throw { code: body.code };
      throw requestError;
    }
    const tokens = result?.session;
    if (!tokens?.access_token || !tokens?.refresh_token) throw new Error("Missing login session");
    const { data, error } = await supabase.auth.setSession({
      access_token: tokens.access_token,
      refresh_token: tokens.refresh_token,
    });
    if (error) throw error;
    setSession(data.session);
  }

  async function signOut() {
    if (isAdmin) {
      try { await adminSession("release", AbortSignal.timeout(5000)); }
      catch { /* Auth sign-out also invalidates the session. */ }
    }
    const { error } = await supabase.auth.signOut({ scope: "local" });
    if (error) throw error;
    setSession(null);
    setProfileResult(null);
  }

  async function switchDevice() {
    if (!switchRequired || await adminSession("switch", AbortSignal.timeout(12000), deviceId) !== "active") {
      throw new Error("Cannot switch admin device");
    }
    refreshProfile();
  }

  return (
    <AuthContext.Provider value={{ session, user: session?.user ?? null, profile, loading, profileLoading, ...access, isAdmin, mfaRequired, switchRequired, switchDevice, deviceNotice, refreshProfile, signIn, signOut }}>
      {children}
    </AuthContext.Provider>
  );
}
