alter policy "profiles: xem" on public.profiles using (id = (select auth.uid()));
revoke all on table public.profiles from anon;
revoke insert, update, delete, truncate, references, trigger on table public.profiles from authenticated;
