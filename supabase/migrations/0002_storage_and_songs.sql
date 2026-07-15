-- Iran Seda — Storage buckets + policies
-- Run this in Supabase SQL editor (or via supabase CLI) ONCE.
-- The buckets `music` and `covers` are referenced in lib/core/constants.dart.

-- 1) Create storage buckets (public so the app can read files without auth)
insert into storage.buckets (id, name, public)
values
  ('music',  'music',  true),
  ('covers', 'covers', true)
on conflict (id) do update set public = true;

-- 2) Allow public read of both buckets
create policy "Public read music"
  on storage.objects for select
  using (bucket_id = 'music');
create policy "Public read covers"
  on storage.objects for select
  using (bucket_id = 'covers');

-- 3) Allow authenticated users to upload (admin panel uses anon key, so allow anon insert too)
create policy "Anon insert music"
  on storage.objects for insert to anon
  with check (bucket_id = 'music');
create policy "Anon insert covers"
  on storage.objects for insert to anon
  with check (bucket_id = 'covers');

-- 4) Ensure the songs table exists (idempotent). Adjust columns if your schema differs.
create table if not exists public.songs (
  id          uuid primary key default gen_random_uuid(),
  title       text not null,
  artist      text not null,
  genre       text,
  audio_url   text not null,
  cover_url   text,
  plays       integer default 0,
  created_at  timestamptz default now()
);

-- 5) Public read on songs
alter table public.songs enable row level security;
create policy "Public read songs"
  on public.songs for select
  using (true);
