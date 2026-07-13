-- Bot infrastructure for Iranian Spotify
-- Run this in Supabase SQL Editor (Dashboard -> SQL Editor -> Run)

-- 1) lyrics column on songs (if not already added)
ALTER TABLE songs ADD COLUMN IF NOT EXISTS lyrics TEXT;

-- 2) pending_songs: collects the 3-step submission (audio -> cover -> lyrics)
CREATE TABLE IF NOT EXISTS pending_songs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id bigint NOT NULL,
  step int NOT NULL DEFAULT 1,           -- 1 awaiting cover, 2 awaiting lyrics, 3 ready
  audio_file_id text,
  cover_file_id text,
  lyrics text DEFAULT '',
  title text DEFAULT 'بدون نام',
  artist text DEFAULT 'ناشناس',
  status text DEFAULT 'collecting',       -- collecting | pending | approved | rejected
  created_at timestamptz DEFAULT now()
);

-- 3) public storage buckets for audio + covers
INSERT INTO storage.buckets (id, name, public)
VALUES ('songs', 'songs', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public)
VALUES ('covers', 'covers', true) ON CONFLICT (id) DO NOTHING;

-- 4) RLS: pending_songs is only touched by the Edge Function (service role),
--    so no anon policy is needed. songs stays publicly readable.
--    (Make sure songs has an anon SELECT policy — it should already.)
