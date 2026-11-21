-- Snapshot of the existing UTHBookingApp schema, without data.

-- Run on a fresh Supabase database or after the standalone Auth test fixture.

create schema if not exists extensions;

create extension if not exists btree_gist with schema public;

create type public."booking_status" as enum ('pending', 'approved', 'rejected', 'cancelled', 'completed');

create type public."incident_status" as enum ('open', 'in_progress', 'resolved');

create type public."user_role" as enum ('student', 'teacher', 'technician');

create table public."bookings" (
  "id" uuid default gen_random_uuid() not null,
  "user_id" uuid default auth.uid() not null,
  "room_id" uuid,
  "equipment_id" uuid,
  "start_time" timestamp with time zone not null,
  "end_time" timestamp with time zone not null,
  "purpose" text,
  "status" booking_status default 'pending'::booking_status not null,
  "created_at" timestamp with time zone default now() not null
);

create table public."equipment" (
  "id" uuid default gen_random_uuid() not null,
  "name" text not null,
  "room_id" uuid,
  "status" text default 'available'::text not null,
  "note" text,
  "created_at" timestamp with time zone default now() not null
);

create table public."incident_reports" (
  "id" uuid default gen_random_uuid() not null,
  "reporter_id" uuid default auth.uid() not null,
  "room_id" uuid,
  "equipment_id" uuid,
  "title" text not null,
  "description" text,
  "status" incident_status default 'open'::incident_status not null,
  "resolved_by" uuid,
  "resolved_at" timestamp with time zone,
  "created_at" timestamp with time zone default now() not null
);

create table public."profiles" (
  "id" uuid not null,
  "email" text not null,
  "full_name" text,
  "student_code" text,
  "role" user_role default 'student'::user_role not null,
  "is_active" boolean default true not null,
  "created_at" timestamp with time zone default now() not null
);

create table public."rooms" (
  "id" uuid default gen_random_uuid() not null,
  "name" text not null,
  "location" text,
  "capacity" integer,
  "is_active" boolean default true not null,
  "created_at" timestamp with time zone default now() not null
);

alter table public."bookings" add constraint "bookings_pkey" PRIMARY KEY (id);

alter table public."equipment" add constraint "equipment_pkey" PRIMARY KEY (id);

alter table public."incident_reports" add constraint "incident_reports_pkey" PRIMARY KEY (id);

alter table public."profiles" add constraint "profiles_pkey" PRIMARY KEY (id);

alter table public."rooms" add constraint "rooms_pkey" PRIMARY KEY (id);

alter table public."bookings" add constraint "bookings_check" CHECK ((end_time > start_time));

alter table public."bookings" add constraint "bookings_check1" CHECK (((room_id IS NOT NULL) OR (equipment_id IS NOT NULL)));

alter table public."equipment" add constraint "equipment_status_check" CHECK ((status = ANY (ARRAY['available'::text, 'in_use'::text, 'broken'::text])));

alter table public."incident_reports" add constraint "incident_reports_check" CHECK (((room_id IS NOT NULL) OR (equipment_id IS NOT NULL)));

alter table public."bookings" add constraint "no_equipment_overlap" EXCLUDE USING gist (equipment_id WITH =, tstzrange(start_time, end_time) WITH &&) WHERE (((equipment_id IS NOT NULL) AND (status = ANY (ARRAY['pending'::booking_status, 'approved'::booking_status]))));

alter table public."bookings" add constraint "no_room_overlap" EXCLUDE USING gist (room_id WITH =, tstzrange(start_time, end_time) WITH &&) WHERE (((room_id IS NOT NULL) AND (status = ANY (ARRAY['pending'::booking_status, 'approved'::booking_status]))));

alter table public."rooms" add constraint "rooms_capacity_check" CHECK (((capacity IS NULL) OR (capacity > 0)));

alter table public."bookings" add constraint "bookings_equipment_id_fkey" FOREIGN KEY (equipment_id) REFERENCES equipment(id) ON DELETE CASCADE;

alter table public."bookings" add constraint "bookings_room_id_fkey" FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE;

alter table public."bookings" add constraint "bookings_user_id_fkey" FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;

alter table public."equipment" add constraint "equipment_room_id_fkey" FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE SET NULL;

alter table public."incident_reports" add constraint "incident_reports_equipment_id_fkey" FOREIGN KEY (equipment_id) REFERENCES equipment(id) ON DELETE SET NULL;

alter table public."incident_reports" add constraint "incident_reports_reporter_id_fkey" FOREIGN KEY (reporter_id) REFERENCES profiles(id) ON DELETE CASCADE;

