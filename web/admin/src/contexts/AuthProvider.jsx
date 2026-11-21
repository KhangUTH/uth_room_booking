import { useEffect, useState } from "react";
import { AuthContext } from "./AuthContext.js";
import { supabase } from "../lib/supabase.js";
import { getAdminAccess, loadProfile } from "../lib/adminAccess.js";

export default function AuthProvider({ children }) {
  const [session, setSession] = useState(null);
  const [loading, setLoading] = useState(Boolean(supabase));
  const [profileResult, setProfileResult] = useState(null);
  const [profileRevision, setProfileRevision] = useState(0);
  const accessToken = session?.access_token;
  const userId = session?.user?.id;

  const profileLoading = Boolean(session) && (
    profileResult?.accessToken !== accessToken || profileResult?.revision !== profileRevision
  );
  const profile = session && !profileLoading ? profileResult?.profile ?? null : null;
  const access = session && !profileLoading
    ? getAdminAccess(userId, profile, profileResult?.error)
    : { isAdmin: false, accessError: null };

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
        if (active) setProfileResult({ accessToken, revision: profileRevision, profile: nextProfile, error: null });
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
  }, [userId, accessToken, profileRevision]);

  function refreshProfile() {
    setProfileRevision((revision) => revision + 1);
  }

  async function signIn(email, password) {
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) throw error;
    setSession(data.session);
  }

  async function signOut() {
    const { error } = await supabase.auth.signOut({ scope: "local" });
    if (error) throw error;
    setSession(null);
    setProfileResult(null);
  }

  return (
    <AuthContext.Provider value={{ session, user: session?.user ?? null, profile, loading, profileLoading, ...access, refreshProfile, signIn, signOut }}>
      {children}
    </AuthContext.Provider>
  );
}
