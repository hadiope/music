-- ============================================================
--  Harmony Music — Supabase schema + Row Level Security
--  Run this in: Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

-- ---------- SONGS ----------
create table if not exists public.songs (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  artist text not null,
  album text,
  cover_url text,
  audio_url text not null,
  genre text,
  plays int default 0,
  duration_ms int,
  created_at timestamptz default now()
);

-- ---------- ALBUMS ----------
create table if not exists public.albums (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  artist text not null,
  cover_url text,
  year int
);

-- ---------- PLAYLISTS ----------
create table if not exists public.playlists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  name text not null,
  cover_url text,
  created_at timestamptz default now()
);

-- ---------- PLAYLIST_SONGS ----------
create table if not exists public.playlist_songs (
  playlist_id uuid references public.playlists(id) on delete cascade,
  song_id uuid references public.songs(id) on delete cascade,
  added_at timestamptz default now(),
  primary key (playlist_id, song_id)
);

-- ---------- LIKES ----------
create table if not exists public.likes (
  user_id uuid references auth.users(id) on delete cascade,
  song_id uuid references public.songs(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (user_id, song_id)
);

-- ---------- PLAY HISTORY ----------
create table if not exists public.play_history (
  user_id uuid references auth.users(id) on delete cascade,
  song_id uuid references public.songs(id) on delete cascade,
  played_at timestamptz default now(),
  primary key (user_id, song_id)
);

-- ---------- BANNERS ----------
create table if not exists public.banners (
  id uuid primary key default gen_random_uuid(),
  image_url text not null,
  link text,
  active boolean default true,
  created_at timestamptz default now()
);

-- ---------- increment plays function ----------
-- SECURITY DEFINER: runs with the owner's privileges so anonymous users
-- (who only have SELECT on `songs`) can still increment the play counter
-- via RPC. Without this, plays never increase and "Popular" stays empty.
create or replace function public.increment_plays(song_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.songs set plays = plays + 1 where id = song_id;
end;
$$;

-- Allow anonymous + authenticated users to call the RPC.
grant execute on function public.increment_plays(uuid) to anon, authenticated;

-- ============================================================
--  ROW LEVEL SECURITY
-- ============================================================
alter table public.songs        enable row level security;
alter table public.albums       enable row level security;
alter table public.banners      enable row level security;
alter table public.playlists    enable row level security;
alter table public.playlist_songs enable row level security;
alter table public.likes        enable row level security;
alter table public.play_history enable row level security;

-- Public content: anyone (even anon) can read songs / albums / banners
create policy "public read songs"   on public.songs   for select using (true);
create policy "public read albums"  on public.albums  for select using (true);
create policy "public read banners" on public.banners for select using (true);

-- Playlists: owner only
create policy "own playlists select" on public.playlists for select using (auth.uid() = user_id);
create policy "own playlists insert" on public.playlists for insert with check (auth.uid() = user_id);
create policy "own playlists update" on public.playlists for update using (auth.uid() = user_id);
create policy "own playlists delete" on public.playlists for delete using (auth.uid() = user_id);

-- Playlist songs: only if the playlist belongs to the user
create policy "own playlist_songs select" on public.playlist_songs for select
  using (exists (select 1 from public.playlists p where p.id = playlist_id and p.user_id = auth.uid()));
create policy "own playlist_songs insert" on public.playlist_songs for insert
  with check (exists (select 1 from public.playlists p where p.id = playlist_id and p.user_id = auth.uid()));
create policy "own playlist_songs delete" on public.playlist_songs for delete
  using (exists (select 1 from public.playlists p where p.id = playlist_id and p.user_id = auth.uid()));

-- Likes: owner only
create policy "own likes select" on public.likes for select using (auth.uid() = user_id);
create policy "own likes insert" on public.likes for insert with check (auth.uid() = user_id);
create policy "own likes delete" on public.likes for delete using (auth.uid() = user_id);

-- History: owner only
create policy "own history select" on public.play_history for select using (auth.uid() = user_id);
create policy "own history insert" on public.play_history for insert with check (auth.uid() = user_id);
create policy "own history update" on public.play_history for update using (auth.uid() = user_id);

-- ============================================================
--  SAMPLE DATA (optional — free/royalty-free test audio)
-- ============================================================
insert into public.songs (title, artist, cover_url, audio_url, genre, plays) values
  ('SoundHelix Song 1', 'SoundHelix', 'https://picsum.photos/seed/1/400', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3', 'Electronic', 120),
  ('SoundHelix Song 2', 'SoundHelix', 'https://picsum.photos/seed/2/400', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3', 'Pop', 340),
  ('SoundHelix Song 3', 'SoundHelix', 'https://picsum.photos/seed/3/400', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3', 'Rock', 90),
  ('SoundHelix Song 4', 'SoundHelix', 'https://picsum.photos/seed/4/400', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3', 'Chill', 210);

insert into public.banners (image_url, link, active) values
  ('https://picsum.photos/seed/banner1/800/300', 'https://t.me/YourChannel', true);

-- ============================================================
--  STORAGE (do this in the dashboard UI):
--  1) Storage -> New bucket -> name: "music"  -> Public bucket ✅
--  2) Storage -> New bucket -> name: "covers" -> Public bucket ✅
--  Then upload your mp3/cover files and paste their public URLs
--  into the songs table (audio_url / cover_url).
-- ============================================================
