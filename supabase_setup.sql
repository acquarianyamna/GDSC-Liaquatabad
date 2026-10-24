-- Run once in Supabase: SQL Editor -> New query -> paste -> Run

create table if not exists public.timetable (
  class text primary key,
  data jsonb not null,
  updated_at timestamptz default now()
);

create table if not exists public.day_overrides (
  day date not null,
  class text not null,
  slots jsonb not null,
  updated_at timestamptz default now(),
  primary key (day, class)
);

create table if not exists public.attendance (
  id bigint generated always as identity primary key,
  day date not null,
  class text not null,
  period text not null,
  teacher text not null,
  subject text not null,
  status text not null check (status in ('on_time','late','absent','students_absent')),
  late_minutes int default 0,
  photo text,
  note text,
  created_at timestamptz default now()
);
create index if not exists attendance_day_idx on public.attendance (day, teacher);

alter table public.timetable      enable row level security;
alter table public.day_overrides  enable row level security;
alter table public.attendance     enable row level security;

-- Everyone can READ the time table and daily shifts (public page)
create policy "public read timetable"     on public.timetable     for select to anon, authenticated using (true);
create policy "public read day_overrides" on public.day_overrides for select to anon, authenticated using (true);
-- Only the logged-in officer can WRITE, and only the officer can read raw attendance (photos stay private)
create policy "officer write timetable"     on public.timetable     for all to authenticated using (true) with check (true);
create policy "officer write day_overrides" on public.day_overrides for all to authenticated using (true) with check (true);
create policy "officer all attendance"      on public.attendance    for all to authenticated using (true) with check (true);

-- Public status badges (no photos / notes) for the time table page
create or replace view public.attendance_public as
  select day, class, period, teacher, subject, status, late_minutes from public.attendance;
grant select on public.attendance_public to anon, authenticated;