alter table public."incident_reports" add constraint "incident_reports_resolved_by_fkey" FOREIGN KEY (resolved_by) REFERENCES profiles(id) ON DELETE SET NULL;

alter table public."incident_reports" add constraint "incident_reports_room_id_fkey" FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE SET NULL;

alter table public."profiles" add constraint "profiles_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;

CREATE UNIQUE INDEX profiles_email_key ON public.profiles USING btree (lower(email));

CREATE UNIQUE INDEX profiles_student_code_key ON public.profiles USING btree (student_code) WHERE (student_code IS NOT NULL);

CREATE INDEX bookings_user_idx ON public.bookings USING btree (user_id);

CREATE INDEX bookings_room_idx ON public.bookings USING btree (room_id, start_time);

CREATE INDEX bookings_equip_idx ON public.bookings USING btree (equipment_id, start_time);

CREATE INDEX incident_reports_reporter_idx ON public.incident_reports USING btree (reporter_id);

CREATE INDEX incident_reports_status_idx ON public.incident_reports USING btree (status, created_at DESC);

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if new.email is null or lower(new.email) not like '%@ut.edu.vn' then
    raise exception 'Chỉ cho phép email @ut.edu.vn (nhận: %)', new.email;
  end if;

  insert into public.profiles (id, email, full_name, student_code, role)
  values (
    new.id,
    lower(new.email),
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'student_code',
    coalesce(nullif(new.raw_app_meta_data->>'app_role', '')::public.user_role,
             'student')
  );
  return new;
end;
$function$;

CREATE OR REPLACE FUNCTION public.my_role()
 RETURNS user_role
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select role from public.profiles where id = auth.uid()
$function$;

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION handle_new_user();

alter table public."bookings" enable row level security;
grant all on public."bookings" to anon, authenticated, service_role;

alter table public."equipment" enable row level security;
grant all on public."equipment" to anon, authenticated, service_role;

alter table public."incident_reports" enable row level security;
grant all on public."incident_reports" to anon, authenticated, service_role;

alter table public."profiles" enable row level security;
grant all on public."profiles" to anon, authenticated, service_role;

alter table public."rooms" enable row level security;
grant all on public."rooms" to anon, authenticated, service_role;

create policy "bookings: huỷ lịch của mình" on public."bookings" for update to "authenticated"
  using ((user_id = auth.uid()))
  with check (((user_id = auth.uid()) AND (status = 'cancelled'::booking_status)));

create policy "bookings: staff cập nhật" on public."bookings" for update to "authenticated"
  using ((my_role() = ANY (ARRAY['teacher'::user_role, 'technician'::user_role])))
  with check ((my_role() = ANY (ARRAY['teacher'::user_role, 'technician'::user_role])));

create policy "bookings: tạo" on public."bookings" for insert to "authenticated"
  with check (((user_id = auth.uid()) AND (status = 'pending'::booking_status) AND (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND p.is_active)))));

create policy "bookings: xem" on public."bookings" for select to "authenticated"
  using (((user_id = auth.uid()) OR (status = 'approved'::booking_status) OR (my_role() = ANY (ARRAY['teacher'::user_role, 'technician'::user_role]))));

create policy "equipment: technician quản lý" on public."equipment" for all to "authenticated"
  using ((my_role() = 'technician'::user_role))
  with check ((my_role() = 'technician'::user_role));

create policy "equipment: xem" on public."equipment" for select to "authenticated"
  using (true);

create policy "incident_reports: technician xử lý" on public."incident_reports" for update to "authenticated"
  using ((my_role() = 'technician'::user_role))
  with check ((my_role() = 'technician'::user_role));

create policy "incident_reports: tạo" on public."incident_reports" for insert to "authenticated"
  with check (((reporter_id = auth.uid()) AND (status = 'open'::incident_status) AND (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND p.is_active)))));

create policy "incident_reports: xem" on public."incident_reports" for select to "authenticated"
  using (((reporter_id = auth.uid()) OR (my_role() = ANY (ARRAY['teacher'::user_role, 'technician'::user_role]))));

create policy "profiles: xem" on public."profiles" for select to "authenticated"
  using (((id = auth.uid()) OR (my_role() = ANY (ARRAY['teacher'::user_role, 'technician'::user_role]))));

create policy "rooms: technician quản lý" on public."rooms" for all to "authenticated"
  using ((my_role() = 'technician'::user_role))
  with check ((my_role() = 'technician'::user_role));

create policy "rooms: xem" on public."rooms" for select to "authenticated"
  using (true);
