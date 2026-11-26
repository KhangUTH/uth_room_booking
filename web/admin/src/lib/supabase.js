import { createClient } from "@supabase/supabase-js";

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY
  || import.meta.env.VITE_SUPABASE_ANON_KEY;
const isLocalHost = typeof window !== "undefined"
  && ["localhost", "127.0.0.1", "[::1]"].includes(window.location.hostname);

export const isSupabaseConfigured = Boolean(supabaseUrl && supabaseKey);

// Only use a publishable/anon key here. Service role keys must stay on a server.
export const supabase = isSupabaseConfigured
  ? createClient(supabaseUrl, supabaseKey, {
      auth: {
        persistSession: !isLocalHost,
        autoRefreshToken: true,
        detectSessionInUrl: true,
      },
    })
  : null;
