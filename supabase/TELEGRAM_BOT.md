# Telegram Bot — Iranian Spotify

The bot lets any user submit a song in 3 steps (audio → cover → lyrics). Every
submission waits for the admin to approve before it appears in the app.

## Setup (do this once)

1. Create the bot with @BotFather and copy the token.
2. In Supabase Dashboard → Project Settings → API, copy:
   - Project URL  (SUPABASE_URL)
   - service_role key (SUPABASE_SERVICE_ROLE_KEY)  ⚠️ secret, never commit
3. In Supabase Dashboard → Edge Functions → set Secrets:
   - TELEGRAM_BOT_TOKEN = <your bot token>
   - ADMIN_TELEGRAM_ID = 5080529808
   - SUPABASE_URL = https://xhpglphhbchejhciepcr.supabase.co
   - SUPABASE_SERVICE_ROLE_KEY = <service role key>
4. Deploy the function:
   supabase functions deploy telegram-bot
5. Set the Telegram webhook:
   curl -X POST "https://api.telegram.org/bot<TOKEN>/setWebhook" \
     -H "Content-Type: application/json" \
     -d '{"url":"https://xhpglphhbchejhciepcr.supabase.co/functions/v1/telegram-bot"}'
6. Apply SQL: run supabase/migrations/0003_bot.sql in SQL Editor.

## How it works
- User sends audio → bot asks for cover → user sends cover (or "رد") →
  bot asks for lyrics → user sends text (or "رد") → status = pending.
- Admin gets a message with /approve <id> and /reject <id>.
- On /approve, the function downloads the files, uploads to storage buckets
  (songs, covers) and inserts a row into `songs`. The app shows it immediately.
