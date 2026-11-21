-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.profiles (
  id uuid NOT NULL,
  email text NOT NULL,
  full_name text,
  student_code text,
  role USER-DEFINED NOT NULL DEFAULT 'student'::user_role,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  lecturer_code text,
  employee_code text,
  faculty text,
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
CREATE TABLE public.rooms (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  location text,
  capacity integer CHECK (capacity IS NULL OR capacity > 0),
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  is_archived boolean NOT NULL DEFAULT false,
  CONSTRAINT rooms_pkey PRIMARY KEY (id)
);
CREATE TABLE public.equipment (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  room_id uuid,
  status text NOT NULL DEFAULT 'available'::text CHECK (status = ANY (ARRAY['available'::text, 'in_use'::text, 'broken'::text])),
  note text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  location text,
  CONSTRAINT equipment_pkey PRIMARY KEY (id),
  CONSTRAINT equipment_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.rooms(id)
);
CREATE TABLE public.bookings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid(),
  room_id uuid,
  equipment_id uuid,
  start_time timestamp with time zone NOT NULL,
  end_time timestamp with time zone NOT NULL,
  purpose text,
  status USER-DEFINED NOT NULL DEFAULT 'pending'::booking_status,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  student_count integer,
  teaching_section_id uuid,
  CONSTRAINT bookings_pkey PRIMARY KEY (id),
  CONSTRAINT bookings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT bookings_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.rooms(id),
  CONSTRAINT bookings_equipment_id_fkey FOREIGN KEY (equipment_id) REFERENCES public.equipment(id),
  CONSTRAINT bookings_teaching_section_id_fkey FOREIGN KEY (teaching_section_id) REFERENCES public.teaching_sections(id)
);
CREATE TABLE public.incident_reports (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  reporter_id uuid NOT NULL DEFAULT auth.uid(),
  room_id uuid,
  equipment_id uuid,
  title text NOT NULL,
  description text,
  status USER-DEFINED NOT NULL DEFAULT 'open'::incident_status,
  resolved_by uuid,
  resolved_at timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT incident_reports_pkey PRIMARY KEY (id),
  CONSTRAINT incident_reports_reporter_id_fkey FOREIGN KEY (reporter_id) REFERENCES public.profiles(id),
  CONSTRAINT incident_reports_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.rooms(id),
  CONSTRAINT incident_reports_equipment_id_fkey FOREIGN KEY (equipment_id) REFERENCES public.equipment(id),
  CONSTRAINT incident_reports_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES public.profiles(id)
);
CREATE TABLE public.teaching_sections (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  lecturer_id uuid NOT NULL,
  code text NOT NULL CHECK (length(TRIM(BOTH FROM code)) > 0),
  name text NOT NULL CHECK (length(TRIM(BOTH FROM name)) > 0),
  CONSTRAINT teaching_sections_pkey PRIMARY KEY (id),
  CONSTRAINT teaching_sections_lecturer_id_fkey FOREIGN KEY (lecturer_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.app_notifications (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  recipient_id uuid NOT NULL,
  booking_id uuid,
  title text NOT NULL,
  message text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  is_read boolean NOT NULL DEFAULT false,
  is_saved boolean NOT NULL DEFAULT false,
  CONSTRAINT app_notifications_pkey PRIMARY KEY (id),
  CONSTRAINT app_notifications_recipient_id_fkey FOREIGN KEY (recipient_id) REFERENCES public.profiles(id),
  CONSTRAINT app_notifications_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id)
);