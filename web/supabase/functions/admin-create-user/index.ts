import { createClient } from "npm:@supabase/supabase-js@2.119.0";
import { createAdminUserHandler } from "./handler.js";

Deno.serve(createAdminUserHandler(createClient, (name: string) => Deno.env.get(name)));
