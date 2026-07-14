-- Migration: bot v6 (genres, forced-join user state, channel text)
-- Run in Supabase SQL Editor (Dashboard > SQL Editor > New query > Run)

-- pending_songs new columns
ALTER TABLE pending_songs
  ADD COLUMN IF NOT EXISTS genre TEXT,
  ADD COLUMN IF NOT EXISTS cover_from_audio BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS audio_title TEXT,
  ADD COLUMN IF NOT EXISTS audio_performer TEXT,
  ADD COLUMN IF NOT EXISTS cover_url TEXT,
  ADD COLUMN IF NOT EXISTS anonymous BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS step INTEGER DEFAULT 0;

-- bot_users: per-user session + anonymous + mode
CREATE TABLE IF NOT EXISTS bot_users (
  chat_id BIGINT PRIMARY KEY,
  step INTEGER DEFAULT 0,
  data JSONB,
  anon BOOLEAN DEFAULT FALSE,
  mode TEXT
);

-- storage buckets (public) for songs + covers
INSERT INTO storage.buckets (id, name, public)
VALUES ('songs', 'songs', true), ('covers', 'covers', true)
ON CONFLICT (id) DO NOTHING;

-- ensure songs table has genre column
ALTER TABLE songs ADD COLUMN IF NOT EXISTS genre TEXT;
